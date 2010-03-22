
#include <pin.h>
#include <encoder.h>



void setup()
{
  Serial.begin(9600);
}

void loop()
{

  Encoder.setMin(0);
  Encoder.setMax(100);
  Encoder.begin(2,4,11,1,ALPS);
  
  while(1)
  {    
    if((Encoder.change()>-1) || Encoder.getEnter())
    {
       
       Serial.print("Count:");
       Serial.print(Encoder.getCount(),DEC);
       if(Encoder.ok())
         Serial.println("enter = OK");
       else if(Encoder.cancel())
         Serial.println("enter = CANCEL");
       else
         Serial.println("enter = NONE");
    }
  }
}
