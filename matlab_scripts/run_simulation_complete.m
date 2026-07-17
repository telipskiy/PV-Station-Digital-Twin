%  ========================================================================
%  DIGITAL TWIN: Complete simulation workflow
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-07-14
%  
% Description:
%   Complete workflow for PV Station Digital Twin simulation:
%   1. Initialize all system parameters
%   2. Build enhanced models with proper connections
%   3. Generate 24-hour input profiles
%   4. Run 24-hour simulation
%   5. Perform power quality and energy analysis
%   6. Generate reports
%  ========================================================================

function run_simulation_complete()
    
    clear all; close all; clc;
    
    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║                                                                    ║\n');
    fprintf('║     PV STATION DIGITAL TWIN - Complete Simulation Run             ║\n');
    fprintf('║     PhD-Level Implementation with Full Signal Connections         ║\n');
    fprintf('║                                                                    ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════════╝\n\n');
    
    % ========================================================================
    % SETUP
    % ========================================================================
    
    fprintf('═ STEP 1: Environment Setup ═════════════════════════════════════\n\n');
    
    % Get project root
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(script_dir);
    models_dir = fullfile(project_root, 'simulink_models');
    data_dir = fullfile(project_root, 'data');
    reports_dir = fullfile(project_root, 'reports');
    
    % Create directories
    if ~exist(data_dir, 'dir'), mkdir(data_dir); end
    if ~exist(reports_dir, 'dir'), mkdir(reports_dir); end
    if ~exist(models_dir, 'dir'), mkdir(models_dir); end
    
    % Add paths
    addpath(genpath(fullfile(project_root, 'matlab_scripts')));
    
    fprintf('✓ Project root: %s\n', project_root);
    fprintf('✓ Models directory: %s\n', models_dir);
    fprintf('✓ Data directory: %s\n', data_dir);
    
    % ========================================================================
    % INITIALIZATION
    % ========================================================================
    
    fprintf('\n═ STEP 2: Parameter Initialization ══════════════════════════════\n\n');
    
    % Initialize PV parameters
    init_pv_station_main;  % This loads all system parameters
    
    % ========================================================================
    % MODEL BUILDING
    % ========================================================================
    
    fprintf('\n═ STEP 3: Building Enhanced Models ══════════════════════════════\n\n');
    
    fprintf('Building all subsystems with complete signal connections...\n\n');
    build_all_models_enhanced();  % This builds all enhanced models
    
    % ========================================================================
    % LOAD MODELS
    % ========================================================================
    
    fprintf('\n═ STEP 4: Loading Simulink Models ══════════════════════════════\n\n');
    
    try
        fprintf('Loading Network_Subsystem...\n');
        load_system(fullfile(models_dir, 'Network_Subsystem.slx'));
        
        fprintf('Loading Transformer_Subsystem...\n');
        load_system(fullfile(models_dir, 'Transformer_Subsystem.slx'));
        
        fprintf('Loading Inverter_Subsystem...\n');
        load_system(fullfile(models_dir, 'Inverter_Subsystem.slx'));
        
        fprintf('Loading PV_Array_Subsystem...\n');
        load_system(fullfile(models_dir, 'PV_Array_Subsystem.slx'));
        
        fprintf('Loading PV_Station_Main...\n');
        load_system(fullfile(models_dir, 'PV_Station_Main.slx'));
        
        fprintf('✓ All models loaded successfully\n');
        
    catch ME
        fprintf('✗ Error loading models: %s\n', ME.message);
        return;
    end
    
    % ========================================================================
    % PREPARE SIMULATION INPUTS
    % ========================================================================
    
    fprintf('\n═ STEP 5: Generating 24-Hour Input Profiles ═════════════════════\n\n');
    
    % Generate profiles
    [G_profile, T_profile, Load_profile, t_sim] = generate_24h_profiles();
    
    % Assign to base workspace for Simulink
    assignin('base', 'G_profile', G_profile);
    assignin('base', 'T_profile', T_profile);
    assignin('base', 'Load_profile', Load_profile);
    assignin('base', 't_sim', t_sim);
    
    % ========================================================================
    % CONFIGURE SIMULATION
    % ========================================================================
    
    fprintf('\n═ STEP 6: Configuring Simulation Parameters ══════════════════════\n\n');
    
    % Set simulation time
    sim_time_total = 86400;  % 24 hours in seconds
    
    fprintf('Simulation configuration:\n');
    fprintf('  • Total time: %.0f seconds (24 hours)\n', sim_time_total);
    fprintf('  • Solver: ode45 (variable-step)\n');
    fprintf('  • Start time: 0 s\n');
    fprintf('  • Stop time: %.0f s\n', sim_time_total);
    
    set_param('PV_Station_Main', 'StopTime', sprintf('%g', sim_time_total));
    set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
    
    % ========================================================================
    % RUN SIMULATION
    % ========================================================================
    
    fprintf('\n═ STEP 7: Running 24-Hour Simulation ════════════════════════════\n\n');
    fprintf('WARNING: This simulation may take several minutes on first run.\n');
    fprintf('(Subsequent runs will be faster with Accelerator mode)\n\n');
    
    try
        % Record start time
        sim_start_time = tic;
        
        % Run simulation
        fprintf('▶ Starting simulation...\n');
        sim_output = sim('PV_Station_Main');
        
        % Calculate elapsed time
        sim_elapsed = toc(sim_start_time);
        
        fprintf('✓ Simulation completed in %.2f seconds\n', sim_elapsed);
        
        % Store simulation output
        assignin('base', 'sim_output', sim_output);
        
    catch ME
        fprintf('✗ Simulation error: %s\n', ME.message);
        fprintf('   Stack: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        return;
    end
    
    % ========================================================================
    % POST-PROCESSING & ANALYSIS
    % ========================================================================
    
    fprintf('\n═ STEP 8: Post-Processing & Analysis ════════════════════════════\n\n');
    
    % Extract results from logged data
    if isfield(sim_output, 'P_pv_log') && ~isempty(sim_output.P_pv_log)
        P_pv = sim_output.P_pv_log;
        fprintf('✓ PV power data retrieved\n');
    else
        fprintf('⚠ PV power data not found\n');
    end
    
    if isfield(sim_output, 'P_inv_log') && ~isempty(sim_output.P_inv_log)
        P_inv = sim_output.P_inv_log;
        fprintf('✓ Inverter power data retrieved\n');
    else
        fprintf('⚠ Inverter power data not found\n');
    end
    
    if isfield(sim_output, 'V_pcc_log') && ~isempty(sim_output.V_pcc_log)
        V_pcc = sim_output.V_pcc_log;
        fprintf('✓ PCC voltage data retrieved\n');
    else
        fprintf('⚠ PCC voltage data not found\n');
    end
    
    if isfield(sim_output, 'eta_log') && ~isempty(sim_output.eta_log)
        eta = sim_output.eta_log;
        fprintf('✓ System efficiency data retrieved\n');
    else
        fprintf('⚠ Efficiency data not found\n');
    end
    
    % ========================================================================
    % ENERGY & EFFICIENCY METRICS
    % ========================================================================
    
    fprintf('\n═ STEP 9: Computing Performance Metrics ═════════════════════════\n\n');
    
    % Energy calculations (if data available)
    if exist('P_pv', 'var') && isstruct(P_pv) && isfield(P_pv, 'signals')
        signals = P_pv.signals;
        time_pv = signals(1).values(:, 1);
        power_pv = signals(1).values(:, 2);
        
        % Total energy (trapezoidal integration)
        E_pv = trapz(time_pv, power_pv) / 3.6e6;  % Convert J to kWh
        fprintf('Total PV energy generated: %.2f kWh\n', E_pv);
    end
    
    if exist('P_inv', 'var') && isstruct(P_inv) && isfield(P_inv, 'signals')
        signals = P_inv.signals;
        time_inv = signals(1).values(:, 1);
        power_inv = signals(1).values(:, 2);
        
        E_inv = trapz(time_inv, power_inv) / 3.6e6;  % Convert J to kWh
        fprintf('Total inverter energy output: %.2f kWh\n', E_inv);
        
        % System efficiency
        if exist('E_pv', 'var')
            system_eta = (E_inv / E_pv) * 100;
            fprintf('Overall system efficiency: %.2f %%\n', system_eta);
        end
    end
    
    if exist('V_pcc', 'var') && isstruct(V_pcc) && isfield(V_pcc, 'signals')
        signals = V_pcc.signals;
        if ~isempty(signals) && isfield(signals(1), 'values')
            voltage_dev = signals(1).values(:, 2);
            fprintf('Max voltage deviation: %.2f %%\n', max(abs(voltage_dev)));
            fprintf('Mean voltage deviation: %.4f %%\n', mean(abs(voltage_dev)));
        end
    end
    
    % ========================================================================
    % VISUALIZATION
    % ========================================================================
    
    fprintf('\n═ STEP 10: Generating Visualization & Reports ═══════════════════\n\n');
    
    % Create comprehensive plots
    create_analysis_plots(sim_output, t_sim, reports_dir);
    
    % ========================================================================
    % SAVE RESULTS
    % ========================================================================
    
    fprintf('\n═ STEP 11: Saving Results ═══════════════════════════════════════\n\n');
    
    % Save simulation data
    results_file = fullfile(data_dir, 'simulation_results.mat');
    save(results_file, 'sim_output', 'P_pv', 'P_inv', 'V_pcc', 'eta', '-v7.3');
    fprintf('✓ Results saved to: %s\n', results_file);
    
    % Create summary report
    create_summary_report(reports_dir, sim_output);
    
    % ========================================================================
    % COMPLETION
    % ========================================================================
    
    fprintf('\n╔════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║                                                                    ║\n');
    fprintf('║               ✓ SIMULATION COMPLETED SUCCESSFULLY                 ║\n');
    fprintf('║                                                                    ║\n');
    fprintf('║  Results saved in: %s\n', data_dir);
    fprintf('║  Reports in: %s\n', reports_dir);
    fprintf('║                                                                    ║\n');
    fprintf('║  Next steps:                                                     ║\n');
    fprintf('║  • Review generated plots in %s            ║\n', reports_dir);
    fprintf('║  • Analyze results with MATLAB figures                           ║\n');
    fprintf('║  • Run optimize_topology.m for GA-based optimization             ║\n');
    fprintf('║                                                                    ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════════╝\n\n');
    
end

%% ========================================================================
% Helper: Generate 24-hour profiles
%% ========================================================================

function [G_profile, T_profile, Load_profile, t_sim] = generate_24h_profiles()
    
    % Time vector: 0 to 86400 seconds (24 hours), 1-minute resolution
    t_sim = (0:60:86400)';
    n_points = length(t_sim);
    
    % Hours
    t_hours = t_sim / 3600;
    
    % ========= SOLAR IRRADIANCE ==========
    % Gaussian profile peaking at noon
    t_peak = 12;  % Peak at noon
    G_max = 1000;  % W/m²
    sigma = 6;  % Spread (hours)
    
    G_profile = G_max * exp(-((t_hours - t_peak).^2) / (2 * sigma^2));
    G_profile(G_profile < 5) = 0;  % No generation at night
    G_profile = G_profile + 20 * randn(n_points, 1);  % Add noise
    G_profile(G_profile < 0) = 0;
    
    % For Simulink: [time, values]
    G_profile = [t_sim, G_profile];
    
    % ========= TEMPERATURE ==========
    % Ambient temperature with daily variation
    T_amb = 20 + 10 * sin((t_hours - 6) * pi / 12);
    T_amb(t_hours < 6 | t_hours > 18) = 15;
    
    % Cell temperature rises with irradiance
    G_values = G_profile(:, 2);
    T_cell = T_amb + 0.05 * G_values;
    T_cell(T_cell > 60) = 60;
    
    T_profile = [t_sim, T_cell];
    
    % ========= LOAD ==========
    % Typical daily pattern
    P_load = 5000 + 8000 * sin((t_hours - 6) * pi / 12);
    P_load(t_hours < 6 | t_hours > 18) = 3000;
    P_load(t_hours >= 12 & t_hours <= 14) = P_load(t_hours >= 12 & t_hours <= 14) + 2000;
    P_load(P_load < 0) = 0;
    
    Load_profile = [t_sim, P_load];
    
    fprintf('✓ Solar irradiance: 0-%.0f W/m²\n', max(G_profile(:, 2)));
    fprintf('✓ Temperature: %.0f-%.0f°C\n', min(T_profile(:, 2)), max(T_profile(:, 2)));
    fprintf('✓ Load demand: 0-%.0f W\n', max(Load_profile(:, 2)));
    
end

%% ========================================================================
% Helper: Create analysis plots
%% ========================================================================

function create_analysis_plots(sim_output, t_sim, reports_dir)
    
    t_hours = t_sim / 3600;
    
    figure('Name', 'PV Station Simulation Results', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    
    % Plot 1: Power generation
    if isfield(sim_output, 'P_pv_log')
        subplot(3, 2, 1);
        try
            P_pv = sim_output.P_pv_log;
            if isstruct(P_pv) && isfield(P_pv, 'signals')
                t = P_pv.signals(1).values(:, 1) / 3600;
                P = P_pv.signals(1).values(:, 2) / 1000;
                plot(t, P, 'b-', 'LineWidth', 2);
                grid on;
            end
        catch
            text(0.5, 0.5, 'PV Power data unavailable', 'HorizontalAlignment', 'center');
        end
        xlabel('Time [hours]'); ylabel('Power [kW]');
        title('PV Array Power Output');
    end
    
    % Plot 2: Voltage
    if isfield(sim_output, 'V_pcc_log')
        subplot(3, 2, 2);
        try
            V = sim_output.V_pcc_log;
            if isstruct(V) && isfield(V, 'signals')
                t = V.signals(1).values(:, 1) / 3600;
                V_dev = V.signals(1).values(:, 2);
                plot(t, V_dev, 'r-', 'LineWidth', 1.5);
                grid on;
                yline(3, 'k--', 'Limit');
                yline(-3, 'k--');
            end
        catch
            text(0.5, 0.5, 'Voltage data unavailable', 'HorizontalAlignment', 'center');
        end
        xlabel('Time [hours]'); ylabel('Deviation [%]');
        title('Voltage Deviation at PCC');
    end
    
    % Plot 3: System efficiency
    if isfield(sim_output, 'eta_log')
        subplot(3, 2, 3);
        try
            eta = sim_output.eta_log;
            if isstruct(eta) && isfield(eta, 'signals')
                t = eta.signals(1).values(:, 1) / 3600;
                eff = eta.signals(1).values(:, 2);
                plot(t, eff, 'g-', 'LineWidth', 2);
                grid on;
                ylabel('%');
            end
        catch
            text(0.5, 0.5, 'Efficiency data unavailable', 'HorizontalAlignment', 'center');
        end
        xlabel('Time [hours]'); ylabel('Efficiency [%]');
        title('System Efficiency');
    end
    
    % Empty plots for future metrics
    for i = 4:6
        subplot(3, 2, i);
        text(0.5, 0.5, 'Reserved for future metrics', 'HorizontalAlignment', 'center');
        axis off;
    end
    
    % Save figure
    savefig(fullfile(reports_dir, 'simulation_results.fig'));
    saveas(gcf, fullfile(reports_dir, 'simulation_results.png'));
    fprintf('✓ Plots saved to: %s\n', reports_dir);
    
end

%% ========================================================================
% Helper: Create summary report
%% ========================================================================

function create_summary_report(reports_dir, sim_output)
    
    report_file = fullfile(reports_dir, 'simulation_summary.txt');
    
    fid = fopen(report_file, 'w');
    fprintf(fid, '╔════════════════════════════════════════════════════════════════╗\n');
    fprintf(fid, '║  PV STATION DIGITAL TWIN - 24-HOUR SIMULATION SUMMARY          ║\n');
    fprintf(fid, '║  PhD-Level Implementation                                       ║\n');
    fprintf(fid, '╚════════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf(fid, 'Simulation Date: %s\n\n', datestr(now));
    
    fprintf(fid, 'System Components:\n');
    fprintf(fid, '  • PV Array Subsystem (Single Diode Model with MPPT)\n');
    fprintf(fid, '  • 3-Phase Inverter (VSI with SVM, PLL, Current Control)\n');
    fprintf(fid, '  • Step-Up Transformer (0.4kV/10kV, 63 kVA)\n');
    fprintf(fid, '  • Grid Model (10kV distribution network)\n\n');
    
    fprintf(fid, 'Output Data Available:\n');
    if isfield(sim_output, 'P_pv_log')
        fprintf(fid, '  ✓ PV Power Data\n');
    end
    if isfield(sim_output, 'P_inv_log')
        fprintf(fid, '  ✓ Inverter Power Data\n');
    end
    if isfield(sim_output, 'V_pcc_log')
        fprintf(fid, '  ✓ PCC Voltage Data\n');
    end
    if isfield(sim_output, 'eta_log')
        fprintf(fid, '  ✓ System Efficiency Data\n');
    end
    
    fprintf(fid, '\n\nNext Steps:\n');
    fprintf(fid, '  1. Review plots in reports/ folder\n');
    fprintf(fid, '  2. Run post_processing.m for detailed analysis\n');
    fprintf(fid, '  3. Use optimize_topology.m for GA optimization\n');
    
    fclose(fid);
    fprintf('✓ Summary report saved to: %s\n', report_file);
    
end
