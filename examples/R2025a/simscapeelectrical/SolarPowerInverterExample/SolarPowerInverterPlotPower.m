% Code to plot simulation results from SolarPowerInverter
%% Plot Description:
%
% The plots below show the current output from the inverter and the power
% dissipated by two of the MOSFETs.

% Copyright 2016-2023 The MathWorks, Inc.

% Generate new simulation results if they don't exist or if they need to be updated
if ~exist('simlog_SolarPowerInverter', 'var') || ...
        simlogNeedsUpdate(simlog_SolarPowerInverter, 'SolarPowerInverter') 
    sim('SolarPowerInverter')
    % Model StopFcn callback adds a timestamp to the Simscape simulation data log
end

% Reuse figure if it exists, else create new figure
if ~exist('h1_SolarPowerInverter', 'var') || ...
        ~isgraphics(h1_SolarPowerInverter, 'figure')
    h1_SolarPowerInverter = figure('Name', 'SolarPowerInverter');
end
figure(h1_SolarPowerInverter)
clf(h1_SolarPowerInverter)

% Get simulation results
simlog_t = simlog_SolarPowerInverter.CL.i.series.time;
simlog_CLi = simlog_SolarPowerInverter.CL.i.series.values('A');
simlog_MOS1pwr = simlog_SolarPowerInverter.MOS1.mos.power_dissipated.series.values('W');
simlog_MOS2pwr = simlog_SolarPowerInverter.MOS2.mos.power_dissipated.series.values('W');

% Plot results
simlog_handles(1) = subplot(2, 1, 1);
plot(simlog_t, simlog_CLi, 'LineWidth', 1)
hold off
grid on
title('Inverter Output')
ylabel('Current (A)')

simlog_handles(2) = subplot(2, 1, 2);
plot(simlog_t, simlog_MOS1pwr, 'LineWidth', 1)
hold on
plot(simlog_t, simlog_MOS2pwr, 'LineWidth', 1)
hold off
grid on
title('Power Dissipated')
ylabel('Power (W)')
xlabel('Time (s)')
legend({'MOSFET1','MOSFET2'},'Location','Best');

linkaxes(simlog_handles, 'x')

% Remove temporary variables
clear simlog_t simlog_CLi simlog_MOS1pwr simlog_MOS2pwr simlog_handles
