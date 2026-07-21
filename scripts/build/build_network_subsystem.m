%  ========================================================================
%  DIGITAL TWIN: BUILD NETWORK_SUBSYSTEM
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-06-24
%  
% Description:
%   Builds the Network/Grid Subsystem (Level 2.4) with complete signal routing.
%   - Grid voltage source (10 kV, 50 Hz, 3-phase)
%   - Cable impedance model (R-L, temperature dependent)
%   - Point of Common Coupling (PCC) voltage calculation
%   - Load model (power flow)
%   - Network frequency measurement
%   - Complete signal connections for simulation
%   
% Output: Network_Subsystem.slx
%  ========================================================================

function hModel = build_network_subsystem(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'Network_Subsystem', @ischar);
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
    set_param(hModel, 'MaxStep', '1e-4');
    set_param(hModel, 'MinStep', '1e-8');
    set_param(hModel, 'StopTime', '86400');
    
    % ====================================================================
    % INPUTS
    % ====================================================================
    
    % Input 1-3: Three-phase currents from transformer (secondary) [A]
    I_a_in = add_block('simulink/Sources/In1', [model_name '/I_a_pcc_in']);
    set_param(I_a_in, 'Position', [20 50 50 70]);
    set_param(I_a_in, 'Port', '1');
    
    I_b_in = add_block('simulink/Sources/In1', [model_name '/I_b_pcc_in']);
    set_param(I_b_in, 'Position', [20 120 50 140]);
    set_param(I_b_in, 'Port', '2');
    
    I_c_in = add_block('simulink/Sources/In1', [model_name '/I_c_pcc_in']);
    set_param(I_c_in, 'Position', [20 190 50 210]);
    set_param(I_c_in, 'Port', '3');
    
    % Input 4-6: Three-phase load currents [A]
    I_load_a = add_block('simulink/Sources/In1', [model_name '/I_load_a_in']);
    set_param(I_load_a, 'Position', [20 260 50 280]);
    set_param(I_load_a, 'Port', '4');
    
    I_load_b = add_block('simulink/Sources/In1', [model_name '/I_load_b_in']);
    set_param(I_load_b, 'Position', [20 330 50 350]);
    set_param(I_load_b, 'Port', '5');
    
    I_load_c = add_block('simulink/Sources/In1', [model_name '/I_load_c_in']);
    set_param(I_load_c, 'Position', [20 400 50 420]);
    set_param(I_load_c, 'Port', '6');
    
    % Input 7: Ambient temperature [°C]
    T_amb_in = add_block('simulink/Sources/In1', [model_name '/T_amb_in']);
    set_param(T_amb_in, 'Position', [20 470 50 490]);
    set_param(T_amb_in, 'Port', '7');
    
    % ====================================================================
    % GRID VOLTAGE SOURCE
    % ====================================================================
    
    % Grid parameters
    V_grid_rms = add_block('simulink/Sources/Constant', [model_name '/V_grid_rms_const']);
    set_param(V_grid_rms, 'Value', '5773.5');  % 10 kV phase-to-neutral RMS
    set_param(V_grid_rms, 'Position', [130 50 170 70]);
    
    % Grid frequency 50 Hz = 314.159 rad/s
    omega_grid = add_block('simulink/Sources/Constant', [model_name '/omega_grid_const']);
    set_param(omega_grid, 'Value', '314.159');
    set_param(omega_grid, 'Position', [130 120 170 140]);
    
    % Grid phase reference (0, -2π/3, -4π/3 for balanced 3-phase)
    phase_a = add_block('simulink/Sources/Constant', [model_name '/phase_a_const']);
    set_param(phase_a, 'Value', '0');
    set_param(phase_a, 'Position', [130 190 170 210]);
    
    phase_b = add_block('simulink/Sources/Constant', [model_name '/phase_b_const']);
    set_param(phase_b, 'Value', '-2.0944');  % -2π/3
    set_param(phase_b, 'Position', [130 260 170 280]);
    
    phase_c = add_block('simulink/Sources/Constant', [model_name '/phase_c_const']);
    set_param(phase_c, 'Value', '-4.1888');  % -4π/3
    set_param(phase_c, 'Position', [130 330 170 350]);
    
    % Time input (for phase calculation)
    t_input = add_block('simulink/Sources/Clock', [model_name '/t_clock']);
    set_param(t_input, 'Position', [130 400 170 420]);
    
    % Phase angle: theta(t) = omega * t + phase_offset
    theta_a = add_block('simulink/Math Operations/Product', [model_name '/theta_a_prod']);
    set_param(theta_a, 'Position', [240 390 280 430]);
    set_param(theta_a, 'Inputs', '**');
    
    theta_a_sum = add_block('simulink/Math Operations/Sum', [model_name '/theta_a_sum']);
    set_param(theta_a_sum, 'Position', [310 380 340 440]);
    set_param(theta_a_sum, 'Inputs', '|++');
    
    theta_b_sum = add_block('simulink/Math Operations/Sum', [model_name '/theta_b_sum']);
    set_param(theta_b_sum, 'Position', [310 450 340 510]);
    set_param(theta_b_sum, 'Inputs', '|++');
    
    theta_c_sum = add_block('simulink/Math Operations/Sum', [model_name '/theta_c_sum']);
    set_param(theta_c_sum, 'Position', [310 520 340 580]);
    set_param(theta_c_sum, 'Inputs', '|++');
    
    % Voltage generation: V = V_rms * sqrt(2) * cos(theta)
    cos_theta_a = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta_a']);
    set_param(cos_theta_a, 'Expr', 'cos(u)');
    set_param(cos_theta_a, 'Position', [400 380 440 420]);
    
    cos_theta_b = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta_b']);
    set_param(cos_theta_b, 'Expr', 'cos(u)');
    set_param(cos_theta_b, 'Position', [400 450 440 490]);
    
    cos_theta_c = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta_c']);
    set_param(cos_theta_c, 'Expr', 'cos(u)');
    set_param(cos_theta_c, 'Position', [400 520 440 560]);
    
    % Peak voltage: V_peak = V_rms * sqrt(2)
    V_peak_scale = add_block('simulink/Math Operations/Gain', [model_name '/V_peak_scale']);
    set_param(V_peak_scale, 'Gain', 'sqrt(2)');
    set_param(V_peak_scale, 'Position', [200 50 240 90]);
    
    V_a_grid = add_block('simulink/Math Operations/Product', [model_name '/V_a_grid_prod']);
    set_param(V_a_grid, 'Position', [480 40 520 80]);
    set_param(V_a_grid, 'Inputs', '**');
    
    V_b_grid = add_block('simulink/Math Operations/Product', [model_name '/V_b_grid_prod']);
    set_param(V_b_grid, 'Position', [480 110 520 150]);
    set_param(V_b_grid, 'Inputs', '**');
    
    V_c_grid = add_block('simulink/Math Operations/Product', [model_name '/V_c_grid_prod']);
    set_param(V_c_grid, 'Position', [480 180 520 220]);
    set_param(V_c_grid, 'Inputs', '**');
    
    % ====================================================================
    % CABLE IMPEDANCE MODEL
    % ====================================================================
    
    % Cable parameters: NYC 3x150 mm², 0.5 km
    % R ≈ 0.12 Ω/km * 0.5 km = 0.06 Ω per phase
    % X ≈ 0.08 Ω/km * 0.5 km = 0.04 Ω per phase
    
    R_cable = add_block('simulink/Sources/Constant', [model_name '/R_cable_const']);
    set_param(R_cable, 'Value', '0.06');
    set_param(R_cable, 'Position', [560 50 600 70]);
    
    X_cable = add_block('simulink/Sources/Constant', [model_name '/X_cable_const']);
    set_param(X_cable, 'Value', '0.04');
    set_param(X_cable, 'Position', [560 120 600 140]);
    
    % Temperature dependence: R(T) = R_ref * [1 + alpha*(T - T_ref)]
    alpha_R = add_block('simulink/Sources/Constant', [model_name '/alpha_R_const']);
    set_param(alpha_R, 'Value', '0.004');  % Temperature coefficient for copper
    set_param(alpha_R, 'Position', [560 190 600 210]);
    
    T_ref = add_block('simulink/Sources/Constant', [model_name '/T_ref_const']);
    set_param(T_ref, 'Value', '20');
    set_param(T_ref, 'Position', [560 260 600 280]);
    
    % T_cable ≈ T_amb + (dT per Ampere) * I
    % Simplified: use ambient temperature directly
    T_diff = add_block('simulink/Math Operations/Sum', [model_name '/T_diff_sum']);
    set_param(T_diff, 'Position', [640 220 670 260]);
    set_param(T_diff, 'Inputs', '|+-');
    
    alpha_T = add_block('simulink/Math Operations/Product', [model_name '/alpha_T_prod']);
    set_param(alpha_T, 'Position', [720 210 760 270]);
    
    R_temp_factor = add_block('simulink/Math Operations/Sum', [model_name '/R_temp_factor_sum']);
    set_param(R_temp_factor, 'Position', [800 190 830 270]);
    set_param(R_temp_factor, 'Inputs', '|++');
    
    one_const = add_block('simulink/Sources/Constant', [model_name '/one_const']);
    set_param(one_const, 'Value', '1');
    set_param(one_const, 'Position', [780 170 810 190]);
    
    % Actual resistance
    R_actual = add_block('simulink/Math Operations/Product', [model_name '/R_actual_prod']);
    set_param(R_actual, 'Position', [880 100 920 140]);
    
    % Voltage drops across cable impedance
    % dV_R = I * R
    dV_R_a = add_block('simulink/Math Operations/Product', [model_name '/dV_R_a_prod']);
    set_param(dV_R_a, 'Position', [560 300 600 340]);
    
    dV_R_b = add_block('simulink/Math Operations/Product', [model_name '/dV_R_b_prod']);
    set_param(dV_R_b, 'Position', [560 370 600 410]);
    
    dV_R_c = add_block('simulink/Math Operations/Product', [model_name '/dV_R_c_prod']);
    set_param(dV_R_c, 'Position', [560 440 600 480]);
    
    % Inductive voltage drops: dV_L = L*di/dt
    L_cable_a = add_block('simulink/Continuous/Integrator', [model_name '/L_cable_a_int']);
    set_param(L_cable_a, 'Position', [660 300 700 340]);
    set_param(L_cable_a, 'InitialCondition', '0');
    
    L_cable_b = add_block('simulink/Continuous/Integrator', [model_name '/L_cable_b_int']);
    set_param(L_cable_b, 'Position', [660 370 700 410]);
    set_param(L_cable_b, 'InitialCondition', '0');
    
    L_cable_c = add_block('simulink/Continuous/Integrator', [model_name '/L_cable_c_int']);
    set_param(L_cable_c, 'Position', [660 440 700 480]);
    set_param(L_cable_c, 'InitialCondition', '0');
    
    % ====================================================================
    % PCC VOLTAGE CALCULATION
    % ====================================================================
    
    % V_PCC = V_grid - dV_R - dV_L
    V_a_pcc = add_block('simulink/Math Operations/Sum', [model_name '/V_a_pcc_sum']);
    set_param(V_a_pcc, 'Position', [780 40 810 80]);
    set_param(V_a_pcc, 'Inputs', '|+--');
    
    V_b_pcc = add_block('simulink/Math Operations/Sum', [model_name '/V_b_pcc_sum']);
    set_param(V_b_pcc, 'Position', [780 110 810 150]);
    set_param(V_b_pcc, 'Inputs', '|+--');
    
    V_c_pcc = add_block('simulink/Math Operations/Sum', [model_name '/V_c_pcc_sum']);
    set_param(V_c_pcc, 'Position', [780 180 810 220]);
    set_param(V_c_pcc, 'Inputs', '|+--');
    
    % ====================================================================
    % CABLE LOSSES
    % ====================================================================
    
    % P_loss = I²*R
    I_sq_a = add_block('simulink/Math Operations/Product', [model_name '/I_sq_a_prod']);
    set_param(I_sq_a, 'Position', [720 300 760 340]);
    set_param(I_sq_a, 'Inputs', '**');
    
    P_loss_a = add_block('simulink/Math Operations/Product', [model_name '/P_loss_a_prod']);
    set_param(P_loss_a, 'Position', [800 290 840 350]);
    
    P_loss_total = add_block('simulink/Math Operations/Sum', [model_name '/P_loss_total_sum']);
    set_param(P_loss_total, 'Position', [900 300 930 360]);
    set_param(P_loss_total, 'Inputs', '|+++');
    
    % ====================================================================
    % GRID FREQUENCY MEASUREMENT (PLL-like)
    % ====================================================================
    
    % Measure phase derivative to estimate frequency
    % df/dt ≈ (phase_meas - phase_prev) / Δt
    
    % ====================================================================
    % OUTPUTS
    % ====================================================================
    
    % Output 1-3: PCC voltages [V]
    V_a_pcc_out = add_block('simulink/Sinks/Out1', [model_name '/V_a_pcc_out']);
    set_param(V_a_pcc_out, 'Position', [880 40 910 60]);
    set_param(V_a_pcc_out, 'Port', '1');
    
    V_b_pcc_out = add_block('simulink/Sinks/Out1', [model_name '/V_b_pcc_out']);
    set_param(V_b_pcc_out, 'Position', [880 110 910 130]);
    set_param(V_b_pcc_out, 'Port', '2');
    
    V_c_pcc_out = add_block('simulink/Sinks/Out1', [model_name '/V_c_pcc_out']);
    set_param(V_c_pcc_out, 'Position', [880 180 910 200]);
    set_param(V_c_pcc_out, 'Port', '3');
    
    % Output 4: Cable losses [W]
    P_cable_loss_out = add_block('simulink/Sinks/Out1', [model_name '/P_cable_loss_out']);
    set_param(P_cable_loss_out, 'Position', [960 310 990 330]);
    set_param(P_cable_loss_out, 'Port', '4');
    
    % Output 5: Grid frequency [Hz]
    f_grid_out = add_block('simulink/Sinks/Out1', [model_name '/f_grid_out']);
    set_param(f_grid_out, 'Position', [960 380 990 400]);
    set_param(f_grid_out, 'Port', '5');
    
    % ====================================================================
    % SIGNAL CONNECTIONS (Add Lines)
    % ====================================================================
    
    try
        % Grid voltage generation
        add_line(hModel, 'V_grid_rms_const/1', 'V_peak_scale/1');
        add_line(hModel, 'V_peak_scale/1', 'V_a_grid_prod/1');
        add_line(hModel, 'V_peak_scale/1', 'V_b_grid_prod/1');
        add_line(hModel, 'V_peak_scale/1', 'V_c_grid_prod/1');
        
        % Phase calculation
        add_line(hModel, 't_clock/1', 'theta_a_prod/1');
        add_line(hModel, 'omega_grid_const/1', 'theta_a_prod/2');
        add_line(hModel, 'theta_a_prod/1', 'theta_a_sum/1');
        add_line(hModel, 'phase_a_const/1', 'theta_a_sum/2');
        
        add_line(hModel, 'theta_a_sum/1', 'theta_b_sum/1');
        add_line(hModel, 'phase_b_const/1', 'theta_b_sum/2');
        
        add_line(hModel, 'theta_a_sum/1', 'theta_c_sum/1');
        add_line(hModel, 'phase_c_const/1', 'theta_c_sum/2');
        
        % Cosine calculations
        add_line(hModel, 'theta_a_sum/1', 'cos_theta_a/1');
        add_line(hModel, 'theta_b_sum/1', 'cos_theta_b/1');
        add_line(hModel, 'theta_c_sum/1', 'cos_theta_c/1');
        
        add_line(hModel, 'cos_theta_a/1', 'V_a_grid_prod/2');
        add_line(hModel, 'cos_theta_b/1', 'V_b_grid_prod/2');
        add_line(hModel, 'cos_theta_c/1', 'V_c_grid_prod/2');
        
        % Cable resistance temperature dependency
        add_line(hModel, 'T_amb_in/1', 'T_diff_sum/1');
        add_line(hModel, 'T_ref_const/1', 'T_diff_sum/2');
        add_line(hModel, 'T_diff_sum/1', 'alpha_T_prod/1');
        add_line(hModel, 'alpha_R_const/1', 'alpha_T_prod/2');
        add_line(hModel, 'alpha_T_prod/1', 'R_temp_factor_sum/1');
        add_line(hModel, 'one_const/1', 'R_temp_factor_sum/2');
        add_line(hModel, 'R_temp_factor_sum/1', 'R_actual_prod/1');
        add_line(hModel, 'R_cable_const/1', 'R_actual_prod/2');
        
        % Cable voltage drops (resistive)
        add_line(hModel, 'I_a_pcc_in/1', 'dV_R_a_prod/1');
        add_line(hModel, 'R_actual_prod/1', 'dV_R_a_prod/2');
        
        add_line(hModel, 'I_b_pcc_in/1', 'dV_R_b_prod/1');
        add_line(hModel, 'R_actual_prod/1', 'dV_R_b_prod/2');
        
        add_line(hModel, 'I_c_pcc_in/1', 'dV_R_c_prod/1');
        add_line(hModel, 'R_actual_prod/1', 'dV_R_c_prod/2');
        
        % Cable voltage drops (inductive)
        add_line(hModel, 'I_a_pcc_in/1', 'L_cable_a_int/1');
        add_line(hModel, 'I_b_pcc_in/1', 'L_cable_b_int/1');
        add_line(hModel, 'I_c_pcc_in/1', 'L_cable_c_int/1');
        
        % PCC voltage calculation
        add_line(hModel, 'V_a_grid_prod/1', 'V_a_pcc_sum/1');
        add_line(hModel, 'dV_R_a_prod/1', 'V_a_pcc_sum/2');
        add_line(hModel, 'L_cable_a_int/1', 'V_a_pcc_sum/3');
        add_line(hModel, 'V_a_pcc_sum/1', 'V_a_pcc_out/1');
        
        add_line(hModel, 'V_b_grid_prod/1', 'V_b_pcc_sum/1');
        add_line(hModel, 'dV_R_b_prod/1', 'V_b_pcc_sum/2');
        add_line(hModel, 'L_cable_b_int/1', 'V_b_pcc_sum/3');
        add_line(hModel, 'V_b_pcc_sum/1', 'V_b_pcc_out/1');
        
        add_line(hModel, 'V_c_grid_prod/1', 'V_c_pcc_sum/1');
        add_line(hModel, 'dV_R_c_prod/1', 'V_c_pcc_sum/2');
        add_line(hModel, 'L_cable_c_int/1', 'V_c_pcc_sum/3');
        add_line(hModel, 'V_c_pcc_sum/1', 'V_c_pcc_out/1');
        
        % Cable losses
        add_line(hModel, 'I_a_pcc_in/1', 'I_sq_a_prod/1');
        add_line(hModel, 'I_a_pcc_in/1', 'I_sq_a_prod/2');
        add_line(hModel, 'I_sq_a_prod/1', 'P_loss_a_prod/1');
        add_line(hModel, 'R_actual_prod/1', 'P_loss_a_prod/2');
        add_line(hModel, 'P_loss_a_prod/1', 'P_loss_total_sum/1');
        add_line(hModel, 'P_loss_total_sum/1', 'P_cable_loss_out/1');
        
        % Grid frequency (constant for now)
        add_line(hModel, 'omega_grid_const/1', 'f_grid_out/1');
        
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
    fprintf('✓ Network Subsystem built successfully\n\n');
    
end
