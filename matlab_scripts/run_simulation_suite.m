%% ========================================================================
%  RUN SIMULATION SUITE - MULTI-CONFIGURATION EXPERIMENT RUNNER
%  ========================================================================
%  PhD Research: Digital Twin for PV Station Design
%  Purpose: Execute multiple simulation scenarios and accumulate results
%  Date: 2025
%  ========================================================================

function results_table = run_simulation_suite()

    % Load initialization parameters
    if ~exist('pv_station_parameters.mat', 'file')
        init_pv_station_main;
    end
    load('pv_station_parameters.mat');
    
    disp(' ');
    disp('=========================================================================');
    disp('SIMULATION SUITE RUNNER');
    disp('Parametric Study of PV Station Configurations');
    disp('=========================================================================');
    disp(' ');
    
    % ====================================================================
    % 1. DEFINE SCENARIO MATRIX (Design of Experiments)
    % ====================================================================
    
    % Parameter ranges for parametric study
    scenarios.ns_values = [5, 10, 15, 20];              % Series modules
    scenarios.np_values = [2, 5, 10, 15];               % Parallel strings
    scenarios.Pinv_values = [25e3, 50e3, 75e3, 100e3];  % Inverter power [W]
    scenarios.topology_values = [1, 2, 3];              % 1=String, 2=Multi-String, 3=Central
    
    % Generate all combinations
    [ns_grid, np_grid, Pinv_grid, top_grid] = ndgrid(...
        scenarios.ns_values, scenarios.np_values, scenarios.Pinv_values, scenarios.topology_values);
    
    n_scenarios = numel(ns_grid);
    disp(sprintf('Total Scenarios: %d', n_scenarios));
    disp('(Parametric study of all combinations)');
    disp(' ');
    
    % ====================================================================
    % 2. PRE-ALLOCATE RESULTS TABLE
    % ====================================================================
    
    results_table = table();
    scenario_count = 0;
    
    % ====================================================================
    % 3. EXECUTE SIMULATION FOR EACH SCENARIO
    % ====================================================================
    
    h_waitbar = waitbar(0, 'Running simulations...');
    
    for idx = 1:n_scenarios
        
        % Update waitbar
        waitbar(idx/n_scenarios, h_waitbar, ...
            sprintf('Simulation %d of %d', idx, n_scenarios));
        
        % Extract scenario parameters
        n_s = ns_grid(idx);
        n_p = np_grid(idx);
        P_inv = Pinv_grid(idx);
        topology = top_grid(idx);
        
        % ================================================================
        % 3.1 CONFIGURE SIMULINK MODEL
        % ================================================================
        
        try
            % Update PV configuration
            PV.ns_current = n_s;
            PV.np_current = n_p;
            PV.Pfield_current = PV.Pmax_stc * n_s * n_p;
            
            % Update inverter configuration
            INV.P_rated_current = P_inv;
            
            % Topology mapping
            topology_names = {'String', 'Multi-String', 'Central'};
            topology_name = topology_names{topology};
            
            % Save current configuration to workspace
            set_param('PV_Station_Main', 'SimulationCommand', 'update');
            assignin('base', 'PV_config', PV);
            assignin('base', 'INV_config', INV);
            assignin('base', 'topology_type', topology);
            
            % ============================================================
            % 3.2 RUN SINGLE SIMULATION
            % ============================================================
            
            % Simulation options
            simIn = Simulink.SimulationInput('PV_Station_Main');
            simIn = setVariable(simIn, 'PV_config', PV);
            simIn = setVariable(simIn, 'INV_config', INV);
            simIn = setVariable(simIn, 'topology_type', topology);
            simIn = setVariable(simIn, 'SOLAR_profile', SOLAR.G_profile);
            simIn = setVariable(simIn, 'LOAD_profile', LOAD.P_demand);
            
            % Execute simulation
            try
                simOut = sim(simIn);
                
                % ========================================================
                % 3.3 EXTRACT RESULTS
                % ========================================================
                
                % Time vector
                t = simOut.tout;
                
                % Electrical signals (from simulation output)
                P_pv = simOut.yout.P_pv.Data;
                V_pv = simOut.yout.V_pv.Data;
                I_pv = simOut.yout.I_pv.Data;
                
                P_grid = simOut.yout.P_grid.Data;
                Q_grid = simOut.yout.Q_grid.Data;
                I_grid = simOut.yout.I_grid.Data;
                V_grid = simOut.yout.V_grid.Data;
                
                P_loss_cable = simOut.yout.P_loss_cable.Data;
                THD_current = simOut.yout.THD_current.Data;
                V_deviation = simOut.yout.V_deviation.Data;
                
                % ========================================================
                % 3.4 CALCULATE METRICS
                % ========================================================
                
                % Annual energy production [kWh]
                E_annual = trapz(t, P_pv) / 3.6e6;  % Convert J to kWh
                
                % Annual energy losses [kWh]
                W_loss_annual = trapz(t, P_loss_cable) / 3.6e6;
                
                % System efficiency [%]
                efficiency_sys = 100 * (1 - W_loss_annual / E_annual);
                
                % Inverter efficiency (estimated)
                efficiency_inv = mean(P_grid(P_pv > 0.1*max(P_pv)) ./ ...
                    P_pv(P_pv > 0.1*max(P_pv)));
                efficiency_inv = 100 * min(efficiency_inv, 1);
                
                % PV efficiency (estimated)
                G_mean = mean(SOLAR.G_profile);
                if G_mean > 0
                    efficiency_pv = 100 * mean(P_pv(SOLAR.G_profile > 100)) ./ ...
                        (SOLAR.G_profile(SOLAR.G_profile > 100) * ...
                        PV.ns_current * PV.np_current * PV.Pmax_stc / 1000);
                    efficiency_pv = min(efficiency_pv, 25);  % PV cells ~15-22%
                else
                    efficiency_pv = 0;
                end
                
                % Power quality metrics
                THD_avg = mean(THD_current(THD_current > 0));
                V_dev_max = max(abs(V_deviation));
                
                % Capacity factor [%]
                capacity_factor = 100 * E_annual / (PV.ns_current * PV.np_current * ...
                    PV.Pmax_stc / 1000 * 24 * 365);
                
                % Levelized Cost of Energy (LCOE) [$/kWh]
                C_cap_scenario = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS);
                LCOE = (C_cap_scenario + ECONOMICS.annual_opex_rate * C_cap_scenario * ...
                    ECONOMICS.study_period) / (E_annual * ECONOMICS.study_period);
                
                % System reliability (SAIDI - System Average Interruption Duration Index)
                SAIDI = calculate_saidi(n_s, n_p, P_inv, topology);
                
                % ========================================================
                % 3.5 STORE RESULTS
                % ========================================================
                
                scenario_count = scenario_count + 1;
                
                new_row = table(...
                    scenario_count, ...
                    n_s, ...
                    n_p, ...
                    P_inv/1000, ...
                    topology, ...
                    topology_name, ...
                    E_annual, ...
                    W_loss_annual, ...
                    efficiency_sys, ...
                    efficiency_pv, ...
                    efficiency_inv, ...
                    THD_avg, ...
                    V_dev_max, ...
                    capacity_factor, ...
                    LCOE, ...
                    SAIDI, ...
                    C_cap_scenario, ...
                    'VariableNames', {...
                        'Scenario_ID', 'n_s', 'n_p', 'P_inv_kW', 'Topology_ID', ...
                        'Topology_Name', 'E_annual_kWh', 'W_loss_kWh', 'Efficiency_percent', ...
                        'Efficiency_PV_percent', 'Efficiency_INV_percent', 'THD_avg_percent', ...
                        'V_deviation_max_percent', 'Capacity_Factor_percent', 'LCOE_USD_kWh', ...
                        'SAIDI_hours_year', 'Capital_Cost_USD'});
                
                results_table = [results_table; new_row];
                
            catch sim_error
                warning(sprintf('Simulation failed for scenario %d: %s', idx, sim_error.message));
                continue;
            end
            
        catch config_error
            warning(sprintf('Configuration failed for scenario %d: %s', idx, config_error.message));
            continue;
        end
        
    end
    
    close(h_waitbar);
    
    % ====================================================================
    % 4. SAVE RESULTS TO FILE
    % ====================================================================
    
    writetable(results_table, 'simulation_results.csv');
    writetable(results_table, 'simulation_results.xlsx');
    save('simulation_results.mat', 'results_table');
    
    disp(' ');
    disp('=========================================================================');
    disp('SIMULATION SUITE COMPLETE');
    disp('=========================================================================');
    disp(sprintf('Total Scenarios Simulated: %d', scenario_count));
    disp(sprintf('Results saved to: simulation_results.csv'));
    disp(sprintf('Results saved to: simulation_results.xlsx'));
    disp(sprintf('Results saved to: simulation_results.mat'));
    disp(' ');
    
    % ====================================================================
    % 5. DISPLAY SUMMARY STATISTICS
    % ====================================================================
    
    display_summary_statistics(results_table);
    
    % ====================================================================
    % 6. CREATE VISUALIZATION
    % ====================================================================
    
    create_results_visualization(results_table);

end

%% ========================================================================
% HELPER FUNCTION: CALCULATE CAPITAL COST
% ========================================================================

function C_cap = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS)
    
    % Assuming typical costs (USD)
    C_PV = 500;         % $/kW
    C_INV = 300;        % $/kW
    C_TR = 50;          % $/kVA (rough estimate)
    C_CABLE = 200;      % $/km
    
    P_pv_kw = 0.350 * n_s * n_p;  % 350W modules
    S_tr_kva = max(P_inv, P_pv_kw * 1000) / 1000;
    L_cable = 0.5;  % km
    
    C_cap = P_pv_kw * C_PV + (P_inv/1000) * C_INV + S_tr_kva * C_TR + ...
        L_cable * C_CABLE;
    C_cap = C_cap * 1.2;  % Add 20% for installation
    
end

%% ========================================================================
% HELPER FUNCTION: CALCULATE SAIDI (RELIABILITY)
% ========================================================================

function SAIDI = calculate_saidi(n_s, n_p, P_inv, topology)
    
    % Simplified SAIDI calculation
    % SAIDI = System Average Interruption Duration Index [hours/year]
    
    % Base failure rates
    lambda_string = 0.001;  % Failures per year per string
    lambda_inv = 0.002;     % Failures per year per inverter
    
    r_string = 2;           % Mean repair time [hours]
    r_inv = 4;              % Mean repair time [hours]
    
    % System SAIDI depends on topology
    switch topology
        case 1  % String topology: series failure
            SAIDI = lambda_string * n_p * r_string;
        case 2  % Multi-string: parallel fault tolerance
            SAIDI = lambda_string * r_string;
        case 3  % Central: single point of failure
            SAIDI = lambda_inv * r_inv;
    end
    
    % Add some randomness
    SAIDI = SAIDI * (0.8 + 0.4*rand);
    
end

%% ========================================================================
% HELPER FUNCTION: DISPLAY SUMMARY STATISTICS
% ========================================================================

function display_summary_statistics(results_table)
    
    disp(' ');
    disp('SUMMARY STATISTICS');
    disp('---');
    
    fprintf('Number of Scenarios: %d\n', height(results_table));
    fprintf('Average Annual Energy: %.1f kWh\n', mean(results_table.E_annual_kWh));
    fprintf('Average System Efficiency: %.2f %%\n', mean(results_table.Efficiency_percent));
    fprintf('Average LCOE: $%.3f/kWh\n', mean(results_table.LCOE_USD_kWh));
    fprintf('Average Capacity Factor: %.2f %%\n', mean(results_table.Capacity_Factor_percent));
    fprintf('Average SAIDI: %.2f hours/year\n', mean(results_table.SAIDI_hours_year));
    
    disp(' ');
    disp('TOP 5 SCENARIOS BY EFFICIENCY:');
    [~, idx_eff] = sort(results_table.Efficiency_percent, 'descend');
    top_eff = results_table(idx_eff(1:min(5, height(results_table))), ...
        {'Scenario_ID', 'n_s', 'n_p', 'Efficiency_percent', 'LCOE_USD_kWh'});
    disp(top_eff);
    
    disp(' ');
    disp('TOP 5 SCENARIOS BY LCOE:');
    [~, idx_lcoe] = sort(results_table.LCOE_USD_kWh, 'ascend');
    top_lcoe = results_table(idx_lcoe(1:min(5, height(results_table))), ...
        {'Scenario_ID', 'n_s', 'n_p', 'LCOE_USD_kWh', 'Efficiency_percent'});
    disp(top_lcoe);
    
end

%% ========================================================================
% HELPER FUNCTION: CREATE RESULTS VISUALIZATION
% ========================================================================

function create_results_visualization(results_table)
    
    figure('Position', [100 100 1600 1000]);
    
    % Plot 1: Efficiency vs LCOE
    subplot(2,3,1);
    scatter(results_table.LCOE_USD_kWh, results_table.Efficiency_percent, ...
        100, results_table.Capacity_Factor_percent, 'filled');
    xlabel('LCOE ($/kWh)'); ylabel('Efficiency (%)');
    title('Efficiency vs LCOE (color = Capacity Factor)');
    colorbar;
    grid on;
    
    % Plot 2: Energy Production Distribution
    subplot(2,3,2);
    histogram(results_table.E_annual_kWh, 20);
    xlabel('Annual Energy (kWh)'); ylabel('Frequency');
    title('Distribution of Annual Energy Production');
    grid on;
    
    % Plot 3: LCOE by Topology
    subplot(2,3,3);
    topology_names = {'String', 'Multi-String', 'Central'};
    for i = 1:3
        idx = results_table.Topology_ID == i;
        lcoe_by_topo{i} = results_table.LCOE_USD_kWh(idx);
    end
    boxplot(lcoe_by_topo, 'Labels', topology_names);
    ylabel('LCOE ($/kWh)');
    title('LCOE Distribution by Topology');
    grid on;
    
    % Plot 4: Efficiency vs Series Modules
    subplot(2,3,4);
    scatter(results_table.n_s, results_table.Efficiency_percent, 50, 'b');
    xlabel('Number of Series Modules'); ylabel('Efficiency (%)');
    title('System Efficiency vs Series Modules');
    grid on;
    
    % Plot 5: SAIDI Reliability
    subplot(2,3,5);
    scatter(results_table.P_inv_kW, results_table.SAIDI_hours_year, 50, 'r');
    xlabel('Inverter Power (kW)'); ylabel('SAIDI (hours/year)');
    title('System Reliability vs Inverter Power');
    grid on;
    
    % Plot 6: Summary metrics
    subplot(2,3,6);
    metrics = {...
        sprintf('Avg Efficiency: %.2f%%', mean(results_table.Efficiency_percent)); ...
        sprintf('Avg LCOE: $%.3f/kWh', mean(results_table.LCOE_USD_kWh)); ...
        sprintf('Avg Capacity Factor: %.2f%%', mean(results_table.Capacity_Factor_percent)); ...
        sprintf('Avg SAIDI: %.2f hr/yr', mean(results_table.SAIDI_hours_year))};
    text(0.1, 0.9, metrics{1}, 'FontSize', 11);
    text(0.1, 0.7, metrics{2}, 'FontSize', 11);
    text(0.1, 0.5, metrics{3}, 'FontSize', 11);
    text(0.1, 0.3, metrics{4}, 'FontSize', 11);
    axis off;
    
    savefig('simulation_results_overview.fig');
    saveas(gcf, 'simulation_results_overview.png');
    
end
