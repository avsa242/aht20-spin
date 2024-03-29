# aht20-spin 
------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the ASAIR AHT20 Temperature/RH sensor

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* I2C connection at up to 400kHz
* Read temperature, relative humidity (current and previous measurements)
* Measurements are validated by CRC


## Requirements

P1/SPIN1:
* spin-standard-library
* `sensor.temp_rh.common.spinh` (provided by spin-standard-library)
* 1 extra core/cog for the PASM-based I2C engine (none if bytecode-based engine is used)

P2/SPIN2:
* p2-spin-standard-library
* `sensor.temp_rh.common.spin2h` (provided by p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.5.0-beta)  | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (6.5.0-beta)  | Native code | OK                    |
| P2        | SPIN2    | FlexSpin (6.5.0-beta)  | NuCode      | OK                    |
| P2        | SPIN2    | FlexSpin (6.5.0-beta)  | Native code | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* TBD

