%% ========================================================================
%  PLOT ANALYSIS - ADVANCED VISUALIZATION MODULE
%  ========================================================================
%  Purpose: Create publication-quality plots for research dissertation
%  ========================================================================

function plot_analysis(varargin)
    
    if nargin < 1 || isempty(varargin{1})
        if ~exist('simulation_results.mat', 'file')
            error('simulation_results.mat not found');
        end
        load('simulation_results.mat');
    else
        results_table = varargin{1};
    end
    
    % Create comprehensive visualization
    create_multi_panel_figures(results_table);
    
end

function create_multi_panel_figures(results_table)
    
    figure('Position', [50 50 1400 900]);
    
    % Plot 1: Pareto Front - Efficiency vs Cost
    subplot(2,3,1);
    scatter(results_table.LCOE_USD_kWh, results_table.Efficiency_percent, ...
        80, results_table.E_annual_kWh, 'filled');
    colorbar; xlabel('LCOE (\$/kWh)'); ylabel('Efficiency (\%)');
    title('Pareto Front: Efficiency vs Cost');
    grid on; axis square;
    
    % Plot 2: Topology Comparison
    subplot(2,3,2);
    hold on;
    topology_names = {'String', 'Multi-String', 'Central'};
    colors = {'r', 'g', 'b'};
    for top = 1:3
        idx = results_table.Topology_ID == top;
        scatter(results_table.LCOE_USD_kWh(idx), results_table.Efficiency_percent(idx), ...
            80, colors{top}, 'filled', 'DisplayName', topology_names{top});
    end
    legend; xlabel('LCOE (\$/kWh)'); ylabel('Efficiency (\%)');
    title('Topology Comparison');
    grid on; axis square;
    
    % Plot 3: Efficiency Distribution
    subplot(2,3,3);
    histogram(results_table.Efficiency_percent, 15, 'FaceColor', 'b', 'EdgeColor', 'k');
    xlabel('System Efficiency (\%)');
    ylabel('Frequency');
    title('Distribution of System Efficiency');
    grid on;
    
    % Plot 4: LCOE Distribution
    subplot(2,3,4);
    histogram(results_table.LCOE_USD_kWh, 15, 'FaceColor', 'r', 'EdgeColor', 'k');
    xlabel('LCOE (\$/kWh)');
    ylabel('Frequency');
    title('Distribution of LCOE');
    grid on;
    
    % Plot 5: Energy Production
    subplot(2,3,5);
    scatter(results_table.n_s, results_table.E_annual_kWh, 80, results_table.n_p, 'filled');
    colorbar; xlabel('Series Modules'); ylabel('Annual Energy (kWh)');
    title('Energy Production vs Configuration (color = parallel strings)');
    grid on; axis square;
    
    % Plot 6: Summary Table
    subplot(2,3,6);
    text(0.1, 0.85, 'Summary Statistics', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.1, 0.70, sprintf('Avg LCOE: %.3f \$/kWh', mean(results_table.LCOE_USD_kWh)), 'FontSize', 10);
    text(0.1, 0.60, sprintf('Avg Efficiency: %.2f \%%', mean(results_table.Efficiency_percent)), 'FontSize', 10);
    text(0.1, 0.50, sprintf('Min LCOE: %.3f \$/kWh', min(results_table.LCOE_USD_kWh)), 'FontSize', 10);
    text(0.1, 0.40, sprintf('Max Efficiency: %.2f \%%', max(results_table.Efficiency_percent)), 'FontSize', 10);
    text(0.1, 0.30, sprintf('Total Scenarios: %d', height(results_table)), 'FontSize', 10);
    axis off;
    
    savefig('analysis_pareto_front.fig');
    saveas(gcf, 'analysis_pareto_front.png');
    
end
