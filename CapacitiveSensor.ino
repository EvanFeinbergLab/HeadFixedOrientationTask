#include <CapacitiveSensor.h>

CapacitiveSensor cs_7_6 = CapacitiveSensor(7, 6);  // 1M resistor between pins 7 & 6, pin 6 is sensor pin

unsigned long previousTime = 0;
const long interval = 10;

void setup()                    
{
   //cs_7_6.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example
   Serial.begin(9600);
}

void loop()                    
{
    unsigned long currentTime=millis();
    int total = cs_7_6.capacitiveSensor(5);

    if (currentTime-previousTime >= interval) {
       previousTime=currentTime;    
       Serial.print(total);                  // print sensor output 1
       Serial.println("\t");
    }



}
