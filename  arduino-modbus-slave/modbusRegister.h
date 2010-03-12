#ifndef MODBUSREGISTER
#define MODBUSREGISTER

#include <Wprogram.h>
#include <avr/eeprom.h>
#include "EEPROM.h"

class modbusRegister
{
public:
	modbusRegister(void);
	modbusRegister(word);
	~modbusRegister(void);
	//call init methods if using malloc to create the object
	void init(void);
	void init(word);
	//call flush before free'ing the object
	void flush(void);

	void setAddress(word);
	void set(byte);
	void set(word);
	void setNext(modbusRegister *);
	
	word getAddress(void);
	word get(void);
	modbusRegister * getNext(void);

private:
	typedef union
	{
		word *aVal;
		byte *dVal;
	}regVal;

	word	_address,
			_eepromStart,
			_eepromEnd;

	regVal	_value;
	modbusRegister *_next;	
};

#endif