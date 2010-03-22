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

#include <avr/EEPROM.h>
#include <EEPROM.h>

void saveSetup() {
  //Option Array
  //EEPROM bytes 0-3 (was 57)
  //Bits 1, 2, 4, 8, 16, 32, 64, 128 = Pid Enabled for Zones 1-6
  for (byte b = 0; b < 4; b++) {
    byte options = B00000000;
    for (byte i = 0; i < 8; i++) if (PIDEnabled[b * 8 + i]) options |= 1<<i;
    EEPROM.write(b, options);
  }

  //88-96 Reserved for Power Recovery

  //Walk through the tSensor elements and store 8-byte address of each
  //Theoretical maximum of 32 zones + ambient
  //EEPROM bytes 100-363 (Was 0-55)
  for (byte i = 0; i < NUM_ZONES + 1; i++) PROMwriteBytes(100 + i * 8, tSensor[i], 8);

  
  
  //Output Settings for Zones 
  //EEPROM bytes 400-559 (Was 58-87)
  for (byte i = 0; i < NUM_ZONES; i++) {
    if (i < NUM_PID_OUTS) {
      EEPROM.write(i * 5 + 400, PIDp[i]);
      EEPROM.write(i * 5 + 401, PIDi[i]);
      EEPROM.write(i * 5 + 402, PIDd[i]);
      EEPROM.write(i * 5 + 403, PIDCycle[i]);
    }
    EEPROM.write(i * 5 + 404, hysteresis[i]);
  }
  
  //600-631 CoolOffTime counters
  
  //2046 FermTroller FingerPrint
  //2047 EEPROM Version
}

void loadSetup() {
  //Option Array
  // EEPROM bytes 0-3 (was 57)
  //Bits 1, 2, 4, 8, 16, 32, 64, 128 = Pid Enabled for Zones 1-6
  for (byte b = 0; b < 4; b++) {
    byte options = EEPROM.read(b);
    for (byte i = 0; i < 8; i++) { 
      if (b * 8 + i < NUM_PID_OUTS) {
        if (options & 1<<i) PIDEnabled[b * 8 + i] = 1; else PIDEnabled[b * 8 + i] = 0;
      } else PIDEnabled[b * 8 + i] = 0;
    }
  }

  //Power Recovery(88)
  pwrRecovery = EEPROM.read(88);
  
  //Setpoints
  //EEPROM bytes 4-35 (Was 89-94)
  for (byte i = 0; i < NUM_ZONES; i++) setpoint[i] = EEPROM.read(4 + i);
  
  //95 - 96 Timer Recovery


  //Walk through the tSensor elements and store 8-byte address of each
  //Theoretical maximum of 32 zones + ambient
  //EEPROM bytes 100-363 (Was 0-55)
  for (byte i = 0; i < NUM_ZONES + 1; i++) {
    PROMreadBytes(100 + i * 8, tSensor[i], 8);
    logTSensor(i);
  }
  
  //Output Settings for Zones 
  //EEPROM bytes 400-559 (Was 58-87)
  for (byte i = 0; i < NUM_ZONES; i++) {
    if (i < NUM_PID_OUTS) {
      PIDp[i] = EEPROM.read(i * 5 + 400);
      PIDi[i] = EEPROM.read(i * 5 + 401);
      PIDd[i] = EEPROM.read(i * 5 + 402);
      PIDCycle[i] = EEPROM.read(i * 5 + 403);
    }
    hysteresis[i] = EEPROM.read(i * 5 + 404);
    logOSet(i);
  }

//600-631 coolOffTime counters
for (byte zone = 0; zone <= NUM_ZONES; zone++) coolOnTime[zone] = EEPROM.read(600 + zone) * 1000;

  //2046 FermTroller FingerPrint
  //2047 EEPROM Version
}

void PROMwriteBytes(int addr, byte bytes[], byte numBytes) {
  for (byte i = 0; i < numBytes; i++) {
    EEPROM.write(addr + i, bytes[i]);
  }
}

void PROMreadBytes(int addr, byte bytes[], byte numBytes) {
  for (byte i = 0; i < numBytes; i++) {
    bytes[i] = EEPROM.read(addr + i);
  }
}

void checkConfig() {
  byte cfgVersion = EEPROM.read(2047);
  byte FTfingerprint = EEPROM.read(2046); //253 = FermTroller

#ifdef DEBUG
  logStart_P(LOGDEBUG);
  logField_P(PSTR("CFGVER"));
  logFieldI(cfgVersion);
  logEnd();
#endif

  if (cfgVersion == 255 || FTfingerprint != 253) cfgVersion = 0;
  switch(cfgVersion) {
    case 0:
      clearLCD();
      printLCD_P(0, 0, PSTR("Missing Config"));
      {
        strcpy_P(menuopts[0], INIT_EEPROM);
        strcpy_P(menuopts[1], CANCEL);
        if (!getChoice(2, 3)) {
          clearLCD();
          logString_P(LOGSYS, INIT_EEPROM);
          printLCD_P(1, 0, INIT_EEPROM);
          printLCD_P(2, 3, PSTR("Please Wait..."));
          //Format EEPROM to 0's
          for (int i=0; i<2048; i++) EEPROM.write(i, 0);
          {
            //Default Output Settings: p: 3, i: 4, d: 2, cycle: 4s, Hysteresis 0.3C(0.5F)
            #ifdef USEMETRIC
              byte defOutputSettings[5] = {3, 4, 2, 4, 3};
            #else
              byte defOutputSettings[5] = {3, 4, 2, 4, 5};
            #endif
            PROMwriteBytes(58, defOutputSettings, 5);
            PROMwriteBytes(63, defOutputSettings, 5);
            PROMwriteBytes(68, defOutputSettings, 5);
            PROMwriteBytes(73, defOutputSettings, 5);
          }
        }
      }
      //Set FermTroller Fingerprint
      EEPROM.write(2046, 253);
      //Set cfgVersion = 1
      EEPROM.write(2047, 1);
    case 1:
      //Bump cfgVersion up to 7 to resolve EEPROM mismatch with BT
      EEPROM.write(2047, 7);
    case 7:
      //Next Update
    default:
      //No EEPROM Upgrade Required
      return;
  }
}

long PROMreadLong(int address) {
  long out;
  eeprom_read_block((void *) &out, (unsigned char *) address, 4);
  return out;
}

void PROMwriteLong(int address, long value) {
  eeprom_write_block((void *) &value, (unsigned char *) address, 4);
}

int PROMreadInt(int address) {
  int out;
  eeprom_read_block((void *) &out, (unsigned char *) address, 2);
  return out;
}

void PROMwriteInt(int address, int value) {
  eeprom_write_block((void *) &value, (unsigned char *) address, 2);
}

void setPwrRecovery(byte funcValue) {
  pwrRecovery = funcValue;
  EEPROM.write(88, funcValue);
}

  //Setpoints
  //EEPROM bytes 4-35 (Was 89-94)
void saveSetpoints() { for (byte i = 0; i < NUM_ZONES; i++) { EEPROM.write(4 + i, setpoint[i]); } }

unsigned int getTimerRecovery() { return PROMreadInt(95); }
void setTimerRecovery(unsigned int newMins) { PROMwriteInt(95, newMins); }

//EEPROM bytes 600-631
//Store seconds of Cool-On delay remaining in EEPROM for each zone
void setCoolDelaySecs(byte zone) {
  if (coolOnTime[zone] > millis()) EEPROM.write(600 + zone, round((coolOnTime[zone] - millis()) / 1000));
  else EEPROM.write(600 + zone, 0);
}
