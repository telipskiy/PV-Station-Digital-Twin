% ========================================================================
%  COMPATIBILITY CHECK - Verify System for PV Station Digital Twin
%  ========================================================================
%  Purpose: Check all system requirements before running simulations
%  Platform: macOS with Apple Silicon | MATLAB R2025a
%  ========================================================================

function COMPATIBILITY_CHECK()
    
    clc;
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║          COMPATIBILITY CHECK - PV STATION DIGITAL TWIN             ║');
    disp('║          macOS Apple Silicon | MATLAB R2025a                       ║');
    disp('║                                                                    ║');
    disp('╚════════════════════════════════════════════════════════════════════╝');
    disp(' ');
    
    % Initialize results
    results = struct();
    results.passed = 0;
    results.failed = 0;
    results.warnings = 0;
    
    % ===== CHECK 1: MATLAB Version =====
    disp('CHECK 1: MATLAB Version');
    disp('──────────────────────────────────────────────────────────────');
    v = ver('MATLAB');
    fprintf('Version: %s', v.Version);
    fprintf('Release: %s', v.Release);
    
    version_num = str2double(v.Version(1:4));
    if version_num >= 25
        disp('✓ PASS: R2025a or later detected');
        results.passed = results.passed + 1;
    else
        disp('✗ FAIL: R2025a or later required');
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 2: Architecture =====
    disp('CHECK 2: System Architecture');
    disp('──────────────────────────────────────────────────────────────');
    [~, arch] = system('uname -m');
    arch = strtrim(arch);
    fprintf('Architecture: %s', arch);
    
    if strcmp(arch, 'arm64')
        disp('✓ PASS: Apple Silicon (ARM64) detected');
        results.passed = results.passed + 1;
    else
        disp('✗ FAIL: ARM64 not detected (got %s)', arch);
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 3: Available Memory =====
    disp('CHECK 3: System Memory');
    disp('──────────────────────────────────────────────────────────────');
    [~, mem_str] = system('sysctl hw.memsize');
    mem_bytes = sscanf(mem_str, 'hw.memsize: %d');
    mem_gb = mem_bytes / (1024^3);
    fprintf('Available: %.1f GB', mem_gb);
    
    if mem_gb >= 32
        disp('✓ PASS: Sufficient memory (>=32 GB)');
        results.passed = results.passed + 1;
    elseif mem_gb >= 16
        disp('⚠ WARN: Minimum memory (16-31 GB)');
        results.warnings = results.warnings + 1;
    else
        disp('✗ FAIL: Insufficient memory (<16 GB)');
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 4: Simulink =====
    disp('CHECK 4: Simulink Installation');
    disp('──────────────────────────────────────────────────────────────');
    if ~isempty(ver('Simulink'))
        disp('✓ PASS: Simulink installed');
        results.passed = results.passed + 1;
    else
        disp('✗ FAIL: Simulink not found');
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 5: Simscape =====
    disp('CHECK 5: Simscape Electrical');
    disp('──────────────────────────────────────────────────────────────');
    if ~isempty(ver('Simscape'))
        disp('✓ PASS: Simscape installed');
        results.passed = results.passed + 1;
    else
        disp('✗ FAIL: Simscape not found');
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 6: Optimization Toolbox =====
    disp('CHECK 6: Optimization Toolbox');
    disp('──────────────────────────────────────────────────────────────');
    if ~isempty(ver('Optimization'))
        disp('✓ PASS: Optimization Toolbox installed');
        results.passed = results.passed + 1;
    else
        disp('✗ FAIL: Optimization Toolbox not found');
        results.failed = results.failed + 1;
    end
    disp(' ');
    
    % ===== CHECK 7: Directory Structure =====
    disp('CHECK 7: Project Directory Structure');
    disp('──────────────────────────────────────────────────────────────');
    
    directories = {
        'matlab_scripts';
        'simulink_models';
        'data';
        'docs'
    };
    
    dirs_ok = 0;
    for i = 1:length(directories)
        dir_name = directories{i};
        if isfolder(dir_name)
            fprintf('✓ %s', dir_name);
            dirs_ok = dirs_ok + 1;
        else
            fprintf('⚠ %s (will be created)', dir_name);
        end
    end
    disp(' ');
    
    % ===== CHECK 8: Key Files =====
    disp('CHECK 8: Required Files');
    disp('──────────────────────────────────────────────────────────────');
    
    files_required = {
        'matlab_scripts/init_pv_station_main.m';
        'matlab_scripts/create_simulink_models.m';
        'README.md';
        'ARCHITECTURE.md'
    };
    
    files_ok = 0;
    for i = 1:length(files_required)
        file_name = files_required{i};
        if isfile(file_name)
            fprintf('✓ %s', file_name);
            files_ok = files_ok + 1;
        else
            fprintf('✗ %s (missing)', file_name);
        end
    end
    disp(' ');
    
    % ===== SUMMARY =====
    disp('═════════════════════════════════════════════════════════════');
    disp('SUMMARY');
    disp('═════════════════════════════════════════════════════════════');
    fprintf('✓ PASSED: %d checks', results.passed);
    fprintf('✗ FAILED: %d checks', results.failed);
    fprintf('⚠ WARNINGS: %d checks', results.warnings);
    disp(' ');
    
    if results.failed == 0
        disp('✓✓✓ ALL CHECKS PASSED ✓✓✓');
        disp(' ');
        disp('Your system is ready for PV Station Digital Twin!');
        disp(' ');
        disp('Next steps:');
        disp('  1. >> init_pv_station_main');
        disp('  2. >> create_simulink_models');
        disp('  3. >> open(''PV_Station_Main.slx'')');
    else
        disp('✗✗✗ SOME CHECKS FAILED ✗✗✗');
        disp(' ');
        disp('Please address the failures above before continuing.');
    end
    
    disp(' ');
    disp('═════════════════════════════════════════════════════════════');
    disp(' ');
    
end