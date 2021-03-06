{
    --------------------------------------------
    Filename: sensor.temp_rh.aht20.spin
    Author: Jesse Burt
    Description: Driver for AHT20 temperature/RH sensors
    Copyright (c) 2022
    Started Mar 26, 2022
    Updated Jul 16, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{ pull in methods common to all Temp/RH drivers }
#include "sensor.temp_rh.common.spinh"

CON

    { I2C }
    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR | 1
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000

    FP_SCALE    = 10_000
    TWO20       = (1 << 20)                     ' 2^20

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef AHT20_I2C_BC
    i2c : "com.i2c.nocog"                       ' SPIN I2C engine (~25kHz)
#else
    i2c : "com.i2c"                             ' PASM I2C engine (up to ~800kHz)
#endif
    core: "core.con.aht20"                      ' AHT20-specific constants
    time: "time"                                ' basic timing functions
    u64 : "math.unsigned64"                     ' unsigned 64-bit math
    crc : "math.crc"

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if (deviceid{} == core#DEVID_RESP)
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}
' Stop driver
'   Deinitialize I2C engine
    i2c.deinit{}

PUB Defaults{}
' Set factory defaults
    reset{}

PUB Calibrate{}
' Perform device calibration
'   NOTE: This only needs to be performed once at power-on
    cmd(core#CMD_CAL)

PUB DeviceID{}: id
' Read device identification
'   NOTE: This device has no known device ID register, so the I2C address
'       is returned instead, if it responds.
    if (i2c.present(core#SLAVE_ADDR))
        return core#DEVID_RESP

PUB Measure{}: flag
' Perform temperature/RH measurement
    cmd(core#CMD_MEAS)
    readreg(core#GET_MEAS, 0, 0)

PUB Reset{}
' Reset the device
    cmd(core#CMD_SOFT_RST)
    time.usleep(core#T_RES)
    calibrate{}

PUB RHData{}: rhword
' Relative humidity ADC word
'   Returns: u20
    measure{}
    readreg(core#GET_MEAS, 0, 0)
    return _last_rh

PUB RHDataReady{}: flag
' Flag indicating relative humidity measurement data ready
'   Returns: TRUE (-1) or FALSE (0)
    return temprhdataready{}

PUB RHWord2Pct(rhword): pct
' Convert RH ADC word to hundredths of a percent
'   Returns: 0..100_00
    return u64.multdiv(rhword, FP_SCALE, TWO20)

PUB TempDataReady{}: flag
' Flag indicating temperature measurement data ready
'   Returns: TRUE (-1) or FALSE (0)
    return temprhdataready{}

PUB TempRHDataReady{}: flag
' Flag indicating temperature and RH measurements data ready
'   Returns: TRUE (-1) or FALSE (0)
    flag := 0
    readreg(core#STATUS, 1, @flag)
    return ((flag & core#ST_BUSY) == 0)

PUB TempData{}: tword
' Temperature ADC word
'   Returns: s20
    measure{}
    readreg(core#GET_MEAS, 0, 0)
    return _last_temp

PUB TempWord2Deg(tword): deg | sign
' Convert temperature ADC word to degrees
'   Returns: hundredths of a degree, in chosen scale
    if (tword & $8000_0000)                     ' negative temp?
        sign := -1                              ' preserve sign - u64 object
    else                                        '   only handles unsigned math
        sign := 1
    deg := ((u64.multdiv(tword, FP_SCALE, TWO20) * 200) - (50 * FP_SCALE)) / 100
    deg *= sign

    case _temp_scale
        C:                                      ' Celsius (default)
            return deg
        F:                                      ' Fahrenheit
            return ((deg * 9) / 5) + 32_00
        K:                                      ' Kelvin
            return (deg + 273_15)

PRI cmd(cmd_nr)
' Issue command 'cmd_nr' to device
    case cmd_nr
        core#CMD_MEAS:                          ' perform measurement
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(core#CMD_MEAS)
            i2c.write(core#MEAS_PARMSB)
            i2c.write(core#MEAS_PARLSB)
            i2c.stop{}
        core#CMD_CAL:                           ' perform calibration
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(core#CMD_CAL)
            i2c.write(core#CAL_PARMSB)
            i2c.write(core#CAL_PARLSB)
            i2c.stop{}
        core#CMD_SOFT_RST:                      ' soft-reset or calibrate
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(cmd_nr)
            i2c.stop{}
        other:
            return

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, rd_data_tmp[2], crc_rd, crc_calc
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#STATUS:
            i2c.start{}
            i2c.write(SLAVE_WR)
            i2c.write(core#STATUS)
            i2c.start{}
            i2c.wr_byte(SLAVE_RD)
            byte[ptr_buff] := i2c.read(i2c#NAK)
            i2c.stop{}
        core#GET_MEAS:
            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rdblock_lsbf(@rd_data_tmp, 7, i2c#NAK)
            i2c.stop{}
            _last_rh := rd_data_tmp.byte[1] << 12
            _last_rh |= (rd_data_tmp.byte[2] << 4)
            _last_rh |= ((rd_data_tmp.byte[3] >> 4) & $0f)

            _last_temp := ((rd_data_tmp.byte[3] & $0f) << 16)
            _last_temp |= (rd_data_tmp.byte[4] << 8)
            _last_temp |= (rd_data_tmp.byte[5])

            { extend sign of temperature data }
            _last_temp := (_last_temp << 12) ~> 12

            crc_rd := rd_data_tmp.byte[6]
            crc_calc := crc.asaircrc8(@rd_data_tmp, 6)
            if (crc_rd == crc_calc)
                return 0                        ' CRC good
            else
                return -1                       ' CRC bad
        other:                                  ' invalid reg_nr
            return

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

