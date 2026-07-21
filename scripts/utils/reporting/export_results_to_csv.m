%% ========================================================================
%  DIGITAL TWIN: REPORTING - Export result reports to CSV file
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function export_results_to_csv(results, filename)
    writetable(results, filename);
    fprintf('Results exported to: %s\n', filename);
end