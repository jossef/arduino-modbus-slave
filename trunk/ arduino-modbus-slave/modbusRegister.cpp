#include<modbusRegister.h>
#include<modbus.h>
#include<Wprogram.h>

modbusRegister::modbusRegister(void)
{
	_address	= 0;
	_next		= 0;
}

modbusRegister::modbusRegister(word addr)
{
	this->init(addr);
}

modbusRegister::~modbusRegister(void)
{
	this->flush();
}

void modbusRegister::init(void)
{
	_address	= 0;
	_next		= 0;
	
}

void modbusRegister::init(word addr)
{
	_address	= 0;
	_next		= 0;
	this->setAddress(addr);
}

void modbusRegister::flush(void)
{
	if(_address)
		if(_address < 20000)
			free(_value.dVal);
		else if((_address < EEPROM_START) || (_address > EEPROM_END))
			free(_value.aVal);
}

void modbusRegister::setAddress(word addr)
{

	//if the address has already been assigned, bail

	if(_address)
		return;

	_address = addr;

	if(_address < 20000)
	{
		_value.dVal = (byte*) malloc(sizeof(byte));
		*_value.dVal = 0;
		return;
	}
	else if((_address < EEPROM_START) || (_address > EEPROM_END))
	{
		_value.aVal = (word*) malloc(sizeof(word));
		*_value.aVal = 0;
		return;
	}
}

void modbusRegister::set(byte val)
{
	this->set(word(val));
}

void modbusRegister::set(word val)
{
	if(_address == 0)
		return;

	if(_address < 2000)
	{
		if(val)
			*_value.dVal = 0xFF;
		else
			*_value.dVal = 0x00;
	}
	else if((_address < EEPROM_START) || (_address > EEPROM_END))
		*_value.aVal = val;
	else
		EEPROM.write(_address - EEPROM_START, byte(val & 0xFF));
}

void modbusRegister::setNext(modbusRegister *next)
{
	_next = next;
}

word modbusRegister::getAddress(void)
{
	return(_address);
}

word modbusRegister::get(void)
{
	if (_address < 20000)
	{
		return(word(*_value.dVal));
	}
	else if((_address < EEPROM_START) || (_address > EEPROM_END))
	{
		return(*_value.aVal);
	}
	else 
		 return(EEPROM.read(_address - EEPROM_START));
}

modbusRegister* modbusRegister::getNext(void)
{
	return(_next);
}
