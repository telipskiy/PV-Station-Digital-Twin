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
    scenarios.ns_values = [5, 10, 15, 20];
    scenarios.np_values = [2, 5, 10, 15];
    scenarios.Pinv_values = [25e3, 50e3, 75e3, 100e3];
    scenarios.topology_values = [1, 2, 3];
    
    % Generate all combinations
    [ns_grid, np_grid, Pinv_grid, top_grid] = ndgrid(...
        scenarios.ns_values, scenarios.np_values, scenarios.Pinv_values, scenarios.topology_values);
    
    n_scenarios = numel(ns_grid);
    disp(sprintf('Total Scenarios: %d', n_scenarios));
    
    results_table = table();
    scenario_count = 0;
    
    % ====================================================================
    % 2. EXECUTE SIMULATION FOR EACH SCENARIO
    % ====================================================================
    
    h_waitbar = waitbar(0, 'Running simulations...');
    
    for idx = 1:n_scenarios
        waitbar(idx/n_scenarios, h_waitbar, sprintf('Simulation %d of %d', idx, n_scenarios));
        
        n_s = ns_grid(idx);
        n_p = np_grid(idx);
        P_inv = Pinv_grid(idx);
        topology = top_grid(idx);
        
        try
            % Update PV configuration
            PV.ns_current = n_s;
            PV.np_current = n_p;
            PV.Pfield_current = PV.Pmax_stc * n_s * n_p;
            INV.P_rated_current = P_inv;
            
            % Simulate
            simIn = Simulink.SimulationInput('PV_Station_Main');
            simIn = setVariable(simIn, 'PV_config', PV);
            simIn = setVariable(simIn, 'INV_config', INV);
            
            simOut = sim(simIn);
            
            % Extract metrics
            t = simOut.tout;
            P_pv = simOut.yout.P_pv.Data;
            P_loss_cable = simOut.yout.P_loss_cable.Data;
            
            E_annual = trapz(t, P_pv) / 3.6e6;
            W_loss_annual = trapz(t, P_loss_cable) / 3.6e6;
            efficiency_sys = 100 * (1 - W_loss_annual / E_annual);
            
            C_cap_scenario = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS);
            LCOE = (C_cap_scenario + ECONOMICS.annual_opex_rate * C_cap_scenario * ECONOMICS.study_period) / (E_annual * ECONOMICS.study_period);
            
            scenario_count = scenario_count + 1;
            
            new_row = table(scenario_count, n_s, n_p, P_inv/1000, topology, ...
                E_annual, W_loss_annual, efficiency_sys, LCOE, C_cap_scenario, ...
                'VariableNames', {'Scenario_ID', 'n_s', 'n_p', 'P_inv_kW', 'Topology_ID', ...
                'E_annual_kWh', 'W_loss_kWh', 'Efficiency_percent', 'LCOE_USD_kWh', 'Capital_Cost_USD'});
            
            results_table = [results_table; new_row];
            
        catch sim_error
            warning(sprintf('Simulation failed for scenario %d', idx));
            continue;
        end
    end
    
    close(h_waitbar);
    
    % Save results
    writetable(results_table, 'simulation_results.csv');
    save('simulation_results.mat', 'results_table');
    
    disp('=========================================================================');
    disp(sprintf('Scenarios Simulated: %d', scenario_count));
    disp('Results saved to: simulation_results.csv');
    disp('=========================================================================');

end

function C_cap = calculate_capital_cost(n_s, n_p, P_inv, ECONOMICS)
    C_PV = 500;
    C_INV = 300;
    C_TR = 50;
    C_CABLE = 200;
    
    P_pv_kw = 0.350 * n_s * n_p;
    S_tr_kva = max(P_inv, P_pv_kw * 1000) / 1000;
    L_cable = 0.5;
    
    C_cap = P_pv_kw * C_PV + (P_inv/1000) * C_INV + S_tr_kva * C_TR + L_cable * C_CABLE;
    C_cap = C_cap * 1.2;
end
