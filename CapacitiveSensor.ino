#include <CapacitiveSensor.h>

CapacitiveSensor cs_7_6 = CapacitiveSensor(7, 6);  // 1M resistor between pins 7 & 6, pin 6 is sensor pin

void setup()                    
{
   //cs_7_6.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example
   Serial.begin(9600);
}

void loop()                    
{
    int total = cs_7_6.capacitiveSensor(5);

    Serial.print(total);                  // print sensor output 1
    Serial.println("\t");

    delay(10);                             // arbitrary delay to limit data to serial port 
}
