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

void(* softReset) (void) = 0;

void logPLR() {
#ifdef LOG_ENABLED
  logStart_P(LOGGLB);
  logField_P(PSTR("PLR"));
  logFieldI(pwrRecovery);
  logEnd();
#endif
}

void logPgm() {
#ifdef LOG_ENABLED
  logStart_P(LOGDATA);
  logField_P(PSTR("PGM"));
  logFieldI(pwrRecovery);
  logEnd();
#endif
}

void logString_P (const char *sType, const char *sText) {
#ifdef LOG_ENABLED
 logStart_P(sType);
 logField_P(sText);
 logEnd();
#endif
}

void logStart_P (const char *sType) {
#ifdef LOG_ENABLED
 Serial.print(millis(),DEC);
 Serial.print("\t");
 while (pgm_read_byte(sType) != 0) Serial.print(pgm_read_byte(sType++)); 
 Serial.print("\t");
#endif
}

void logEnd () {
#ifdef LOG_ENABLED
 Serial.println();
#endif
}

void logField (char sText[]) {
#ifdef LOG_ENABLED
  Serial.print(sText);
  Serial.print("\t");
#endif
}

void logFieldI (unsigned long value) {
#ifdef LOG_ENABLED
  Serial.print(value, DEC);
  Serial.print("\t");
#endif
}

void logField_P (const char *sText) {
#ifdef LOG_ENABLED
  while (pgm_read_byte(sText) != 0) Serial.print(pgm_read_byte(sText++));
  Serial.print("\t");
#endif
}

boolean chkMsg() {
#ifdef LOG_ENABLED
  if (!msgQueued) {
    while (Serial.available()) {
      byte byteIn = Serial.read();
      if (byteIn == '\r') { 
        msgQueued = 1;
        //Check for Global Commands
        if       (strcasecmp(msg[0], "GET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val < NUM_ZONES + 1) {
            logTSensor(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 9 && val < NUM_ZONES + 1) {
            for (byte i=0; i<8; i++) tSensor[val][i] = (byte)atoi(msg[i+2]);
            saveSetup();
            clearMsg();
            logTSensor(val);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SCAN_TS") == 0) {
          byte tsAddr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
          getDSAddr(tsAddr);
          logStart_P(LOGGLB);
          logField_P(PSTR("TS_SCAN"));
          for (byte i=0; i<8; i++) logFieldI(tsAddr[i]);
          logEnd();
        } else if(strcasecmp(msg[0], "GET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val < NUM_ZONES) {
            logOSet(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 7 && val < NUM_ZONES) {
            if (val < NUM_PID_OUTS) {
              PIDEnabled[val] = (byte)atoi(msg[2]);
              PIDCycle[val] = (byte)atoi(msg[3]);
              PIDp[val] = (byte)atoi(msg[4]);
              PIDi[val] = (byte)atoi(msg[5]);
              PIDd[val] = (byte)atoi(msg[6]);
            }
            hysteresis[val] = (byte)atoi(msg[7]);
            saveSetup();
            clearMsg();
            logOSet(val);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_UNIT") == 0) {
          clearMsg();
          logStart_P(LOGGLB);
          logField_P(PSTR("UNIT"));
          #ifdef USEMETRIC
            logFieldI(0);
          #else
            logFieldI(1);
          #endif
          logEnd();
        } else if(strcasecmp(msg[0], "RESET") == 0) {
          if (msgField == 1 && strcasecmp(msg[1], "SURE") == 0) {
            clearMsg();
            logStart_P(LOGSYS);
            logField_P(PSTR("SOFT_RESET"));
            logEnd();
            softReset();
          }
        } else if(strcasecmp(msg[0], "GET_PLR") == 0) {
          clearMsg();
          logPLR();
        } else if(strcasecmp(msg[0], "SET_PLR") == 0) {
          byte PLR = atoi(msg[1]);
          if (msgField == 1 && PLR >= 0 && PLR <= 2) {
            setPwrRecovery(PLR);
            clearMsg();
            logPLR();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "PING") == 0) {
          clearMsg();
          logStart_P(LOGGLB);
          logField_P(PSTR("PONG"));
          logEnd();
        } else if(strcasecmp(msg[0], "SET_SETPOINT") == 0) {
          byte zone = atoi(msg[1]);
          if (msgField == 2 && zone < NUM_ZONES) {
            setpoint[zone] = (byte)atoi(msg[2]);
            saveSetpoints();
            clearMsg();
          } else rejectParam(LOGGLB);
        }
        break;
      } else if (byteIn == '\t') {
        if (msgField < 25) {
          msgField++;
        } else {
          logString_P(LOGCMD, PSTR("MSG_OVERFLOW"));
          clearMsg();
        }
      } else {
        byte charCount = strlen(msg[msgField]);
        if (charCount < 20) { 
          msg[msgField][charCount] = byteIn; 
          msg[msgField][charCount + 1] = '\0';
        } else {
          logString_P(LOGCMD, PSTR("FIELD_OVERFLOW"));
          clearMsg();
        }
      }
    }
  }
  if (msgQueued) return 1; else return 0;
#endif
  return(0);
}

void clearMsg() {
#ifdef LOG_ENABLED
  msgQueued = 0;
  msgField = 0;
  for (byte i = 0; i < 20; i++) msg[i][0] = '\0';
#endif
}

void rejectMsg(const char *handler) {
#ifdef LOG_ENABLED
  logStart_P(LOGCMD);
  logField_P(PSTR("UNKNOWN_CMD"));
  logField_P(handler);
  for (byte i = 0; i < msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
#endif
}

void rejectParam(const char *handler) {
#ifdef LOG_ENABLED
  logStart_P(LOGCMD);
  logField_P(PSTR("BAD_PARAM"));
  logField_P(handler);
  for (byte i = 0; i < msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
#endif
}

void logTSensor(byte sensor) {
#ifdef LOG_ENABLED
  logStart_P(LOGGLB);
  logField_P(PSTR("TS_ADDR"));
  logFieldI(sensor);
  for (byte i=0; i<8; i++) logFieldI(tSensor[sensor][i]);
  logEnd();
#endif
}

void logOSet(byte zone) {
#ifdef LOG_ENABLED
  logStart_P(LOGGLB);
  logField_P(PSTR("OUTPUT_SET"));
  logFieldI(zone);
  logFieldI(PIDEnabled[zone]);
  if (zone < NUM_PID_OUTS) {
    logFieldI(PIDCycle[zone]);
    logFieldI(PIDp[zone]);
    logFieldI(PIDi[zone]);
    logFieldI(PIDd[zone]);
  } else {
    logFieldI(0);
    logFieldI(0);
    logFieldI(0);
    logFieldI(0);
  }
  logFieldI(hysteresis[zone]);
  logEnd();
#endif
}

