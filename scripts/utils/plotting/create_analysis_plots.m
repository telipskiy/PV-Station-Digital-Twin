%% ========================================================================
%  DIGITAL TWIN: PLOT ANALYSIS - ADVANCED VISUALIZATION MODULE
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

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