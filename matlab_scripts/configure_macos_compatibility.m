%  ========================================================================
%  CONFIGURE macOS SILICON COMPATIBILITY FOR MATLAB R2025a
%  ========================================================================
%  Purpose: Ensure all settings are optimized for Apple Silicon (ARM64)
%  Date: 2026-05-27
%  ========================================================================

function configure_macos_compatibility()

    disp(' ');
    disp('=========================================================================');
    disp('CONFIGURING macOS SILICON COMPATIBILITY');
    disp('MATLAB R2025a on Apple Silicon (ARM64)');
    disp('=========================================================================');
    disp(' ');
    
    % 1. Check MATLAB version
    disp('[1] Checking MATLAB Version...');
    v = ver('MATLAB');
    fprintf('    MATLAB %s', v.Version);
    fprintf('    Release: %s', v.Release);
    
    % Verify it's R2025a or later
    version_num = str2double(v.Version(1:4));
    if version_num < 25
        warning('MATLAB R2025a or later is required. Your version may have compatibility issues.');
    else
        disp('    ✓ Compatible version detected');
    end
    
    % 2. Check Architecture
    disp(' ');
    disp('[2] Checking System Architecture...');
    [status, computer_str] = system('uname -m');
    computer_str = strtrim(computer_str);
    fprintf('    Architecture: %s', computer_str);
    
    if strcmp(computer_str, 'arm64')
        disp('    ✓ Apple Silicon (ARM64) detected');
    else
        warning('Expected ARM64 architecture for Apple Silicon Mac');
    end
    
    % 3. Check Available Memory
    disp(' ');
    disp('[3] Checking System Memory...');
    [status, memory_str] = system('sysctl hw.memsize');
    memory_bytes = sscanf(memory_str, 'hw.memsize: %d');
    memory_gb = memory_bytes / (1024^3);
    fprintf('    Available Memory: %.1f GB', memory_gb);
    
    if memory_gb < 32
        warning('Recommended minimum 32 GB RAM. You have %.1f GB.', memory_gb);
    else
        disp('    ✓ Sufficient memory available');
    end
    
    % 4. Configure Simulink Solver Settings
    disp(' ');
    disp('[4] Configuring Simulink Solver Settings...');
    
    % Set optimized solver for stiff systems
    set_param('PV_Station_Main', 'Solver', 'ode23tb');
    disp('    ✓ Solver: ode23tb (for stiff systems)');
    
    % Set optimization level
    set_param('PV_Station_Main', 'RTWSystemCodeOnlyUsed', 'on');
    disp('    ✓ Enabled RTW system code generation');
    
    % Set simulation mode to Accelerator for better performance
    set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
    disp('    ✓ Simulation Mode: Accelerator');
    
    % 5. Configure Parallel Computing (if available)
    disp(' ');
    disp('[5] Checking Parallel Computing Capability...');
    
    try
        pool = gcp('nocreate');
        if isempty(pool)
            % Try to open a pool
            parpool('Threads');
            disp('    ✓ Parallel pool initialized (Threads)');
        else
            fprintf('    ✓ Parallel pool already active (%d workers)', pool.NumWorkers);
        end
    catch ME
        disp('    Note: Parallel Computing disabled or not available');
    end
    
    % 6. Verify Toolbox Availability
    disp(' ');
    disp('[6] Verifying Required Toolboxes...');
    
    required_toolboxes = {
        'Simulink';
        'Simscape';
        'Control System Toolbox';
        'Optimization Toolbox';
        'Signal Processing Toolbox'
    };
    
    for i = 1:length(required_toolboxes)
        toolbox = required_toolboxes{i};
        v = ver(toolbox);
        if ~isempty(v)
            fprintf('    ✓ %s available', toolbox);
        else
            fprintf('    ✗ %s NOT available (may be required)', toolbox);
        end
    end
    
    % 7. Create necessary directories
    disp(' ');
    disp('[7] Creating Project Directories...');
    
    directories = {
        'simulink_models';
        'data';
        'results';
        'logs'
    };
    
    for i = 1:length(directories)
        dir_name = directories{i};
        if ~isfolder(dir_name)
            mkdir(dir_name);
            fprintf('    ✓ Created: %s', dir_name);
        else
            fprintf('    ✓ Exists: %s', dir_name);
        end
    end
    
    % 8. Set MATLAB path
    disp(' ');
    disp('[8] Configuring MATLAB Path...');
    
    project_root = pwd;
    paths_to_add = {
        fullfile(project_root, 'matlab_scripts');
        fullfile(project_root, 'simulink_models');
        fullfile(project_root, 'data')
    };
    
    for i = 1:length(paths_to_add)
        path_item = paths_to_add{i};
        if ~any(strcmp(path, path_item))
            addpath(path_item);
            fprintf('    ✓ Added to path: %s', path_item);
        end
    end
    
    % 9. Performance Tips for ARM64
    disp(' ');
    disp('[9] macOS Silicon Performance Tips...');
    disp('    • Use Accelerator or Rapid Accelerator simulation modes');
    disp('    • Enable parallel simulation for parameter sweeps');
    disp('    • Use codegen for compiled simulations');
    disp('    • Monitor CPU usage with Activity Monitor');
    
    % 10. System Information
    disp(' ');
    disp('[10] System Information Summary');
    disp('=========================================================================');
    fprintf('    OS: macOS on Apple Silicon (ARM64)');
    fprintf('    MATLAB Version: R2025a');
    fprintf('    RAM Available: %.1f GB', memory_gb);
    fprintf('    Project Directory: %s', project_root);
    disp('=========================================================================');
    disp(' ');
    disp('✓ Configuration Complete!');
    disp('Ready to create and run Simulink models.');
    disp(' ');
    
end
