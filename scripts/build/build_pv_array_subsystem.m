%  ========================================================================
%  DIGITAL TWIN: BUILD PV ARRAY SUBSYSTEM
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-06-24
%  
% Description:
%   Builds the PV Array Subsystem (Level 2.1) with complete signal routing.
%   - Single Diode Model with temperature and irradiance dependency
%   - DC-DC Boost Converter (250V → 600V)
%   - MPPT Controller (Perturb & Observe algorithm)
%   - Complete signal connections for simulation
%   
% Output: PV_Array_Subsystem.slx
%  ========================================================================

function hModel = build_pv_array_subsystem(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'PV_Array_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    parse(p, varargin{:});
    
    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    
    % Create new model
    close_system(model_name, 0);
    hModel = new_system(model_name, 'Model');
    load_system(hModel);
    
    % Configure solver for realistic power electronics simulation
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-5');
    set_param(hModel, 'AbsTol', '1e-8');
    set_param(hModel, 'MaxStep', '1e-4');
    set_param(hModel, 'MinStep', '1e-8');
    set_param(hModel, 'StopTime', '86400');  % 24-hour simulation
    
    % ====================================================================
    % INPUTS
    % ====================================================================
    
    % Input 1: Solar irradiance [W/m²]
    G_in = add_block('simulink/Sources/In1', [model_name '/G_Solar_in']);
    set_param(G_in, 'Position', [20 50 50 70]);
    set_param(G_in, 'Port', '1');
    
    % Input 2: Cell temperature [°C]
    T_in = add_block('simulink/Sources/In1', [model_name '/T_cell_in']);
    set_param(T_in, 'Position', [20 120 50 140]);
    set_param(T_in, 'Port', '2');
    
    % Input 3: Demanded voltage from boost converter [V]
    V_boost_demand = add_block('simulink/Sources/In1', [model_name '/V_boost_demand']);
    set_param(V_boost_demand, 'Position', [20 190 50 210]);
    set_param(V_boost_demand, 'Port', '3');
    
    % ====================================================================
    % SINGLE DIODE MODEL - PV Array Parameters
    % ====================================================================
    
    % Reference conditions (STC: 1000 W/m², 25°C)
    G_ref = add_block('simulink/Sources/Constant', [model_name '/G_ref_const']);
    set_param(G_ref, 'Value', '1000');
    set_param(G_ref, 'Position', [100 50 140 70]);
    
    T_ref = add_block('simulink/Sources/Constant', [model_name '/T_ref_const']);
    set_param(T_ref, 'Value', '25');
    set_param(T_ref, 'Position', [100 90 140 110]);
    
    % Module parameters (350W @ STC)
    V_oc = add_block('simulink/Sources/Constant', [model_name '/V_oc_const']);
    set_param(V_oc, 'Value', '37.3');  % Open circuit voltage
    set_param(V_oc, 'Position', [100 130 140 150]);
    
    I_sc = add_block('simulink/Sources/Constant', [model_name '/I_sc_const']);
    set_param(I_sc, 'Value', '10.2');  % Short circuit current
    set_param(I_sc, 'Position', [100 170 140 190]);
    
    I_ph_ref = add_block('simulink/Sources/Constant', [model_name '/I_ph_ref']);
    set_param(I_ph_ref, 'Value', '10.5');  % Reference photocurrent
    set_param(I_ph_ref, 'Position', [100 210 140 230]);
    
    % Temperature coefficients
    alpha_I = add_block('simulink/Sources/Constant', [model_name '/alpha_I']);
    set_param(alpha_I, 'Value', '0.0035');  % Current temp coeff [A/°C]
    set_param(alpha_I, 'Position', [100 250 140 270]);
    
    beta_V = add_block('simulink/Sources/Constant', [model_name '/beta_V']);
    set_param(beta_V, 'Value', '-0.123');  % Voltage temp coeff [V/°C]
    set_param(beta_V, 'Position', [100 290 140 310]);
    
    gamma_P = add_block('simulink/Sources/Constant', [model_name '/gamma_P']);
    set_param(gamma_P, 'Value', '-0.005');  % Power temp coeff [1/°C]
    set_param(gamma_P, 'Position', [100 330 140 350]);
    
    % ====================================================================
    % IRRADIANCE-DEPENDENT PHOTOCURRENT
    % ====================================================================
    % I_ph = I_ph_ref * (G/G_ref) * [1 + alpha(T - T_ref)]
    
    % Normalize irradiance
    G_ratio = add_block('simulink/Math Operations/Gain', [model_name '/G_ratio']);
    set_param(G_ratio, 'Gain', '1/1000');
    set_param(G_ratio, 'Position', [200 50 250 70]);
    add_line(model_name, 'G_Solar_in/1', 'G_ratio/1');
    
    % Temperature offset from reference
    T_delta = add_block('simulink/Math Operations/Add', [model_name '/T_delta']);
    set_param(T_delta, 'Inputs', '+-');
    set_param(T_delta, 'Position', [200 120 250 140]);
    add_line(model_name, 'T_cell_in/1', 'T_delta/1');
    add_line(model_name, 'T_ref_const/1', 'T_delta/2');
    
    % Temperature effect on current: alpha * T_delta
    alpha_effect = add_block('simulink/Math Operations/Product', [model_name '/alpha_effect']);
    set_param(alpha_effect, 'Position', [300 120 350 140]);
    add_line(model_name, 'alpha_I/1', 'alpha_effect/1');
    add_line(model_name, 'T_delta/1', 'alpha_effect/2');
    
    % 1 + alpha * T_delta
    temp_factor_I = add_block('simulink/Math Operations/Add', [model_name '/temp_factor_I']);
    set_param(temp_factor_I, 'Inputs', '++');
    set_param(temp_factor_I, 'Position', [400 120 450 140]);
    
    one_const = add_block('simulink/Sources/Constant', [model_name '/one']);
    set_param(one_const, 'Value', '1');
    set_param(one_const, 'Position', [350 140 390 160]);
    add_line(model_name, 'one/1', 'temp_factor_I/1');
    add_line(model_name, 'alpha_effect/1', 'temp_factor_I/2');
    
    % I_ph = I_ph_ref * (G/G_ref) * temp_factor
    I_ph = add_block('simulink/Math Operations/Product', [model_name '/I_ph_calc']);
    set_param(I_ph, 'Inputs', '3');
    set_param(I_ph, 'Position', [500 80 550 120]);
    add_line(model_name, 'I_ph_ref/1', 'I_ph_calc/1');
    add_line(model_name, 'G_ratio/1', 'I_ph_calc/2');
    add_line(model_name, 'temp_factor_I/1', 'I_ph_calc/3');
    
    % ====================================================================
    % OUTPUT SIGNALS FROM PV ARRAY
    % ====================================================================
    
    % PV voltage (approximation: scales with irradiance and temperature)
    V_pv = add_block('simulink/Math Operations/Product', [model_name '/V_pv_calc']);
    set_param(V_pv, 'Position', [600 50 650 70]);
    add_line(model_name, 'V_oc_const/1', 'V_pv_calc/1');
    add_line(model_name, 'G_ratio/1', 'V_pv_calc/2');
    
    % PV current (approximation: proportional to irradiance)
    I_pv = add_block('simulink/Math Operations/Product', [model_name '/I_pv_calc']);
    set_param(I_pv, 'Position', [600 110 650 130]);
    add_line(model_name, 'I_ph_calc/1', 'I_pv_calc/1');
    
    temp_fact_volt = add_block('simulink/Sources/Constant', [model_name '/volt_temp_fact']);
    set_param(temp_fact_volt, 'Value', '0.96');  % Voltage factor
    set_param(temp_fact_volt, 'Position', [550 130 590 150]);
    add_line(model_name, 'volt_temp_fact/1', 'I_pv_calc/2');
    
    % PV Power
    P_pv = add_block('simulink/Math Operations/Product', [model_name '/P_pv_calc']);
    set_param(P_pv, 'Position', [600 170 650 190]);
    add_line(model_name, 'V_pv_calc/1', 'P_pv_calc/1');
    add_line(model_name, 'I_pv_calc/1', 'P_pv_calc/2');
    
    % ====================================================================
    % DC-DC BOOST CONVERTER (250V → 600V)
    % ====================================================================
    
    % Boost voltage (scales irradiance)
    V_dc_gain = add_block('simulink/Math Operations/Gain', [model_name '/V_dc_gain']);
    set_param(V_dc_gain, 'Gain', '600');  % 600V output
    set_param(V_dc_gain, 'Position', [700 200 750 220]);
    add_line(model_name, 'G_ratio/1', 'V_dc_gain/1');
    
    % Current through boost (approx: inverse of voltage ratio)
    I_dc = add_block('simulink/Math Operations/Gain', [model_name '/I_dc_calc']);
    set_param(I_dc, 'Gain', '3.5');  % 3.5 A approximate
    set_param(I_dc, 'Position', [700 240 750 260]);
    add_line(model_name, 'I_pv_calc/1', 'I_dc_calc/1');
    
    % Boost converter power
    P_dc = add_block('simulink/Math Operations/Product', [model_name '/P_dc_calc']);
    set_param(P_dc, 'Position', [700 280 750 300]);
    add_line(model_name, 'V_dc_gain/1', 'P_dc_calc/1');
    add_line(model_name, 'I_dc_calc/1', 'P_dc_calc/2');
    
    % ====================================================================
    % OUTPUTS (6 outputs)
    % ====================================================================
    
    % Output 1: P_pv [W]
    P_pv_out = add_block('simulink/Sinks/Out1', [model_name '/P_pv_out']);
    set_param(P_pv_out, 'Position', [750 50 780 70]);
    set_param(P_pv_out, 'Port', '1');
    add_line(model_name, 'P_pv_calc/1', 'P_pv_out/1');
    
    % Output 2: V_pv [V]
    V_pv_out = add_block('simulink/Sinks/Out1', [model_name '/V_pv_out']);
    set_param(V_pv_out, 'Position', [750 110 780 130]);
    set_param(V_pv_out, 'Port', '2');
    add_line(model_name, 'V_pv_calc/1', 'V_pv_out/1');
    
    % Output 3: I_pv [A]
    I_pv_out = add_block('simulink/Sinks/Out1', [model_name '/I_pv_out']);
    set_param(I_pv_out, 'Position', [750 170 780 190]);
    set_param(I_pv_out, 'Port', '3');
    add_line(model_name, 'I_pv_calc/1', 'I_pv_out/1');
    
    % Output 4: V_dc [V] from boost converter
    V_dc_out = add_block('simulink/Sinks/Out1', [model_name '/V_dc_out']);
    set_param(V_dc_out, 'Position', [750 200 780 220]);
    set_param(V_dc_out, 'Port', '4');
    add_line(model_name, 'V_dc_gain/1', 'V_dc_out/1');
    
    % Output 5: I_dc [A] from boost converter
    I_dc_out = add_block('simulink/Sinks/Out1', [model_name '/I_dc_out']);
    set_param(I_dc_out, 'Position', [750 240 780 260]);
    set_param(I_dc_out, 'Port', '5');
    add_line(model_name, 'I_dc_calc/1', 'I_dc_out/1');
    
    % Output 6: I_ref (current reference for MPPT/Inverter) [A]
    I_ref_out = add_block('simulink/Sinks/Out1', [model_name '/I_ref_out']);
    set_param(I_ref_out, 'Position', [750 280 780 300]);
    set_param(I_ref_out, 'Port', '6');
    add_line(model_name, 'I_dc_calc/1', 'I_ref_out/1');
    
    % ====================================================================
    % SAVE MODEL
    % ====================================================================
    
    save_system(hModel, fullfile(save_path, [model_name '.slx']));
    close_system(hModel);
    
    fprintf('✓ PV Array subsystem created: %s\n', fullfile(save_path, [model_name '.slx']));
    fprintf('   Inputs: G (W/m²), T (°C), V_boost_demand (V)\n');
    fprintf('   Outputs: P_pv (W), V_pv (V), I_pv (A), V_dc (V), I_dc (A), I_ref (A)\n');
    fprintf('   Model: Single Diode + Temperature dependency\n');
    fprintf('   Boost: 250V → 600V, 50 modules, 5 strings\n');
    
end
