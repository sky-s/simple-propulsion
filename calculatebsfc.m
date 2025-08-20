function [BSFC,eProd,e] = calculatebsfc(h,M,throttle,assumptions)
% CALCULATEBSFC calculates piston engine brake specific fuel consumption as a
% function of altitude, Mach number, and throttle setting.
%
%   [BSFC,eProd,e] = CALCULATEBSFC(h,M,throttle,assumptions)
%
%   Inputs and outputs:
%   BSFC        - Brake specific fuel consumption. Units for BSFC are the
%                 inverse of the units of the provided Q (fuel heating value).
%   eProd       - Overall engine efficiency at operating point.
%   e           - Cell vector with breakdown of eProd; eProd = prod(e).
%   h           - Altitude in meters or DimVar.
%   M           - Mach number.
%   throttle    - Throttle setting (range 0 to 1). Default is 1.
%   assumptions - Struct with fields:
%     Q            - Fuel heating value. Default is 43.2e6 J/kg (100LL avgas).
%                    Units of Q determine the units of BSFC.
%     efficiencies - Cell vector defining constants and functions that together 
%                    determine the total engine efficiency. Elements may
%                    be numeric or function handles of the form
%                    relativeEfficiency = f(h,M,throttle,assumptions). Default
%                    is {maxEfficiency,@pistonefficiency},
%                    where maxEfficiency is 0.35 (typical for piston engines).
%
%   CALCULATEBSFC accepts arguments of the DimVar class, the use of which will
%   ensure unit consistency.
%
%   See also DEMOPISTONENGINEDECK, CALCULATEPSFC, PISTONEFFICIENCY,
%       U - http://www.mathworks.com/matlabcentral/fileexchange/38977.
%
%   [BSFC,eProd,e] = CALCULATEBSFC(h,M,throttle,assumptions)

%   Copyright 2024 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

if nargin < 4 || isempty(assumptions)
    assumptions = struct();
    % Default assumptions and efficiency models in use.
end
if ~isfield(assumptions,'Q')
    if isa(h,'DimVar')
        assumptions.Q = 43.2*u.MJ/u.kg; % 100LL avgas
    else
        assumptions.Q = 43.2e6; % J/kg, 100LL avgas (slightly higher than Jet A)
    end
end
if ~isfield(assumptions,'efficiencies')
    eMax = 0.35; % Typical maximum efficiency for piston engines (lower than gas turbines)
    assumptions.efficiencies = {eMax,@pistonefficiency};
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
BSFC = massPerUnitEnergy./eProd;

end