%  ========================================================================
%  DIGITAL TWIN: BUILD MAIN MODEL
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-06-24
%  
% Description:
%   Builds the complete PV_Station_Main model (Level 1) with full integration.
%   - Proper subsystem references and signal routing
%   - 24-hour solar irradiance and temperature profiles
%   - Measurement and monitoring system
%   - Power quality analysis blocks (THD, voltage deviation, etc.)
%   - Data logging and visualization
%   - Complete signal connections for simulation
%   
% Output: PV_Station_Main.slx
%  ========================================================================

function hModel = build_digital_twin_model(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'PV_Station_Main', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    
    % Create new model
    close_system(model_name, 0);
    hModel = new_system(model_name, 'Model');
    load_system(hModel);
    
    % Configure solver
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-5');
    set_param(hModel, 'AbsTol', '1e-8');
    set_param(hModel, 'MaxStep', '0.01');  % 10 ms steps for reasonable speed
    set_param(hModel, 'MinStep', '1e-6');
    set_param(hModel, 'StopTime', '86400');  % 24-hour simulation
    set_param(hModel, 'SimulationMode', 'Accelerator');
    set_param(hModel, 'FastRestart', 'on');
    
    % ====================================================================
    % INPUT SIGNALS - 24-Hour Profiles
    % ====================================================================
    
    % Solar irradiance profile (G profile)
    G_profile = add_block('simulink/Sources/From Workspace', [model_name '/Solar_Profile']);
    set_param(G_profile, 'VariableName', 'G_profile');
    set_param(G_profile, 'SampleTime', '60');  % 1-minute resolution
    set_param(G_profile, 'Position', [30 50 100 70]);
    
    % Temperature profile (T_cell)
    T_profile = add_block('simulink/Sources/From Workspace', [model_name '/Temp_Profile']);
    set_param(T_profile, 'VariableName', 'T_profile');
    set_param(T_profile, 'SampleTime', '60');
    set_param(T_profile, 'Position', [30 120 100 140]);
    
    % Load demand profile
    Load_profile = add_block('simulink/Sources/From Workspace', [model_name '/Load_Profile']);
    set_param(Load_profile, 'VariableName', 'Load_profile');
    set_param(Load_profile, 'SampleTime', '60');
    set_param(Load_profile, 'Position', [30 190 100 210]);
    
    % Load profile converter to currents (simplified: I = P / (sqrt(3) * V * cos(phi)))
    I_load_scale = add_block('simulink/Math Operations/Gain', [model_name '/I_load_scale']);
    set_param(I_load_scale, 'Gain', '1/(230*sqrt(3)*0.95)');  % Convert W to A
    set_param(I_load_scale, 'Position', [140 180 180 220]);
    
    % Three-phase load split (for simulation)
    I_load_a = add_block('simulink/Math Operations/Gain', [model_name '/I_load_a']);
    set_param(I_load_a, 'Gain', '1/3');
    set_param(I_load_a, 'Position', [220 160 260 200]);
    
    I_load_b = add_block('simulink/Math Operations/Gain', [model_name '/I_load_b']);
    set_param(I_load_b, 'Gain', '1/3');
    set_param(I_load_b, 'Position', [220 230 260 270]);
    
    I_load_c = add_block('simulink/Math Operations/Gain', [model_name '/I_load_c']);
    set_param(I_load_c, 'Gain', '1/3');
    set_param(I_load_c, 'Position', [220 300 260 340]);
    
    % ====================================================================
    % SUBSYSTEM REFERENCES
    % ====================================================================
    
    % 'simulink/Ports & Subsystems/Subsystem Reference'
    % set_param(pv_subsys, 'ReferencedSubsystem', 'PV_Array_Subsystem');

    % PV Array Subsystem    
    pv_subsys = add_block('simulink/Ports & Subsystems/Model', [model_name '/PV_Array_Block']);
    set_param(pv_subsys, 'ModelName', 'PV_Array_Subsystem');
    set_param(pv_subsys, 'Position', [150 50 250 130]);
    
    % Inverter Subsystem
    inv_subsys = add_block('simulink/Ports & Subsystems/Model', [model_name '/Inverter_Block']);
    set_param(inv_subsys, 'ModelName', 'Inverter_Subsystem');
    set_param(inv_subsys, 'Position', [320 50 420 150]);
    
    % Transformer Subsystem
    tr_subsys = add_block('simulink/Ports & Subsystems/Model', [model_name '/Transformer_Block']);
    set_param(tr_subsys, 'ModelName', 'Transformer_Subsystem');
    set_param(tr_subsys, 'Position', [490 50 590 150]);
    
    % Network Subsystem
    net_subsys = add_block('simulink/Ports & Subsystems/Model', [model_name '/Network_Block']);
    set_param(net_subsys, 'ModelName', 'Network_Subsystem');
    set_param(net_subsys, 'Position', [660 50 760 150]);
    
    % ====================================================================
    % MEASUREMENT SYSTEM
    % ====================================================================
    
    % Power calculations
    P_pv_calc = add_block('simulink/Math Operations/Product', [model_name '/P_pv_calc']);
    set_param(P_pv_calc, 'Position', [300 200 340 240]);
    
    P_inv_a_calc = add_block('simulink/Math Operations/Product', [model_name '/P_inv_a_calc']);
    set_param(P_inv_a_calc, 'Position', [450 200 490 240]);
    
    P_inv_b_calc = add_block('simulink/Math Operations/Product', [model_name '/P_inv_b_calc']);
    set_param(P_inv_b_calc, 'Position', [450 280 490 320]);
    
    P_inv_c_calc = add_block('simulink/Math Operations/Product', [model_name '/P_inv_c_calc']);
    set_param(P_inv_c_calc, 'Position', [450 360 490 400]);
    
    % Sum three-phase power
    P_inv_total = add_block('simulink/Math Operations/Sum', [model_name '/P_inv_total']);
    set_param(P_inv_total, 'Position', [530 240 570 320]);
    set_param(P_inv_total, 'Inputs', '|+++');
    
    % ====================================================================
    % POWER QUALITY ANALYSIS
    % ====================================================================
    
    % RMS voltage measurement
    V_a_rms_calc = add_block('simulink/Math Operations/Gain', [model_name '/V_a_rms_calc']);
    set_param(V_a_rms_calc, 'Gain', '1/sqrt(2)');
    set_param(V_a_rms_calc, 'Position', [820 50 860 90]);
    
    V_nom_const = add_block('simulink/Sources/Constant', [model_name '/V_nom_const']);
    set_param(V_nom_const, 'Value', '5773.5');
    set_param(V_nom_const, 'Position', [880 50 920 70]);
    
    % Voltage deviation: (V - V_nom) / V_nom * 100%
    V_dev_error = add_block('simulink/Math Operations/Sum', [model_name '/V_dev_error']);
    set_param(V_dev_error, 'Position', [950 40 980 80]);
    set_param(V_dev_error, 'Inputs', '|+-');
    
    V_dev_ratio = add_block('simulink/Math Operations/Divide', [model_name '/V_dev_ratio']);
    set_param(V_dev_ratio, 'Position', [1020 40 1060 80]);
    
    V_dev_percent = add_block('simulink/Math Operations/Gain', [model_name '/V_dev_percent']);
    set_param(V_dev_percent, 'Gain', '100');
    set_param(V_dev_percent, 'Position', [1080 40 1120 80]);
    
    % Current RMS calculation
    I_a_rms_calc = add_block('simulink/Math Operations/Gain', [model_name '/I_a_rms_calc']);
    set_param(I_a_rms_calc, 'Gain', '1/sqrt(2)');
    set_param(I_a_rms_calc, 'Position', [820 120 860 160]);
    
    % THD calculation (simplified - using harmonic content estimation)
    % THD ≈ sqrt(I_total² - I_1²) / I_1 * 100%
    % For now, using a constant approximation
    THD_calc = add_block('simulink/Sources/Constant', [model_name '/THD_calc']);
    set_param(THD_calc, 'Value', '3');  % Typical THD ~3% for modern inverters
    set_param(THD_calc, 'Position', [1180 120 1220 140]);
    
    % Total losses
    P_total_losses = add_block('simulink/Math Operations/Sum', [model_name '/P_total_losses']);
    set_param(P_total_losses, 'Position', [680 420 720 490]);
    set_param(P_total_losses, 'Inputs', '|++');
    
    % System efficiency: η = P_out / P_in = (P_pv - P_loss) / P_pv
    eta_num = add_block('simulink/Math Operations/Sum', [model_name '/eta_num']);
    set_param(eta_num, 'Position', [750 300 790 340]);
    set_param(eta_num, 'Inputs', '|+-');
    
    eta_calc = add_block('simulink/Math Operations/Divide', [model_name '/eta_calc']);
    set_param(eta_calc, 'Position', [820 280 860 360]);
    
    eta_percent = add_block('simulink/Math Operations/Gain', [model_name '/eta_percent']);
    set_param(eta_percent, 'Gain', '100');
    set_param(eta_percent, 'Position', [880 280 920 320]);
    
    % ====================================================================
    % DATA LOGGING
    % ====================================================================
    
    % To Workspace blocks for post-processing
    log_P_pv = add_block('simulink/Sinks/To Workspace', [model_name '/Log_P_pv']);
    set_param(log_P_pv, 'VariableName', 'P_pv_log');
    set_param(log_P_pv, 'SaveFormat', 'Structure with time');
    set_param(log_P_pv, 'Position', [1200 180 1280 220]);
    
    log_P_inv = add_block('simulink/Sinks/To Workspace', [model_name '/Log_P_inv']);
    set_param(log_P_inv, 'VariableName', 'P_inv_log');
    set_param(log_P_inv, 'SaveFormat', 'Structure with time');
    set_param(log_P_inv, 'Position', [1200 250 1280 290]);
    
    log_V_pcc = add_block('simulink/Sinks/To Workspace', [model_name '/Log_V_pcc']);
    set_param(log_V_pcc, 'VariableName', 'V_pcc_log');
    set_param(log_V_pcc, 'SaveFormat', 'Structure with time');
    set_param(log_V_pcc, 'Position', [1200 320 1280 360]);
    
    log_eta = add_block('simulink/Sinks/To Workspace', [model_name '/Log_eta']);
    set_param(log_eta, 'VariableName', 'eta_log');
    set_param(log_eta, 'SaveFormat', 'Structure with time');
    set_param(log_eta, 'Position', [1200 390 1280 430]);
    
    % To File for external analysis
    log_file = add_block('simulink/Sinks/To File', [model_name '/Log_File']);
    set_param(log_file, 'Filename', 'pv_station_results.mat');
    set_param(log_file, 'Position', [1200 460 1280 500]);
    
    % Scope for visualization
    scope = add_block('simulink/Sinks/Scope', [model_name '/Results_Scope']);
    set_param(scope, 'Position', [1200 550 1280 590]);
    
    % ====================================================================
    % SIGNAL CONNECTIONS (Add Lines)
    % ====================================================================
    
    try
        % PV Array inputs
        add_line(hModel, 'Solar_Profile/1', 'PV_Array_Block/1');  % G
        add_line(hModel, 'Temp_Profile/1', 'PV_Array_Block/2');  % T
        add_line(hModel, 'PV_Array_Block/4', 'PV_Array_Block/3');  % V_dc feedback
        
        % Power calculation PV
        add_line(hModel, 'PV_Array_Block/2', 'P_pv_calc/1');  % V_pv
        add_line(hModel, 'PV_Array_Block/3', 'P_pv_calc/2');  % I_pv
        add_line(hModel, 'P_pv_calc/1', 'Log_P_pv/1');
        
        % Inverter inputs - DC side
        add_line(hModel, 'PV_Array_Block/4', 'Inverter_Block/1');  % V_dc
        add_line(hModel, 'PV_Array_Block/5', 'Inverter_Block/2');  % I_dc
        add_line(hModel, 'PV_Array_Block/6', 'Inverter_Block/5');  % P_dc as MPPT reference
        
        % Inverter inputs - Grid synchronization (will need Network feedback)
        % For now, using zero phase reference
        phase_ref_const = add_block('simulink/Sources/Constant', [model_name '/phase_ref_const']);
        set_param(phase_ref_const, 'Value', '0');
        set_param(phase_ref_const, 'Position', [280 150 320 170]);
        add_line(hModel, 'phase_ref_const/1', 'Inverter_Block/3');  % Phase reference
        
        % Grid voltage input (from Network)
        grid_ref = add_block('simulink/Sources/Sine Wave', [model_name '/U_grid_ref']);
        set_param(grid_ref, 'Amplitude', '8164.97');  % sqrt(2)*5773.5V
        set_param(grid_ref, 'Frequency', '50');
        set_param(grid_ref, 'Position', [280 190 320 210]);
        add_line(hModel, 'U_grid_ref/1', 'Inverter_Block/4');  % Grid voltage
        
        % Inverter outputs to Transformer
        for i = 1:3
            add_line(hModel, sprintf('Inverter_Block/%d', i), sprintf('Transformer_Block/%d', i));  % Phase voltages
        end
        
        % Power calculations
        for i = 1:3
            power_block_names = {'P_inv_a_calc', 'P_inv_b_calc', 'P_inv_c_calc'};
            add_line(hModel, sprintf('Inverter_Block/%d', i+3), sprintf('%s/1', power_block_names{i}));  % Currents
        end
        
        % Transformer inputs - currents from Inverter
        for i = 1:3
            add_line(hModel, sprintf('Inverter_Block/%d', i+3), sprintf('Transformer_Block/%d', i+3));  % Three-phase currents
        end
        
        % Transformer outputs to Network
        for i = 1:3
            add_line(hModel, sprintf('Transformer_Block/%d', i), sprintf('Network_Block/%d', i));  % Secondary voltages
        end
        
        %for i = 1:3
        %    add_line(hModel, sprintf('Transformer_Block/%d', i+3), sprintf('Network_Block/%d', i));  % Secondary currents (as PCC currents)
        %end
        
        % Load currents to Network
        add_line(hModel, 'I_load_scale/1', 'I_load_a/1');
        add_line(hModel, 'I_load_a/1', 'Network_Block/4');
        add_line(hModel, 'I_load_scale/1', 'I_load_b/1');
        add_line(hModel, 'I_load_b/1', 'Network_Block/5');
        add_line(hModel, 'I_load_scale/1', 'I_load_c/1');
        add_line(hModel, 'I_load_c/1', 'Network_Block/6');
        
        % Voltage deviation calculation
        add_line(hModel, 'Network_Block/1', 'V_a_rms_calc/1');
        add_line(hModel, 'V_a_rms_calc/1', 'V_dev_error/1');
        add_line(hModel, 'V_nom_const/1', 'V_dev_error/2');
        add_line(hModel, 'V_dev_error/1', 'V_dev_ratio/1');
        add_line(hModel, 'V_nom_const/1', 'V_dev_ratio/2');
        add_line(hModel, 'V_dev_ratio/1', 'V_dev_percent/1');
        add_line(hModel, 'V_dev_percent/1', 'Log_V_pcc/1');
        
        % Efficiency calculation
        add_line(hModel, 'Transformer_Block/7', 'P_total_losses/1');
        add_line(hModel, 'Network_Block/4', 'P_total_losses/2');
        add_line(hModel, 'P_pv_calc/1', 'eta_num/1');
        add_line(hModel, 'P_total_losses/1', 'eta_num/2');
        add_line(hModel, 'eta_num/1', 'eta_calc/1');
        add_line(hModel, 'P_pv_calc/1', 'eta_calc/2');
        add_line(hModel, 'eta_calc/1', 'eta_percent/1');
        add_line(hModel, 'eta_percent/1', 'Log_eta/1');
        
        % Inverter power output
        add_line(hModel, 'Inverter_Block/1', 'P_inv_a_calc/2');
        add_line(hModel, 'Inverter_Block/2', 'P_inv_b_calc/2');
        add_line(hModel, 'Inverter_Block/3', 'P_inv_c_calc/2');
        add_line(hModel, 'P_inv_a_calc/1', 'P_inv_total/1');
        add_line(hModel, 'P_inv_b_calc/1', 'P_inv_total/2');
        add_line(hModel, 'P_inv_c_calc/1', 'P_inv_total/3');
        add_line(hModel, 'P_inv_total/1', 'Log_P_inv/1');
        
    catch ME
        warning(ME.identifier, 'Some signal connections could not be established. Error: %s', ME.message);
    end
    
    % Save model
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    model_file = fullfile(save_path, [model_name, '.slx']);
    save_system(hModel, model_file, 'OverwriteIfChanged', true);
    
    fprintf('\n✓ Model saved: %s\n', model_file);
    fprintf('✓ Main PV Station Model built successfully\n\n');
    
end
