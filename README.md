# simple-propulsion
Tools for simple estimation of aircraft propulsion performance.

[![View Simple propulsion performance estimation on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/40740)

This set of functions enables building a full engine deck by modeling the engine core (which produces shaft power) and the fan or propeller (how that shaft power is turned into thrust).
Variations in fuel consumption / fuel flow and available thrust can be mapped as functions of speed, altitude, and throttle setting. Closed-form reverse lookup of throttle setting for desired thrust is also possible.

Some default modeling assumptions are provided, but can all be easily replaced by your own assumptions to e.g. use alternate fuel, alternate efficiency functions, etc.

An example engine deck function is provided with an included example.
