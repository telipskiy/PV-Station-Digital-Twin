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

function run_system()
    
    clear all; 
    close all; 
    clc;

    disp(' ');
    disp('╔═══════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                       ║');
    disp('║            PV STATION DIGITAL TWIN - Complete Simulation Run          ║');
    disp('║                                                                       ║');
    disp('╚═══════════════════════════════════════════════════════════════════════╝');
    
    disp(' ');
    disp('=========================================================================');
    disp('STEP 1: Environment Setup');
    disp('=========================================================================');
    % Initialize folder paths
    project_root = fileparts(fileparts(mfilename('fullpath')));
    init_environment();


    disp(' ');
    disp('=========================================================================');
    disp('STEP 2: Verify Current System');
    disp('=========================================================================');
    test_compatibility();
    
    disp(' ');
    disp('=========================================================================');
    disp('STEP 3: Parameters Initialization');
    disp('=========================================================================');
    % Load all system parameters
    init_pv_station_main();
    
    disp(' ');
    disp('=========================================================================');
    disp('STEP 4: Building Simulink Models');
    disp('=========================================================================');
    % This builds all subsustem models and main model
    build_all_models(); 
    
    disp(' ');
    disp('=========================================================================');
    disp('STEP 5: Loading Simulink Models');
    disp('=========================================================================');
    % Load all created Simulink models
    load_simulink_models();
    
    disp(' ');
    disp('=========================================================================');
    disp('STEP 6: Generating 24-Hour Simulation Input Profile Data');
    disp('=========================================================================');
    % Generate profiles
    init_24h_profiles();

    disp(' ');
    disp('=========================================================================');
    disp('STEP 7: Configuring Simulation Parameters');
    disp('=========================================================================');
    % Set simulation time
    sim_time_total = 86400;  % 24 hours in seconds
    set_param('PV_Station_Main', 'StopTime', sprintf('%g', sim_time_total));
    set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
    
    fprintf('Simulation configuration:\n');
    fprintf('  • Total time: %.0f seconds (24 hours)\n', sim_time_total);
    fprintf('  • Solver: ode45 (variable-step)\n');
    fprintf('  • Start time: 0 s\n');
    fprintf('  • Stop time: %.0f s\n', sim_time_total);

    % =============================================================================
    % RUN SIMULATION
    % =============================================================================
    disp(' ');
    disp('=========================================================================');
    disp('STEP 8: Running 24-Hour Simulation');
    disp('=========================================================================');
    disp('WARNING: This simulation may take several minutes on first run.');
    disp('(Subsequent runs will be faster with Accelerator mode)');
    disp(' ');
    
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
    
    % =============================================================================
    % POST-PROCESSING & ANALYSIS
    % =============================================================================
    disp(' ');
    disp('=========================================================================');
    disp('STEP 9: Post-Processing & Analysis');
    disp('=========================================================================');

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
    
    % =============================================================================
    % ENERGY & EFFICIENCY METRICS
    % =============================================================================
    disp(' ');
    disp('=========================================================================');
    disp('STEP 10: Computing Performance Metrics');
    disp('=========================================================================');
    
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
    
    % =============================================================================
    % VISUALIZATION
    % =============================================================================
    disp(' ');
    disp('=========================================================================');
    disp('STEP 11: Generating Visualization & Reports');
    disp('=========================================================================');

    % Create comprehensive plots
    reports_dir = fullfile(project_root, 'reports');
    create_analysis_plots(sim_output, t_sim, reports_dir);
    
    % =============================================================================
    % SAVE RESULTS
    % =============================================================================
    disp(' ');
    disp('=========================================================================');
    disp('STEP 12: Saving Results');
    disp('=========================================================================');
    
    % Save simulation data
    data_dir = fullfile(project_root, 'data');
    results_file = fullfile(data_dir, 'simulation_results.mat');
    save(results_file, 'sim_output', 'P_pv', 'P_inv', 'V_pcc', 'eta', '-v7.3');
    fprintf('✓ Results saved to: %s\n', results_file);
    
    % Create summary report
    create_summary_report(reports_dir, sim_output);
    
    % ========================================================================
    % COMPLETION
    % ========================================================================
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║                 ✓ SIMULATION COMPLETED SUCCESSFULLY                ║');
    disp('║                                                                    ║');
    disp('║  Results saved in Data folder                                      ║');
    disp('║  Reports saved in Reports filder                                   ║');
    disp('║                                                                    ║');
    disp('║  Next steps:                                                       ║');
    disp('║  • Review generated plots in Reports                               ║');
    disp('║  • Analyze results with MATLAB figures                             ║');
    disp('║  • Run optimize_topology.m for GA-based optimization               ║');
    disp('║                                                                    ║');
    disp('╚════════════════════════════════════════════════════════════════════╝');
    disp(' ');
    
end
