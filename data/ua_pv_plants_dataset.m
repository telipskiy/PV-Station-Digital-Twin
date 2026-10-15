%
% Reference technical dataset of real Ukrainian PV power plants
% for parameterization and benchmarking of the PV Station Digital Twin.
%
% Data quality:
%   A = directly published
%   B = calculated from published parameters
%   C = engineering inference
%   D = unavailable / not published

UA_PV_PLANTS_DATASET = struct();

%% ========================================================================
%  DATASET METADATA
% =========================================================================

UA_PV_PLANTS_DATASET.DatasetName = 'UA_PV_PLANTS_DATASET';

UA_PV_PLANTS_DATASET.Version = '1.0';

UA_PV_PLANTS_DATASET.Description = ...
    ['Reference technical characteristics of real Ukrainian PV power plants' ...
     'used for benchmarking and parameterization of the PV Station Digital Twin.'];

UA_PV_PLANTS_DATASET.Units = struct( ...
    'Power',       'MW', ...
    'Energy',      'MWh/year', ...
    'SpecificYield','kWh/kWp/year', ...
    'Voltage',     'kV', ...
    'Current',     'A', ...
    'Resistance',  'Ohm', ...
    'Area',        'ha', ...
    'CO2',         't/year');

UA_PV_PLANTS_DATASET.DataQualityCodes = struct( ...
    'A', 'Directly published', ...
    'B', 'Calculated from published data', ...
    'C', 'Engineering inference', ...
    'D', 'Unavailable / not published');

%% ========================================================================
%  STATION 1 — FOTON ENERGY, PIDHORODNE
% =========================================================================

S = struct();

S.ID = 'UA_PV_001';

S.Name = 'FOTON ENERGY PV Power Plant';

S.Location = struct( ...
    'City',        'Pidhorodne', ...
    'Region',      'Dnipropetrovsk Oblast', ...
    'Country',     'Ukraine');

S.Topology = struct( ...
    'Class',       'String', ...
    'Architecture','Distributed string-inverter architecture', ...
    'DataQuality', 'C');

%% --- PV FIELD ------------------------------------------------------------

S.PV = struct();

S.PV.DC_Power_MWp = 17.55;
S.PV.DC_Power_Quality = 'B';

S.PV.Module.Model = 'RISEN';
S.PV.Module.Model_Quality = 'A';

S.PV.Module.Power_W = 325;
S.PV.Module.Power_Quality = 'A';

S.PV.Module.Count = 54000;
S.PV.Module.Count_Quality = 'A';

S.PV.Module.TotalPower_MWp = S.PV.Module.Count * S.PV.Module.Power_W / 1e6;

S.PV.Module.TotalPower_Quality = 'B';

%% --- INVERTERS -----------------------------------------------------------

S.Inverter = struct();

S.Inverter.Manufacturer = 'ABB';
S.Inverter.Model = 'PVS-120-TL';

S.Inverter.UnitPower_kW = 120;
S.Inverter.UnitPower_Quality = 'A';

S.Inverter.Count = 125;
S.Inverter.Count_Quality = 'A';

S.Inverter.TotalPower_MW = S.Inverter.Count * S.Inverter.UnitPower_kW / 1000;

S.Inverter.TotalPower_Quality = 'B';

%% --- DC/AC RATIO ---------------------------------------------------------

S.DC_AC_Ratio = S.PV.DC_Power_MWp / S.Inverter.TotalPower_MW;

S.DC_AC_Ratio_Quality = 'B';

%% --- TRANSFORMERS --------------------------------------------------------

S.Transformer = struct();

S.Transformer.Count = 8;
S.Transformer.Count_Quality = 'A';

S.Transformer.UnitPower_MVA = 2;
S.Transformer.UnitPower_Quality = 'A';

S.Transformer.TotalPower_MVA = S.Transformer.Count * S.Transformer.UnitPower_MVA;

S.Transformer.TotalPower_Quality = 'B';

S.Transformer.Type = 'TMG-35/0.4';
S.Transformer.Voltage_LV_kV = 0.4;
S.Transformer.Voltage_MV_kV = 35;

S.Transformer.LoadingRatio = S.Inverter.TotalPower_MW / S.Transformer.TotalPower_MVA;

S.Transformer.LoadingRatio_Quality = 'B';

%% --- MV NETWORK ----------------------------------------------------------

S.Grid = struct();

S.Grid.MV_Voltage_kV = 35;
S.Grid.MV_Voltage_Quality = 'A';

S.Grid.ConnectionPoint = '35 kV switchgear';
S.Grid.ConnectionPoint_Quality = 'C';

S.Grid.ShortCircuitPower_MVA = NaN;
S.Grid.ShortCircuitPower_Quality = 'D';

%% --- ENERGY --------------------------------------------------------------

S.Energy = struct();

S.Energy.AnnualGeneration_MWh = 22190;
S.Energy.AnnualGeneration_Quality = 'A';

S.Energy.SpecificYield_kWh_kWp = S.Energy.AnnualGeneration_MWh * 1000 / (S.PV.DC_Power_MWp * 1000);

S.Energy.SpecificYield_Quality = 'B';

S.Energy.CapacityFactor_DC = S.Energy.AnnualGeneration_MWh / (S.PV.DC_Power_MWp * 8760);

S.Energy.CapacityFactor_DC_Quality = 'B';

S.Energy.CapacityFactor_AC = S.Energy.AnnualGeneration_MWh / (S.Inverter.TotalPower_MW * 8760);

S.Energy.CapacityFactor_AC_Quality = 'B';

%% --- LAND ---------------------------------------------------------------

S.Land = struct();

S.Land.Area_ha = 28;
S.Land.Area_Quality = 'A';

S.Land.PowerDensity_MW_per_ha = S.PV.DC_Power_MWp / S.Land.Area_ha;

S.Land.PowerDensity_Quality = 'B';

%% --- SCADA ---------------------------------------------------------------

S.SCADA = struct();

S.SCADA.Platform = 'zenon';
S.SCADA.Platform_Quality = 'A';

S.SCADA.VariableCount = 1024;
S.SCADA.VariableCount_Quality = 'A';

S.SCADA.Protocols = { 'Modbus RTU', 'Modbus TCP/IP', 'IEC 60870-5-101', 'IEC 60870-5-104'};

S.SCADA.Historian = true;
S.SCADA.ExtendedTrend = true;
S.SCADA.AutomaticLineColoring = true;
S.SCADA.IEC60870Gateway = true;

%% --- DATA QUALITY / SOURCE ----------------------------------------------

S.Source = struct();

S.Source.Primary = 'COPA-DATA Ukraine / EDS Engineering project description';

S.Source.URL = 'https://www.copa-data.com.ua/proekty/sonyachna-elektrostantsiya-v-misti-pidgorodne-dnipropetrovskoji-oblasti';

S.Source.Accessed = '2026-09-14';

UA_PV_PLANTS_DATASET.Stations(1) = S;


%% ========================================================================
%  STATION 2 — MALA BILOZERKA
% =========================================================================

S = struct();

S.ID = 'UA_PV_002';

S.Name = 'Mala Bilozerka PV Power Plant';

S.Location = struct( ...
    'City',        'Mala Bilozerka', ...
    'Region',      'Zaporizhzhia Oblast', ...
    'Country',     'Ukraine');

S.Topology = struct( ...
    'Class',       'String', ...
    'Architecture','Distributed string-inverter architecture', ...
    'DataQuality', 'C');

%% PV FIELD

S.PV = struct();

S.PV.DC_Power_MWp = 22.5;
S.PV.DC_Power_Quality = 'A';

S.PV.Module.Model = 'RISEN';
S.PV.Module.Model_Quality = 'A';

S.PV.Module.Power_W = 345;
S.PV.Module.Power_Quality = 'A';

S.PV.Module.Count = 66232;
S.PV.Module.Count_Quality = 'A';

S.PV.Module.TotalPower_MWp = S.PV.Module.Count * S.PV.Module.Power_W / 1e6;

S.PV.Module.TotalPower_Quality = 'B';

%% INVERTERS

S.Inverter = struct();

S.Inverter.Manufacturer = 'ABB';
S.Inverter.Model = 'PVS-120-TL';

S.Inverter.UnitPower_kW = 120;
S.Inverter.UnitPower_Quality = 'A';

S.Inverter.Count = 162;
S.Inverter.Count_Quality = 'A';

S.Inverter.TotalPower_MW = S.Inverter.Count * S.Inverter.UnitPower_kW / 1000;

S.Inverter.TotalPower_Quality = 'B';

%% DC/AC

S.DC_AC_Ratio = S.PV.DC_Power_MWp / S.Inverter.TotalPower_MW;

S.DC_AC_Ratio_Quality = 'B';

%% TRANSFORMERS

S.Transformer = struct();

S.Transformer.Count = 11;
S.Transformer.Count_Quality = 'A';

S.Transformer.UnitPower_MVA = 2;
S.Transformer.UnitPower_Quality = 'A';

S.Transformer.TotalPower_MVA = S.Transformer.Count * S.Transformer.UnitPower_MVA;

S.Transformer.TotalPower_Quality = 'B';

S.Transformer.Type = 'TMG-35/0.48';

S.Transformer.Voltage_LV_kV = 0.48;
S.Transformer.Voltage_MV_kV = 35;

S.Transformer.LoadingRatio = S.Inverter.TotalPower_MW / S.Transformer.TotalPower_MVA;

S.Transformer.LoadingRatio_Quality = 'B';

%% MV NETWORK

S.Grid = struct();

S.Grid.MV_Voltage_kV = 35;
S.Grid.MV_Voltage_Quality = 'A';

S.Grid.ConnectionPoint = '35 kV network';
S.Grid.ConnectionPoint_Quality = 'C';

S.Grid.ShortCircuitPower_MVA = NaN;
S.Grid.ShortCircuitPower_Quality = 'D';

%% ENERGY

S.Energy = struct();

S.Energy.AnnualGeneration_MWh = 29787;
S.Energy.AnnualGeneration_Quality = 'A';

S.Energy.SpecificYield_kWh_kWp = S.Energy.AnnualGeneration_MWh * 1000 / (S.PV.DC_Power_MWp * 1000);

S.Energy.SpecificYield_Quality = 'B';

S.Energy.CapacityFactor_DC = S.Energy.AnnualGeneration_MWh / (S.PV.DC_Power_MWp * 8760);

S.Energy.CapacityFactor_DC_Quality = 'B';

S.Energy.CapacityFactor_AC = S.Energy.AnnualGeneration_MWh / (S.Inverter.TotalPower_MW * 8760);

S.Energy.CapacityFactor_AC_Quality = 'B';

%% ENVIRONMENTAL

S.Environment = struct();

S.Environment.CO2Reduction_t_year = 16594;
S.Environment.CO2Reduction_Quality = 'A';

S.Environment.CO2Intensity_kg_per_kWh = S.Environment.CO2Reduction_t_year * 1000 / (S.Energy.AnnualGeneration_MWh * 1000);

S.Environment.CO2Intensity_Quality = 'B';

%% SCADA

S.SCADA = struct();

S.SCADA.Platform = 'zenon';
S.SCADA.Platform_Quality = 'A';

S.SCADA.VariableCount = 2048;
S.SCADA.VariableCount_Quality = 'A';

S.SCADA.Protocols = { 'Modbus RTU', 'Modbus TCP/IP', 'IEC 60870-5-101', 'IEC 60870-5-104'};

S.SCADA.Historian = true;
S.SCADA.ExtendedTrend = true;
S.SCADA.AutomaticLineColoring = true;
S.SCADA.IEC60870Gateway = true;

%% SOURCE

S.Source = struct();

S.Source.Primary = 'COPA-DATA Ukraine / EDS Engineering project description';

S.Source.URL = 'https://www.copa-data.com.ua/proekty/sonyachna-elektrostantsiya-v-seli-mala-bilozerka';

S.Source.Accessed = '2026-09-14';

UA_PV_PLANTS_DATASET.Stations(2) = S;


%% ========================================================================
%  STATION 3 — SOUTHERN UKRAINE / ODESA OBLAST
% =========================================================================

S = struct();

S.ID = 'UA_PV_003';

S.Name = 'Southern Ukraine PV Power Plant';

S.Location = struct( ...
    'City',        'Not published', ...
    'Region',      'Odesa Oblast', ...
    'Country',     'Ukraine');

S.Topology = struct( ...
    'Class',       'String', ...
    'Architecture','Distributed inverter architecture', ...
    'DataQuality', 'C');

%% IMPORTANT:
% The source identifies this project as 6.3 MW.
% The user-provided URL title contains "63 MW", which should NOT
% be used as the technical rating without independent confirmation.

S.PV = struct();

S.PV.DC_Power_MWp = NaN;
S.PV.DC_Power_Quality = 'D';

S.PV.Module.Model = '';
S.PV.Module.Model_Quality = 'D';

S.PV.Module.Power_W = NaN;
S.PV.Module.Power_Quality = 'D';

S.PV.Module.Count = NaN;
S.PV.Module.Count_Quality = 'D';

%% INVERTERS

S.Inverter = struct();

S.Inverter.Manufacturer = 'Schneider Electric';
S.Inverter.Model = 'Conext CL-60 E';

S.Inverter.UnitPower_kW = NaN;
S.Inverter.UnitPower_Quality = 'D';

S.Inverter.Count = 95;
S.Inverter.Count_Quality = 'A';

S.Inverter.TotalPower_MW = 6.3;
S.Inverter.TotalPower_Quality = 'A';

%% DC/AC

S.DC_AC_Ratio = NaN;
S.DC_AC_Ratio_Quality = 'D';

%% TRANSFORMERS / SUBSTATIONS

S.Transformer = struct();

S.Transformer.Count = 6;
S.Transformer.Count_Quality = 'A';

S.Transformer.UnitPower_MVA = NaN;
S.Transformer.UnitPower_Quality = 'D';

S.Transformer.TotalPower_MVA = NaN;
S.Transformer.TotalPower_Quality = 'D';

S.Transformer.Type = '';
S.Transformer.Voltage_LV_kV = NaN;
S.Transformer.Voltage_MV_kV = NaN;

S.Transformer.LoadingRatio = NaN;
S.Transformer.LoadingRatio_Quality = 'D';

%% GRID

S.Grid = struct();

S.Grid.MV_Voltage_kV = NaN;
S.Grid.MV_Voltage_Quality = 'D';

S.Grid.ConnectionPoint = '';
S.Grid.ConnectionPoint_Quality = 'D';

S.Grid.ShortCircuitPower_MVA = NaN;
S.Grid.ShortCircuitPower_Quality = 'D';

%% ENERGY

S.Energy = struct();

S.Energy.AnnualGeneration_MWh = NaN;
S.Energy.AnnualGeneration_Quality = 'D';

S.Energy.SpecificYield_kWh_kWp = NaN;
S.Energy.CapacityFactor_DC = NaN;
S.Energy.CapacityFactor_AC = NaN;

%% SCADA

S.SCADA = struct();

S.SCADA.Platform = 'zenon v11';
S.SCADA.Platform_Quality = 'A';

S.SCADA.VariableCount = 4096;
S.SCADA.VariableCount_Quality = 'A';

S.SCADA.Protocols = {'Modbus'};

S.SCADA.Historian = true;
S.SCADA.InverterLevelMonitoring = true;
S.SCADA.SubstationMonitoring = true;
S.SCADA.GenerationLimitation = true;

S.SCADA.AdditionalSystems = {'Zabbix','Grafana'};

%% SOURCE

S.Source = struct();

S.Source.Primary = 'SV ALTERA project description';

S.Source.URL = 'https://www.svaltera.ua/solutions/projects/10950.php';

S.Source.Accessed = '2026-09-14';

UA_PV_PLANTS_DATASET.Stations(3) = S;


%% ========================================================================
%  GLOBAL BENCHMARK PARAMETERS
% =========================================================================

UA_PV_PLANTS_DATASET.Benchmark = struct();

UA_PV_PLANTS_DATASET.Benchmark.StationCount = numel(UA_PV_PLANTS_DATASET.Stations);

UA_PV_PLANTS_DATASET.Benchmark.StationIDs = { UA_PV_PLANTS_DATASET.Stations.ID};

%% ========================================================================
%  DESIGN VARIABLES RELEVANT TO THE DIGITAL TWIN
% =========================================================================

UA_PV_PLANTS_DATASET.DesignVariables = { ...
    'Topology', ...
    'P_DC_MWp', ...
    'P_AC_MW', ...
    'DC_AC_Ratio', ...
    'N_Modules', ...
    'Module_Power_W', ...
    'N_Inverters', ...
    'Inverter_Power_kW', ...
    'N_Substations', ...
    'Transformer_Power_MVA', ...
    'MV_Voltage_kV', ...
    'DC_Cable_Length', ...
    'AC_Cable_Length', ...
    'DC_Cable_Resistance', ...
    'AC_Cable_Resistance', ...
    'Transformer_Loading'};

%% ========================================================================
%  OBJECTIVE / PERFORMANCE VARIABLES
% =========================================================================

UA_PV_PLANTS_DATASET.PerformanceMetrics = { ...
    'AnnualGeneration_MWh', ...
    'SpecificYield_kWh_kWp', ...
    'CapacityFactor_DC', ...
    'CapacityFactor_AC', ...
    'DC_Losses_MWh', ...
    'AC_Losses_MWh', ...
    'Transformer_Losses_MWh', ...
    'Clipping_MWh', ...
    'Curtailment_MWh', ...
    'TotalElectricalLosses_MWh', ...
    'Efficiency_percent', ...
    'TransformerLoading_percent', ...
    'CapEx', ...
    'LifecycleCost', ...
    'LCOE', ...
    'Feasibility'};

%% ========================================================================
%  DATA AVAILABILITY MATRIX
% =========================================================================

UA_PV_PLANTS_DATASET.Availability = struct();

UA_PV_PLANTS_DATASET.Availability.Published = { ...
    'P_DC_MWp', ...
    'P_AC_MW', ...
    'N_Modules', ...
    'Module_Power_W', ...
    'N_Inverters', ...
    'Inverter_Model', ...
    'N_Substations', ...
    'Transformer_Power_MVA', ...
    'MV_Voltage_kV', ...
    'AnnualGeneration_MWh', ...
    'SCADA_Platform'};

UA_PV_PLANTS_DATASET.Availability.Calculated = { ...
    'DC_AC_Ratio', ...
    'SpecificYield_kWh_kWp', ...
    'CapacityFactor_DC', ...
    'CapacityFactor_AC', ...
    'TransformerLoading', ...
    'PowerDensity'};

UA_PV_PLANTS_DATASET.Availability.Inferred = { ...
    'Topology_Class', ...
    'ConnectionArchitecture'};

UA_PV_PLANTS_DATASET.Availability.Unavailable = { ...
    'DC_Cable_Length', ...
    'AC_Cable_Length', ...
    'Cable_CrossSection', ...
    'Cable_Resistance', ...
    'Transformer_NoLoad_Loss', ...
    'Transformer_Load_Loss', ...
    'Grid_ShortCircuitPower', ...
    'Irradiance_Profile', ...
    'Temperature_Profile', ...
    'CapEx', ...
    'Opex', ...
    'LCOE'};

%% ========================================================================
%  SAVE DATASET
% =========================================================================

save('UA_PV_PLANTS_DATASET.mat', 'UA_PV_PLANTS_DATASET');

disp('UA_PV_PLANTS_DATASET created successfully.');