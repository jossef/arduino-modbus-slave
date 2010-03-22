#ifndef _ENCODER_H
#define _ENCODER_H

#define ALPS		0
#define CUI			1

#define CUI_DEBOUNCE		50

#define ENTER_SHORT_PUSH	50
#define ENTER_LONG_PUSH		1000

#include<Wprogram.h>
#include<pin.h>

//ISR wrappers
void alpsISR();
void cuiISR();
void enterISR();

class encoder
{
public:
	encoder(void);
	void begin(byte,byte,byte,byte,byte);
	void begin(byte,byte,byte,byte);
	void attach(void);
	void end(void);

	void setMin(int);
	void setMax(int);

	void setCount(int);
	int getCount(void);
	void clearCount(void);
	int change(void);
	int getDelta(void);
/*********************************************
If wrap is set the encoder value will roll over
to 0 if greater than max and roll to max if less
than 0.
If wrap is cleared the encoder value will be
limited to operate with in the min max constraints
with no roll over.
*********************************************/
	void setWrap(void);
	void clearWrap(void);

	byte getEnter(void);
	void clearEnter(void);
	byte ok(void);
	byte cancel(void);


	//Interrupt Handlers.
	void alpsHandler(void);
	void cuiHandler(void);
	void enterHandler(void);

private:

	pin _aPin,
	    _bPin,
		_enterPin;


	volatile unsigned long	_lastUpd,
							_enterStart;

	volatile byte _enter;

	int _min,
		_max,
		_oldCount;

	volatile int _count;

	byte	_enterInterrupt,
			_type,
			_wrap;
};

extern encoder Encoder;

#endif