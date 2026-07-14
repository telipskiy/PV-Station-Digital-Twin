%% Solar Power Inverter
% 
% This example shows how to determine the efficiency of a single-stage
% solar inverter. The model simulates one complete AC cycle for a
% specified level of solar irradiance and corresponding optimal DC voltage
% and AC RMS current. Using the example SolarCellPowerCurveExample,
% the optimal values have been determined as 342V DC and 20.05A AC for an
% irradiance of 1000W/m^2 and panel temperature of 20 degrees Celsius.
% Inverter efficiency is determined in two independent ways. The first
% compares the ratio of AC power out to DC power in over one AC cycle.
% The second calculates losses by component by making use of Simscape(TM)
% logging. The small difference in calculated efficiency value is due to
% differences between trapezoidal integration used by the script and the
% greater accuracy achieved by the Simulink(R) variable-step solver.
% 
% 

% Copyright 2008-2023 The MathWorks, Inc.



%% Model

open_system('SolarPowerInverter')

set_param(find_system('SolarPowerInverter','FindAll', 'on','type','annotation','Tag','ModelFeatures'),'Interpreter','off')

%% Simulation Results from Simscape Logging
%%
%
% The plots below show the current output from the inverter and the power
% dissipated by two of the MOSFETs.
%


SolarPowerInverterPlotPower;
%%
%
% The table below shows the power dissipated by individual components in
% the SolarPowerInverter model.  These totals were calculated from
% simulation results using logged Simscape variables and the losses
% calculation utility ee_getPowerLossSummary.



SolarPowerInverterPlotLossesTable;

%%

