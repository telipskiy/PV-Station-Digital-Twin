% This script assigns datasheet values to MATLAB(R) workspace variables
% for use by the example model SolarPanelValidation. The model uses the Solar
% Cell parameterization option based on short circuit current and open
% circuit voltage data that is often provided on datasheets.

%% Copyright 2013-2023 The MathWorks, Inc.

%% Data from solar photovoltaic panel manufacturer datasheet
% Data for standard test condition (STC)
Isc=8.18; % Short circuit current at STC in ampere
Voc=36.7; % Open circuit voltage at STC in volts
% Most of the solar PV panels will have many solar cells connected in series,
Ns_cell=60; % Number of solar cells connected in series
% As a check, make sure that Voc/Ns_cell is equal to a typical diode
% forward voltage drop. For silicon solar cell Voc/Ns_cell should be
% between 0.55 to 0.75. For a CdTe solar cell, Voc/Ns_cell can be nearer 1.

% Some of the solar pv panels may also have parallel-connected strings of cells, 
% for example in low voltage applications.
Np_cell=3; % Number of parallel strings of series-connected cells

Tct=(0.04/100); % Current (Isc) temperature coefficient (units 1/degC)
                % For a temperature coefficent given in A/degC, divide by Isc.

Tmeas=25; % Measurement temperature (25 degC for STC)
Irad=1000; % Irradiance (1000 W/m2 for STC)

%% Non-datasheet parameters
% The parameters below are not given on the datasheet, but are set to
% typical values for the technology used.
NQ=1.5; % Ideality factor for diode dark current 
        % Ideality factor of a single crytaline solar cells is closer to 1,
        % and ideality factor for an amorphous solar cell is closer to 2.

Rs=0; % Series resistance of the cell in ohm.  
      % This value can be used for tuning the I-V characteristic to match the
      % manufacturer datasheet. Results are sensitive to the Rs value, so it is
      % usually best to start with the value at zero. 

TXIS1=3; % Temperature exponent for diode saturation current Is
         % This factor accounts for output voltage temperature dependency,
         % and can be tuned to match datasheet performance curves. For an
         % approximate result set to 3, and keep in the range 1.5 to 4.5.

%% Define independent environmental variables
% Specify the range of irradiance levels and temperatures over which to
% plot the current and power curves.
irradianceVec = [200 500 1000]; % Solar irradiance in W/m^2
temperatureVec = [25 50]; % Simulation cell temperature in degC
