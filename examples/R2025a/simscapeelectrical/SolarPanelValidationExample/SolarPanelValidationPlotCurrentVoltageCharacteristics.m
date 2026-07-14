% Code to plot simulation results from SolarPanelValidation
%% Plot Description:
%
% This script shows how to generate the current-voltage and power-voltage
% curves given on commerical solar panel datasheets. The plots can be used
% to show that the panel model has correctly been parameterized using
% datasheet numerical values. Understanding the current-voltage and
% power-voltage curves is also important for inverter design. Ideally the
% solar array will always be operating at peak power given the irradiance
% level and panel temperature.

% Copyright 2013-2023 The MathWorks, Inc.

%% Parameterize the panel
SolarPanelValidationInput;

%% Color code
Num_plot=length(irradianceVec)*length(temperatureVec);
Color_map=parula(Num_plot);

%% Create figure for the results
if ~exist('h1_SolarPanelValidation', 'var') || ...
        ~isgraphics(h1_SolarPanelValidation, 'figure')
    h1_SolarPanelValidation = figure('Name', 'SolarPanelValidation');
end
figure(h1_SolarPanelValidation)
clf(h1_SolarPanelValidation)

%% Load the model and simulate all combinations of irradiance and temperature
open_system('SolarPanelValidation')

index = 0;
legend_info = cell(1,Num_plot);
PanelIrradiance = zeros(Num_plot,1);
CellTemperature = zeros(Num_plot,1);
MaximumCurrent  = zeros(Num_plot,1);
MaximumVoltage  = zeros(Num_plot,1);
MaximumPower    = zeros(Num_plot,1);

for temperature = temperatureVec
   for irradiance = irradianceVec
       index = index+1;      % ukLine color selection    
        sim('SolarPanelValidation')
        
       % Extract results from simlog
       simlog_vPanel = simlog_SolarPanelValidation.Controlled_Voltage_Source.v.series.values;
       simlog_iPanel = simlog_SolarPanelValidation.Controlled_Voltage_Source.i.series.values;
       simlog_vPanel = simlog_vPanel(simlog_iPanel>=0);
       simlog_iPanel = simlog_iPanel(simlog_iPanel>=0);
       power = simlog_vPanel.*simlog_iPanel;
       Max_Volt=simlog_vPanel(power==max(power));
       
       % Extract and save data for max power table
       PanelIrradiance(index) = irradiance;
       CellTemperature(index) = temperature;
       MaximumCurrent(index)  = simlog_iPanel(power==max(power));
       MaximumVoltage(index)  = Max_Volt;
       MaximumPower(index)    = max(power);
    
       % Plot current and power curves
       legend_info{index} = ['T=' num2str(temperature) '^{\o}C, Ir=' num2str(irradiance) 'W/m{^2}'];
       yyaxis left
       plot(simlog_vPanel,simlog_iPanel,'Marker','none','color',Color_map(index,:),'LineStyle','-','LineWidth',1);
       hold on       
       yyaxis right
       plot(simlog_vPanel,power,'Marker','none','color',Color_map(index,:),'LineWidth',1,'LineStyle','--');       
   end    
end

% Plot labeling
grid on
title('Performance (solid line=current, dashed line=power)'); 
xlabel('Output Voltage (V)')
yyaxis right
ylabel('Output Power (W)')
yyaxis left
ylabel('Output Current (A)')
legend(legend_info,'Location','NorthWest')

%% Tabulate the maximum power points
MaxP=table(PanelIrradiance,CellTemperature,MaximumCurrent,MaximumVoltage,MaximumPower);
disp('Maximum power operating points');
disp(MaxP);

% Clear temporary variables
clear simlog_vPanel simlog_iPanel power Max_Volt index legend_info Num_plot Color_map
