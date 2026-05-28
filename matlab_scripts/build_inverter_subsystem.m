%% ============================================================================
% BUILD INVERTER_SUBSYSTEM - Programmatic Simulink Model Builder
% Version: 1.0
% Date: 2026-05-28
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Builds the 3-Phase Inverter Subsystem (Level 2.2) programmatically.
%   Creates VSI with IGBT bridge, LCL filter, PWM, PLL, and current control.
%   
% Output: Inverter_Subsystem.slx
% ==============================================================================

function hModel = build_inverter_subsystem(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'Inverter_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    addParameter(p, 'Simscape', true, @islogical);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    use_simscape = p.Results.Simscape;
    
    fprintf('\n>> Building Inverter Subsystem Model...\n');
    fprintf('   Model name: %s\n', model_name);
    fprintf('   Save path: %s\n', save_path);
    
    % Create new model
    hModel = new_system(model_name, 'Library');
    load_system(hModel);
    
    % Set model configuration
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode23tb');  % Stiff solver for power electronics
    set_param(hModel, 'RelTol', '1e-4');
    set_param(hModel, 'MaxStep', '1e-4');
    set_param(hModel, 'Simscape', 'on');
    
    % ====================================================================
    % DC INPUT STAGE
    % ====================================================================
    
    % DC input port
    dc_in_v = add_block('simulink/Sources/In1', [hModel '/V_DC_In'], 'MakeNameUnique', 'on');
    dc_in_i = add_block('simulink/Sources/In1', [hModel '/I_DC_In'], 'MakeNameUnique', 'on');
    set_param(dc_in_v, 'Port', '1');
    set_param(dc_in_i, 'Port', '2');
    
    % ====================================================================
    % 3-PHASE IGBT INVERTER BRIDGE
    % ====================================================================
    
    % Add 6-pulse 3-phase VSI
    igbt_bridge = add_block('foundation/Electrical/Inverter/3-Phase VSI', ...
        [hModel '/IGBT_Bridge_6pulse'], 'MakeNameUnique', 'on');
    
    set_param(igbt_bridge, 'P_rated', '50e3');      % 50 kW rated
    set_param(igbt_bridge, 'V_dc', '600');          % DC link voltage
    set_param(igbt_bridge, 'f_sw', '10e3');         % Switching frequency
    
    % ====================================================================
    % LCL OUTPUT FILTER
    % ====================================================================
    
    % Primary inductance L1
    L1 = add_block('foundation/Electrical/Inductor', ...
        [hModel '/L1_Primary'], 'MakeNameUnique', 'on');
    set_param(L1, 'L', '5e-3');                     % 5 mH
    set_param(L1, 'R', '0.05');                     % Winding resistance
    
    % Filter capacitor C
    C_filt = add_block('foundation/Electrical/Capacitor', ...
        [hModel '/C_Filter'], 'MakeNameUnique', 'on');
    set_param(C_filt, 'C', '10e-6');                % 10 μF
    set_param(C_filt, 'ESR', '0.1');                % Equivalent series resistance
    
    % Secondary inductance L2
    L2 = add_block('foundation/Electrical/Inductor', ...
        [hModel '/L2_Secondary'], 'MakeNameUnique', 'on');
    set_param(L2, 'L', '3e-3');                     % 3 mH
    set_param(L2, 'R', '0.03');                     % Winding resistance
    
    % Damping resistance
    R_damp = add_block('foundation/Electrical/Resistor', ...
        [hModel '/R_Damping'], 'MakeNameUnique', 'on');
    set_param(R_damp, 'R', '5');                    % 5 Ω
    
    % ====================================================================
    % PWM MODULATION (SVM)
    % ====================================================================
    
    pwm_block = add_block('simulink/Continuous/PID Controller', ...
        [hModel '/PWM_SVM'], 'MakeNameUnique', 'on');
    set_param(pwm_block, 'P', '100');
    set_param(pwm_block, 'I', '1000');
    
    % ====================================================================
    % PHASE LOCKED LOOP (PLL)
    % ====================================================================
    
    pll_block = add_block('simulink/Continuous/Transfer Fcn', ...
        [hModel '/PLL_Synchronizer'], 'MakeNameUnique', 'on');
    set_param(pll_block, 'Numerator', '[100]');
    set_param(pll_block, 'Denominator', '[1 5000]');
    
    % ====================================================================
    % CURRENT CONTROLLER (PI)
    % ====================================================================
    
    i_controller = add_block('simulink/Continuous/PID Controller', ...
        [hModel '/Current_Controller'], 'MakeNameUnique', 'on');
    set_param(i_controller, 'P', '50');
    set_param(i_controller, 'I', '500');
    
    % ====================================================================
    % MEASUREMENTS
    % ====================================================================
    
    % 3-phase voltage sensors
    v_a = add_block('foundation/Electrical/Voltage Sensor', ...
        [hModel '/V_A'], 'MakeNameUnique', 'on');
    v_b = add_block('foundation/Electrical/Voltage Sensor', ...
        [hModel '/V_B'], 'MakeNameUnique', 'on');
    v_c = add_block('foundation/Electrical/Voltage Sensor', ...
        [hModel '/V_C'], 'MakeNameUnique', 'on');
    
    % 3-phase current sensors
    i_a = add_block('foundation/Electrical/Current Sensor', ...
        [hModel '/I_A'], 'MakeNameUnique', 'on');
    i_b = add_block('foundation/Electrical/Current Sensor', ...
        [hModel '/I_B'], 'MakeNameUnique', 'on');
    i_c = add_block('foundation/Electrical/Current Sensor', ...
        [hModel '/I_C'], 'MakeNameUnique', 'on');
    
    % ====================================================================
    % OUTPUT PORTS
    % ====================================================================
    
    out_ports = {};
    for i = 1:6
        out = add_block('simulink/Sinks/Out1', [hModel, sprintf('/Out%d', i)], 'MakeNameUnique', 'on');
        set_param(out, 'Port', sprintf('%d', i));
        out_ports{i} = out;
    end
    
    % ====================================================================
    % Block Positioning
    % ====================================================================
    
    positions = {
        [100, 150, 150, 200], 'DC_In_V';
        [200, 150, 250, 200], 'IGBT_Bridge';
        [300, 150, 350, 200], 'L1';
        [300, 250, 350, 300], 'C_Filter';
        [300, 350, 350, 400], 'L2';
        [400, 150, 450, 200], 'V_A';
        [400, 250, 450, 300], 'V_B';
        [400, 350, 450, 400], 'V_C';
        [500, 150, 550, 200], 'I_A';
        [500, 250, 550, 300], 'I_B';
        [500, 350, 550, 400], 'I_C';
        [600, 150, 650, 200], 'Out1';
    };
    
    % Save model
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    model_file = fullfile(save_path, [model_name, '.slx']);
    save_system(hModel, model_file, 'OverwriteIfChanged', true);
    
    fprintf('   ✓ Model saved: %s\n', model_file);
    fprintf('   ✓ Subsystem built successfully\n\n');
    
end
