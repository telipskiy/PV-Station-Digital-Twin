%% Solar Panel Parameterization Validation
% 
% This example shows how to model a solar panel by using data from a
% manufacturer datasheet. This example uses the datasheet data to generate
% current-voltage and power-voltage curves for the solar panel. The
% power-voltage curve helps you identifying the peak power for a given irradiance level
% and panel cell temperature. This peak power is then useful when designing
% an inverter.

% Copyright 2008-2023 The MathWorks, Inc.

%% Model

open_system('SolarPanelValidation')
set_param(find_system('SolarPanelValidation','FindAll', 'on','type','annotation','Tag','ModelFeatures'),'Interpreter','off')


%% Solar Panel Subsystem
% The Solar Panel subsystem models a solar panel that contains
% parallel-connected strings of series-connected solar cells. The solar
% cell strings are modeled by a single Solar Cell block from the
% Simscape(TM) Electrical(TM) library. The workspace variables _Np_cell_ and 
% _Ns_cell_ define the number of parallel strings and the number of 
% series-connected cells in each string, respectively.
%
% Connecting multiple solar cell strings in parallel slows down the  simulation
% because it increases the number of elements in a model. To avoid a
% reduction in performance, a controlled-current source scales up the
% current to the fulfill the demand of the requisite number of parallel
% paths. The current source is modeled by a Current-Controlled Current
% Source block from the Simscape(TM) Foundation Library. 
%
% The implicit assumptions are that: 
%
% * All of the solar cells are identical.
% * Temperature and irradiance levels are the same for each cell.


imshow('SolarPanelValidationCircuit.jpg');

%% Simulation Results
% This plot shows the current and power as a function of voltage for various
% irradiance and cell temperatures. The table shows the peak power values
% extracted from the plot. If the datasheet includes a similar plot, 
% then you can use it to validate the correct parameterization of the Solar
% Cell block.

SolarPanelValidationPlotCurrentVoltageCharacteristics;

%% Results from Real-Time Simulation
%%
%
% This example has been tested on a Speedgoat Performance real-time target 
% machine with an Intel(R) 3.5 GHz i7 multi-core CPU. This model can run 
% in real time with a step size of 30 microseconds.

%%

