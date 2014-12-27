#include <avr/interrupt.h>

void setup();
void loop();

int main(void)
{
  sei();
  
  setup();
  for (;;) {
    loop();
    //if (serialEventRun) serialEventRun();
  }
  return 0;
}

