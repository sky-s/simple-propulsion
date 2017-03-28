function [PSFC,eProd,e] = calculatepsfc(h,M,throttle,assumptions)
% CALCULATEPSFC calculates gas turbine power specific fuel consumption as a
% function of altitude, Mach number, and throttle setting.
%
%   [PSFC,eProd,e] = CALCULATEPSFC(h,M,throttle,assumptions)
%
%   Inputs and outputs:
%   PSFC        - Power specific fuel consumption. Units for PSFC are the
%                 inverse of the units of the provided Q.
%   eProd       - Core thermal efficiency at operating point.
%   e           - Cell vector with breakdown of eProd; eProd = prod(e).
%   h           - Altitude in meters or DimVar.
%   M           - Mach number.
%   throttle    - Throttle setting (range 0 to 1). Default is 1.
%   assumptions - Struct with fields:
%     Q            - Fuel heating value. Default is 43e6 J/kg (Jet A fuel).
%                    Units of Q determine the units of PSFC, for example, PSFC
%                    is in kg/J (i.e. kg/s/W) for Q in J/kg.
%     efficiencies - Cell vector defining constants and functions that together 
%                    determine the total core thermal efficiency. Elements may
%                    be numeric or function handles of the form
%                    relativeEfficiency = f(h,M,throttle,assumptions). Default
%                    is {maxEfficiency,@throttleefficiency,@altitudeefficiency},
%                    where maxEfficiency is 0.4.
%
%   CALCULATEPSFC accepts arguments of the DimVar class, the use of which will
%   ensure unit consistency.
%
%   See also DEMOENGINEDECK, ACTUATORDISC, POWERLAPSE,
%       THROTTLEEFFICIENCY, ALTITUDEEFFICIENCY,
%       U - http://www.mathworks.com/matlabcentral/fileexchange/38977.
%
%   [PSFC,eProd,e] = CALCULATEPSFC(h,M,throttle,assumptions)

%   Copyright 2013 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

if nargin < 4 || isempty(assumptions)
    assumptions = struct();
    % Default assumptions and efficiency models in use.
end
if ~isfield(assumptions,'Q')
    if isa(h,'DimVar')
        assumptions.Q = 43*u.MJ/u.kg; % Jet A fuel
    else
        assumptions.Q = 43e6; 
    end
end
if ~isfield(assumptions,'efficiencies')
    eMax = 0.4;
    assumptions.efficiencies = {eMax,@altitudeefficiency,@throttleefficiency};
end

if nargin < 3
    throttle = 1;
end

e = cell(size(assumptions.efficiencies));
eProd = 1;
for ii = 1:length(assumptions.efficiencies)
    if iscell(assumptions.efficiencies)
        thisEfficiency = assumptions.efficiencies{ii};
    else
        thisEfficiency = assumptions.efficiencies(ii);
    end
    
    if isnumeric(thisEfficiency) % constant efficiency multiplier
        e{ii} = thisEfficiency;
    else
        e{ii} = thisEfficiency(h,M,throttle,assumptions);
    end
    eProd = eProd.*e{ii};
end

massPerUnitEnergy = 1./assumptions.Q;
PSFC = massPerUnitEnergy./eProd;

end