%% ========================================================================
%  DIGITAL TWIN: HELPER FUNCTIONS - UTILITY FUNCTIONS FOR DIGITAL TWIN
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function [mean_val, std_val, min_val, max_val] = compute_statistics(data)
    mean_val = mean(data);
    std_val = std(data);
    min_val = min(data);
    max_val = max(data);
end