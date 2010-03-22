#include <encoder.h>
#include <pin.h>

#define BUILD 379 
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


//*****************************************************************************************************************************
// USER COMPILE OPTIONS
//*****************************************************************************************************************************

//**********************************************************************************
// UNIT (Metric/US)
//**********************************************************************************
// By default BrewTroller will use US Units
// Uncomment USEMETRIC below to use metric instead
// 
//#define USEMETRIC
//**********************************************************************************

//**********************************************************************************
// BrewTroller Board Version
//**********************************************************************************
// The Brewtroller 3.0 board uses MUX instead of direct on-board outputs.
// 
#define BTBOARD_3
//**********************************************************************************

//**********************************************************************************
// ENCODER TYPE
//**********************************************************************************
// You must uncomment one and only one of the following ENCODER_ definitions
// Use ENCODER_ALPS for ALPS and Panasonic Encoders
// Use ENCODER_CUI for older CUI encoders
// 
//#define ENCODER_ALPS
//#define ENCODER_CUI
#define ENCODER ALPS

//**********************************************************************************

//**********************************************************************************
// Number of Zones
//**********************************************************************************
// Theoretical maximum value is 32 zones
//
// Default for BTBOARD_2.x is 6 zones
// Default for BTBOARD_3 is 8 zones
// 
//#define NUM_ZONES 6
//**********************************************************************************

//**********************************************************************************
// Number of Outputs
//**********************************************************************************
// The total number of outputs used
// 12 is the theoretical maximum for non-MUX
// MUX enabled systems could support up to 32 outputs
// 
// Default for BTBOARD_2.x is 12 outputs
// Default for BTBOARD_3 is 16 outputs
//
//#define NUM_OUTS 12
//**********************************************************************************

//**********************************************************************************
// Number of Cool/Heat Outputs
//**********************************************************************************
// The number of output pins dedicated to heat
// Increase to trade cool outputs for heat.
// Decrease to trade heat outputs for cool.
// If there are fewer heat or cool outputs than zones, the outputs will be applied
// starting with Zone 1. Higher zones will lack those outputs.
// 
// Default for BTBOARD_2.x is 6 (6+6)
// Default for BTBOARD_3 is 8 (8+8)
//
// Examples:
//   NUM_ZONES 6, NUM_OUTS 12, COOLPIN_OFFSET 6 gives 6 zones with heat on 1-6 and cool on 1-6 (Default)
//   NUM_ZONES 8, NUM_OUTS 12, COOLPIN_OFFSET 8 gives 8 zones with heat on 1-8 and cool on 1-4
//   NUM_ZONES 8, NUM_OUTS 12, COOLPIN_OFFSET 4 gives 8 zones with heat on 1-4 and cool on 1-8
//   NUM_ZONES 12, NUM_OUTS 12, COOLPIN_OFFSET 0 gives 12 zones with cool on 1-12
//   NUM_ZONES 12, NUM_OUTS 12, COOLPIN_OFFSET 12 gives 12 zones with heat on 1-12
//
//#define COOLPIN_OFFSET 6
//**********************************************************************************

//**********************************************************************************
// Number of PID Outputs
//**********************************************************************************
//WARNING: A value greater than 5 on 3.x boards will conflict with MUX outputs.
//Output pin 5 is not connected on the 3.x board. A value of 0-4 is recommended for 3.x boards.
//Theoretical limit for is 12 on 2.x boards, matching NUM_OUTS. 
//PID is only used on heat so a value > 6 would only be useful if you were using > 6 zones.
// 
// Default for BTBOARD_2.x is 6
// Default for BTBOARD_3 is 4
//
//#define NUM_PID_OUTS 6
//**********************************************************************************

//**********************************************************************************
// Enable MUX
//**********************************************************************************
// 3.x boards use MUX by default. Use this setting to enable MUX on 2.x boards
//
//#define USE_MUX
//**********************************************************************************

//**********************************************************************************
// LOG INTERVAL
//**********************************************************************************
// Specifies how often data is logged via serial in milliseconds. If real time
// display of data is being used a smaller interval is best (1000 ms). A larger
// interval can be used for logging applications to reduce log file size (5000 ms).

#define LOG_INTERVAL 2000
// #define LOG_ENABLED

//**********************************************************************************

//**********************************************************************************
// LCD Timing Fix
//**********************************************************************************
// Some LCDs seem to have issues with displaying garbled characters but introducing
// a delay seems to help or resolve completely. You may comment out the following
// lines to remove this delay between a print of each character.
//
//#define LCD_DELAY_CURSOR 60
//#define LCD_DELAY_CHAR 60
//**********************************************************************************

//**********************************************************************************
// Cool Cycle Limit
//**********************************************************************************
// When using cool outputs for devices with compressors like refrigerators you may
// need to specify a minimum delay before enabling the output. This is intended to
// eliminate quick cycling of the output On/Off. Specify a limit in seconds for each
// zone in the array below. Maximum value is 255 seconds or approximately 4.2 min.
//
byte coolDelay[32] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
//**********************************************************************************

//**********************************************************************************
// DEBUG
//**********************************************************************************
// Enables Serial Out with Additional Debug Data
//
//#define DEBUG
//**********************************************************************************

//**********************************************************************************
// MODBUS SLAVE
//**********************************************************************************
// Enables FermTroller to become a modbus slave device
//
#define MODBUS_SLAVE
#define MODBUS_DEVICE_ID 1
#define MODBUS_BPS 9600

//**********************************************************************************

//*****************************************************************************************************************************
// BEGIN CODE
//*****************************************************************************************************************************
#include <avr/pgmspace.h>
#include <PID_Beta6.h>

#include <modbus.h>
#include <modbusDevice.h>
#include <modbusRegBank.h>
#include <modbusSlave.h>

//Pin and Interrupt Definitions
#define ENCA_PIN 2
#define ENCB_PIN 4
#define TEMP_PIN 5
#define ENTER_PIN 11
#define ALARM_PIN 15
#define ENTER_INT 1
#define ENCA_INT 2

//Output Pin Array
//BTBOARD_3 uses only the first four pins and uses MUX for the remaining outputs
byte outputPin[12] = { 0, 1, 3, 6, 7, 10, 12, 13, 14, 24, 18, 16 };

//float/dual word union
typedef union
{
  float fl;
  word in[2];
}fi;

//BTBOARD_3 Defaults: MUX, 16 Outputs, 8 Zones, 8 Heat Pins + 8 Cool Pins, 4 PID Heat Outputs
#if defined BTBOARD_3 && !defined USE_MUX
  #define USE_MUX
#endif

#if defined BTBOARD_3 && !defined NUM_OUTS
  #define NUM_OUTS 16
#endif

#if defined BTBOARD_3 && !defined NUM_ZONES
  #define NUM_ZONES 8
#endif

#if defined BTBOARD_3 && !defined COOLPIN_OFFSET
  #define COOLPIN_OFFSET 8
#endif

#if defined USE_MUX && !defined NUM_PID_OUTS
  #define NUM_PID_OUTS 4
#endif

//BTBOARD_2.x Defaults: 12 Outputs, 6 Zones, 6 Heat Pins + 6 Cool Pins, 6 PID Heat Outputs
#if !defined BTBOARD_3 && !defined NUM_OUTS
  #define NUM_OUTS 12
#endif

#if !defined BTBOARD_3 && !defined NUM_ZONES
  #define NUM_ZONES 6
#endif

#if !defined BTBOARD_3 && !defined COOLPIN_OFFSET
  #define COOLPIN_OFFSET 6
#endif

#if !defined BTBOARD_3 && !defined NUM_PID_OUTS
  #define NUM_PID_OUTS 6
#endif

#ifdef USE_MUX
  #define MUX_LATCH_PIN 12
  #define MUX_CLOCK_PIN 13
  #define MUX_DATA_PIN 14
  #define MUX_OE_PIN 10
  boolean muxOuts[32] = {0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
#else
  boolean muxOuts[32] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
#endif

//Safety catch if using fewer zones than defined PID outputs
#if NUM_PID_OUTS > NUM_ZONES
  #define NUM_PID_OUTS NUM_ZONES
#endif

//Encoder Globals
int encCount;
byte encMin;
byte encMax;
byte enterStatus = 0;

//8-byte Temperature Sensor Address x6 Sensors
byte tSensor[NUM_ZONES + 1][8];
float temp[NUM_ZONES + 1];
word rawTemp[NUM_ZONES +1];

unsigned long convStart = 0;

//Shared menuOptions Array
char menuopts[45][20];

//Common Buffer
char buf[11];

//Output Globals
double PIDInput[NUM_PID_OUTS], PIDOutput[NUM_PID_OUTS], setpoint[NUM_ZONES];
byte PIDp[NUM_PID_OUTS], PIDi[NUM_PID_OUTS], PIDd[NUM_PID_OUTS], PIDCycle[NUM_PID_OUTS], hysteresis[NUM_ZONES];
unsigned long cycleStart[NUM_PID_OUTS];
boolean heatStatus[NUM_ZONES];
boolean coolStatus[NUM_ZONES];
boolean PIDEnabled[32];
unsigned long coolOnTime[32];

PID pid[NUM_PID_OUTS] = {
  #if NUM_PID_OUTS > 0
    PID(&PIDInput[0], &PIDOutput[0], &setpoint[0], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 1
    PID(&PIDInput[1], &PIDOutput[1], &setpoint[1], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 2
    PID(&PIDInput[2], &PIDOutput[2], &setpoint[2], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 3
    PID(&PIDInput[3], &PIDOutput[3], &setpoint[3], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 4
    PID(&PIDInput[4], &PIDOutput[4], &setpoint[4], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 5
    PID(&PIDInput[5], &PIDOutput[5], &setpoint[5], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 6
    PID(&PIDInput[6], &PIDOutput[6], &setpoint[6], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 7
    PID(&PIDInput[7], &PIDOutput[7], &setpoint[7], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 8
    PID(&PIDInput[8], &PIDOutput[8], &setpoint[8], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 9
    PID(&PIDInput[9], &PIDOutput[9], &setpoint[9], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 10
    PID(&PIDInput[10], &PIDOutput[10], &setpoint[10], 3, 4, 1),
  #endif
  #if NUM_PID_OUTS > 11
    PID(&PIDInput[11], &PIDOutput[11], &setpoint[11], 3, 4, 1),
  #endif 
};

//Timer Globals
unsigned long timerValue = 0;
unsigned long lastTime = 0;
unsigned long timerLastWrite = 0;
boolean timerStatus = 0;
boolean alarmStatus = 0;

#ifdef LOG_ENABLED
char msg[25][21];
byte msgField = 0;
boolean msgQueued = 0;
#endif

byte pwrRecovery;

unsigned long lastLog;
byte logCount;

const char BT[] PROGMEM = "FermTroller";
const char BTVER[] PROGMEM = "v0.1";

//Log Message Classes
const char LOGCMD[] PROGMEM = "CMD";
const char LOGDEBUG[] PROGMEM = "DEBUG";
const char LOGSYS[] PROGMEM = "SYSTEM";
const char LOGGLB[] PROGMEM = "GLOBAL";
const char LOGDATA[] PROGMEM = "DATA";

//Other PROGMEM Repeated Strings
const char PWRLOSSRECOVER[] PROGMEM = "PLR";
const char INIT_EEPROM[] PROGMEM = "Initialize EEPROM";
const char CANCEL[] PROGMEM = "Cancel";
const char EXIT[] PROGMEM = "Exit";
const char SPACE[] PROGMEM = " ";
const char CONTINUE[] PROGMEM = "Continue";
const char ABORT[] PROGMEM = "Abort";
        
#ifdef USEMETRIC
const char VOLUNIT[] PROGMEM = "l";
const char WTUNIT[] PROGMEM = "kg";
const char TUNIT[] PROGMEM = "C";
const char PUNIT[] PROGMEM = "kPa";
#else
const char VOLUNIT[] PROGMEM = "gal";
const char WTUNIT[] PROGMEM = "lb";
const char TUNIT[] PROGMEM = "F";
const char PUNIT[] PROGMEM = "psi";
#endif

//Custom LCD Chars
const byte CHARFIELD[] PROGMEM = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARCURSOR[] PROGMEM = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARSEL[] PROGMEM = {B10001, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte BMP[][8] PROGMEM = {B00000, B00000, B00000, B00000, B00011, B01111, B11111, B11111,
                              B00000, B00000, B00000, B00000, B11100, B11110, B11111, B11111,
                              B00001, B00011, B00111, B01111, B00001, B00011, B01111, B11111,
                              B11111, B11111, B10001, B00011, B01111, B11111, B11111, B11111,
                              B11111, B11111, B11111, B11111, B11111, B11111, B11111, B11111,
                              B01111, B01110, B01100, B00001, B01111, B00111, B00011, B11101,
                              B11111, B00111, B00111, B11111, B11111, B11111, B11110, B11001,
                              B11111, B11111, B11110, B11101, B11011, B00111, B11111, B11111};
  
#ifdef MODBUS_SLAVE  
modbusDevice FtRegBank;
modbusSlave  FtSlave;
#endif

void setup() {
int i;

#ifdef LOG_ENABLED
  Serial.begin(9600);
  Serial.println();
#endif

//#ifdef MODBUS_SLAVE
  FtRegBank.setId(MODBUS_DEVICE_ID);
  FtSlave._device = &FtRegBank;
  FtSlave.setBaud(MODBUS_BPS);


for(i = 0; i < NUM_ZONES ; i++)
{
  FtRegBank.add(30001+i);
}
//#endif

  FtSlave.setBaud(MODBUS_BPS);
  
  //Start the encoder  
  Encoder.begin(ENCA_PIN, ENCB_PIN, ENTER_PIN, ENTER_INT, ENCODER);

  for (byte i = 0; i < 12; i++) if (!muxOuts[i]) pinMode(outputPin[i], OUTPUT);
 
  #ifdef USE_MUX
    pinMode(MUX_LATCH_PIN, OUTPUT);
    pinMode(MUX_CLOCK_PIN, OUTPUT);
    pinMode(MUX_DATA_PIN, OUTPUT);
    pinMode(MUX_OE_PIN, OUTPUT);
  #endif
  resetOutputs();
  initLCD();
  
  //Memory Check
  //printLCD(0,0,itoa(availableMemory(), buf, 10)); delay (5000);
  
  //Check for cfgVersion variable and format EEPROM if necessary
  checkConfig();
  
  //Load global variable values stored in EEPROM
  loadSetup();

  for (byte i = 0; i < NUM_PID_OUTS; i++) {
      pid[i].SetInputLimits(0, 255);
      pid[i].SetOutputLimits(0, PIDCycle[i] * 1000);
      pid[i].SetTunings(PIDp[i], PIDi[i], PIDd[i]);
  }
  
  if (pwrRecovery == 1) {
    logPLR();
    doMon();
  } else {
    splashScreen();
  }
}

void loop() 
{
  strcpy_P(menuopts[0], PSTR("Start"));
  strcpy_P(menuopts[1], PSTR("System Setup"));
 
  byte lastoption = scrollMenu("FermTroller", 2, 0);
  if (lastoption == 0) 
	doMon();
  else if (lastoption == 1)
	menuSetup();
}

void splashScreen() 
{
  int i;
  
  clearLCD();
  for(i=0;i<8;i++);
    lcdSetCustChar_P(i, BMP[i]);
 
  lcdWriteCustChar(0, 1, 0);
  lcdWriteCustChar(0, 2, 1);
  lcdWriteCustChar(1, 0, 2); 
  lcdWriteCustChar(1, 1, 3); 
  lcdWriteCustChar(1, 2, 4); 
  lcdWriteCustChar(2, 0, 5); 
  lcdWriteCustChar(2, 1, 6); 
  lcdWriteCustChar(2, 2, 7); 

  printLCD_P(0, 4, BT);
  printLCD_P(0, 16, BTVER);
  printLCD_P(1, 10, PSTR("Build "));
  printLCDLPad(1, 16, itoa(BUILD, buf, 10), 4, '0');
  printLCD_P(3, 1, PSTR("www.brewtroller.com"));


  while(!Encoder.getEnter()) 
  {
#ifdef LOG_ENABLED
    if (chkMsg()) rejectMsg(LOGGLB);
#endif

#ifdef MODBUS_SLAVE
    FtSlave.run();
#endif

    fermCore();
  }
  Encoder.clearEnter();
}

