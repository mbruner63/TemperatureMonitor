# TemperatureMonitor
A simple example of Reading a BLE Thermometer and posting the results to a Kinvey cloud database. 

The BLE Temperature simulator was built using a Cypress BLE Pioneer Baseboard with a CY8CKIT-143A PSoC.  The code is currently set to transmit incrementing temperatures.

Example code for PSoC was taken from this respository:
https://github.com/cypresssemiconductorco/PSoC-4-BLE

Delphi project can be built with Embarcadero Rad Studio 10.3+.  An Android APK file can be found in the bin folder.

getTemperature.py is a simple script that can be used to pull a temperature record from the Kinvey Data base.


