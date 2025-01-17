# CppGPIO
C++14 GPIO library for Raspberry Pi and other embedded systems

### ***************************************************************************************************
## NOTE (by Mariwan):
This fork contains some updates to the library. The library failed to provide any kind of digitl read directly. "getstate" which is a function in the DigitlIn is not working. 
I added readValue function to get the actual reading of the pin. 
Be aware about pull up/pull down. You need to know when you should use them or avoid them. 
Since the author, didn't update the library while there are (question, I think RP ..etc) I decided to update the library with the mentioned updates. 
There were some bugs like not including the main Linux library which is added to many files and other bugs. 
Further developing of this library might be difficult task for me but I might add or fix other issues if I find them.

### ***************************************************************************************************

### What is CppGPIO
CppGPIO is a C++ library for the GPIOs of embedded systems like the Raspberry Pi written entirely in the
modern C++ dialect C++14.

It provides a fallback to C++11 however. Please read below.

With the current source CppGPIO only works on the Pi, but it has enough abstraction to be ported to other boards.

It implements a high speed low level access on the GPIO pins of the embedded CPU, much like the C
libraries like [wiringPi](http://wiringpi.com) or the [bcm2835](http://www.airspayce.com/mikem/bcm2835/) library.

It also supports I2C communication via the Linux I2C abstraction.

Inspired by the implementation in wiringPi, it supports Soft PWM and tone outputs on all GPIO ports. Hardware
PWM is supported when run as root, by addressing the registers in the bcm2835.

In addition it implements a number of hardware abstractions based on the low level model, such as PushButtons,
RotaryDials, LCD displays, and other inputs and outputs.

It performs proper software debouncing on input ports. If you want to, you can modify the default parameters
for the debouncing. You can also set the pullup/pulldown mode for all inputs.

The library works event based for input objects. This means that you do not have to poll for state changes
of e.g. a switch, but can simply register a function from your own class that will be called from the object
when the state changes. This sounds complicated but is actually quite simple with C++11/14 features like lambda
expressions. The demo.cpp file has samples for this.

The speed of the library is at the upper limit of the hardware capabilities of the Raspberry Pi (2). Only 12 
nanoseconds are needed to switch an output pin on or off. This results in a 44.67 Mhz square wave output
just by soft control.

### C++11 fallback
CppGPIO compiles with any C++11 compiler, as the only (but important) feature used from C++14 is
std::make_unique<>(), and the library provides a local copy of the standard implementation of that
feature. The main reason for this is that this provides support for the previous Raspian version,
based on debian wheezy, once you install g++-4.8 with `sudo apt-get install g++-4.8` (which is available on
wheezy). On wheezy, you then need however specify the newer compiler explicitly, e.g. by changing the Makefiles
supplied with this project to explicitly call g++-4.8 instead of g++ .

In result, CppGPIO is a pure C++11 library. You cannot use it from C nor from non-C++11 capable compilers.



### How to install
Just clone a revision from here, and get into the source directory and type
```
make -j4
sudo make install
make demo
```

### How to use
After you have installed the library and the include headers, you can simply include it into your own projects
by adding
```
#include <cppgpio.hpp>
```
to the files in which you want to use the functionality. For proper linking, you have to add
```
-lcppgpio
```
to your linker arguments. It will normally be added as a shared library, but if you want to force static linking,
it provides a static version as well.

### Documentation
All header files have fully commented public and protected methods. When using IDEs like Eclipse or XCode, you get
the methods "intellisensed", with documentation. If in doubt, just look at the header files in include/cppgpio/.
In the following days I may be adding doxygen generated documentation from the source files.

### Supported operating environments
The only GPIO model is currently the BCM2835 as used in the Raspberry Pi boards. It adapts automatically to the 
various versions (I have it only tested though on a B, A+, and 2 B). The code itself should compile fine on any
OS with a C++14 compiler. I typically develop and test build my projects on OSX with XCode, and then copy them
to the Pi. This works because the GPIO automatically switches to simulation mode when not on Linux
(or can be forced to do with Linux, too).

### License
CppGPIO is open source. The terms of the BSD license apply. Copyright (c) 2016 Joachim Schurig.

### Some examples
The following examples are taken from demo.cpp in this project.

#### Writing to a digital output
```cpp
#include <chrono>
#include <cppgpio.hpp>

using namespace GPIO;

int main()
{
  // use gpio #18

  DigitalOut out(18);
  
  // switch output to logical 1 (3.3V)

  out.on();
  
  // wait some time
  
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
  
  // switch it off again
  
  out.off();

  return 0;
}
```
When DigitalOut goes out of scope, the port is automatically 
reset to input mode and any resource associated with it is freed

#### Example with a PWM output
In the following example we output a PWM signal to a port, not
regarding if it will be generated by a hardware PWM circuit or
by the software emulation, which is a function of the port number
and the initialisation mode.

It could e.g. dim a LED on and off.

```cpp
#include <chrono>
#include <cppgpio.hpp>

using namespace GPIO;

int main()
{
  // create PWM on GPIO 23, set range to 100, inital value to 0
  
  PWMOut pwm(23, 100, 0);
  
  // now dim a LED 20 times from off to on to off
  
  for (int l = 0; l < 20; ++l) {
  
    for (int p = 0; p < 100; ++p) {
      pwm.set_ratio(p);
      std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    
    for (int p = 100; p > 0; --p) {
      pwm.set_ratio(p);
      std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    
  }
  
  return 0;
}
```

#### Example with an LCD display, a rotary dial and a push button
In the following example we use the event driven approach with a
rotary dial with integrated push button. We connect callables
(in this case member functions of the Rotary1 class) to the
rotary and button classes, and have them called whenever an
event occurs. Remark there is no polling, and no control loop.

```cpp
#include <string>
#include <chrono>
#include <stdlib.h>
#include <cppgpio.hpp>

using namespace GPIO;


class Rotary1 {
public:
    Rotary1()
    : lcd(4, 20, "/dev/i2c-1", 0x27)
    , dial(6, 12, GPIO_PULL::UP)
    , push(5, GPIO_PULL::UP)
    {
        lcd.fill();
        lcd.write(0, 0, "Please dial me!");
        lcd.write(1, 0, "Will exit at #42");

        // register a lambda function at the dial to connect it to this class

        dial.f_dialed = [&](bool up, long value) { dialed(up, value); };

        // could also use std::bind():
        // dial.f_dialed = std::bind(&Rotary1::dialed, this, std::placeholders::_1, std::placeholders::_2);

        push.f_pushed = [&]() { pushed(); };

        push.f_released = [&](std::chrono::nanoseconds nano) { released(nano); };

        // after finishing the initialization of the event driven input objects
        // start the event threads of the input objects

        dial.start();
        push.start();
    }

private:
    HitachiLCD lcd;
    RotaryDial dial;
    PushButton push;
    
    void dialed(bool up, long value)
    {
        std::string out = "Value: ";
        out += std::to_string(value);
        lcd.write(0, 0, out);

        if (value == 42) {
            lcd.write(0, 0, "Goodbye");
            lcd.write(1, 0, "");
            std::this_thread::sleep_for(std::chrono::seconds(2));
            lcd.backlight(false);
            exit(0);
        }
    }
    
    void pushed()
    {
        lcd.write(1, 0, "Button: pushed");
    }
    
    void released(std::chrono::nanoseconds nano)
    {
        lcd.write(1, 0, "Button: released");
    }
    
};



int main()
{

  Rotary1 rotary;

  // the rotary object will function properly on any
  // event alltough the main thread will now sleep for an hour
  
  std::this_thread::sleep_for(std::chrono::hours(1));
  
  return 0;
}

```
When Rotary1 goes out of scope, all GPIO objects used inside are 
properly reset and freed.

