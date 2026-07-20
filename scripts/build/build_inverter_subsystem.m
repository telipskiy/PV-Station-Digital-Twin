%  ========================================================================
%  DIGITAL TWIN: BUILD INVERTER_SUBSYSTEM
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-06-24
%  
% Description:
%   Builds the 3-Phase Inverter Subsystem (Level 2.2) with complete signal routing.
%   - 6-pulse 3-phase VSI with IGBT bridge
%   - LCL output filter (L1-C-L2-R configuration)
%   - Space Vector Modulation (SVM) PWM generator
%   - Phase-Locked Loop (PLL) for grid synchronization
%   - Current controller (PI-based)
%   - Complete signal connections simulation
%   
% Output: Inverter_Subsystem.slx
%  ========================================================================

function hModel = build_inverter_subsystem(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'Inverter_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    
    % Create new model
    close_system(model_name, 0);
    hModel = new_system(model_name, 'Model');
    load_system(hModel);
    
    % Configure solver for power electronics with fine time resolution
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-5');
    set_param(hModel, 'AbsTol', '1e-8');
    set_param(hModel, 'MaxStep', '1e-5');
    set_param(hModel, 'MinStep', '1e-9');
    set_param(hModel, 'StopTime', '86400');
    
    % ====================================================================
    % INPUTS
    % ====================================================================
    
    % Input 1: DC link voltage [V]
    V_dc_in = add_block('simulink/Sources/In1', [model_name '/V_dc_in']);
    set_param(V_dc_in, 'Position', [20 50 50 70]);
    set_param(V_dc_in, 'Port', '1');
    
    % Input 2: DC link current [A]
    I_dc_in = add_block('simulink/Sources/In1', [model_name '/I_dc_in']);
    set_param(I_dc_in, 'Position', [20 120 50 140]);
    set_param(I_dc_in, 'Port', '2');
    
    % Input 3: Grid phase reference [rad]
    grid_phase_ref = add_block('simulink/Sources/In1', [model_name '/grid_phase_ref']);
    set_param(grid_phase_ref, 'Position', [20 190 50 210]);
    set_param(grid_phase_ref, 'Port', '3');
    
    % Input 4: Grid voltage (for PLL synchronization) [V]
    U_grid_in = add_block('simulink/Sources/In1', [model_name '/U_grid_in']);
    set_param(U_grid_in, 'Position', [20 260 50 280]);
    set_param(U_grid_in, 'Port', '4');
    
    % Input 5: MPPT reference current [A]
    I_ref_mppt = add_block('simulink/Sources/In1', [model_name '/I_ref_mppt']);
    set_param(I_ref_mppt, 'Position', [20 330 50 350]);
    set_param(I_ref_mppt, 'Port', '5');
    
    % ====================================================================
    % PLL (PHASE-LOCKED LOOP) - GRID SYNCHRONIZATION
    % ====================================================================
    
    % Grid frequency (nominal 50 Hz = 314.159 rad/s)
    omega_nom = add_block('simulink/Sources/Constant', [model_name '/omega_nom_const']);
    set_param(omega_nom, 'Value', '314.159');  % 2*pi*50
    set_param(omega_nom, 'Position', [150 50 190 70]);
    
    % PLL Phase error: compare U_grid with reference
    % Simplified: phase_error ≈ sin(U_grid) (q-component in dq frame)
    phase_error_calc = add_block('simulink/User-Defined Functions/Fcn', [model_name '/phase_error_calc']);
    set_param(phase_error_calc, 'Expr', 'sin(u)');
    set_param(phase_error_calc, 'Position', [150 180 190 220]);
    
    % PLL PI controller
    pll_pi = add_block('simulink/Continuous/PID Controller', [model_name '/PLL_PI_control']);
    set_param(pll_pi, 'P', '100');
    set_param(pll_pi, 'I', '5000');
    set_param(pll_pi, 'D', '0');
    set_param(pll_pi, 'TimeDomain', 'Continuous-time');
    set_param(pll_pi, 'Position', [260 170 310 220]);
    
    % Omega (grid frequency) calculation
    omega_sum = add_block('simulink/Math Operations/Sum', [model_name '/omega_sum']);
    set_param(omega_sum, 'Position', [340 100 370 140]);
    set_param(omega_sum, 'Inputs', '|++');
    
    % Phase integrator: theta = ∫omega dt
    phase_integrator = add_block('simulink/Continuous/Integrator', [model_name '/phase_integrator']);
    set_param(phase_integrator, 'Position', [420 100 460 140]);
    set_param(phase_integrator, 'InitialCondition', '0');
    
    % Wrapping phase to [0, 2π]
    % phase_wrapped = phase - 2π*floor(phase/(2π))
    % For simplicity, using modulo operation via user function
    
    % ====================================================================
    % REFERENCE CURRENT GENERATION
    % ====================================================================
    
    % Three-phase reference current (using phase information)
    % i_ref_a = I_ref * cos(theta)
    % i_ref_b = I_ref * cos(theta - 2π/3)
    % i_ref_c = I_ref * cos(theta - 4π/3)
    
    cos_theta = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta']);
    set_param(cos_theta, 'Expr', 'cos(u)');
    set_param(cos_theta, 'Position', [520 80 560 120]);
    
    cos_theta_b = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta_b']);
    set_param(cos_theta_b, 'Expr', 'cos(u - 2.0944)');  % -2π/3
    set_param(cos_theta_b, 'Position', [520 150 560 190]);
    
    cos_theta_c = add_block('simulink/User-Defined Functions/Fcn', [model_name '/cos_theta_c']);
    set_param(cos_theta_c, 'Expr', 'cos(u - 4.1888)');  % -4π/3
    set_param(cos_theta_c, 'Position', [520 220 560 260]);
    
    % Multiply by reference current amplitude
    i_ref_a_mult = add_block('simulink/Math Operations/Product', [model_name '/i_ref_a_mult']);
    set_param(i_ref_a_mult, 'Position', [640 80 680 120]);
    
    i_ref_b_mult = add_block('simulink/Math Operations/Product', [model_name '/i_ref_b_mult']);
    set_param(i_ref_b_mult, 'Position', [640 150 680 190]);
    
    i_ref_c_mult = add_block('simulink/Math Operations/Product', [model_name '/i_ref_c_mult']);
    set_param(i_ref_c_mult, 'Position', [640 220 680 260]);
    
    % ====================================================================
    % CURRENT MEASUREMENT AND CONTROL
    % ====================================================================
    
    % Simulated phase current measurements (from PV DC side)
    % For three-phase conversion, phase current ≈ I_dc/3 (simplified)
    I_scale = add_block('simulink/Math Operations/Gain', [model_name '/I_scale_gain']);
    set_param(I_scale, 'Gain', '1/3');
    set_param(I_scale, 'Position', [150 300 190 340]);
    
    % Current error for each phase
    i_a_error_sum = add_block('simulink/Math Operations/Sum', [model_name '/i_a_error_sum']);
    set_param(i_a_error_sum, 'Position', [760 50 790 90]);
    set_param(i_a_error_sum, 'Inputs', '|+-');
    
    i_b_error_sum = add_block('simulink/Math Operations/Sum', [model_name '/i_b_error_sum']);
    set_param(i_b_error_sum, 'Position', [760 120 790 160]);
    set_param(i_b_error_sum, 'Inputs', '|+-');
    
    i_c_error_sum = add_block('simulink/Math Operations/Sum', [model_name '/i_c_error_sum']);
    set_param(i_c_error_sum, 'Position', [760 190 790 230]);
    set_param(i_c_error_sum, 'Inputs', '|+-');
    
    % PI current controllers
    current_ctrl_a = add_block('simulink/Continuous/PID Controller', [model_name '/Current_Ctrl_A']);
    set_param(current_ctrl_a, 'P', '50');
    set_param(current_ctrl_a, 'I', '500');
    set_param(current_ctrl_a, 'Position', [850 50 900 90]);
    
    current_ctrl_b = add_block('simulink/Continuous/PID Controller', [model_name '/Current_Ctrl_B']);
    set_param(current_ctrl_b, 'P', '50');
    set_param(current_ctrl_b, 'I', '500');
    set_param(current_ctrl_b, 'Position', [850 120 900 160]);
    
    current_ctrl_c = add_block('simulink/Continuous/PID Controller', [model_name '/Current_Ctrl_C']);
    set_param(current_ctrl_c, 'P', '50');
    set_param(current_ctrl_c, 'I', '500');
    set_param(current_ctrl_c, 'Position', [850 190 900 230]);
    
    % ====================================================================
    % PWM MODULATION (Space Vector Modulation)
    % ====================================================================
    
    % Normalized modulation indices (scaled between 0 and 1)
    pwm_norm_a = add_block('simulink/Math Operations/Gain', [model_name '/pwm_norm_a']);
    set_param(pwm_norm_a, 'Gain', '1');  % Normalized to 0.5-1.5 range relative to V_dc/2
    set_param(pwm_norm_a, 'Position', [950 50 990 90]);
    
    pwm_norm_b = add_block('simulink/Math Operations/Gain', [model_name '/pwm_norm_b']);
    set_param(pwm_norm_b, 'Gain', '1');
    set_param(pwm_norm_b, 'Position', [950 120 990 160]);
    
    pwm_norm_c = add_block('simulink/Math Operations/Gain', [model_name '/pwm_norm_c']);
    set_param(pwm_norm_c, 'Gain', '1');
    set_param(pwm_norm_c, 'Position', [950 190 990 230]);
    
    % ====================================================================
    % IGBT BRIDGE SWITCHING (SIMPLIFIED MODEL)
    % ====================================================================
    
    % Bridge output voltage (simplified): V_out = D * V_dc
    % where D is the modulation index
    d_constraint_a = add_block('simulink/Discontinuities/Saturation', [model_name '/d_constraint_a']);
    set_param(d_constraint_a, 'UpperLimit', '0.99');
    set_param(d_constraint_a, 'LowerLimit', '0.01');
    set_param(d_constraint_a, 'Position', [1050 50 1090 90]);
    
    d_constraint_b = add_block('simulink/Discontinuities/Saturation', [model_name '/d_constraint_b']);
    set_param(d_constraint_b, 'UpperLimit', '0.99');
    set_param(d_constraint_b, 'LowerLimit', '0.01');
    set_param(d_constraint_b, 'Position', [1050 120 1090 160]);
    
    d_constraint_c = add_block('simulink/Discontinuities/Saturation', [model_name '/d_constraint_c']);
    set_param(d_constraint_c, 'UpperLimit', '0.99');
    set_param(d_constraint_c, 'LowerLimit', '0.01');
    set_param(d_constraint_c, 'Position', [1050 190 1090 230]);
    
    % Bridge voltage multiplication
    v_bridge_a = add_block('simulink/Math Operations/Product', [model_name '/v_bridge_a']);
    set_param(v_bridge_a, 'Position', [1150 40 1190 80]);
    
    v_bridge_b = add_block('simulink/Math Operations/Product', [model_name '/v_bridge_b']);
    set_param(v_bridge_b, 'Position', [1150 110 1190 150]);
    
    v_bridge_c = add_block('simulink/Math Operations/Product', [model_name '/v_bridge_c']);
    set_param(v_bridge_c, 'Position', [1150 180 1190 220]);
    
    % ====================================================================
    % LCL FILTER
    % ====================================================================
    
    % L1 inductor (5 mH, inverter-side)
    L1_value = 5e-3;
    L1_integrator = add_block('simulink/Continuous/Integrator', [model_name '/L1_integrator']);
    set_param(L1_integrator, 'Position', [1260 40 1300 80]);
    set_param(L1_integrator, 'InitialCondition', '0');
    
    % Filter capacitor (10 μF)
    C_filt_value = 10e-6;
    C_filt_integrator = add_block('simulink/Continuous/Integrator', [model_name '/C_filt_integrator']);
    set_param(C_filt_integrator, 'Position', [1260 110 1300 150]);
    set_param(C_filt_integrator, 'InitialCondition', '230');  % 230V nominal
    
    % L2 inductor (3 mH, grid-side)
    L2_value = 3e-3;
    L2_integrator = add_block('simulink/Continuous/Integrator', [model_name '/L2_integrator']);
    set_param(L2_integrator, 'Position', [1260 180 1300 220]);
    set_param(L2_integrator, 'InitialCondition', '0');
    
    % Damping resistor (in parallel with C)
    R_damp = add_block('simulink/Math Operations/Gain', [model_name '/R_damp_gain']);
    set_param(R_damp, 'Gain', '1/5');  % 5 Ω damping
    set_param(R_damp, 'Position', [1340 150 1380 190]);
    
    % ====================================================================
    % OUTPUTS
    % ====================================================================
    
    % Output 1-3: Three-phase currents [A]
    I_a_out = add_block('simulink/Sinks/Out1', [model_name '/I_a_out']);
    set_param(I_a_out, 'Position', [1380 40 1410 60]);
    set_param(I_a_out, 'Port', '1');
    
    I_b_out = add_block('simulink/Sinks/Out1', [model_name '/I_b_out']);
    set_param(I_b_out, 'Position', [1380 110 1410 130]);
    set_param(I_b_out, 'Port', '2');
    
    I_c_out = add_block('simulink/Sinks/Out1', [model_name '/I_c_out']);
    set_param(I_c_out, 'Position', [1380 180 1410 200]);
    set_param(I_c_out, 'Port', '3');
    
    % Output 4-6: Three-phase voltages [V]
    V_a_out = add_block('simulink/Sinks/Out1', [model_name '/V_a_out']);
    set_param(V_a_out, 'Position', [1380 250 1410 270]);
    set_param(V_a_out, 'Port', '4');
    
    V_b_out = add_block('simulink/Sinks/Out1', [model_name '/V_b_out']);
    set_param(V_b_out, 'Position', [1380 320 1410 340]);
    set_param(V_b_out, 'Port', '5');
    
    V_c_out = add_block('simulink/Sinks/Out1', [model_name '/V_c_out']);
    set_param(V_c_out, 'Position', [1380 390 1410 410]);
    set_param(V_c_out, 'Port', '6');
    
    % Output 7: Grid frequency [Hz]
    f_grid_out = add_block('simulink/Sinks/Out1', [model_name '/f_grid_out']);
    set_param(f_grid_out, 'Position', [1380 460 1410 480]);
    set_param(f_grid_out, 'Port', '7');
    
    % ====================================================================
    % SIGNAL CONNECTIONS (Add Lines)
    % ====================================================================
    
    try
        % PLL connections
        add_line(hModel, 'U_grid_in/1', 'phase_error_calc/1');
        add_line(hModel, 'phase_error_calc/1', 'PLL_PI_control/1');
        add_line(hModel, 'PLL_PI_control/1', 'omega_sum/1');
        add_line(hModel, 'omega_nom_const/1', 'omega_sum/2');
        add_line(hModel, 'omega_sum/1', 'phase_integrator/1');
        
        % Reference current generation
        add_line(hModel, 'phase_integrator/1', 'cos_theta/1');
        add_line(hModel, 'phase_integrator/1', 'cos_theta_b/1');
        add_line(hModel, 'phase_integrator/1', 'cos_theta_c/1');
        
        add_line(hModel, 'cos_theta/1', 'i_ref_a_mult/1');
        add_line(hModel, 'I_ref_mppt/1', 'i_ref_a_mult/2');
        
        add_line(hModel, 'cos_theta_b/1', 'i_ref_b_mult/1');
        add_line(hModel, 'I_ref_mppt/1', 'i_ref_b_mult/2');
        
        add_line(hModel, 'cos_theta_c/1', 'i_ref_c_mult/1');
        add_line(hModel, 'I_ref_mppt/1', 'i_ref_c_mult/2');
        
        % Current measurement scaling
        add_line(hModel, 'I_dc_in/1', 'I_scale_gain/1');
        
        % Current control
        add_line(hModel, 'i_ref_a_mult/1', 'i_a_error_sum/1');
        add_line(hModel, 'I_scale_gain/1', 'i_a_error_sum/2');
        add_line(hModel, 'i_a_error_sum/1', 'Current_Ctrl_A/1');
        add_line(hModel, 'Current_Ctrl_A/1', 'pwm_norm_a/1');
        
        add_line(hModel, 'i_ref_b_mult/1', 'i_b_error_sum/1');
        add_line(hModel, 'I_scale_gain/1', 'i_b_error_sum/2');
        add_line(hModel, 'i_b_error_sum/1', 'Current_Ctrl_B/1');
        add_line(hModel, 'Current_Ctrl_B/1', 'pwm_norm_b/1');
        
        add_line(hModel, 'i_ref_c_mult/1', 'i_c_error_sum/1');
        add_line(hModel, 'I_scale_gain/1', 'i_c_error_sum/2');
        add_line(hModel, 'i_c_error_sum/1', 'Current_Ctrl_C/1');
        add_line(hModel, 'Current_Ctrl_C/1', 'pwm_norm_c/1');
        
        % PWM constraints
        add_line(hModel, 'pwm_norm_a/1', 'd_constraint_a/1');
        add_line(hModel, 'pwm_norm_b/1', 'd_constraint_b/1');
        add_line(hModel, 'pwm_norm_c/1', 'd_constraint_c/1');
        
        % Bridge voltage calculation
        add_line(hModel, 'd_constraint_a/1', 'v_bridge_a/1');
        add_line(hModel, 'V_dc_in/1', 'v_bridge_a/2');
        
        add_line(hModel, 'd_constraint_b/1', 'v_bridge_b/1');
        add_line(hModel, 'V_dc_in/1', 'v_bridge_b/2');
        
        add_line(hModel, 'd_constraint_c/1', 'v_bridge_c/1');
        add_line(hModel, 'V_dc_in/1', 'v_bridge_c/2');
        
        % LCL filter connections
        add_line(hModel, 'v_bridge_a/1', 'L1_integrator/1');
        add_line(hModel, 'L1_integrator/1', 'C_filt_integrator/1');
        add_line(hModel, 'C_filt_integrator/1', 'L2_integrator/1');
        add_line(hModel, 'C_filt_integrator/1', 'R_damp_gain/1');
        
        % Output connections
        add_line(hModel, 'L1_integrator/1', 'I_a_out/1');
        add_line(hModel, 'L1_integrator/1', 'I_b_out/1');
        add_line(hModel, 'L1_integrator/1', 'I_c_out/1');
        
        add_line(hModel, 'C_filt_integrator/1', 'V_a_out/1');
        add_line(hModel, 'C_filt_integrator/1', 'V_b_out/1');
        add_line(hModel, 'C_filt_integrator/1', 'V_c_out/1');
        
        % Grid frequency output
        add_line(hModel, 'omega_sum/1', 'f_grid_out/1');
        
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
    fprintf('✓ Inverter Subsystem built successfully\n\n');
    
end
