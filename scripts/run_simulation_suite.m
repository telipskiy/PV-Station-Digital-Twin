%  ========================================================================
%  DIGITAL TWIN: PV STATION - MULTI-CONFIGURATION EXPERIMENT RUNNER
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 24.07.2026
%  
%  Purpose: Execute multiple simulation scenarios and accumulate results
%
% DESCRIPTION:
%    This function runs parametric simulations for various PV station
%    configurations. It performs a Design of Experiments (DoE) study by:
%    - Generating all combinations of configuration parameters
%    - Running Simulink simulations for each configuration
%    - Extracting key performance metrics (energy, losses, efficiency, LCOE)
%    - Saving results to CSV and MAT files for post-processing
%
%  INPUTS:
%    None (loads parameters from 'pv_station_parameters.mat')
%
%  OUTPUTS:
%    results_table - Table with columns:
%      * Scenario_ID: Unique scenario identifier
%      * n_s, n_p: PV array configuration
%      * P_inv_kW: Inverter power rating
%      * Topology_ID: System topology variant
%      * E_annual_kWh: Annual energy generation
%      * W_loss_kWh: Annual energy losses
%      * Efficiency_percent: Overall system efficiency
%      * LCOE_USD_kWh: Levelized Cost of Energy
%      * Capital_Cost_USD: Total capital investment
%
%  USAGE:
%    >> results = run_simulation_suite();
%    >> plot(results.E_annual_kWh, results.LCOE_USD_kWh, 'o');
%
%  FILES CREATED:
%    - simulation_results.csv (Excel-compatible table)
%    - simulation_results.mat (MATLAB format)
%  ========================================================================

function results_table = run_simulation_suite()

    % Load initialization parameters - All system parameters must be loaded
    % before simulations can run. Parameters include electrical specs,
    % economic data, and simulation settings.
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
    % Purpose: Create parameter ranges for parametric study. Each parameter
    % represents a design decision that affects system cost and performance.
    % All combinations will be evaluated (factorial design).
    
    % Parameter ranges for parametric study
    % - n_s: Series modules affect voltage (higher = more voltage, less current)
    % - n_p: Parallel strings affect current (higher = more current, less voltage)
    % - P_inv: Inverter sizing (undersizing = losses, oversizing = cost)
    % - Topology: Different system architectures (1=string, 2=multi-string, 3=central)
    % ====================================================================
    
    % Parameter ranges for parametric study
    scenarios.ns_values = [5, 10, 15, 20];
    scenarios.np_values = [2, 5, 10, 15];
    scenarios.Pinv_values = [25e3, 50e3, 75e3, 100e3];
    scenarios.topology_values = [1, 2, 3];
    
    % Generate all combinations using ndgrid (creates Cartesian product)
    % Example: 4 × 4 × 4 × 3 = 192 total scenarios
    [ns_grid, np_grid, Pinv_grid, top_grid] = ndgrid(...
        scenarios.ns_values, scenarios.np_values, scenarios.Pinv_values, scenarios.topology_values);
    
    n_scenarios = numel(ns_grid);
    fprintf('Total Scenarios: %d\n', n_scenarios);
    
    results_table = table();
    scenario_count = 0;
    
    % ====================================================================
    % 2. EXECUTE SIMULATION FOR EACH SCENARIO
    % Purpose: Loop through all configurations and run Simulink simulations.
    % Errors are caught gracefully to continue with remaining scenarios.
    % ====================================================================
    
    h_waitbar = waitbar(0, 'Running simulations...');
    
    for idx = 1:n_scenarios
        waitbar(idx/n_scenarios, h_waitbar, sprintf('Simulation %d of %d', idx, n_scenarios));
        
        n_s = ns_grid(idx);
        n_p = np_grid(idx);
        P_inv = Pinv_grid(idx);
        topology = top_grid(idx);
        
        try
            % Update PV configuration for this scenario
            PV.ns_current = n_s;
            PV.np_current = n_p;
            PV.Pfield_current = PV.Pmax_stc * n_s * n_p;
            INV.P_rated_current = P_inv;
            
            % Create simulation input object and configure variables
            % Simulink.SimulationInput allows programmatic simulation setup
            simIn = Simulink.SimulationInput('PV_Station_Main');
            simIn = setVariable(simIn, 'PV_config', PV);
            simIn = setVariable(simIn, 'INV_config', INV);
            
            % Run simulation - returns logged signals in simOut structure
            simOut = sim(simIn);
            
            % Extract performance metrics from simulation results
            t = simOut.tout;                                % Time vector
            P_pv = simOut.yout.P_pv.Data;                   % PV power output [W]
            P_loss_cable = simOut.yout.P_loss_cable.Data;   % Cable losses [W]

            % Calculate annual energy metrics using trapezoidal integration
            % Note: This is approximated from 24-hour simulation
            E_annual = trapz(t, P_pv) / 3.6e6;                      % Energy [kWh]
            W_loss_annual = trapz(t, P_loss_cable) / 3.6e6;         % Losses [kWh]
            efficiency_sys = 100 * (1 - W_loss_annual / E_annual);  % Efficiency [%]
            
            % Calculate economic metrics
            C_cap_scenario = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS);
            % LCOE = (Capital + Operating Costs) / Annual Energy
            % Annualized over study period using discount rate
            LCOE = (C_cap_scenario + ECONOMICS.annual_opex_rate * C_cap_scenario * ECONOMICS.study_period) / (E_annual * ECONOMICS.study_period);
            
            scenario_count = scenario_count + 1;
            
            % Create result row with all metrics
            new_row = table(scenario_count, n_s, n_p, P_inv/1000, topology, ...
                E_annual, W_loss_annual, efficiency_sys, LCOE, C_cap_scenario, ...
                'VariableNames', {'Scenario_ID', 'n_s', 'n_p', 'P_inv_kW', 'Topology_ID', ...
                'E_annual_kWh', 'W_loss_kWh', 'Efficiency_percent', 'LCOE_USD_kWh', 'Capital_Cost_USD'});
            
            % Append to results table
            results_table = [results_table; new_row];
            
        catch sim_error
            % If simulation fails, log warning and continue (robust execution)
            warning('Simulation failed for scenario %d', idx);
            continue;
        end
    end
    
    close(h_waitbar);
    
    % Save results to files for post-processing and archival
    writetable(results_table, 'simulation_results.csv');
    save('simulation_results.mat', 'results_table');
    
    disp('=========================================================================');
    fprintf('Scenarios Simulated: %d\n', scenario_count);
    disp('Results saved to: simulation_results.csv');
    disp('=========================================================================');

end

% ========================================================================
% CALCULATE CAPITAL COST
% Purpose: Estimate total capital investment for given configuration.
% Includes PV modules, inverters, transformer, and balance of system.
%
% INPUTS:
%   n_s, n_p - Array configuration (modules in series/parallel)
%   P_inv - Inverter power rating [W]
%   ECONOMICS - Cost data structure
%
% OUTPUTS:
%   C_cap - Total capital cost [USD]
% ========================================================================

function C_cap = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS)
    % Cost coefficients (typically from market data)
    C_PV = 500;
    C_INV = 300;
    C_TR = 50;
    C_CABLE = 200;
    
    % Calculate total PV power in kilowatts
    P_pv_kw = 0.350 * n_s * n_p;

    % Transformer must be rated for at least PV power
    S_tr_kva = max(P_inv, P_pv_kw * 1000) / 1000;

    % Assumed cable length (fixed for this analysis)
    L_cable = 0.5;
    
    % Sum of all component costs
    C_cap = P_pv_kw * C_PV + (P_inv/1000) * C_INV + S_tr_kva * C_TR + L_cable * C_CABLE;

    % Apply 20% markup for balance of system (installation, labor, contingency)
    C_cap = C_cap * 1.2;
end
