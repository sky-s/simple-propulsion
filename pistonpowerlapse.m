function [lapse,manifoldPressure] = pistonpowerlapse(h,M,assumptions)
% PISTONPOWERLAPSE determines the amount of power available from a piston engine
% as a function of flight altitude and Mach number.
% 
%   lapse = PISTONPOWERLAPSE(h,M,assumptions)
% 
%   lapse:            Ratio of available power to available power under sea level
%                     static conditions, Pavail/Psls.
%   manifoldPressure: Manifold pressure ratio (for turbo-normalized engines)
%   h:                Altitude in meters or DimVar.
%   M:                Mach number.
%   assumptions:      Struct with fields:
%     engineType      - 'normally_aspirated' or 'turbo_normalized'. Default is
%                       'normally_aspirated'.
%     criticalAltitude- For turbo-normalized engines, altitude in meters where
%                       turbocharger can no longer maintain sea level manifold
%                       pressure. Default is 6096 m (20000 ft).
%     ramRecovery     - Ram air recovery efficiency. Default is 0.7.
% 
%   PISTONPOWERLAPSE requires a standard atmosphere model on the MATLAB path.
% 
%   See also DEMOPISTONENGINEDECK, POWERLAPSE,
%    ATMOS - http://www.mathworks.com/matlabcentral/fileexchange/28135

%   Copyright 2024 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

% Default assumptions
if nargin < 3 || isempty(assumptions)
    assumptions = struct();
end
if ~isfield(assumptions,'engineType')
    assumptions.engineType = 'normally_aspirated';
end
if ~isfield(assumptions,'criticalAltitude')
    if isa(h,'DimVar')
        assumptions.criticalAltitude = 20000*u.ft; % 6096 m
    else
        assumptions.criticalAltitude = 6096; % meters (20000 ft)
    end
end
if ~isfield(assumptions,'ramRecovery')
    assumptions.ramRecovery = 0.7;
end

% Find pressure ratio
if exist('atmos','file') >= 2
    [~,~,P] = atmos(h);
    [~,~,P0] = atmos(0*h);
    delta = P./P0;
elseif exist('atmosisa','file') >= 2
    [~,P,~,~] = atmosisa(h);
    [~,P0,~,~] = atmosisa(0*h);
    delta = P./P0;
else
    link = 'http://www.mathworks.com/matlabcentral/fileexchange/28135';
    a='PISTONPOWERLAPSE requires a standard atmosphere model on the MATLAB path';
    b=['<a href="' link '">Standard atmosphere on MatlabCentral</a>'];
    c=['<a href="' link '?download=true">Direct download</a>'];
    error('%s.\n%s\n%s',a,b,c)
end

% Ram pressure recovery
ramPressureRatio = 1 + assumptions.ramRecovery * 0.2 * M.^2;
delta = delta .* ramPressureRatio;

switch lower(assumptions.engineType)
    case 'normally_aspirated'
        % For normally aspirated engines, power decreases directly with air density
        % Typically: Power ~ (density)^0.7 to (density)^1.0
        % Using 0.8 as a reasonable compromise
        lapse = delta.^0.8;
        manifoldPressure = delta;
        
    case 'turbo_normalized'
        % For turbo-normalized engines, maintain sea level power up to critical altitude
        % Above critical altitude, behaves like normally aspirated
        if isa(h,'DimVar')
            [~,~,Pcrit] = atmos(assumptions.criticalAltitude);
            [~,~,P0] = atmos(0*assumptions.criticalAltitude);
            criticalDelta = Pcrit./P0;
        else
            if exist('atmos','file') >= 2
                [~,~,Pcrit] = atmos(assumptions.criticalAltitude);
                [~,~,P0] = atmos(0);
                criticalDelta = Pcrit./P0;
            elseif exist('atmosisa','file') >= 2
                [~,Pcrit,~,~] = atmosisa(assumptions.criticalAltitude);
                [~,P0,~,~] = atmosisa(0);
                criticalDelta = Pcrit./P0;
            end
        end
        
        % Manifold pressure limited by turbocharger capability
        manifoldPressure = min(1.0, delta ./ criticalDelta);
        
        % Power follows manifold pressure below critical altitude,
        % then decreases with density above critical altitude
        belowCritical = delta >= criticalDelta;
        lapse = ones(size(delta));
        lapse(~belowCritical) = (delta(~belowCritical) ./ criticalDelta).^0.8;
        
    otherwise
        error('Unknown engine type: %s. Use ''normally_aspirated'' or ''turbo_normalized''.', ...
            assumptions.engineType);
end

end