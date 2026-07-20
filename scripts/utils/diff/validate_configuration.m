%% ========================================================================
%  DIGITAL TWIN: HELPER FUNCTIONS - UTILITY FUNCTIONS FOR DIGITAL TWIN
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function validate_configuration(X, constraints)
    % Validate configuration against constraints
    [c, ceq] = constraints(X);
    
    if any(c > 1e-3) || any(abs(ceq) > 1e-3)
        error('Configuration violates constraints');
    end
end
