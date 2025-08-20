% DEMO_PISTON_ENGINE - Demonstration of piston engine modeling capabilities
%
% This script demonstrates how to use the piston engine modeling functions
% for both normally aspirated and turbo-normalized engines.
%
% See also DEMOPISTONENGINEDECK, PISTONPOWERLAPSE, CALCULATEBSFC

%   Copyright 2024 Sky Sartorius
%   Author contact: mathworks.com/matlabcentral/fileexchange/authors/101715

%% Example 1: Lycoming IO-540 (normally aspirated, ~300 HP)
fprintf('Example 1: Lycoming IO-540 Normally Aspirated Engine\n');
fprintf('===================================================\n');

% Engine parameters
Psls_lycoming = 224000; % 300 HP in watts
propDiameter = 2.0; % 2 meter diameter propeller
propArea = pi * (propDiameter/2)^2;

% Define engine deck function for normally aspirated engine
assumptions_na.engineType = 'normally_aspirated';
assumptions_na.Q = 43.2e6; % 100LL avgas heating value
assumptions_na.etaDisc = 0.82; % Fixed pitch propeller efficiency

lycoming_deck = @(h,M,Treq) demopistonenginedeck(Psls_lycoming, propArea, h, M, Treq, assumptions_na);

% Test at various altitudes
altitudes_ft = [0, 2000, 5000, 8000, 12000]; % feet
altitudes_m = altitudes_ft * 0.3048; % convert to meters
M_cruise = 0.15; % Typical cruise Mach number

fprintf('Altitude (ft)  Power Available (HP)  Max Thrust (lbf)\n');
fprintf('--------------------------------------------------\n');

for i = 1:length(altitudes_m)
    try
        [Tavail, ~, ~, ~] = lycoming_deck(altitudes_m(i), M_cruise, []);
        % Convert back to common units
        power_hp = Psls_lycoming * pistonpowerlapse(altitudes_m(i), M_cruise, assumptions_na) / 745.7; % watts to HP
        thrust_lbf = Tavail / 4.448; % Newtons to lbf
        
        fprintf('%8d      %12.0f        %10.0f\n', altitudes_ft(i), power_hp, thrust_lbf);
    catch
        fprintf('%8d      Unable to calculate (missing atmos function)\n', altitudes_ft(i));
    end
end

fprintf('\n');

%% Example 2: Turbo-normalized engine (e.g., Piper Malibu engine)
fprintf('Example 2: Turbo-Normalized Engine (Critical Alt: 20,000 ft)\n');
fprintf('===========================================================\n');

% Engine parameters for turbo-normalized engine
Psls_turbo = 268000; % 350 HP in watts
assumptions_tn.engineType = 'turbo_normalized';
assumptions_tn.criticalAltitude = 6096; % 20,000 ft in meters
assumptions_tn.Q = 43.2e6; % 100LL avgas
assumptions_tn.etaDisc = 0.85; % Constant speed propeller

turbo_deck = @(h,M,Treq) demopistonenginedeck(Psls_turbo, propArea, h, M, Treq, assumptions_tn);

fprintf('Altitude (ft)  Power Available (HP)  Max Thrust (lbf)\n');
fprintf('--------------------------------------------------\n');

for i = 1:length(altitudes_m)
    try
        [Tavail, ~, ~, ~] = turbo_deck(altitudes_m(i), M_cruise, []);
        % Convert back to common units
        power_hp = Psls_turbo * pistonpowerlapse(altitudes_m(i), M_cruise, assumptions_tn) / 745.7;
        thrust_lbf = Tavail / 4.448;
        
        fprintf('%8d      %12.0f        %10.0f\n', altitudes_ft(i), power_hp, thrust_lbf);
    catch
        fprintf('%8d      Unable to calculate (missing atmos function)\n', altitudes_ft(i));
    end
end

fprintf('\n');

%% Example 3: Fuel consumption comparison
fprintf('Example 3: Fuel Consumption at 75%% Power\n');
fprintf('========================================\n');

throttle_75 = 0.75;
h_cruise = 2438; % 8000 ft in meters
M_cruise = 0.15;

fprintf('Engine Type     Fuel Flow (gal/hr)  BSFC (lb/hp/hr)\n');
fprintf('------------------------------------------------\n');

try
    % Normally aspirated
    [~, TSFC_na, fuelFlow_na] = lycoming_deck(h_cruise, M_cruise, []);
    power_75_na = Psls_lycoming * pistonpowerlapse(h_cruise, M_cruise, assumptions_na) * throttle_75;
    fuel_flow_na_gph = fuelFlow_na * 3600 / 2.68; % kg/s to gal/hr (avgas density ~2.68 kg/gal)
    bsfc_na = fuelFlow_na / (power_75_na / 745.7) * 2.205; % kg/s per HP to lb/hr per HP
    
    fprintf('Normally Asp.   %12.1f        %10.3f\n', fuel_flow_na_gph, bsfc_na);
    
    % Turbo-normalized  
    [~, TSFC_tn, fuelFlow_tn] = turbo_deck(h_cruise, M_cruise, []);
    power_75_tn = Psls_turbo * pistonpowerlapse(h_cruise, M_cruise, assumptions_tn) * throttle_75;
    fuel_flow_tn_gph = fuelFlow_tn * 3600 / 2.68;
    bsfc_tn = fuelFlow_tn / (power_75_tn / 745.7) * 2.205;
    
    fprintf('Turbo-Norm.     %12.1f        %10.3f\n', fuel_flow_tn_gph, bsfc_tn);
    
catch
    fprintf('Unable to calculate fuel consumption (missing atmos function)\n');
    fprintf('To run this demo fully, install a standard atmosphere function:\n');
    fprintf('https://www.mathworks.com/matlabcentral/fileexchange/28135\n');
end

fprintf('\n');

%% Example 4: Creating custom engine assumptions
fprintf('Example 4: Custom Engine with Different Fuel\n');
fprintf('===========================================\n');

% Custom assumptions for diesel engine
assumptions_diesel.engineType = 'turbo_normalized';
assumptions_diesel.criticalAltitude = 4572; % 15,000 ft (lower than gasoline)
assumptions_diesel.Q = 42.8e6; % Diesel fuel heating value (J/kg)
assumptions_diesel.efficiencies = {0.40, @pistonefficiency}; % Higher max efficiency for diesel
assumptions_diesel.etaDisc = 0.85;

fprintf('Custom diesel engine assumptions created.\n');
fprintf('Higher efficiency (40%% vs 35%%) but different critical altitude.\n');
fprintf('Fuel heating value: %.1f MJ/kg (diesel)\n', assumptions_diesel.Q/1e6);

fprintf('\nDemo completed. Key features demonstrated:\n');
fprintf('- Normally aspirated vs turbo-normalized power lapse\n');
fprintf('- Fuel consumption calculations\n');
fprintf('- Custom engine configuration\n');
fprintf('- Integration with propeller modeling\n');