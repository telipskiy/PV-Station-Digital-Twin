% Code to plot simulation results from Three Phase Solar Inverter with Controller
%% Plot Description:
%
% The plot below shows the requested and measured power and voltage for the test.

% Copyright 2023-2024 The MathWorks, Inc.

% Generate simulation results  
sim('ControlThreePhaseSolarInverter'); % Run simulation

% Reuse figure if it exists, else create new figure
if ~exist('h1_PVControllerdemo', 'var') || ...
        ~isgraphics(h1_PVControllerdemo, 'figure')
    h1_PVControllerdemo = figure('Name', 'ControlThreePhaseSolarInverter');
end
figure(h1_PVControllerdemo)
clf(h1_PVControllerdemo)

% Get simulation results
vdcmeas=logsout_PVControllerdemo{1}.Values.Data;
vdcref=logsout_PVControllerdemo{2}.Values.Data;
time=logsout_PVControllerdemo{1}.Values.Time;
activePower=logsout_PVControllerdemo{6}.Values.Data;
reactivePower=logsout_PVControllerdemo{5}.Values.Data;

% Plot results
simlog_handles(1) = subplot(3, 1, 1);
plot(time, vdcmeas, 'LineWidth', 1)
grid on
title('DC Bus Voltage')
ylabel('Voltage (V)')

simlog_handles(2) = subplot(3, 1, 2);
plot(time, activePower, 'LineWidth', 1)
grid on
title('PV Inverter Real Power Output')
ylabel('Real Power (W)')
simlog_handles(3) = subplot(3, 1, 3);
plot(time, reactivePower, 'LineWidth', 1)
grid on
title('PV Inverter Reactive Power Output')
ylabel('Reactive Power (VARS)')
xlabel('Time (s)');
linkaxes(simlog_handles, 'x')