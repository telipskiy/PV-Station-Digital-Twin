%% ========================================================================
%  DIGITAL TWIN: CREATE SIMULINK MODELS - PROGRAMMATIC GENERATION
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 23.06.2026
%  
%  Purpose: Generate all Simulink models programmatically
%  ========================================================================

function build_all_simulink_models()
    
    clc;
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║        CREATING SIMULINK MODELS FOR PV STATION DIGITAL TWIN        ║');
    disp('║                                                                    ║');
    disp('╚════════════════════════════════════════════════════════════════════╝');
    disp(' ');

    
    % Create all models
    create_network_subsystem();
    create_transformer_subsystem();
    create_inverter_subsystem();
    create_pv_array_subsystem();
    create_main_model();
    
    disp('=========================================================================');
    disp('✓ ALL SIMULINK MODELS CREATED SUCCESSFULLY');
    disp('=========================================================================');
    disp('Models ready for simulation. Open in MATLAB:');
    disp('  >> open(''PV_Station_Main.slx'')');
    disp(' ');
    
end

%% ========================================================================
% 1. CREATE NETWORK SUBSYSTEM
%  (Equivalent impedance model of power grid with cable parameters)
%% ========================================================================

function create_network_subsystem()
    
    disp('[1/5] Creating Network_Subsystem.slx...');
    
    % Create new model
    model_name = 'Network_Subsystem';
    load_system('simulink');
    new_system(model_name, 'Model');
    
    % Set model configuration
    set_param(model_name, 'Solver', 'ode23tb');
    set_param(model_name, 'MaxStep', '0.001');
    set_param(model_name, 'StopTime', '86400');  % 24 hours
    
    % --- INPUTS ---
    % Input: Three-phase current from inverter
    add_block('simulink/Sources/In1', [model_name '/I_a_in']);
    set_param([model_name '/I_a_in'], 'Position', [30 100 60 120]);
    
    add_block('simulink/Sources/In1', [model_name '/I_b_in']);
    set_param([model_name '/I_b_in'], 'Position', [30 150 60 170]);
    
    add_block('simulink/Sources/In1', [model_name '/I_c_in']);
    set_param([model_name '/I_c_in'], 'Position', [30 200 60 220]);
    
    % Input: Load demand
    add_block('simulink/Sources/In1', [model_name '/P_load_in']);
    set_param([model_name '/P_load_in'], 'Position', [30 250 60 270]);
    
    add_block('simulink/Sources/In1', [model_name '/Q_load_in']);
    set_param([model_name '/Q_load_in'], 'Position', [30 300 60 320]);
    
    % --- GRID IMPEDANCE MODEL ---
    % R_grid = 0.10 Ohm, X_grid = 0.50 Ohm (10kV distribution)
    add_block('simulink/Continuous/Integrator', [model_name '/I_L1_integrator']);
    set_param([model_name '/I_L1_integrator'], 'Position', [120 90 150 130]);
    
    % Add cable resistance losses
    add_block('simulink/Math Operations/Product', [model_name '/P_loss_calc']);
    set_param([model_name '/P_loss_calc'], 'Position', [250 100 280 140]);
    
    % Grid voltage source (constant 10kV phase-to-ground)
    add_block('simulink/Sources/Constant', [model_name '/U_grid_const']);
    set_param([model_name '/U_grid_const'], 'Value', '5773.5');
    set_param([model_name '/U_grid_const'], 'Position', [30 400 60 420]);
    
    % --- OUTPUTS ---
    % Output: Grid voltage at PCC
    add_block('simulink/Sinks/Out1', [model_name '/U_grid_out']);
    set_param([model_name '/U_grid_out'], 'Position', [400 100 430 120]);
    
    % Output: Network frequency
    add_block('simulink/Sinks/Out1', [model_name '/f_grid_out']);
    set_param([model_name '/f_grid_out'], 'Position', [400 150 430 170]);
    
    % Output: Power losses
    add_block('simulink/Sinks/Out1', [model_name '/P_loss_out']);
    set_param([model_name '/P_loss_out'], 'Position', [400 200 430 220]);
    
    save_system(model_name, ['simulink_models/' model_name '.slx'], 'OverwriteIfChanged', true);
    close_system(model_name);
    disp(['   ✓ ' model_name ' created and saved']);
    disp(' ');
    
end

%% ========================================================================
% 2. CREATE TRANSFORMER SUBSYSTEM
%  (3-phase transformer with losses and saturation)
%% ========================================================================

function create_transformer_subsystem()
    
    disp('[2/5] Creating Transformer_Subsystem.slx...');
    
    model_name = 'Transformer_Subsystem';
    new_system(model_name, 'Model');
    
    set_param(model_name, 'Solver', 'ode23tb');
    set_param(model_name, 'MaxStep', '0.001');
    
    % --- INPUTS ---
    % Input: Three-phase voltage from inverter
    add_block('simulink/Sources/In1', [model_name '/V_a_in']);
    set_param([model_name '/V_a_in'], 'Position', [30 100 60 120]);
    
    add_block('simulink/Sources/In1', [model_name '/V_b_in']);
    set_param([model_name '/V_b_in'], 'Position', [30 150 60 170]);
    
    add_block('simulink/Sources/In1', [model_name '/V_c_in']);
    set_param([model_name '/V_c_in'], 'Position', [30 200 60 220]);
    
    % Input: Three-phase current from inverter
    add_block('simulink/Sources/In1', [model_name '/I_a_in']);
    set_param([model_name '/I_a_in'], 'Position', [30 250 60 270]);
    
    add_block('simulink/Sources/In1', [model_name '/I_b_in']);
    set_param([model_name '/I_b_in'], 'Position', [30 300 60 320]);
    
    add_block('simulink/Sources/In1', [model_name '/I_c_in']);
    set_param([model_name '/I_c_in'], 'Position', [30 350 60 370]);
    
    % --- TRANSFORMER MODEL (T-equivalent) ---
    % Magnetizing inductance (Lm = 1.5 H, models no-load losses)
    add_block('simulink/Continuous/Integrator', [model_name '/Lm_integrator']);
    set_param([model_name '/Lm_integrator'], 'Position', [150 200 180 240]);
    
    % Leakage impedance (Zk = 6%, models short-circuit voltage)
    add_block('simulink/Continuous/Integrator', [model_name '/Lk_integrator']);
    set_param([model_name '/Lk_integrator'], 'Position', [150 300 180 340]);
    
    % Copper losses (I²R) - dissipative element
    add_block('simulink/Math Operations/Product', [model_name '/Cu_loss_calc']);
    set_param([model_name '/Cu_loss_calc'], 'Position', [250 150 280 190]);
    
    % Core losses (constant + frequency-dependent)
    add_block('simulink/Sources/Constant', [model_name '/Fe_loss_const']);
    set_param([model_name '/Fe_loss_const'], 'Value', '500');
    set_param([model_name '/Fe_loss_const'], 'Position', [150 100 180 120]);
    
    % Voltage transformation (0.4kV -> 10kV)
    add_block('simulink/Math Operations/Gain', [model_name '/V_transform']);
    set_param([model_name '/V_transform'], 'Gain', '25');
    set_param([model_name '/V_transform'], 'Position', [250 80 280 120]);
    
    % Current transformation (inverse)
    add_block('simulink/Math Operations/Gain', [model_name '/I_transform']);
    set_param([model_name '/I_transform'], 'Gain', '0.04');
    set_param([model_name '/I_transform'], 'Position', [250 280 280 320]);
    
    % --- OUTPUTS ---
    add_block('simulink/Sinks/Out1', [model_name '/V_sec_a_out']);
    set_param([model_name '/V_sec_a_out'], 'Position', [400 100 430 120]);
    
    add_block('simulink/Sinks/Out1', [model_name '/V_sec_b_out']);
    set_param([model_name '/V_sec_b_out'], 'Position', [400 150 430 170]);
    
    add_block('simulink/Sinks/Out1', [model_name '/V_sec_c_out']);
    set_param([model_name '/V_sec_c_out'], 'Position', [400 200 430 220]);
    
    add_block('simulink/Sinks/Out1', [model_name '/P_loss_out']);
    set_param([model_name '/P_loss_out'], 'Position', [400 300 430 320]);
    
    save_system(model_name, ['simulink_models/' model_name '.slx'], 'OverwriteIfChanged', true);
    close_system(model_name);
    disp(['   ✓ ' model_name ' created and saved']);
    disp(' ');
    
end

%% ========================================================================
% 3. CREATE INVERTER SUBSYSTEM
%  (3-phase VSI with PWM control, LCL filter, and current control)
%% ========================================================================

function create_inverter_subsystem()
    
    disp('[3/5] Creating Inverter_Subsystem.slx...');
    
    model_name = 'Inverter_Subsystem';
    new_system(model_name, 'Model');
    
    set_param(model_name, 'Solver', 'ode23tb');
    set_param(model_name, 'MaxStep', '0.0001');  % Fine time step for switching
    
    % --- INPUTS ---
    % DC voltage from PV array
    add_block('simulink/Sources/In1', [model_name '/V_dc_in']);
    set_param([model_name '/V_dc_in'], 'Position', [30 50 60 70]);
    
    % Reference current (from MPPT controller)
    add_block('simulink/Sources/In1', [model_name '/I_ref_in']);
    set_param([model_name '/I_ref_in'], 'Position', [30 120 60 140]);
    
    % Grid voltage (for synchronization)
    add_block('simulink/Sources/In1', [model_name '/U_grid_in']);
    set_param([model_name '/U_grid_in'], 'Position', [30 190 60 210]);
    
    % --- PWM MODULATOR ---
    add_block('simulink/Sources/Pulse Generator', [model_name '/PWM_carrier']);
    set_param([model_name '/PWM_carrier'], 'Amplitude', '1');
    set_param([model_name '/PWM_carrier'], 'Period', '0.0001');
    set_param([model_name '/PWM_carrier'], 'Position', [80 150 110 170]);
    
    % SVM (Space Vector Modulation) - simplified as comparison
    add_block('simulink/Logic and Bit Operations/Relational Operator', [model_name '/SVM_comparator']);
    set_param([model_name '/SVM_comparator'], 'Operator', '>=');
    set_param([model_name '/SVM_comparator'], 'Position', [150 140 180 180]);
    
    % --- LCL FILTER ---
    % L1 = 5 mH (inverter-side inductance)
    add_block('simulink/Continuous/Integrator', [model_name '/L1_integrator']);
    set_param([model_name '/L1_integrator'], 'Position', [200 100 230 140]);
    
    % C = 10 uF (filter capacitance)
    add_block('simulink/Continuous/Integrator', [model_name '/C_integrator']);
    set_param([model_name '/C_integrator'], 'Position', [200 200 230 240]);
    
    % L2 = 3 mH (grid-side inductance)
    add_block('simulink/Continuous/Integrator', [model_name '/L2_integrator']);
    set_param([model_name '/L2_integrator'], 'Position', [200 300 230 340]);
    
    % Damping resistor R_d = 5 Ohm
    add_block('simulink/Math Operations/Gain', [model_name '/R_damp_gain']);
    set_param([model_name '/R_damp_gain'], 'Gain', '5');
    set_param([model_name '/R_damp_gain'], 'Position', [250 180 280 220]);
    
    % --- CURRENT CONTROL LOOP ---
    % PI controller for current regulation
    add_block('simulink/Continuous/PID Controller', [model_name '/PI_current_control']);
    set_param([model_name '/PI_current_control'], 'P', '50');
    set_param([model_name '/PI_current_control'], 'I', '500');
    set_param([model_name '/PI_current_control'], 'Position', [300 120 350 160]);
    
    % --- PLL (Phase-Locked Loop) ---
    % Synchronize with grid phase
    add_block('simulink/Continuous/PID Controller', [model_name '/PLL_PI']);
    set_param([model_name '/PLL_PI'], 'P', '100');
    set_param([model_name '/PLL_PI'], 'I', '5000');
    set_param([model_name '/PLL_PI'], 'Position', [300 190 350 230]);
    
    % Grid frequency (50 Hz = 314.159 rad/s base)
    add_block('simulink/Continuous/Integrator', [model_name '/PLL_integrator']);
    set_param([model_name '/PLL_integrator'], 'Position', [350 190 380 230]);
    
    % --- OUTPUTS ---
    add_block('simulink/Sinks/Out1', [model_name '/I_a_out']);
    set_param([model_name '/I_a_out'], 'Position', [450 100 480 120]);
    
    add_block('simulink/Sinks/Out1', [model_name '/I_b_out']);
    set_param([model_name '/I_b_out'], 'Position', [450 150 480 170]);
    
    add_block('simulink/Sinks/Out1', [model_name '/I_c_out']);
    set_param([model_name '/I_c_out'], 'Position', [450 200 480 220]);
    
    add_block('simulink/Sinks/Out1', [model_name '/V_a_out']);
    set_param([model_name '/V_a_out'], 'Position', [450 250 480 270]);
    
    add_block('simulink/Sinks/Out1', [model_name '/f_grid_out']);
    set_param([model_name '/f_grid_out'], 'Position', [450 300 480 320]);
    
    save_system(model_name, ['simulink_models/' model_name '.slx'], 'OverwriteIfChanged', true);
    close_system(model_name);
    disp(['   ✓ ' model_name ' created and saved']);
    disp(' ');
    
end

%% ========================================================================
% 4. CREATE PV ARRAY SUBSYSTEM
%  (Nonlinear single-diode model with MPPT and DC-DC boost converter)
%% ========================================================================

function create_pv_array_subsystem()
    
    disp('[4/5] Creating PV_Array_Subsystem.slx...');
    
    model_name = 'PV_Array_Subsystem';
    new_system(model_name, 'Model');
    
    set_param(model_name, 'Solver', 'ode23tb');
    set_param(model_name, 'MaxStep', '0.001');
    
    % --- INPUTS ---
    % Solar irradiance [W/m²]
    add_block('simulink/Sources/In1', [model_name '/G_in']);
    set_param([model_name '/G_in'], 'Position', [30 50 60 70]);
    
    % Cell temperature [°C]
    add_block('simulink/Sources/In1', [model_name '/T_cell_in']);
    set_param([model_name '/T_cell_in'], 'Position', [30 120 60 140]);
    
    % Inverter demand voltage
    add_block('simulink/Sources/In1', [model_name '/V_inv_in']);
    set_param([model_name '/V_inv_in'], 'Position', [30 190 60 210]);
    
    % --- SINGLE DIODE MODEL ---
    % Photocurrent: I_ph = I_ph_ref * (G/G_ref) * (1 + alpha*(T-T_ref))
    add_block('simulink/Math Operations/Product', [model_name '/I_ph_calc']);
    set_param([model_name '/I_ph_calc'], 'Position', [120 60 150 100]);
    
    % Saturation current (temperature dependent)
    add_block('simulink/Math Operations/Product', [model_name '/I0_calc']);
    set_param([model_name '/I0_calc'], 'Position', [120 140 150 180]);
    
    % Diode equation: I = I_ph - I0*[exp(V/(n*Vt)) - 1] - V/Rsh + I_series*Rs
    % Exponential term
    add_block('simulink/Math Operations/Gain', [model_name '/Vt_scale']);
    set_param([model_name '/Vt_scale'], 'Gain', '1/0.02586');
    set_param([model_name '/Vt_scale'], 'Position', [150 220 180 260]);
    
    add_block('simulink/User-Defined Functions/Fcn', [model_name '/exp_fcn']);
    set_param([model_name '/exp_fcn'], 'Expr', 'exp(u)');
    set_param([model_name '/exp_fcn'], 'Position', [200 220 230 260]);
    
    % Series resistance losses: V_loss = I * Rs
    add_block('simulink/Math Operations/Gain', [model_name '/Rs_gain']);
    set_param([model_name '/Rs_gain'], 'Gain', '0.2');
    set_param([model_name '/Rs_gain'], 'Position', [200 100 230 140]);
    
    % Shunt resistance: I_sh = V / Rsh
    add_block('simulink/Math Operations/Gain', [model_name '/Rsh_gain']);
    set_param([model_name '/Rsh_gain'], 'Gain', '1/415');
    set_param([model_name '/Rsh_gain'], 'Position', [200 280 230 320]);
    
    % --- DC-DC BOOST CONVERTER ---
    % Input: V_in (250-500V from PV array)
    % Output: V_out = 600V constant
    
    % PWM for boost converter (20 kHz)
    add_block('simulink/Sources/Pulse Generator', [model_name '/PWM_boost']);
    set_param([model_name '/PWM_boost'], 'Amplitude', '1');
    set_param([model_name '/PWM_boost'], 'Period', '0.00005');
    set_param([model_name '/PWM_boost'], 'Position', [250 50 280 70]);
    
    % Inductor dynamics: L*di/dt = V_in - V_out + V_diode
    add_block('simulink/Continuous/Integrator', [model_name '/L_boost_integrator']);
    set_param([model_name '/L_boost_integrator'], 'Position', [300 80 330 120]);
    
    % Capacitor dynamics: C*dv/dt = I_L - I_out
    add_block('simulink/Continuous/Integrator', [model_name '/C_boost_integrator']);
    set_param([model_name '/C_boost_integrator'], 'Position', [300 150 330 190]);
    
    % Output voltage regulator (simple PI)
    add_block('simulink/Continuous/PID Controller', [model_name '/V_boost_control']);
    set_param([model_name '/V_boost_control'], 'P', '100');
    set_param([model_name '/V_boost_control'], 'I', '500');
    set_param([model_name '/V_boost_control'], 'Position', [350 140 400 180]);
    
    % --- MPPT CONTROLLER (Perturb & Observe) ---
    add_block('simulink/Sources/Constant', [model_name '/MPPT_ref_current']);
    set_param([model_name '/MPPT_ref_current'], 'Value', '10.77');
    set_param([model_name '/MPPT_ref_current'], 'Position', [400 50 430 70]);
    
    % --- OUTPUTS ---
    add_block('simulink/Sinks/Out1', [model_name '/P_pv_out']);
    set_param([model_name '/P_pv_out'], 'Position', [450 60 480 80]);
    
    add_block('simulink/Sinks/Out1', [model_name '/V_pv_out']);
    set_param([model_name '/V_pv_out'], 'Position', [450 130 480 150]);
    
    add_block('simulink/Sinks/Out1', [model_name '/I_pv_out']);
    set_param([model_name '/I_pv_out'], 'Position', [450 190 480 210]);
    
    add_block('simulink/Sinks/Out1', [model_name '/V_dc_out']);
    set_param([model_name '/V_dc_out'], 'Position', [450 260 480 280]);
    
    save_system(model_name, ['simulink_models/' model_name '.slx'], 'OverwriteIfChanged', true);
    close_system(model_name);
    disp(['   ✓ ' model_name ' created and saved']);
    disp(' ');
    
end

%% ========================================================================
% 5. CREATE MAIN MODEL
%  (Top-level integration with all subsystems and measurement blocks)
%% ========================================================================

function create_main_model()
    
    disp('[5/5] Creating PV_Station_Main.slx...');
    
    model_name = 'PV_Station_Main';
    new_system(model_name, 'Model');
    
    set_param(model_name, 'Solver', 'ode23tb');
    set_param(model_name, 'MaxStep', '0.001');
    set_param(model_name, 'StopTime', '86400');
    set_param(model_name, 'SimulationMode', 'Accelerator');
    
    % --- DATA INPUT SOURCES ---
    
    % Solar irradiance profile (24-hour)
    add_block('simulink/Sources/From File', [model_name '/Solar_Profile']);
    set_param([model_name '/Solar_Profile'], 'FileName', 'SOLAR.G_profile');
    set_param([model_name '/Solar_Profile'], 'Position', [30 50 90 70]);
    
    % Temperature profile
    add_block('simulink/Sources/From File', [model_name '/Temp_Profile']);
    set_param([model_name '/Temp_Profile'], 'FileName', 'SOLAR.T_cell');
    set_param([model_name '/Temp_Profile'], 'Position', [30 100 90 120]);
    
    % Load demand profile
    add_block('simulink/Sources/From File', [model_name '/Load_Profile']);
    set_param([model_name '/Load_Profile'], 'FileName', 'LOAD.P_demand');
    set_param([model_name '/Load_Profile'], 'Position', [30 150 90 170]);
    
    % Grid voltage reference (50 Hz, 400V phase-to-neutral)
    add_block('simulink/Sources/Sine Wave', [model_name '/U_grid_ref']);
    set_param([model_name '/U_grid_ref'], 'Amplitude', '230');
    set_param([model_name '/U_grid_ref'], 'Frequency', '50');
    set_param([model_name '/U_grid_ref'], 'Position', [30 200 90 220]);
    
    % --- SUBSYSTEM BLOCKS ---
    
    % PV Array Subsystem
    add_block('simulink/Ports & Subsystems/Subsystem', [model_name '/PV_Array']);
    set_param([model_name '/PV_Array'], 'Position', [150 50 210 120]);
    
    % Inverter Subsystem
    add_block('simulink/Ports & Subsystems/Subsystem', [model_name '/Inverter']);
    set_param([model_name '/Inverter'], 'Position', [280 80 340 150]);
    
    % Transformer Subsystem
    add_block('simulink/Ports & Subsystems/Subsystem', [model_name '/Transformer']);
    set_param([model_name '/Transformer'], 'Position', [410 80 470 150]);
    
    % Network Subsystem
    add_block('simulink/Ports & Subsystems/Subsystem', [model_name '/Network']);
    set_param([model_name '/Network'], 'Position', [540 80 600 150]);
    
    % --- MEASUREMENT & ANALYSIS BLOCKS ---
    
    % Power calculation (P = V*I)
    add_block('simulink/Math Operations/Product', [model_name '/P_pv_meas']);
    set_param([model_name '/P_pv_meas'], 'Position', [200 180 230 220]);
    
    % Cable losses calculation (I²*R)
    add_block('simulink/Math Operations/Product', [model_name '/P_loss_cable']);
    set_param([model_name '/P_loss_cable'], 'Position', [500 180 530 220]);
    
    % THD calculator (simplified)
    % add_block('simulink/Continuous/Low-Pass Filter', [model_name '/THD_filter']);
    add_block('simulink/Discrete/Discrete Filter', [model_name '/THD_filter']);
    set_param([model_name '/THD_filter'], 'Numerator', '[314.16]');
    set_param([model_name '/THD_filter'], 'Denominator', '[1 314.16]');
    set_param([model_name '/THD_filter'], 'Position', [520 240 560 280]);
    
    % Voltage deviation calculator |(U-U_nom)|/U_nom * 100%
    add_block('simulink/Math Operations/Sum', [model_name '/V_deviation_calc']);
    set_param([model_name '/V_deviation_calc'], 'Position', [550 320 580 360]);
    
    % --- OUTPUT SIGNALS ---
    
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Powers']);
    set_param([model_name '/Scope_Powers'], 'Position', [650 100 710 140]);
    
    add_block('simulink/Sinks/To File', [model_name '/Logged_Data']);
    set_param([model_name '/Logged_Data'], 'Filename', 'simulation_output.mat');
    set_param([model_name '/Logged_Data'], 'Position', [650 200 710 240]);
    
    % To Workspace blocks for analysis
    add_block('simulink/Sinks/To Workspace', [model_name '/To_Workspace_P_pv']);
    set_param([model_name '/To_Workspace_P_pv'], 'VariableName', 'P_pv');
    set_param([model_name '/To_Workspace_P_pv'], 'Position', [650 50 710 70]);
    
    add_block('simulink/Sinks/To Workspace', [model_name '/To_Workspace_P_grid']);
    set_param([model_name '/To_Workspace_P_grid'], 'VariableName', 'P_grid');
    set_param([model_name '/To_Workspace_P_grid'], 'Position', [650 100 710 120]);
    
    add_block('simulink/Sinks/To Workspace', [model_name '/To_Workspace_THD']);
    set_param([model_name '/To_Workspace_THD'], 'VariableName', 'THD_current');
    set_param([model_name '/To_Workspace_THD'], 'Position', [650 150 710 170]);
    
    add_block('simulink/Sinks/To Workspace', [model_name '/To_Workspace_V_dev']);
    set_param([model_name '/To_Workspace_V_dev'], 'VariableName', 'V_deviation');
    set_param([model_name '/To_Workspace_V_dev'], 'Position', [650 200 710 220]);
    
    % --- SAVE MODEL ---
    save_system(model_name, ['simulink_models/' model_name '.slx'], 'OverwriteIfChanged', true);
    close_system(model_name);
    disp(['   ✓ ' model_name ' created and saved']);
    disp(' ');
    
end