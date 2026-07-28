%% ========================================================================
%  DIGITAL TWIN: PLOT ANALYSIS - ADVANCED VISUALIZATION MODULE
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function plot_time_series(t, data, title_str)
    figure;
    plot(t, data, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Power (W)');
    title(title_str);
    grid on;
    set(gca, 'FontSize', 11);
end