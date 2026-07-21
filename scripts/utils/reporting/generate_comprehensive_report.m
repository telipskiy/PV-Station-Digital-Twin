%% ========================================================================
%  DIGITAL TWIN: REPORTING - Generate comprehensive reports
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function generate_comprehensive_report()
    
    % Load all results
    if ~exist('simulation_results.mat', 'file')
        error('simulation_results.mat not found');
    end
    load('simulation_results.mat');
    
    % Generate statistics
    disp('=== STATISTICAL SUMMARY ===');
    disp(' ');
    
    fprintf('Total Scenarios: %d\n', height(results_table));
    fprintf('Average LCOE: %.3f $/kWh\n', mean(results_table.LCOE_USD_kWh));
    fprintf('Min LCOE: %.3f $/kWh\n', min(results_table.LCOE_USD_kWh));
    fprintf('Max LCOE: %.3f $/kWh\n', max(results_table.LCOE_USD_kWh));
    fprintf('\n');
    
    fprintf('Average Efficiency: %.2f %%\n', mean(results_table.Efficiency_percent));
    fprintf('Min Efficiency: %.2f %%\n', min(results_table.Efficiency_percent));
    fprintf('Max Efficiency: %.2f %%\n', max(results_table.Efficiency_percent));
    fprintf('\n');
    
    fprintf('Average Annual Energy: %.0f kWh\n', mean(results_table.E_annual_kWh));
    fprintf('Average Annual Losses: %.0f kWh\n', mean(results_table.W_loss_kWh));
    fprintf('\n');
    
    % Top 5 by LCOE
    [~, idx_lcoe] = sort(results_table.LCOE_USD_kWh, 'ascend');
    disp('=== TOP 5 SCENARIOS BY LCOE ===');
    top_lcoe = results_table(idx_lcoe(1:min(5, height(results_table))), ...
        {'Scenario_ID', 'n_s', 'n_p', 'P_inv_kW', 'LCOE_USD_kWh', 'Efficiency_percent'});
    disp(top_lcoe);
    
    % Top 5 by Efficiency
    [~, idx_eff] = sort(results_table.Efficiency_percent, 'descend');
    disp('=== TOP 5 SCENARIOS BY EFFICIENCY ===');
    top_eff = results_table(idx_eff(1:min(5, height(results_table))), ...
        {'Scenario_ID', 'n_s', 'n_p', 'P_inv_kW', 'Efficiency_percent', 'LCOE_USD_kWh'});
    disp(top_eff);
    
    % Export to Excel
    writetable(results_table, 'comprehensive_analysis_results.xlsx');
    disp(' ');
    disp('Results exported to: comprehensive_analysis_results.xlsx');
    
end
