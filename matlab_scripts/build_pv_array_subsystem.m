%% ============================================================================
% BUILD PV_ARRAY_SUBSYSTEM - Programmatic Simulink Model Builder
% Version: 1.0
% Date: 2026-05-28
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Builds the PV Array Subsystem (Level 2.1) programmatically.
%   Creates a Single Diode Model of PV array with MPPT controller.
%   
% Output: PV_Array_Subsystem.slx
% ==============================================================================

function hModel = build_pv_array_subsystem(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'PV_Array_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    addParameter(p, 'Simscape', true, @islogical);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    use_simscape = p.Results.Simscape;
    
    fprintf('\n>> Building PV Array Subsystem Model...\n');
    fprintf('   Model name: %s\n', model_name);
    fprintf('   Save path: %s\n', save_path);
    
    % Create new model
    hModel = new_system(model_name, 'Library');
    load_system(hModel);
    
    % Set model configuration for Simscape
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-4');
    set_param(hModel, 'MaxStep', '0.1');
    set_param(hModel, 'Simscape', 'on');
    
    % ====================================================================
    % LEVEL 3: Simscape Electrical Components
    % ====================================================================
    
    if use_simscape
        % Add Simscape electrical reference
        add_line(hModel, 'PS_Simulink_Lib/Solver Configuration/1', [model_name '/Solver Configuration/LConn1'], 'autorouting', 'on');
    end
    
    % PV Module: Single Diode Model
    % Using Foundation Library: PV Source
    pv_block = add_block('foundation/Electrical/PV Source', ...
        [hModel '/PV_Module'], ...
        'MakeNameUnique', 'on');
    
    % Set PV module parameters from init file
    set_param(pv_block, 'I_ph0', '8.5');          % Photocurrent
    set_param(pv_block, 'I_0', '1e-9');           % Saturation current
    set_param(pv_block, 'n_id', '1.2');           % Ideality factor
    set_param(pv_block, 'R_s', '0.2');            % Series resistance
    set_param(pv_block, 'R_sh', '415');           % Shunt resistance
    
    % Temperature sensor
    temp_sensor = add_block('foundation/Electrical/Temperature Sensor', ...
        [hModel '/T_Cell_Sensor'], 'MakeNameUnique', 'on');
    
    % Irradiance input
    irr_block = add_block('simulink/Sources/In1', ...
        [hModel '/G_Solar_Input'], 'MakeNameUnique', 'on');
    set_param(irr_block, 'Port', '1');
    
    % DC-DC Boost Converter
    boost_block = add_block('foundation/Electrical/Converter/DC-DC Converter', ...
        [hModel '/Boost_Converter'], 'MakeNameUnique', 'on');
    set_param(boost_block, 'P_rated', '17500');   % 350W * 50 modules
    set_param(boost_block, 'L_in', '5e-3');       % Input inductance
    set_param(boost_block, 'C_out', '200e-6');    % Output capacitance
    
    % MPPT Controller (Perturb & Observe)
    mppt_block = add_block('simulink/Continuous/PID Controller', ...
        [hModel '/MPPT_Controller'], 'MakeNameUnique', 'on');
    set_param(mppt_block, 'P', '50');
    set_param(mppt_block, 'I', '500');
    
    % Output measurements
    v_out = add_block('foundation/Electrical/Voltage Sensor', ...
        [hModel '/V_DC_Sensor'], 'MakeNameUnique', 'on');
    i_out = add_block('foundation/Electrical/Current Sensor', ...
        [hModel '/I_DC_Sensor'], 'MakeNameUnique', 'on');
    p_out = add_block('simulink/Math Operations/Product', ...
        [hModel '/P_DC_Calculator'], 'MakeNameUnique', 'on');
    
    % Output ports
    out_v = add_block('simulink/Sinks/Out1', [hModel '/V_DC_Out'], 'MakeNameUnique', 'on');
    out_i = add_block('simulink/Sinks/Out1', [hModel '/I_DC_Out'], 'MakeNameUnique', 'on');
    out_p = add_block('simulink/Sinks/Out1', [hModel '/P_DC_Out'], 'MakeNameUnique', 'on');
    
    set_param(out_v, 'Port', '1');
    set_param(out_i, 'Port', '2');
    set_param(out_p, 'Port', '3');
    
    % ====================================================================
    % Arrange blocks for better visualization
    % ====================================================================
    
    block_positions = struct();
    block_positions.pv_module = [100, 100, 150, 150];
    block_positions.boost = [300, 100, 350, 150];
    block_positions.mppt = [200, 250, 250, 300];
    block_positions.v_sensor = [400, 100, 450, 150];
    block_positions.i_sensor = [500, 100, 550, 150];
    block_positions.v_out = [600, 100, 650, 150];
    block_positions.i_out = [600, 200, 650, 250];
    block_positions.p_out = [600, 300, 650, 350];
    
    % Apply positions
    set_param([hModel '/PV_Module'], 'Position', block_positions.pv_module);
    set_param([hModel '/Boost_Converter'], 'Position', block_positions.boost);
    set_param([hModel '/MPPT_Controller'], 'Position', block_positions.mppt);
    set_param([hModel '/V_DC_Sensor'], 'Position', block_positions.v_sensor);
    set_param([hModel '/I_DC_Sensor'], 'Position', block_positions.i_sensor);
    set_param([hModel '/V_DC_Out'], 'Position', block_positions.v_out);
    set_param([hModel '/I_DC_Out'], 'Position', block_positions.i_out);
    set_param([hModel '/P_DC_Out'], 'Position', block_positions.p_out);
    
    % Save model
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    model_file = fullfile(save_path, [model_name, '.slx']);
    save_system(hModel, model_file, 'OverwriteIfChanged', true);
    
    fprintf('   ✓ Model saved: %s\n', model_file);
    fprintf('   ✓ Subsystem built successfully\n\n');
    
end
