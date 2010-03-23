#ifndef _PIN_H
#define _PIN_H

#include <pin.h>
#include <avr/io.h>
#include<Wprogram.h>
#define PA 0
#define PB 1
#define PC 2
#define PD 3


//Define the Digital pin arrangements and masks for each port on the Arduino or Sanguino
#if defined(__AVR_ATmega644P__) || defined(__AVR_ATmega644__)
//If on the Sanguino platform
//maximum number of digital IO pins available
#define _P_MAX		31

#define _PA_FIRST   24
#define _PA_LAST	31
#define _PA_MASK(n) (0x80 >> ((n) & 0x07))
#define _PA(n)		((n) > (_PA_FIRST-1)) && ((n) < (_PA_FIRST + 8))

#define _PB_FIRST   0
#define _PB_LAST	7
#define _PB_MASK(n) (0x01 << ((n) & 0x07))
#define _PB(n)		((n) > (_PB_FIRST-1)) && ((n) < (_PB_FIRST + 8))

#define _PC_FIRST   16
#define _PC_LAST	23
#define _PC_MASK(n) (0x01 << ((n) & 0x07))
#define _PC(n)		((n) > (_PC_FIRST-1)) && ((n) < (_PC_FIRST + 8))

#define _PD_FIRST   8
#define _PD_LAST	15
#define _PD_MASK(n) (0x01 << ((n) & 0x07))
#define _PD(n)		((n) > (_PD_FIRST-1)) && ((n) < (_PD_FIRST + 8))


#else
//else if the Arduino platform
#define _P_MAX		15

#define _PA_FIRST   0
#define _PA_LAST	0
#define _PA_MASK(n) 0
#define _PA(n)		0

#define _PB_FIRST   8
#define _PB_LAST	15
#define _PB_MASK(n) (0x01 << ((n) & 0x07))
#define _PB(n)		(((n) > (_PB_FIRST-1)) && ((n) < (_PB_FIRST+8))

#define _PC_FIRST   0
#define _PC_LAST	0
#define _PC_MASK(n) 0
#define _PC(n)		0

#define _PD_FIRST   0
#define _PD_LAST	7
#define _PD_MASK(n) (0x01 << ((n) & 0x07))
#define _PD(n)		(((n) > (_PD_FIRST-1)) && ((n) < (_PD_LAST+8))
#endif


#include <Wprogram.h>

class pin
{
public:
	pin(void);
	pin(byte);
	pin(byte, byte);
	void setup(byte p, byte dir);

	void set(byte);
	void set(void);
	void clear(void);

	byte get(void);
	
	void setDir(byte);
	byte getDir(void);

	void setPin(byte);
	byte getPin(void);

private:
	byte _pinDir;
	byte _port;
	byte _pin;
	byte _mask;
};

#endif
