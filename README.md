# Simple propulsion performance estimation

Tools for simple estimation of aircraft propulsion performance.

[![View Simple propulsion performance estimation on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/40740)

This set of functions enables building a full engine deck by modeling the engine core (which produces shaft power) and the fan or propeller (how that shaft power is turned into thrust).
Variations in fuel consumption / fuel flow and available thrust can be mapped as functions of speed, altitude, and throttle setting. Closed-form reverse lookup of throttle setting for desired thrust is also possible.

The toolkit now supports both **gas turbine engines** and **piston engines**:

## Gas Turbine Engines
- Jet engines and turboprops
- Altitude efficiency modeling
- Throttle efficiency curves
- Power specific fuel consumption (PSFC)

## Piston Engines
- **Normally aspirated** piston engines with significant power loss at altitude
- **Turbo-normalized** piston engines that maintain sea level power up to critical altitude
- Realistic brake specific fuel consumption (BSFC) modeling
- Propeller integration via actuator disc theory

Some default modeling assumptions are provided, but can all be easily replaced by your own assumptions to e.g. use alternate fuel, alternate efficiency functions, etc.

Example engine deck functions are provided with included examples for both engine types.
