#include <modbus.h>
#include <modbusDevice.h>
#include <modbusRegBank.h>
#include <modbusSlave.h>

//required for EEPROM support
#include <avr/eeprom.h>
#include "EEPROM.h"

/*
This example code shows a quick and dirty way to get an
arduino to talk to a modbus master device with a
device ID of 1 at 9600 baud.
*/

//Setup the brewtrollers register bank
//All of the data accumulated will be stored here
modbusDevice regBank;
//Create the modbus slave protocol handler
modbusSlave slave;

void setup()
{   

//Assign the modbus device ID.  
  regBank.setId(1);
}

void loop()
{

	modbusRegister	*do_00001,
					*di_10001,
					*ai_30001,
					*ao_40001,
					*ee_47000;
/*
modbus registers follow the following format
00001-09999  Digital Outputs, A master device can read and write to these registers
10001-19999  Digital Inputs, A master device can only read the values from these registers
30001-39999  Analog Inputs, A master device can only read the values from these registers
40001-49799  Analog Outputs, A master device can read and write to these registers 
49800-498511 EEPROM registers, 0-511 respectively
498512-49999  Analog Outputs, A master device can read and write to these registers 

Digital values are stored as bytes, a zero value is OFF and any nonzer value is ON
Analog values are 16 bit words stored with a range of 0-32767
EEPROM registers contain only one byte worth of data in the low byte of the standard word.

It is best to configure registers of like type into contiguous blocks.  this
allows for more efficient register lookup and and reduces the number of messages
required by the master to retrieve the data
*/

//Add Digital Output registers 00001-00002 to the register bank
  do_00001 = regBank.add(1);  //assign a register pointer to the register upon creation;
  regBank.add(2);

//Add Digital Input registers 10001-10008 to the register bank
  regBank.add(10001);  
  regBank.add(10002);  
  regBank.add(10003);  
  regBank.add(10004);  
  regBank.add(10005);  
  regBank.add(10006);  
  regBank.add(10007);  
  regBank.add(10008);  

//Add Analog Input registers 30001-10010 to the register bank
  regBank.add(30001);  
  regBank.add(30002);  
  regBank.add(30003);  
  regBank.add(30004);  
  regBank.add(30005);  
  regBank.add(30006);  
  regBank.add(30007);  
  regBank.add(30008);  
  regBank.add(30009);  
  regBank.add(30010);  

//Add Analog Output registers 40001-40004 to the register bank
  ao_40001 = regBank.add(40001);  
  regBank.add(40002);  //get register pointer upon creation
  regBank.add(40003);  
  regBank.add(40004);  

//Add EEPROM registers 47000-47004 to the register bank (EEPROM 0-5)
  regBank.add(47000);  
  regBank.add(47001);  
  regBank.add(47002);  
  regBank.add(47003);  
  regBank.add(47004);  

/*
Assign the modbus device object to the protocol handler
This is where the protocol handler will look to read and write
register data.  Currently, a modbus slave protocol handler may
only have one device assigned to it.
*/
  slave._device = &regBank;  

// Initialize the serial port for coms at 9600 baud  
  slave.setBaud(9600);   
  
//get a few other register pointers after the fact

	ai_30001 = regBank.getRegister(30001);  
	ao_40001 = regBank.getRegister(40001);
	ee_47000 = regBank.getRegister(47000);
	
while (1)
{
/*There are 2 ways to read and write to the data.
One is through the modbusDevice class
assign some random number to 30001*/
    regBank.set(10001, (word) random(0, 2));

/* The second is to go directly through a modbusRegister pointer
assign some random number to 40001*/

	ai_30001->set((word) random(0,1200));

//Reading is done much the same way.
// set register 40001 to the value of 40002 * the value of register 30001
	ao_40001->set(regBank.get(40002) * ai_30001->get()); 
  
//Run the MODBUS slave RTU handler.
     slave.run();  

  }
}
