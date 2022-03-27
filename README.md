# aht20-spin 
------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the ASAIR AHT20 Temperature/RH sensor

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) ~~or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P)~~. Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz (P1)
* Read temperature, relative humidity (current and previous measurements)
* Measurements are validated by CRC

## Requirements

P1/SPIN1:
* spin-standard-library
* sensor.temp_rh.common.spinh (source: spin-standard-library)

~~P2/SPIN2:~~
* ~~p2-spin-standard-library~~
* ~~sensor.temp_rh.common.spin2h~~ (source: p2-spin-standard-library)

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.9-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.9-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.9-beta~~
* ~~P2/SPIN2 FlexSpin (native): OK, tested with 5.9.9-beta~~ _(not yet implemented)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* TBD
