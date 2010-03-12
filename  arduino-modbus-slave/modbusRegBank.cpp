#include <modbusRegBank.h>

modbusRegBank::modbusRegBank(void)
{
	_registers		= 0;
}


modbusRegister* modbusRegBank::add(word addr)
{
		modbusRegister *temp;
		temp = (modbusRegister *) malloc(sizeof(modbusRegister));
		temp->init(addr);

		if(_registers)
		{
			modbusRegister *ptr;

			//set the register pointer to the first register
			ptr = _registers;

			//Run to the end of the linked list
			while (ptr->getNext())
				ptr = ptr->getNext();

			//Once at the end of the list, add the new register
			ptr->setNext(temp);
		}
		else
			_registers = temp;
		return(temp);
}

word modbusRegBank::get(word addr)
{
	modbusRegister* ptr;
	
	ptr = this->search(addr);
	return(ptr->get());
}

void modbusRegBank::set(word addr, word value)
{
	modbusRegister* ptr;

	ptr = this->search(addr);
	if(ptr)
		ptr->set(value);

}

modbusRegister* modbusRegBank::getRegister(word addr)
{
	return(this->search(addr));
}

modbusRegister* modbusRegBank::search(word addr)
{
 modbusRegister* ptr;

	//if the requested address is 0-19999 
	//use a digital register pointer assigned to the first digital register
	//else use a analog register pointer assigned the first analog register
	//if there is no register configured, bail

	 if(_registers == 0)
		return(0);

	ptr = _registers;
	
	//scan through the linked list until the end of the list or the register is found.
	//return the pointer.
	do
	{

		if(ptr->getAddress() == addr)
			return(ptr);
		ptr = ptr->getNext();
	}
	while(ptr);

	return(0);
}


