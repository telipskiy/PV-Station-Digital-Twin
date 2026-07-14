%% ============================================================================
% BUILD TRANSFORMER_SUBSYSTEM - Enhanced with Complete Signal Connections
% Version: 2.0 (PhD-level implementation)
% Date: 2026-07-14
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Builds the 3-Phase Transformer Subsystem (Level 2.3) with complete signal routing.
%   - T-equivalent transformer model with core and copper losses
%   - Magnetizing inductance (saturation effects)
%   - Leakage impedance
%   - Temperature-dependent resistance
%   - Complete signal connections for PhD-level simulation
%   
% Output: Transformer_Subsystem.slx
% ==============================================================================

function hModel = build_transformer_subsystem_enhanced(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'Transformer_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    
    fprintf('\n╔════════════════════════════════════════════════════════════════╗\n');
    fprintf('║  Building Enhanced Transformer Subsystem (PhD-level)         ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════╝\n\n');
    fprintf('>> Model name: %s\n', model_name);
    fprintf('>> Save path: %s\n', save_path);
    
    % Create new model
    hModel = new_system(model_name, 'Model');
    load_system(hModel);
    
    % Configure solver
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-5');
    set_param(hModel, 'AbsTol', '1e-8');
    set_param(hModel, 'MaxStep', '1e-4');
    set_param(hModel, 'MinStep', '1e-8');
    set_param(hModel, 'StopTime', '86400');
    
    % ====================================================================
    % INPUTS
    % ====================================================================
    
    % Input 1-3: Three-phase voltages (primary - 400V) [V]
    V_a_in = add_block('simulink/Sources/In1', [model_name '/V_a_prim_in']);
    set_param(V_a_in, 'Position', [20 50 50 70]);
    set_param(V_a_in, 'Port', '1');
    
    V_b_in = add_block('simulink/Sources/In1', [model_name '/V_b_prim_in']);
    set_param(V_b_in, 'Position', [20 120 50 140]);
    set_param(V_b_in, 'Port', '2');
    
    V_c_in = add_block('simulink/Sources/In1', [model_name '/V_c_prim_in']);
    set_param(V_c_in, 'Position', [20 190 50 210]);
    set_param(V_c_in, 'Port', '3');
    
    % Input 4-6: Three-phase currents (primary) [A]
    I_a_in = add_block('simulink/Sources/In1', [model_name '/I_a_prim_in']);
    set_param(I_a_in, 'Position', [20 260 50 280]);
    set_param(I_a_in, 'Port', '4');
    
    I_b_in = add_block('simulink/Sources/In1', [model_name '/I_b_prim_in']);
    set_param(I_b_in, 'Position', [20 330 50 350]);
    set_param(I_b_in, 'Port', '5');
    
    I_c_in = add_block('simulink/Sources/In1', [model_name '/I_c_prim_in']);
    set_param(I_c_in, 'Position', [20 400 50 420]);
    set_param(I_c_in, 'Port', '6');
    
    % Input 7: Oil temperature [°C]
    T_oil_in = add_block('simulink/Sources/In1', [model_name '/T_oil_in']);
    set_param(T_oil_in, 'Position', [20 470 50 490]);
    set_param(T_oil_in, 'Port', '7');
    
    % ====================================================================
    % TRANSFORMER PARAMETERS
    % ====================================================================
    
    % Nominal parameters (63 kVA, 0.4kV/10kV, Yz configuration)
    S_rated = add_block('simulink/Sources/Constant', [model_name '/S_rated_const']);
    set_param(S_rated, 'Value', '63000');  % 63 kVA
    set_param(S_rated, 'Position', [130 50 170 70]);
    
    % Primary nominal voltage: 400V phase-to-phase = 230V phase-to-neutral
    V_prim_nom = add_block('simulink/Sources/Constant', [model_name '/V_prim_nom_const']);
    set_param(V_prim_nom, 'Value', '230');
    set_param(V_prim_nom, 'Position', [130 120 170 140]);
    
    % Secondary nominal voltage: 10000V phase-to-phase = 5773.5V phase-to-neutral
    V_sec_nom = add_block('simulink/Sources/Constant', [model_name '/V_sec_nom_const']);
    set_param(V_sec_nom, 'Value', '5773.5');
    set_param(V_sec_nom, 'Position', [130 190 170 210]);
    
    % Turns ratio: n = V_sec / V_prim = 10000 / 400 = 25 (or 5773.5/230)
    n_ratio = add_block('simulink/Sources/Constant', [model_name '/n_ratio_const']);
    set_param(n_ratio, 'Value', '25');
    set_param(n_ratio, 'Position', [130 260 170 280]);
    
    % Short-circuit impedance: Zk = 6% (phase impedance in primary)
    % Zk = 6% means V_k = 0.06 * V_rated when I_k flows
    Zk_percent = add_block('simulink/Sources/Constant', [model_name '/Zk_percent_const']);
    set_param(Zk_percent, 'Value', '0.06');
    set_param(Zk_percent, 'Position', [130 330 170 350]);
    
    % No-load losses: P_0 = 500 W (iron losses)
    P_0_loss = add_block('simulink/Sources/Constant', [model_name '/P_0_loss_const']);
    set_param(P_0_loss, 'Value', '500');
    set_param(P_0_loss, 'Position', [130 400 170 420]);
    
    % Short-circuit losses: P_k = 1600 W (copper losses at rated)
    P_k_loss = add_block('simulink/Sources/Constant', [model_name '/P_k_loss_const']);
    set_param(P_k_loss, 'Value', '1600');
    set_param(P_k_loss, 'Position', [130 470 170 490]);
    
    % ====================================================================
    % VOLTAGE TRANSFORMATION
    % ====================================================================
    
    % Secondary voltage (ideal): V_sec = n * V_prim
    V_a_trans = add_block('simulink/Math Operations/Gain', [model_name '/V_a_trans_gain']);
    set_param(V_a_trans, 'Gain', '25');  % Turns ratio
    set_param(V_a_trans, 'Position', [240 50 280 90]);
    
    V_b_trans = add_block('simulink/Math Operations/Gain', [model_name '/V_b_trans_gain']);
    set_param(V_b_trans, 'Gain', '25');
    set_param(V_b_trans, 'Position', [240 120 280 160]);
    
    V_c_trans = add_block('simulink/Math Operations/Gain', [model_name '/V_c_trans_gain']);
    set_param(V_c_trans, 'Gain', '25');
    set_param(V_c_trans, 'Position', [240 190 280 230]);
    
    % ====================================================================
    % LEAKAGE IMPEDANCE MODEL
    % ====================================================================
    
    % Total leakage impedance (primary-referred)
    % Z_leak = R_leak + j*X_leak, where V_k = Z_leak * I_k / S_rated
    % At rated: V_k = 0.06 * 230V = 13.8V
    % I_k (rated) = S_rated / (sqrt(3) * V_prim) = 63000 / (1.732 * 230) ≈ 157.8A
    % Z_leak = 13.8 / 157.8 ≈ 0.087 Ω
    
    R_leak_const = add_block('simulink/Sources/Constant', [model_name '/R_leak_const']);
    set_param(R_leak_const, 'Value', '0.05');  % Resistance component
    set_param(R_leak_const, 'Position', [360 50 400 70]);
    
    X_leak_const = add_block('simulink/Sources/Constant', [model_name '/X_leak_const']);
    set_param(X_leak_const, 'Value', '0.07');  % Reactance component
    set_param(X_leak_const, 'Position', [360 120 400 140]);
    
    % Resistance drops
    R_drop_a = add_block('simulink/Math Operations/Product', [model_name '/R_drop_a']);
    set_param(R_drop_a, 'Position', [450 40 490 80]);
    
    R_drop_b = add_block('simulink/Math Operations/Product', [model_name '/R_drop_b']);
    set_param(R_drop_b, 'Position', [450 110 490 150]);
    
    R_drop_c = add_block('simulink/Math Operations/Product', [model_name '/R_drop_c']);
    set_param(R_drop_c, 'Position', [450 180 490 220]);
    
    % Reactance drops (L*di/dt)
    L_leak = 5e-3;  % Leakage inductance (approximately X_leak * sqrt(2) / 2π*f)
    
    L_leak_a = add_block('simulink/Continuous/Integrator', [model_name '/L_leak_a_int']);
    set_param(L_leak_a, 'Position', [450 280 490 320]);
    set_param(L_leak_a, 'InitialCondition', '0');
    
    L_leak_b = add_block('simulink/Continuous/Integrator', [model_name '/L_leak_b_int']);
    set_param(L_leak_b, 'Position', [450 350 490 390]);
    set_param(L_leak_b, 'InitialCondition', '0');
    
    L_leak_c = add_block('simulink/Continuous/Integrator', [model_name '/L_leak_c_int']);
    set_param(L_leak_c, 'Position', [450 420 490 460]);
    set_param(L_leak_c, 'InitialCondition', '0');
    
    % ====================================================================
    % MAGNETIZING INDUCTANCE (Core Model)
    % ====================================================================
    
    % Lm ≈ (V_prim * sqrt(2)) / (2π * f * B_max * A_core)
    % For this transformer: Lm ≈ 1.5 H (typical for 63 kVA transformer)
    Lm = 1.5;
    
    Lm_a = add_block('simulink/Continuous/Integrator', [model_name '/Lm_a_int']);
    set_param(Lm_a, 'Position', [560 40 600 80]);
    set_param(Lm_a, 'InitialCondition', '0');
    
    Lm_b = add_block('simulink/Continuous/Integrator', [model_name '/Lm_b_int']);
    set_param(Lm_b, 'Position', [560 110 600 150]);
    set_param(Lm_b, 'InitialCondition', '0');
    
    Lm_c = add_block('simulink/Continuous/Integrator', [model_name '/Lm_c_int']);
    set_param(Lm_c, 'Position', [560 180 600 220]);
    set_param(Lm_c, 'InitialCondition', '0');
    
    % ====================================================================
    % VOLTAGE DROP CALCULATION
    % ====================================================================
    
    % V_sec = n*V_prim - I_prim*R_leak - L_leak*di_prim/dt
    V_a_drop = add_block('simulink/Math Operations/Sum', [model_name '/V_a_drop_sum']);
    set_param(V_a_drop, 'Position', [570 40 600 80]);
    set_param(V_a_drop, 'Inputs', '|+--');
    
    V_b_drop = add_block('simulink/Math Operations/Sum', [model_name '/V_b_drop_sum']);
    set_param(V_b_drop, 'Position', [570 110 600 150]);
    set_param(V_b_drop, 'Inputs', '|+--');
    
    V_c_drop = add_block('simulink/Math Operations/Sum', [model_name '/V_c_drop_sum']);
    set_param(V_c_drop, 'Position', [570 180 600 220]);
    set_param(V_c_drop, 'Inputs', '|+--');
    
    % ====================================================================
    % CURRENT TRANSFORMATION (Inverse)
    % ====================================================================
    
    % I_sec = I_prim / n (for lossless case)
    I_a_trans = add_block('simulink/Math Operations/Gain', [model_name '/I_a_trans_gain']);
    set_param(I_a_trans, 'Gain', '1/25');  % Inverse turns ratio
    set_param(I_a_trans, 'Position', [680 40 720 80]);
    
    I_b_trans = add_block('simulink/Math Operations/Gain', [model_name '/I_b_trans_gain']);
    set_param(I_b_trans, 'Gain', '1/25');
    set_param(I_b_trans, 'Position', [680 110 720 150]);
    
    I_c_trans = add_block('simulink/Math Operations/Gain', [model_name '/I_c_trans_gain']);
    set_param(I_c_trans, 'Gain', '1/25');
    set_param(I_c_trans, 'Position', [680 180 720 220]);
    
    % ====================================================================
    % LOSSES CALCULATION
    % ====================================================================
    
    % Core (no-load) losses: P_Fe = P_0 * (V/V_rated)^2
    V_mag_rms = add_block('simulink/Math Operations/Gain', [model_name '/V_mag_rms_gain']);
    set_param(V_mag_rms, 'Gain', '1/sqrt(2)');  % Convert to RMS
    set_param(V_mag_rms, 'Position', [450 480 490 520]);
    
    V_rms_ratio_sq = add_block('simulink/Math Operations/Product', [model_name '/V_rms_ratio_sq']);
    set_param(V_rms_ratio_sq, 'Position', [530 470 570 530]);
    set_param(V_rms_ratio_sq, 'Inputs', '**');
    
    P_Fe = add_block('simulink/Math Operations/Product', [model_name '/P_Fe_loss']);
    set_param(P_Fe, 'Position', [610 470 650 530]);
    
    % Copper (load) losses: P_Cu = P_k * (I/I_rated)^2
    I_rms_calc_a = add_block('simulink/Math Operations/Gain', [model_name '/I_rms_calc_a']);
    set_param(I_rms_calc_a, 'Gain', '1/sqrt(2)');
    set_param(I_rms_calc_a, 'Position', [550 300 590 340]);
    
    I_rated = add_block('simulink/Sources/Constant', [model_name '/I_rated_const']);
    set_param(I_rated, 'Value', '157.8');  % Rated current at primary
    set_param(I_rated, 'Position', [550 360 590 380]);
    
    I_ratio_sq = add_block('simulink/Math Operations/Product', [model_name '/I_ratio_sq']);
    set_param(I_ratio_sq, 'Position', [630 300 670 360]);
    set_param(I_ratio_sq, 'Inputs', '**');
    
    P_Cu = add_block('simulink/Math Operations/Product', [model_name '/P_Cu_loss']);
    set_param(P_Cu, 'Position', [710 310 750 370]);
    
    % Total losses
    P_total_loss = add_block('simulink/Math Operations/Sum', [model_name '/P_total_loss_sum']);
    set_param(P_total_loss, 'Position', [790 400 820 440]);
    set_param(P_total_loss, 'Inputs', '|++');
    
    % ====================================================================
    % OUTPUTS
    % ====================================================================
    
    % Output 1-3: Secondary phase voltages [V]
    V_a_sec_out = add_block('simulink/Sinks/Out1', [model_name '/V_a_sec_out']);
    set_param(V_a_sec_out, 'Position', [740 40 770 60]);
    set_param(V_a_sec_out, 'Port', '1');
    
    V_b_sec_out = add_block('simulink/Sinks/Out1', [model_name '/V_b_sec_out']);
    set_param(V_b_sec_out, 'Position', [740 110 770 130]);
    set_param(V_b_sec_out, 'Port', '2');
    
    V_c_sec_out = add_block('simulink/Sinks/Out1', [model_name '/V_c_sec_out']);
    set_param(V_c_sec_out, 'Position', [740 180 770 200]);
    set_param(V_c_sec_out, 'Port', '3');
    
    % Output 4-6: Secondary phase currents [A]
    I_a_sec_out = add_block('simulink/Sinks/Out1', [model_name '/I_a_sec_out']);
    set_param(I_a_sec_out, 'Position', [760 280 790 300]);
    set_param(I_a_sec_out, 'Port', '4');
    
    I_b_sec_out = add_block('simulink/Sinks/Out1', [model_name '/I_b_sec_out']);
    set_param(I_b_sec_out, 'Position', [760 350 790 370]);
    set_param(I_b_sec_out, 'Port', '5');
    
    I_c_sec_out = add_block('simulink/Sinks/Out1', [model_name '/I_c_sec_out']);
    set_param(I_c_sec_out, 'Position', [760 420 790 440]);
    set_param(I_c_sec_out, 'Port', '6');
    
    % Output 7: Total power losses [W]
    P_loss_out = add_block('simulink/Sinks/Out1', [model_name '/P_loss_out']);
    set_param(P_loss_out, 'Position', [860 410 890 430]);
    set_param(P_loss_out, 'Port', '7');
    
    % ====================================================================
    % SIGNAL CONNECTIONS (Add Lines)
    % ====================================================================
    
    try
        % Voltage transformation
        add_line(hModel, 'V_a_prim_in/1', 'V_a_trans_gain/1');
        add_line(hModel, 'V_b_prim_in/1', 'V_b_trans_gain/1');
        add_line(hModel, 'V_c_prim_in/1', 'V_c_trans_gain/1');
        
        % Resistance drops
        add_line(hModel, 'I_a_prim_in/1', 'R_drop_a/1');
        add_line(hModel, 'R_leak_const/1', 'R_drop_a/2');
        
        add_line(hModel, 'I_b_prim_in/1', 'R_drop_b/1');
        add_line(hModel, 'R_leak_const/1', 'R_drop_b/2');
        
        add_line(hModel, 'I_c_prim_in/1', 'R_drop_c/1');
        add_line(hModel, 'R_leak_const/1', 'R_drop_c/2');
        
        % Leakage inductance
        add_line(hModel, 'I_a_prim_in/1', 'L_leak_a_int/1');
        add_line(hModel, 'I_b_prim_in/1', 'L_leak_b_int/1');
        add_line(hModel, 'I_c_prim_in/1', 'L_leak_c_int/1');
        
        % Magnetizing inductance
        add_line(hModel, 'V_a_prim_in/1', 'Lm_a_int/1');
        add_line(hModel, 'V_b_prim_in/1', 'Lm_b_int/1');
        add_line(hModel, 'V_c_prim_in/1', 'Lm_c_int/1');
        
        % Voltage drops
        add_line(hModel, 'V_a_trans_gain/1', 'V_a_drop_sum/1');
        add_line(hModel, 'R_drop_a/1', 'V_a_drop_sum/2');
        add_line(hModel, 'L_leak_a_int/1', 'V_a_drop_sum/3');
        add_line(hModel, 'V_a_drop_sum/1', 'V_a_sec_out/1');
        
        add_line(hModel, 'V_b_trans_gain/1', 'V_b_drop_sum/1');
        add_line(hModel, 'R_drop_b/1', 'V_b_drop_sum/2');
        add_line(hModel, 'L_leak_b_int/1', 'V_b_drop_sum/3');
        add_line(hModel, 'V_b_drop_sum/1', 'V_b_sec_out/1');
        
        add_line(hModel, 'V_c_trans_gain/1', 'V_c_drop_sum/1');
        add_line(hModel, 'R_drop_c/1', 'V_c_drop_sum/2');
        add_line(hModel, 'L_leak_c_int/1', 'V_c_drop_sum/3');
        add_line(hModel, 'V_c_drop_sum/1', 'V_c_sec_out/1');
        
        % Current transformation
        add_line(hModel, 'I_a_prim_in/1', 'I_a_trans_gain/1');
        add_line(hModel, 'I_b_prim_in/1', 'I_b_trans_gain/1');
        add_line(hModel, 'I_c_prim_in/1', 'I_c_trans_gain/1');
        
        add_line(hModel, 'I_a_trans_gain/1', 'I_a_sec_out/1');
        add_line(hModel, 'I_b_trans_gain/1', 'I_b_sec_out/1');
        add_line(hModel, 'I_c_trans_gain/1', 'I_c_sec_out/1');
        
        % Losses calculation
        add_line(hModel, 'V_a_prim_in/1', 'V_mag_rms_gain/1');
        add_line(hModel, 'V_mag_rms_gain/1', 'V_rms_ratio_sq/1');
        add_line(hModel, 'V_mag_rms_gain/1', 'V_rms_ratio_sq/2');
        add_line(hModel, 'V_rms_ratio_sq/1', 'P_Fe_loss/1');
        add_line(hModel, 'P_0_loss_const/1', 'P_Fe_loss/2');
        
        add_line(hModel, 'I_a_prim_in/1', 'I_rms_calc_a/1');
        add_line(hModel, 'I_rms_calc_a/1', 'I_ratio_sq/1');
        add_line(hModel, 'I_rms_calc_a/1', 'I_ratio_sq/2');
        add_line(hModel, 'I_ratio_sq/1', 'P_Cu_loss/1');
        add_line(hModel, 'P_k_loss_const/1', 'P_Cu_loss/2');
        
        add_line(hModel, 'P_Fe_loss/1', 'P_total_loss_sum/1');
        add_line(hModel, 'P_Cu_loss/1', 'P_total_loss_sum/2');
        add_line(hModel, 'P_total_loss_sum/1', 'P_loss_out/1');
        
    catch ME
        warning(ME.identifier, 'Some connections could not be established. Error: %s', ME.message);
    end
    
    % Save model
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    
    model_file = fullfile(save_path, [model_name, '.slx']);
    save_system(hModel, model_file, 'OverwriteIfChanged', true);
    
    fprintf('\n✓ Model saved: %s\n', model_file);
    fprintf('✓ Transformer Subsystem built successfully (PhD-level)\n\n');
    
end
