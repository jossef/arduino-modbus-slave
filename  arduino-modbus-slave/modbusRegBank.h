#ifndef _MODBUSREGBANK
#define _MODBUSREGBANK

#include <modbus.h>

#include <modbusRegister.h>

class modbusRegBank
{
	public:

		modbusRegBank(void);
		
		modbusRegister* add(word);
		word get(word);
		void set(word, word);
		modbusRegister* getRegister(word);
				
	private:
		modbusRegister * search(word);
		
		modbusRegister *_registers;

		word			_eepromStart,
						_eepromEnd;
};

/*
class modbusRegBank
{
	public:

		modbusRegBank(void);
		
		void add(word);
		word get(word);
		void set(word, word);
				
	private:
		void * search(word);
		
		modbusDigReg	*_digRegs,
						*_lastDigReg;
							
		modbusAnaReg	*_anaRegs,
						*_lastAnaReg;

		word			_eepromStart,
						_eepromEnd;
};
*/
#endif
