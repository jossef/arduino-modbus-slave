/*
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

    This file is part of BrewTroller.

    BrewTroller is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    BrewTroller is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with BrewTroller.  If not, see <http://www.gnu.org/licenses/>.

FermTroller - Open Source Fermentation Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

void fermCore() {
word *tempPtr;

#ifdef LOG_ENABLED
  //Log data every 2s
  //Log 1 of 6 chunks per cycle to improve responsiveness to calling function
  if (millis() - lastLog > LOG_INTERVAL) {
    if (logCount == 0) {
      logPgm();
    } else if (logCount == 1) {
      logStart_P(LOGDATA);
      logField_P(PSTR("TIMER"));
      logFieldI(timerValue);
      logFieldI(timerStatus);
      logEnd();
      logStart_P(LOGDATA);
      logField_P(PSTR("ALARM"));
      logFieldI(alarmStatus);
      logEnd();
    } else if (logCount >= 2 && logCount <= NUM_ZONES + 2) {
      byte i = logCount - 2;
      logStart_P(LOGDATA);
      logField_P(PSTR("TEMP"));
      logFieldI(i);
      ftoa(temp[i], buf, 3);
      logField(buf);
      #ifdef USEMETRIC
        logFieldI(0);
      #else
        logFieldI(1);
      #endif
      logEnd();
    } else if (logCount >= NUM_ZONES + 3 && logCount <= NUM_ZONES * 2 + 2) {
      int pct;
      byte i = logCount - NUM_ZONES - 3;
      if (coolStatus[i]) pct = -100;
      else {
        if (PIDEnabled[i]) pct = PIDOutput[i] / PIDCycle[i] / 10;
        else if (heatStatus[i]) pct = 100;
        else pct = 0;
      }
      logStart_P(LOGDATA);
      logField_P(PSTR("HEATPWR"));
      logFieldI(i);
      logFieldI(pct);
      logEnd();
    } else if (logCount >= NUM_ZONES * 2 + 3 && logCount <= NUM_ZONES * 3 + 2) {
      byte i = logCount - NUM_ZONES * 2 - 3;
      logStart_P(LOGDATA);
      logField_P(PSTR("SETPOINT"));
      logFieldI(i);
      ftoa(setpoint[i], buf, 0);
      logField(buf);
      #ifdef USEMETRIC
        logFieldI(0);
      #else
        logFieldI(1);
      #endif
      logEnd();
    } else if (logCount == NUM_ZONES * 3 + 3) { if (millis() - lastLog > LOG_INTERVAL * 2) lastLog = millis(); else lastLog += LOG_INTERVAL; }
    if (logCount == NUM_ZONES * 3 + 3) logCount = 0;
    else logCount++;
  }
#endif

  //Check Temps
  if (convStart == 0) 
  {
    convertAll();
    convStart = millis();
  }
  else if (millis() - convStart >= 750) 
  {
    for (byte i = 0; i < NUM_ZONES + 1; i++) 
    {

      FtRegBank.set(30001+i,read_temp(tSensor[i]));
      temp[i] = (float)FtRegBank.get(30001+i) * 0.5;
    }
    convStart = 0;
  }
  

  //Set doMUXUpdate to 1 to force MUX update on each cycle.
  boolean doMUXUpdate = 0;

  //Process Outputs
  for (byte i = 0; i < NUM_ZONES; i++) {
    if (COOLPIN_OFFSET > i) {
      //Process PID Heat Outputs
      if (PIDEnabled[i]) {
        if (temp[i] == -1 || coolStatus[i]) {
          pid[i].SetMode(MANUAL);
          PIDOutput[i] = 0;
        } else {
          pid[i].SetMode(AUTO);
          PIDInput[i] = temp[i];
          pid[i].Compute();
        }
        if (cycleStart[i] == 0) cycleStart[i] = millis();
        if (millis() - cycleStart[i] > PIDCycle[i] * 1000) cycleStart[i] += PIDCycle[i] * 1000;
        if (PIDOutput[i] > millis() - cycleStart[i]) digitalWrite(outputPin[i], HIGH); else digitalWrite(outputPin[i], LOW);
      } 

      //Process On/Off Heat
      if (heatStatus[i]) {
        if (temp[i] == -1 || temp[i] >= setpoint[i]) {
          if (!PIDEnabled[i]) {
            if (!muxOuts[i]) digitalWrite(outputPin[i], LOW);
              else doMUXUpdate = 1;
          }
          heatStatus[i] = 0;
        }
      } else { 
        if (temp[i] != -1 && ((float)(setpoint[i] - temp[i]) >= (float) hysteresis[i] / 10.0)) {
          if (!PIDEnabled[i]) {
            if (!muxOuts[i]) digitalWrite(outputPin[i], HIGH);
              else doMUXUpdate = 1;
          }
          heatStatus[i] = 1;
        }
      }
    }
    
    if (NUM_OUTS - COOLPIN_OFFSET > i) {
      //Process On/Off Cool
      if (coolStatus[i]) {
        if (temp[i] == -1 || temp[i] <= setpoint[i] || setpoint[i] == 0) {
          if (!muxOuts[i + COOLPIN_OFFSET]) digitalWrite(outputPin[i + COOLPIN_OFFSET], LOW);
            else doMUXUpdate = 1;
          coolStatus[i] = 0;
        }
        coolOnTime[i] = millis() + coolDelay[i] * 1000;
      } else {
        if (temp[i] != -1 && setpoint[i] != 0 && (float)(temp[i] - setpoint[i]) >= (float) hysteresis[i] / 10.0) {
          //Check Cool Off Time Limit
          if (coolOnTime[i] <= millis()) {
            if (!muxOuts[i + COOLPIN_OFFSET]) digitalWrite(outputPin[i + COOLPIN_OFFSET], HIGH);
              else doMUXUpdate = 1;
            coolStatus[i] = 1;
            coolOnTime[i] = millis() + coolDelay[i] * 1000;
          }
        }
      }
      setCoolDelaySecs(i);
    }
  }
  
#ifdef USE_MUX
  if (doMUXUpdate) {
    //Disable outputs
    digitalWrite(MUX_OE_PIN, HIGH);
    //ground latchPin and hold low for as long as you are transmitting
    digitalWrite(MUX_LATCH_PIN, LOW);
    //clear everything out just in case to prepare shift register for bit shifting
    digitalWrite(MUX_DATA_PIN, LOW);
    digitalWrite(MUX_CLOCK_PIN, LOW);

    //for each bit in the long myDataOut
    for (byte i = 32; i > 0; i--)  {
      digitalWrite(MUX_CLOCK_PIN, LOW);
      //create bitmask to grab the bit associated with our counter i and set data pin accordingly (NOTE: 32 - i causes bits to be sent most significant to least significant)
      if (muxOuts[i - 1]) {
        if (i - 1 < COOLPIN_OFFSET) digitalWrite(MUX_DATA_PIN, heatStatus[i - 1]);
        else if (i - 1 < NUM_OUTS) digitalWrite(MUX_DATA_PIN, coolStatus[i - 1 - COOLPIN_OFFSET]);
        else digitalWrite(MUX_DATA_PIN, LOW);
      } else digitalWrite(MUX_DATA_PIN, LOW);
      //register shifts bits on upstroke of clock pin  
      digitalWrite(MUX_CLOCK_PIN, HIGH);
      //zero the data pin after shift to prevent bleed through
      digitalWrite(MUX_DATA_PIN, LOW);
    }

    //stop shifting
    digitalWrite(MUX_CLOCK_PIN, LOW);
    digitalWrite(MUX_LATCH_PIN, HIGH);
    //Enable outputs
    digitalWrite(MUX_OE_PIN, LOW);
  }
    

#endif
}
