function ePiston = pistonefficiency(h,M,throttle,assumptions)
% PISTONEFFICIENCY determines relative efficiency of a piston engine as a
% function of altitude, Mach number, and throttle setting.
% 
%   relativeEfficiency = PISTONEFFICIENCY(h,M,throttle,assumptions)
% 
%   h:           Altitude in meters or DimVar.
%   M:           Mach number.
%   throttle:    Throttle setting (range 0 to 1).
%   assumptions: Struct with fields:
%     optimalThrottle - Throttle setting for maximum efficiency. Default is 0.85.
%     minEfficiency   - Minimum efficiency at idle. Default is 0.6.
%     altitudeLapse   - Efficiency change with altitude due to cooling.
%                       Default is small positive effect up to 10000 ft.
% 
%   See also CALCULATEBSFC, PISTONPOWERLAPSE.

%   Copyright 2024 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

% Default assumptions
if nargin < 4 || isempty(assumptions)
    assumptions = struct();
end
if ~isfield(assumptions,'optimalThrottle')
    assumptions.optimalThrottle = 0.85;
end
if ~isfield(assumptions,'minEfficiency')
    assumptions.minEfficiency = 0.6;
end
if ~isfield(assumptions,'altitudeLapse')
    assumptions.altitudeLapse = true;
end

validateattributes(throttle,{'numeric'},{'nonnegative','<=',1});

%% Throttle efficiency curve
% Piston engines are most efficient at high power settings (around 85% power)
% Efficiency drops significantly at idle due to pumping losses
optThrottle = assumptions.optimalThrottle;
minEff = assumptions.minEfficiency;

% Quadratic curve with peak at optimal throttle
% Efficiency = minEff + (1-minEff) * efficiency_factor
if throttle <= optThrottle
    % Rising efficiency from idle to optimal
    eThrottle = minEff + (1-minEff) * (throttle/optThrottle).^0.5;
else
    % Slight decrease above optimal due to enrichment and timing effects
    excess = (throttle - optThrottle) / (1 - optThrottle);
    eThrottle = 1 - 0.05 * excess.^2;
end

%% Altitude efficiency
% Piston engines benefit slightly from altitude due to:
% 1. Cooler air temperature improves volumetric efficiency
% 2. Reduced air density reduces pumping losses
% 3. Mixture becomes slightly leaner (if not adjusted)
% However, these effects are small compared to power loss

eAltitude = 1.0; % Base efficiency

if assumptions.altitudeLapse
    % Convert altitude to feet for traditional aviation calculations
    if isa(h,'DimVar')
        h_ft = h; % Assume DimVar handles unit conversion
    else
        h_ft = h * 3.28084; % meters to feet
    end
    
    % Small efficiency improvement up to about 10000 ft, then level off
    % Maximum improvement of about 3%
    altitudeFactor = min(h_ft / 10000, 1.0);
    eAltitude = 1.0 + 0.03 * altitudeFactor;
end

%% Mach number effects
% At low speeds, ram air has minimal effect on piston engines
% Slight cooling benefit at higher speeds
eMach = 1.0 + 0.01 * M; % Very small effect, max 1% improvement

%% Combined efficiency
ePiston = eThrottle .* eAltitude .* eMach;

end