%  ========================================================================
%  CONFIGURE macOS SILICON COMPATIBILITY FOR MATLAB R2025a
%  ========================================================================
%  Purpose: Ensure all settings are optimized for Apple Silicon (ARM64)
%  Date: 2026-05-27
%  ========================================================================

function configure_system()

    disp(' ');
    disp('=========================================================================');
    disp('CONFIGURING SYSTEM');
    disp('=========================================================================');
      
    % 1. Configure Simulink Solver Settings
    disp(' ');
    disp('[1] Configuring Simulink Solver Settings...');
    
    % Set optimized solver for stiff systems
    set_param('PV_Station_Main', 'Solver', 'ode23tb');
    disp('    ✓ Solver: ode23tb (for stiff systems)');
    
    % Set simulation mode to Accelerator for better performance
    set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
    disp('    ✓ Simulation Mode: Accelerator');
    
    % 2. Configure Parallel Computing (if available)
    disp(' ');
    disp('[2] Checking Parallel Computing Capability...');
    
    try
        pool = gcp('nocreate');
        if isempty(pool)
            % Try to open a pool
            parpool('Threads');
            disp('    ✓ Parallel pool initialized (Threads)');
        else
            fprintf('    ✓ Parallel pool already active (%d workers)\n', pool.NumWorkers);
        end
    catch ME
        disp('    Note: Parallel Computing disabled or not available');
    end
    
    % 3. Create necessary directories
    disp(' ');
    disp('[3] Creating Project Directories...');
    
    directories = {
        'data';
        'docs';
        'matlab_scripts';
        'simulink_models'
    };
    
    for i = 1:length(directories)
        dir_name = directories{i};
        if ~isfolder(dir_name)
            mkdir(dir_name);
            fprintf('    ✓ Created: %s\n', dir_name);
        else
            fprintf('    ✓ Exists: %s\n', dir_name);
        end
    end
    
    % 4. Set MATLAB path
    disp(' ');
    disp('[4] Configuring MATLAB Path...');
    
    project_root = pwd;
    paths_to_add = {
        fullfile(project_root, 'matlab_scripts');
        fullfile(project_root, 'simulink_models');
        fullfile(project_root, 'data');
        fullfile(project_root, 'docs')
    };
    
    for i = 1:length(paths_to_add)
        path_item = paths_to_add{i};
        if ~any(strcmp(path, path_item))
            addpath(path_item);
            fprintf('    ✓ Added to path: %s\n', path_item);
        end
    end
    
    disp(' ');
    disp('=========================================================================');
    disp('✓ Configuration Complete!');
    disp('Ready to create and run Simulink models.');
    disp('=========================================================================');
    disp(' ');
    
end
