%% This example script shows how to set parameters for the ControlThreePhaseSolarInverter model
% Copyright 2023-2024 The MathWorks, Inc.

% Grid Parameters
grid.voltage=400;    % Actual supply L-L voltage in volts
grid.frequency=60;   % Supply frequency in hertz

% PV Inverter Parameters
imax=1.2;                                      % Current limit of inverter in pu
vdc=1.25*(grid.voltage*sqrt(2)*2/(1*sqrt(3))); % DC voltage of inverter in volts
c=10.5e-4;                                     % DC capacitance in farads
l=1e-3;                                        % AC filter inductance in henries

% PV Cell Parameters
solarcell.diodeSaturationCurrent=3.15e-07; % Cell diode saturation current in amperes
solarcell.solarGeneratedCurrent_AM=3.80;   % Light generated current in amperes
solarcell.qualityFactori=1.4;              % Quality factor1
solarcell.qualityFactorj=2;                % Quality factor2
solarcell.seriesResistance=0.0042;         % Cell series resistance in ohms
solarcell.parallelResistance=10.1;         % Cell parallel resistance in ohms
solarcell.tempCofficient=0.000805;         % Cell temperature cofficient
solarcell.Eg=1.14;                         % Cell energy gap in electron volts
solarcell.temparatureExponent_Is1=3.38;    % Temperature exponent of solar cell
solarcell.temparatureExponent_Is2=3;       % Temperature exponent of solar cell
solarcell.temparatureExponent_Rs=0;        % Temperature exponent of solar cell
solarcell.temparatureExponent_Rp=0;        % Temperature exponent of solar cell
solarcell.measurementTemperature=25;       % Temperature of solar cell in degrees celcius
solarcell.deviceTemperature=25;            % Simulation temperature in degrees celcius

% PV Panel and Array Parameters
panel.nseriesCellPanel=150;               % Number of series cells in an panel
panel.nparallelStringsPanel=10;           % Number of parallel cells in an panel

% Solar Array for 60 kWp Power
array.nseriespanelsPerString=12;          % Number of series panels
array.nparallelStrings=2;                 % Number of parallel strings to produce 60 kWp Power

% Current Controller Gains
kpic=1;   % Proportional gain
kiic=250; % Integral gain

% Voltage Controller Gains
kpv=0.4;  % Proportional gain
kiv=3;    % Integral gain

% MPPT Parameters
mPPT.initialVoltage=850; % Initial voltage in volts 
mPPT.settlingTime=1e-5;  % MPPT settling time in seconds
mPPT.stepSize=10;        % MPPT algorithm step size in volts

% PLL Gains
kppll=200;   % Proportional gain
kipll=2000;  % Integral gain

% System Base
kVbase=400;  % Base voltage in volts
mVAbase=1e5; % Base power in volt-amperes
zbase=(kVbase)^2/mVAbase; % Calculated impedance base in ohms
vdcbase=1e3; % DC bus base voltage in volts

% Simulation Time
Ts=50e-6; % Simulation step size in seconds
T=4;      % Total simulation time in seconds