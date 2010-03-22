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
#include <encoder.h>

encoder::encoder(void)
{
	_count = 0;
	_min = 0;
	_max = 0;
	_wrap = 0;
}

//Use this method to define the encoder type, ALPS or CUI
void encoder::begin(byte encA, byte encB, byte enter, byte enterInt, byte type)
{
	_count = 0;
	_enterInterrupt = enterInt;
	_type = type;

	_aPin.setup(encA,INPUT);
	_bPin.setup(encB,INPUT);
	_enterPin.setup(enter,INPUT);

	this->attach();
}

//Use the default encoder type, ALPS
void encoder::begin(byte encA, byte encB, byte enter, byte enterInt)
{
	_count = 0;
	_enterInterrupt = enterInt;
	_type = ALPS;

	_aPin.setup(encA,INPUT);
	_bPin.setup(encB,INPUT);
	_enterPin.setup(enter,INPUT);

	this->attach();
}

void encoder::setMin(int min)
{
	_min = min;
}

void encoder::setMax(int max)
{
	_max = max;
}

void encoder::setWrap(void)
{
	_wrap = 0xFF;
}

void encoder::clearWrap(void)
{
	_wrap = 0x00;
}

void encoder::setCount(int count)
{
	_count = count;
	_oldCount = _count;
}

int encoder::getCount(void)
{
	if(_wrap)
	{
		//Permit wrap around
		if(_count < _min)
			_count = _max;
		else if(_count > _max)
			_count = _min;
	}
	else
	{
		_count = min(_count,_max);
		_count = max(_count,_min);
	}
	return(_count);
}

void encoder::clearCount(void)
{
	_count = _min;
}

/* encoder::getDelta()
compares the current count to the old count
updates old count to the current count
and returns the difference
*/
int encoder::getDelta(void)
{
	int delta,
		count;

	count = this->getCount();

	delta = count - _oldCount;
	_oldCount = count;

	return(delta);
}

/* encoder::change()
if the count has not changed since the last
time change was called then return -1;
else update the old count and return the new
count value
*/
int encoder::change(void)
{
	if(this->getDelta())
		return(_count);
	else
		return(-1);
}

//Checks for an OK encoder enter value
//returns true if enter is set to OK and clears
//the enter value
byte encoder::ok(void)
{
	byte ret;
	
	if(_enter == 1)
	{
		ret = 0xFF;
		_enter = 0;
	}
	else
		ret = 0x00;

	return(ret);
}

//Checks for a CANCEL encoder enter value
//returns true if enter is set to CANCEL and clears
//the enter value
byte encoder::cancel(void)
{
	byte ret;
	
	if(_enter == 2)
	{
		ret = 0xFF;
		_enter = 0;
	}
	else
		ret = 0x00;

	return(ret);
}

byte encoder::getEnter(void)
{
	return(_enter);
}


void encoder::clearEnter(void)
{
	_enter = 0;
}

//Installs the encoder ISRs
void encoder::attach(void)
{
	//disable interrupts
	noInterrupts();

	if(_type == ALPS)
		attachInterrupt(_aPin.getPin(), alpsISR, CHANGE);
	else if(_type == CUI)
		attachInterrupt(_aPin.getPin(), cuiISR, RISING);

	attachInterrupt(_enterInterrupt, enterISR, CHANGE);

	//enable interrupts
	interrupts();
}

//Detaches the Encoder ISRs
void encoder::end(void)
{
	noInterrupts();
	detachInterrupt(_aPin.getPin());
	detachInterrupt(_enterInterrupt);
	interrupts();
}

void encoder::alpsHandler() 
{
	noInterrupts();

	if(_aPin.get() == _bPin.get())
		_count--;
	else
		_count++;
	interrupts();
} 

void encoder::cuiHandler() 
{
	volatile long time;

	noInterrupts();

	time = millis();

	//if adequate time has not elapsed, bail
	if (time - _lastUpd < CUI_DEBOUNCE) 
	{
		interrupts();
		return;
	}

	//Read EncB
	if(_bPin.get() == LOW)
		_count++;
	else
		_count--;

	//update the last Encoder interrupt time stamp;
	_lastUpd = time;

	interrupts();
} 

void encoder::enterHandler() 
{
	volatile long time;

	noInterrupts();

	time = millis();

	//if the enter pin transitions to high set the time stamp
	if (_enterPin.get()) 
		_enterStart = time;
	else 
	{
		if(time - _enterStart > ENTER_LONG_PUSH)
		{
			_enter = 2;
		}
		else 
		{
			if (time - _enterStart > ENTER_SHORT_PUSH) 
			{
				_enter = 1;
			}
		}
	}
	interrupts();
}

//Global Encoder Object
encoder Encoder;

//ALPS Encoder Function Interrupt Service Routine wrapper
void alpsISR()
{
	Encoder.alpsHandler();
}

//CUI Encoder Function Interrupt Service Routine wrapper
void cuiISR()
{
	Encoder.cuiHandler();
}

//Enter Function Interrupt Service Routine wrapper
void enterISR()
{
	Encoder.enterHandler();
}
