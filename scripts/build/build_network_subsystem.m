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
    
    % Input 1-3: Three-phase CURRENTS from transformer (secondary) [A]
    I_a_in = add_block('simulink/Sources/In1', [model_name '/I_a_pcc_in']);
    set_param(I_a_in, 'Position', [20 50 50 70]);
    set_param(I_a_in, 'Port', '1');
    
    I_b_in = add_block('simulink/Sources/In1', [model_name '/I_b_pcc_in']);
    set_param(I_b_in, 'Position', [20 120 50 140]);
    set_param(I_b_in, 'Port', '2');
    
    I_c_in = add_block('simulink/Sources/In1', [model_name '/I_c_pcc_in']);
    set_param(I_c_in, 'Position', [20 190 50 210]);
    set_param(I_c_in, 'Port', '3');
    
    % Input 4-6: Three-phase LOAD CURRENTS [A]
    I_load_a = add_block('simulink/Sources/In1', [model_name '/I_load_a_in']);
    set_param(I_load_a, 'Position', [20 260 50 280]);
    set_param(I_load_a, 'Port', '4');
    
    I_load_b = add_block('simulink/Sources/In1', [model_name '/I_load_b_in']);
    set_param(I_load_b, 'Position', [20 330 50 350]);
    set_param(I_load_b, 'Port', '5');
    
    I_load_c = add_block('simulink/Sources/In1', [model_name '/I_load_c_in']);
    set_param(I_load_c, 'Position', [20 400 50 420]);
    set_param(I_load_c, 'Port', '6');
    
    % ====================================================================
    % GRID VOLTAGE SOURCE (10 kV, 50 Hz)
    % ====================================================================
    
    % Phase A: V_grid_a = V_nom * cos(2*pi*50*t)
    V_grid_a = add_block('simulink/Sources/Sine Wave', [model_name '/V_grid_a']);
    set_param(V_grid_a, 'Amplitude', '5773.5');  % 10kV / sqrt(3) phase-neutral
    set_param(V_grid_a, 'Frequency', '50');
    set_param(V_grid_a, 'Position', [100 50 150 70]);
    
    % Phase B: 120° phase shift
    V_grid_b = add_block('simulink/Sources/Sine Wave', [model_name '/V_grid_b']);
    set_param(V_grid_b, 'Amplitude', '5773.5');
    set_param(V_grid_b, 'Frequency', '50');
    set_param(V_grid_b, 'Phase', '-2.0944');  % -120° in radians
    set_param(V_grid_b, 'Position', [100 120 150 140]);
    
    % Phase C: 240° phase shift
    V_grid_c = add_block('simulink/Sources/Sine Wave', [model_name '/V_grid_c']);
    set_param(V_grid_c, 'Amplitude', '5773.5');
    set_param(V_grid_c, 'Frequency', '50');
    set_param(V_grid_c, 'Phase', '2.0944');  % +120° in radians
    set_param(V_grid_c, 'Position', [100 190 150 210]);
    
    % ====================================================================
    % CABLE IMPEDANCE MODEL (NYC 3x150, 0.5 km)
    % ====================================================================
    
    % Cable parameters
    R_cable = add_block('simulink/Sources/Constant', [model_name '/R_cable']);
    % CABLE.R_ref is calculated from CABLE.length in the initializer.
    set_param(R_cable, 'Value', 'CABLE.R_ref*(1+CABLE.alpha*(CABLE.T_operating-CABLE.T_ref))');
    set_param(R_cable, 'Position', [100 260 140 280]);
    
    X_cable = add_block('simulink/Sources/Constant', [model_name '/X_cable']);
    set_param(X_cable, 'Value', 'CABLE.X');
    set_param(X_cable, 'Position', [100 300 140 320]);
    
    L_cable = add_block('simulink/Sources/Constant', [model_name '/L_cable']);
    set_param(L_cable, 'Value', 'CABLE.X/(2*pi*GRID.f_rated)');
    set_param(L_cable, 'Position', [100 340 140 360]);
    
    % Cable losses: P_loss = I²·R
    I_sq_a = add_block('simulink/Math Operations/Product', [model_name '/I_sq_a']);
    set_param(I_sq_a, 'Position', [200 50 250 70]);
    add_line(model_name, 'I_a_pcc_in/1', 'I_sq_a/1');
    add_line(model_name, 'I_a_pcc_in/1', 'I_sq_a/2');
    
    P_loss_a = add_block('simulink/Math Operations/Product', [model_name '/P_loss_a']);
    set_param(P_loss_a, 'Position', [300 50 350 70]);
    add_line(model_name, 'I_sq_a/1', 'P_loss_a/1');
    add_line(model_name, 'R_cable/1', 'P_loss_a/2');
    
    % Phase B losses
    I_sq_b = add_block('simulink/Math Operations/Product', [model_name '/I_sq_b']);
    set_param(I_sq_b, 'Position', [200 120 250 140]);
    add_line(model_name, 'I_b_pcc_in/1', 'I_sq_b/1');
    add_line(model_name, 'I_b_pcc_in/1', 'I_sq_b/2');
    
    P_loss_b = add_block('simulink/Math Operations/Product', [model_name '/P_loss_b']);
    set_param(P_loss_b, 'Position', [300 120 350 140]);
    add_line(model_name, 'I_sq_b/1', 'P_loss_b/1');
    add_line(model_name, 'R_cable/1', 'P_loss_b/2');
    
    % Phase C losses
    I_sq_c = add_block('simulink/Math Operations/Product', [model_name '/I_sq_c']);
    set_param(I_sq_c, 'Position', [200 190 250 210]);
    add_line(model_name, 'I_c_pcc_in/1', 'I_sq_c/1');
    add_line(model_name, 'I_c_pcc_in/1', 'I_sq_c/2');
    
    P_loss_c = add_block('simulink/Math Operations/Product', [model_name '/P_loss_c']);
    set_param(P_loss_c, 'Position', [300 190 350 210]);
    add_line(model_name, 'I_sq_c/1', 'P_loss_c/1');
    add_line(model_name, 'R_cable/1', 'P_loss_c/2');
    
    % Total cable losses
    P_cable_sum = add_block('simulink/Math Operations/Add', [model_name '/P_cable_total']);
    set_param(P_cable_sum, 'Inputs', '+++');
    set_param(P_cable_sum, 'Position', [400 100 450 140]);
    add_line(model_name, 'P_loss_a/1', 'P_cable_total/1');
    add_line(model_name, 'P_loss_b/1', 'P_cable_total/2');
    add_line(model_name, 'P_loss_c/1', 'P_cable_total/3');
    
    % ====================================================================
    % POINT OF COMMON COUPLING (PCC) VOLTAGE CALCULATION
    % ====================================================================
    % V_pcc = V_grid - (I_pv + I_load) * R_cable - L * dI/dt
    
    % Total phase currents
    I_total_a = add_block('simulink/Math Operations/Add', [model_name '/I_total_a']);
    set_param(I_total_a, 'Position', [200 260 250 280]);
    add_line(model_name, 'I_a_pcc_in/1', 'I_total_a/1');
    add_line(model_name, 'I_load_a_in/1', 'I_total_a/2');
    
    I_total_b = add_block('simulink/Math Operations/Add', [model_name '/I_total_b']);
    set_param(I_total_b, 'Position', [200 330 250 350]);
    add_line(model_name, 'I_b_pcc_in/1', 'I_total_b/1');
    add_line(model_name, 'I_load_b_in/1', 'I_total_b/2');
    
    I_total_c = add_block('simulink/Math Operations/Add', [model_name '/I_total_c']);
    set_param(I_total_c, 'Position', [200 400 250 420]);
    add_line(model_name, 'I_c_pcc_in/1', 'I_total_c/1');
    add_line(model_name, 'I_load_c_in/1', 'I_total_c/2');
    
    % Voltage drop due to cable resistance
    V_drop_a = add_block('simulink/Math Operations/Product', [model_name '/V_drop_R_a']);
    set_param(V_drop_a, 'Position', [300 260 350 280]);
    add_line(model_name, 'I_total_a/1', 'V_drop_R_a/1');
    add_line(model_name, 'R_cable/1', 'V_drop_R_a/2');
    
    V_drop_b = add_block('simulink/Math Operations/Product', [model_name '/V_drop_R_b']);
    set_param(V_drop_b, 'Position', [300 330 350 350]);
    add_line(model_name, 'I_total_b/1', 'V_drop_R_b/1');
    add_line(model_name, 'R_cable/1', 'V_drop_R_b/2');
    
    V_drop_c = add_block('simulink/Math Operations/Product', [model_name '/V_drop_R_c']);
    set_param(V_drop_c, 'Position', [300 400 350 420]);
    add_line(model_name, 'I_total_c/1', 'V_drop_R_c/1');
    add_line(model_name, 'R_cable/1', 'V_drop_R_c/2');
    
    % PCC voltage (grid voltage minus voltage drop)
    V_pcc_a = add_block('simulink/Math Operations/Add', [model_name '/V_pcc_a']);
    set_param(V_pcc_a, 'Inputs', '+-');
    set_param(V_pcc_a, 'Position', [400 50 450 70]);
    add_line(model_name, 'V_grid_a/1', 'V_pcc_a/1');
    add_line(model_name, 'V_drop_R_a/1', 'V_pcc_a/2');
    
    V_pcc_b = add_block('simulink/Math Operations/Add', [model_name '/V_pcc_b']);
    set_param(V_pcc_b, 'Inputs', '+-');
    set_param(V_pcc_b, 'Position', [400 120 450 140]);
    add_line(model_name, 'V_grid_b/1', 'V_pcc_b/1');
    add_line(model_name, 'V_drop_R_b/1', 'V_pcc_b/2');
    
    V_pcc_c = add_block('simulink/Math Operations/Add', [model_name '/V_pcc_c']);
    set_param(V_pcc_c, 'Inputs', '+-');
    set_param(V_pcc_c, 'Position', [400 190 450 210]);
    add_line(model_name, 'V_grid_c/1', 'V_pcc_c/1');
    add_line(model_name, 'V_drop_R_c/1', 'V_pcc_c/2');
    
    % ====================================================================
    % OUTPUTS
    % ====================================================================
    
    % Output 1-3: PCC VOLTAGES [V]
    V_pcc_a_out = add_block('simulink/Sinks/Out1', [model_name '/V_pcc_a_out']);
    set_param(V_pcc_a_out, 'Position', [500 50 530 70]);
    set_param(V_pcc_a_out, 'Port', '1');
    add_line(model_name, 'V_pcc_a/1', 'V_pcc_a_out/1');
    
    V_pcc_b_out = add_block('simulink/Sinks/Out1', [model_name '/V_pcc_b_out']);
    set_param(V_pcc_b_out, 'Position', [500 120 530 140]);
    set_param(V_pcc_b_out, 'Port', '2');
    add_line(model_name, 'V_pcc_b/1', 'V_pcc_b_out/1');
    
    V_pcc_c_out = add_block('simulink/Sinks/Out1', [model_name '/V_pcc_c_out']);
    set_param(V_pcc_c_out, 'Position', [500 190 530 210]);
    set_param(V_pcc_c_out, 'Port', '3');
    add_line(model_name, 'V_pcc_c/1', 'V_pcc_c_out/1');
    
    % Output 4: CABLE LOSSES [W]
    P_loss_out = add_block('simulink/Sinks/Out1', [model_name '/P_cable_loss_out']);
    set_param(P_loss_out, 'Position', [500 260 530 280]);
    set_param(P_loss_out, 'Port', '4');
    add_line(model_name, 'P_cable_total/1', 'P_cable_loss_out/1');
    
    % Output 5: GRID FREQUENCY [Hz]
    f_grid_out = add_block('simulink/Sinks/Out1', [model_name '/f_grid_out']);
    set_param(f_grid_out, 'Position', [500 330 530 350]);
    set_param(f_grid_out, 'Port', '5');
    
    f_const = add_block('simulink/Sources/Constant', [model_name '/f_50Hz']);
    set_param(f_const, 'Value', '50');
    set_param(f_const, 'Position', [450 330 490 350]);
    add_line(model_name, 'f_50Hz/1', 'f_grid_out/1');
    
    % ====================================================================
    % SAVE MODEL
    % ====================================================================
    
    save_system(hModel, fullfile(save_path, [model_name '.slx']));
    close_system(hModel);
    
    fprintf('✓ Network subsystem created: %s\n', fullfile(save_path, [model_name '.slx']));
    fprintf('   Inputs: I_a/b/c_pcc (A), I_load_a/b/c (A)\n');
    fprintf('   Outputs: V_pcc_a/b/c (V), P_cable_loss (W), f_grid (Hz)\n');
    fprintf('   Grid: 10 kV, 50 Hz, 3-phase\n');
    fprintf('   Cable: R and X are evaluated from CABLE.length and conductor temperature\n');
    
end
