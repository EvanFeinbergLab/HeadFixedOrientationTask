// Angle counter variables

#define chA A0
#define chB A1

int counter_pos = 0;
int angle = 0;
int aState;
int aLastState;

void setup() { 
  pinMode (chA,INPUT);
  pinMode (chB,INPUT);
   
  Serial.begin(115200);
  
  aLastState = digitalRead(chA); // Reads the initial state of the chA
}
 
void loop() { 
  aState = digitalRead(chA); // Reads the "current" state of the chA
  
  // If the previous and the current states of chA are different,
  // then a pulse has occured
  if (aState != aLastState){     

    // If chB state != chA state, then the encoder is rotating CW
    if (digitalRead(chB) != aState) {
      counter_pos ++;
    }

    // If chB state = chA state, then the encoder is rotating CCW
    else {
      counter_pos --;
    }

    if (counter_pos >= 100) {
      counter_pos = 0;
    }

    // 1 cycle / CPR = 360 / 100 = 3.6
    // Multiply by -3.6 b/c CW rotation moves counter ++, but angle --
    angle = counter_pos * (-3.6);

    if (abs(angle) >= 360) {
      if (angle >= 360) {
        angle = angle - 360;
      }

      else if (angle <= -360) {
        angle = angle + 360;
      }
    }

    Serial.println(angle); // What gets serially read by Matlab
   
  }

  aLastState = aState; // Updates the previous chA state with current state
}
