%% ========================================================================
%  HELPER FUNCTIONS - UTILITY FUNCTIONS FOR DIGITAL TWIN
%  ========================================================================

function validate_configuration(X, constraints)
    % Validate configuration against constraints
    [c, ceq] = constraints(X);
    
    if any(c > 1e-3) || any(abs(ceq) > 1e-3)
        error('Configuration violates constraints');
    end
end

function plot_time_series(t, data, title_str)
    figure;
    plot(t, data, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Power (W)');
    title(title_str);
    grid on;
    set(gca, 'FontSize', 11);
end

function [mean_val, std_val, min_val, max_val] = compute_statistics(data)
    mean_val = mean(data);
    std_val = std(data);
    min_val = min(data);
    max_val = max(data);
end

function export_to_csv(results, filename)
    writetable(results, filename);
    fprintf('Data exported to: %s\n', filename);
end
