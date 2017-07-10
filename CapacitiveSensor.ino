#include <CapacitiveSensor.h>

CapacitiveSensor cs_10_9 = CapacitiveSensor(10, 9);  // 1M resistor between pins 10 & 9, pin 9 is sensor pin

unsigned long previousTime = 0;
const long interval = 10;

void setup()                    
{
   //cs_10_9.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example
   Serial.begin(9600);
}

void loop()                    
{
    unsigned long currentTime=millis();
    int total = cs_10_9.capacitiveSensor(5);

    if (currentTime-previousTime >= interval) {
       previousTime=currentTime;    
       Serial.print(total);                  // print sensor output 1
       Serial.println("\t");
    }
    
}
