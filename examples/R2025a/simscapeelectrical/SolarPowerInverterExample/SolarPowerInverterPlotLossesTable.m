%% Solar Cell Power Inverter - Calculate Losses By Component
%% Plot Description:
%
% The table below shows the power dissipated by individual components in
% the SolarPowerInverter model.  These totals were calculated from
% simulation results using logged Simscape(TM) variables and the losses
% calculation utility ee_getPowerLossSummary.

% Copyright 2013-2023 The MathWorks, Inc.

% Generate new simulation results if they don't exist or if they need to be updated
if ~exist('simlog_SolarPowerInverter', 'var') || ...
        simlogNeedsUpdate(simlog_SolarPowerInverter, 'SolarPowerInverter') 
    open_system('SolarPowerInverter')
    disp('Running the Solar Power Inverter model to generate one AC cycle of data')
    sim('SolarPowerInverter')
end

%% Extract losses
tabulatedLosses = ee_getPowerLossSummary(simlog_SolarPowerInverter);

%% Sum total semiconductor device losses
powerLosses = tabulatedLosses{:,2};

%% Power supplied
vDC = simlog_SolarPowerInverter.DC_Voltage_Sensor.Voltage_Sensor.V.series.values;
iDC = simlog_SolarPowerInverter.DC_Current_Sensor.Current_Sensor.I.series.values;
t = simlog_SolarPowerInverter.DC_Voltage_Sensor.Voltage_Sensor.V.series.time;
powerDC = 60*trapz(t,vDC.*iDC);

%% Display the results
totalLosses = sum(powerLosses);
efficiency = 100*(powerDC-totalLosses)/powerDC;
disp(['Efficiency = ' num2str(efficiency) '%'   ])
disp('Losses in watts by component are as follows:')
tabulatedLosses{:,'Power'}=round(tabulatedLosses{:,'Power'},2);
disp(tabulatedLosses)
