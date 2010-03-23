#include <pin.h>

//output for flashing LED;
#define LED 7
//Button Input
#define BUTTON 8

//New pin class
pin led,
    button;

void setup()
{
  //Old way off defining digital pin directions.
  pinMode(LED,OUTPUT);
  pinMode(BUTTON,OUTPUT);
  //New way
  led.setup(LED,OUTPUT);
  button.setup(BUTTON,OUTPUT);
  Serial.begin(9600);
}

void loop()
{
  int i;
  unsigned long time1,
                time2,
                oldtime,
                newtime;
  
  time1=micros();
  //cycle the led output using the old control 100 times
  for(i=0;i<100;i++)
  {
    digitalWrite(LED,HIGH);
    digitalWrite(LED,LOW);
  }
  time2=micros();
  oldtime=time2-time1;
  Serial.print("Old method: ");
  Serial.print(oldtime);
  Serial.println("ms");
  
  time1=micros();
  for(i=0;i<100;i++)
  {
    led.set(HIGH);
    led.set(LOW);
  }
  time2=micros();
  newtime=time2-time1;
  Serial.print("New method: ");
  Serial.print(newtime);
  Serial.println("ms");
  
  i=0; 
  while(i<100)
  {
   //Old method of reading digital lines
    if(digitalRead(BUTTON))
      i++;
  }
  Serial.println("Old digital read done");

  i=0; 
  while(i<100)
  {
   //New method of reading digital lines
    if(button.get())
      i++;
  }
  Serial.println("New digital read done");

  while(1)
  {}
}



