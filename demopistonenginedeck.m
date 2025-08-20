function [Tavail,TSFC,fuelFlow,etaProp,eCoreTotal,eCore] = ...
    demopistonenginedeck(Pshaftsls,propArea,h,M,Treq,assumptions)
%   Example piston engine deck function as a demonstration of piston engine
%   modeling tools for normally aspirated and turbo-normalized engines.
% 
%   [Tavail,TSFC,fuelFlow,etaProp,eCoreTotal,eCore] = ...
%           DEMOPISTONENGINEDECK(Pshaftsls,propArea,h,M,Treq,assumptions)
% 
%   Note: Pshaftsls is the sea level static shaft power output of the engine.
%   For piston engines, this is typically the rated power at sea level.
% 
%   Example:
%       Psls = 300e3; % 300 kW (about 400 HP)
%       A = 3.14; % propeller disc area in m^2
%       myDeck = @(h,M,Treq) demopistonenginedeck(Psls,A,h,M,Treq,[]);
% 
%   Normally aspirated example:
%       assumptions.engineType = 'normally_aspirated';
%       myNADeck = @(h,M,Treq) demopistonenginedeck(Psls,A,h,M,Treq,assumptions);
%
%   Turbo-normalized example:
%       assumptions.engineType = 'turbo_normalized';
%       assumptions.criticalAltitude = 6096; % 20000 ft
%       myTNDeck = @(h,M,Treq) demopistonenginedeck(Psls,A,h,M,Treq,assumptions);
% 
%   See also ACTUATORDISC, CALCULATEBSFC,
%     PISTONPOWERLAPSE, PISTONEFFICIENCY, 
%     ATMOS - http://www.mathworks.com/matlabcentral/fileexchange/28135.

%   Copyright 2024 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

% Default assumptions 
if nargin < 6 || isempty(assumptions)
    assumptions.etaDisc                 = 0.85; % Propeller efficiency (lower than ducted fan)
    assumptions.Q                       = 43.2e6; % J/kg 100LL avgas
    assumptions.efficiencies            = {0.35,@pistonefficiency}; % Max efficiency ~35%
    assumptions.powerlapse              = @pistonpowerlapse;
    assumptions.engineType              = 'normally_aspirated';
    if exist('u','var') % DimVar units available
        assumptions.criticalAltitude    = 20000*u.ft;
    else
        assumptions.criticalAltitude    = 6096; % meters (20000 ft)
    end
    assumptions.ramRecovery             = 0.7;
end

% Set default propeller efficiency if not specified
if ~isfield(assumptions,'etaDisc')
    assumptions.etaDisc = 0.85;
end

% Flight conditions
[rho,a] = atmosphere(h);
V = M.*a;

% Step 1: Find available thrust
if isnumeric(assumptions.powerlapse)
    lapse = assumptions.powerlapse;
else
    lapse = assumptions.powerlapse(h,M,assumptions);
end
PshaftAvail = lapse.*Pshaftsls;
[Tavail,etaProp] = ...
    actuatordisc('computeT',PshaftAvail,rho,propArea,V,assumptions.etaDisc);

% Step 2: Find fuel consumption
if nargin<5 || isempty(Treq)
    [TSFC,fuelFlow,eCoreTotal,eCore] = deal([]);
    return
end

PshaftReq = actuatordisc('computeP',Treq,rho,propArea,V,assumptions.etaDisc);

throttle = PshaftReq./PshaftAvail;

[BSFC,eCoreTotal,eCore] = calculatebsfc(h,M,throttle,assumptions);

fuelFlow = PshaftReq.*BSFC;

TSFC = fuelFlow./Treq;

end

function [rho,a] = atmosphere(h)
if exist('atmos','file') >= 2
    [rho,a] = atmos(h);
elseif exist('atmosisa','file') >= 2
    [T,~,~,rho] = atmosisa(h);
    a = sqrt(1.4*287.05287*T);
else
    link = 'http://www.mathworks.com/matlabcentral/fileexchange/28135';
    a='DEMOPISTONENGINEDECK requires a standard atmosphere model on the MATLAB path';
    b=['<a href="' link '">Standard atmosphere on MatlabCentral</a>'];
    c=['<a href="' link '?download=true">Direct download</a>'];
    error('%s.\n%s\n%s',a,b,c)
end
end