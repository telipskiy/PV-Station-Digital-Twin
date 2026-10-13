function plot_pv_iv_pv_curves()
% plot_pv_iv_pv_curves  Helper to run PV IV/PV validation from examples when available
%   This helper will try to run the SolarPanelValidationExample included in
%   examples/R2025a/simscapeelectrical. If it's present, it will open the
%   example and run the built-in validation which plots I-V and P-V curves.
%
%   The function is intentionally lightweight because the MathWorks example
%   script produces the detailed validation figures. This helper simply
%   locates and runs that script so users of this repo can reproduce the
%   validation steps.

    % Locate this helper's directory
    helperDir = fileparts(mfilename('fullpath'));
    repoRoot = fullfile(helperDir, '..', '..');
    exampleScript = fullfile(repoRoot, 'examples', 'R2025a', 'simscapeelectrical', 'SolarPanelValidationExample', 'SolarPanelValidationExample.m');

    if exist(exampleScript, 'file') == 2
        fprintf('Found SolarPanelValidationExample script. Running it to plot IV/PV curves...\n');
        try
            run(exampleScript);
            fprintf('Validation example executed. Inspect figures created by the example.\n');
        catch ME
            warning('Error running SolarPanelValidationExample: %s', ME.message);
        end
    else
        warning('SolarPanelValidationExample not found at: %s\nPlease add examples/R2025a/simscapeelectrical to the repository or run the MathWorks example manually.', exampleScript);
    end
end
