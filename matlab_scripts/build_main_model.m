%% ============================================================================
% BUILD_MAIN_MODEL - Create Main PV Station Digital Twin Model
% Version: 1.0
% Date: 2026-05-28
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Builds the complete PV_Station_Main model (Level 1) that integrates
%   all subsystems: PV Array, Inverter, Transformer, and Network.
%   
% Output: PV_Station_Main.slx
% ==============================================================================

function hModel = build_main_model(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'PV_Station_Main', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    addParameter(p, 'IncludeTransformer', true, @islogical);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    include_transformer = p.Results.IncludeTransformer;
    
    fprintf('\n>> Building Main PV Station Model...\n');
    fprintf('   Model name: %s\n', model_name);
    fprintf('   Save path: %s\n', save_path);
    
    % Create new model
    hModel = new_system(model_name);
    load_system(hModel);
    
    % Set model configuration for macOS Silicon
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode23tb');
    set_param(hModel, 'RelTol', '1e-4');
    set_param(hModel, 'AbsTol', '1e-6');
    set_param(hModel, 'MaxStep', '0.1');
    set_param(hModel, 'SimulationMode', 'accelerator');  % Accelerator mode
    set_param(hModel, 'FastRestart', 'on');
    
    % ====================================================================
    % LEVEL 1: MAIN SUBSYSTEMS
    % ====================================================================
    
    % PV Array Subsystem
    add_pv_subsystem(hModel);
    
    % Inverter Subsystem
    add_inverter_subsystem(hModel);
    
    % Transformer Subsystem (optional)
    if include_transformer
        add_transformer_subsystem(hModel);
    end
    
    % Network/Grid Subsystem
    add_network_subsystem(hModel);
    
    % ====================================================================
    % MEASUREMENT & MONITORING SYSTEM
    % ====================================================================
    
    add_measurement_system(hModel);
    
    % ====================================================================
    % DATA LOGGING
    % ====================================================================
    
    add_data_logging(hModel);
    
    % Save model
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    model_file = fullfile(save_path, [model_name, '.slx']);
    save_system(hModel, model_file, 'OverwriteIfChanged', true);
    
    fprintf('   ✓ Main model saved: %s\n', model_file);
    fprintf('   ✓ Model built successfully\n\n');
    
end

% ========================================================================
% HELPER FUNCTIONS
% ========================================================================

function add_pv_subsystem(hModel)
    % Add PV Array Subsystem reference
    try
        subsys = add_block('simulink/Ports & Subsystems/Subsystem Reference', ...
            [hModel '/PV_Array'], 'MakeNameUnique', 'on');
        set_param(subsys, 'ReferencedSubsystem', 'PV_Array_Subsystem');
        set_param(subsys, 'Position', [50, 50, 200, 150]);
    catch
        warning('Could not load PV_Array_Subsystem reference. Build it first.');
    end
end

function add_inverter_subsystem(hModel)
    % Add Inverter Subsystem reference
    try
        subsys = add_block('simulink/Ports & Subsystems/Subsystem Reference', ...
            [hModel '/Inverter'], 'MakeNameUnique', 'on');
        set_param(subsys, 'ReferencedSubsystem', 'Inverter_Subsystem');
        set_param(subsys, 'Position', [300, 50, 450, 150]);
    catch
        warning('Could not load Inverter_Subsystem reference. Build it first.');
    end
end

function add_transformer_subsystem(hModel)
    % Add Transformer Subsystem reference
    try
        subsys = add_block('simulink/Ports & Subsystems/Subsystem Reference', ...
            [hModel '/Transformer'], 'MakeNameUnique', 'on');
        set_param(subsys, 'ReferencedSubsystem', 'Transformer_Subsystem');
        set_param(subsys, 'Position', [550, 50, 700, 150]);
    catch
        warning('Could not load Transformer_Subsystem reference. Build it first.');
    end
end

function add_network_subsystem(hModel)
    % Add Network/Grid Subsystem reference
    try
        subsys = add_block('simulink/Ports & Subsystems/Subsystem Reference', ...
            [hModel '/Network'], 'MakeNameUnique', 'on');
        set_param(subsys, 'ReferencedSubsystem', 'Network_Subsystem');
        set_param(subsys, 'Position', [800, 50, 950, 150]);
    catch
        warning('Could not load Network_Subsystem reference. Build it first.');
    end
end

function add_measurement_system(hModel)
    % Add measurement and data logging subsystem
    meas_subsys = add_block('simulink/Ports & Subsystems/Subsystem', ...
        [hModel '/Measurement_System'], 'MakeNameUnique', 'on');
    set_param(meas_subsys, 'Position', [400, 300, 550, 400]);
end

function add_data_logging(hModel)
    % Add to workspace blocks for data logging
    to_ws1 = add_block('simulink/Sinks/To Workspace', ...
        [hModel '/Results_Logger'], 'MakeNameUnique', 'on');
    set_param(to_ws1, 'VariableName', 'sim_results');
    set_param(to_ws1, 'SaveFormat', 'Structure with time');
end
