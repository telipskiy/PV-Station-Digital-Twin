%% ========================================================================
%  PLOT ANALYSIS - ADVANCED VISUALIZATION MODULE
%  ========================================================================
%  Purpose: Create publication-quality plots for research dissertation
%  ========================================================================

function plot_analysis(sim_results, opt_results)
    
    if nargin < 1
        load('simulation_results.mat');
        sim_results = results_table;
    end
    
    if nargin < 2
        load('pv_optimization_full_results.mat');
        opt_results = results;
    end
    
    % Create comprehensive visualization
    create_multi_panel_figures(sim_results, opt_results);
    
end

function create_multi_panel_figures(sim_results, opt_results)
    
    % Figure 1: Performance Pareto Front
    figure('Position', [50 50 1200 800]);
    
    subplot(2,2,1);
    scatter(sim_results.LCOE_USD_kWh, sim_results.Efficiency_percent, ...
        80, sim_results.Capacity_Factor_percent, 'filled');
    colorbar; xlabel('LCOE (\$/kWh)'); ylabel('Efficiency (\%)');
    title('Pareto Front: Efficiency vs Cost');
    grid on; axis square;
    
    subplot(2,2,2);
    hold on;
    for top = 1:3
        idx = sim_results.Topology_ID == top;
        plot(sim_results.LCOE_USD_kWh(idx), sim_results.Efficiency_percent(idx), ...
            'o', 'MarkerSize', 8);
    end
    legend('String', 'Multi-String', 'Central');
    xlabel('LCOE (\$/kWh)'); ylabel('Efficiency (\%)');
    title('Topology Comparison');
    grid on; axis square;
    
    subplot(2,2,3);
    histogram(sim_results.Efficiency_percent, 15, 'FaceColor', 'b', 'EdgeColor', 'k');
    xlabel('System Efficiency (\%)');
    ylabel('Frequency');
    title('Distribution of System Efficiency');
    grid on;
    
    subplot(2,2,4);
    histogram(sim_results.LCOE_USD_kWh, 15, 'FaceColor', 'r', 'EdgeColor', 'k');
    xlabel('LCOE (\$/kWh)');
    ylabel('Frequency');
    title('Distribution of LCOE');
    grid on;
    
    savefig('analysis_pareto_front.fig');
    saveas(gcf, 'analysis_pareto_front.png');
    
end
