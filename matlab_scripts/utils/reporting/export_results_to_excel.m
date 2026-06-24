%% ========================================================================
%  DIGITAL TWIN: REPORTING - Export result reports to Excel
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function export_results_to_excel(results, filename)
    writetable(results, filename);
    fprintf('Results exported to: %s\n', filename);
end
