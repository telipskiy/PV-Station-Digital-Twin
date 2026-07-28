%  ========================================================================
%  DIGITAL TWIN: PV STATION - ENVIRONMENT INITIALIZATION SCRIPT
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  
%  Purpose: Initialization of all folder paths & Configure Parallel Computing
%  ========================================================================

function init_environment()

    % Get project root
    project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));

    data_dir = fullfile(project_root, 'data');
    docs_dir = fullfile(project_root, 'docs');
    reports_dir = fullfile(project_root, 'reports');
    scripts_dir = fullfile(project_root, 'scripts');
    models_dir = fullfile(project_root, 'simulink_models');
    
    % Create directories
    if ~exist(data_dir, 'dir'), mkdir(data_dir); end
    if ~exist(docs_dir, 'dir'), mkdir(docs_dir); end
    if ~exist(reports_dir, 'dir'), mkdir(reports_dir); end
    if ~exist(models_dir, 'dir'), mkdir(scripts_dir); end
    if ~exist(models_dir, 'dir'), mkdir(models_dir); end
    
    % Add paths
    addpath(genpath(data_dir));
    addpath(genpath(docs_dir));
    addpath(genpath(reports_dir));
    addpath(genpath(scripts_dir));
    addpath(genpath(models_dir));
    
    fprintf('✓ Project root: %s\n', project_root);
    fprintf('✓ Data directory: %s\n', data_dir);
    fprintf('✓ Docs directory: %s\n', docs_dir);
    fprintf('✓ Reports directory: %s\n', reports_dir);
    fprintf('✓ Scripts directory: %s\n', scripts_dir);
    fprintf('✓ Models directory: %s\n', models_dir);

     % Configure Parallel Computing (if available)
    fprintf('\nChecking Parallel Computing Capability...\n');
    
    try
        pool = gcp('nocreate');
        if isempty(pool)
            % Try to open a pool
            parpool('Threads');
            fprintf('✓ Parallel pool initialized (Threads)\n');
        else
            fprintf('✓ Parallel pool already active (%d workers)\n', pool.NumWorkers);
        end
    catch ME
        fprintf('Note: Parallel Computing disabled or not available\n');
    end

end
