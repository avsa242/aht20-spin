{
----------------------------------------------------------------------------------------------------
    Filename:       AHT20-Demo.spin
    Description:    Driver for AHT20 temperature/RH sensors
    Author:         Jesse Burt
    Started:        Jun 16, 2021
    Updated:        Sep 3, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}


' Uncomment to use the bytecode-based I2C engine
'#define AHT20_I2C_BC
'#pragma exportdef(AHT20_I2C_BC)

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    sensor: "sensor.temp_rh.aht20" | SCL=28, SDA=29, I2C_FREQ=400_000
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


PUB main() | rh, temp, tscl

    setup()
    sensor.temp_scale(sensor.C)                 ' C, F

    repeat
        ser.pos_xy(0, 3)
        sensor.measure()
        rh := sensor.rh()
        temp := sensor.temperature()
        tscl := lookupz(sensor.temp_scale(-2): "C", "F", "K")

        ser.printf3(@"Temp. (deg %c): %3.3d.%02.2d\n\r", tscl, (temp / 100), ||(temp // 100))
        ser.printf2(@"Rel. humidity (%%): %3.3d.%02.2d\n\r", (rh / 100), (rh // 100))
        time.msleep(250)


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"AHT20 driver started")
    else
        ser.strln(@"AHT20 driver failed to start - halting")
        repeat

    sensor.reset()
    sensor.calibrate()                          ' this only needs to be done once per power cycle


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

