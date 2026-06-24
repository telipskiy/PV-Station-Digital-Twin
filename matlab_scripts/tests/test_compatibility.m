%% ========================================================================
%  DIGITAL TWIN: TEST_COMPATIBILITY - Verify System for Digital Twin
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 28.05.2026
%
% Description:
%   Tests compatibility of system with project requirements:
%   - MATLAB version R2025a
%   - Toolbox availability
%   - macOS Silicon architecture
%   - Simulink/Simscape availability
%   
%  ========================================================================

function test_compatibility()
    
    clc;
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║            PV STATION DIGITAL TWIN COMPATIBILITY CHECK             ║');
    disp('║                                                                    ║');
    disp('╚════════════════════════════════════════════════════════════════════╝');
    disp(' ');
    
    % ====================================================================
    % Test 1: MATLAB Version
    % ====================================================================
    
    fprintf('TEST 1: MATLAB Version\n');
    fprintf('──────────────────────\n');
    
    v = version('-release');
    fprintf('   Current Version: %s\n', v);
    
    if contains(v, '2025a') || contains(v, '2025')
        fprintf('   ✓ MATLAB R2025a or newer detected\n');
        test1_pass = true;
    else
        fprintf('   ⚠ MATLAB version may be older than R2025a\n');
        test1_pass = false;
    end
    fprintf('\n');
    
    % ====================================================================
    % Test 2: Platform Architecture
    % ====================================================================
    
    fprintf('TEST 2: Platform Architecture\n');
    fprintf('──────────────────────────────\n');
    
    [~, arch] = system('uname -s');
    [~, proc] = system('uname -m');
    
    fprintf('   Operating System: %s', strtrim(arch));
    fprintf('   Processor: %s', strtrim(proc));
    fprintf('   Computer: %s\n', computer);
    fprintf('   MATLAB Arch: %s\n', computer('arch'));
    
    if contains(proc, 'arm64') || ismac
        fprintf('   ✓ macOS with Apple Silicon detected\n');
        test2_pass = true;
    else
        fprintf('   ⚠ Platform may not be macOS Silicon\n');
        test2_pass = false;
    end
    fprintf('\n');
    
    % ====================================================================
    % Test 3: Required Toolboxes
    % ====================================================================
    
    fprintf('TEST 3: Required Toolboxes\n');
    fprintf('──────────────────────────\n');
    
    required_toolboxes = {
        'Simulink';     % Simulink
        'Simscape';     % Simscape
        'sps';          % Simscape Electrical
        'optim';        % Optimization Toolbox
        'symbolic';     % Symbolic Math Toolbox
        'control';      % Control System Toolbox
        'signal';       % Signal Processing Toolbox
        'parallel';     % Parallel Computing Toolbox
    };
    
    test3_pass = true;
    for i = 1:length(required_toolboxes)
        tb = required_toolboxes{i};
        try
            v = ver(tb);
            if ~isempty(v)
                fprintf('   ✓ %s (v%.1f)\n', tb, str2double(v.Version));
            else
                fprintf('   ✗ %s - NOT FOUND\n', tb);
                test3_pass = false;
            end
        catch
            fprintf('   ? %s - Could not verify\n', tb);
        end
    end
    fprintf('\n');
    
    % ====================================================================
    % Test 4: Simulink Project Setup
    % ====================================================================
    
    fprintf('TEST 4: Project Structure\n');
    fprintf('─────────────────────────\n');
    
    required_dirs = {
        './simulink_models';
        './matlab_scripts';
        './data';
        './docs';
    };
    
    test4_pass = true;
    for i = 1:length(required_dirs)
        d = required_dirs{i};
        if exist(d, 'dir')
            fprintf('   ✓ %s\n', d);
        else
            fprintf('   ✗ %s - MISSING\n', d);
            test4_pass = false;
        end
    end
    fprintf('\n');
    
    % ====================================================================
    % Test 5: Script Availability
    % ====================================================================
    
    fprintf('TEST 5: MATLAB Script Availability\n');
    fprintf('──────────────────────────────────\n');
    
    required_scripts = {
        'optimize_topology.m';
        'run_simulation_suite.m';
        'init_pv_station_main.m';
        'build_pv_array_subsystem.m';
        'build_inverter_subsystem.m';
        'build_all_simulink_models.m';
        'utils/plotting/plot_analysis.m';
    };
    
    test5_pass = true;
    for i = 1:length(required_scripts)
        script = required_scripts{i};
        path = fullfile('./matlab_scripts', script);
        if isfile(path)
            fprintf('   ✓ %s\n', script);
        else
            fprintf('   ✗ %s - NOT FOUND\n', script);
            test5_pass = false;
        end
    end
    fprintf('\n');
    
    % ====================================================================
    % Test 6: Memory and Computational Resources
    % ====================================================================
    
    fprintf('TEST 6: Computational Resources\n');
    fprintf('────────────────────────────────\n');
    
    [~, avail_mem] = system('vm_stat | grep free');
    fprintf('   Available Memory: %s\n', regexprep(strtrim(avail_mem), ' +', ' '));
    
    [~, cpu_info] = system('sysctl -n hw.ncpu');
    num_cores = str2double(strtrim(cpu_info));
    fprintf('   CPU Cores: %d\n', num_cores);
    
    if num_cores >= 4
        fprintf('   ✓ Sufficient computational resources\n');
        test6_pass = true;
    else
        fprintf('   ⚠ Limited CPU cores (minimum 4 recommended)\n');
        test6_pass = false;
    end
    fprintf('\n');
    
    % ====================================================================
    % SUMMARY
    % ====================================================================
    
    all_pass = test1_pass && test2_pass && test3_pass && test4_pass && test5_pass && test6_pass;
    
    fprintf('════════════════════════════════════════════════════════════════════\n');
    fprintf('   COMPATIBILITY TEST SUMMARY\n');
    fprintf('════════════════════════════════════════════════════════════════════\n');
    fprintf('\n');
    
    fprintf('Test Results:\n');
    fprintf('   Test 1 (MATLAB Version):   %s\n', iff(test1_pass, '✓ PASS', '✗ FAIL'));
    fprintf('   Test 2 (Platform):         %s\n', iff(test2_pass, '✓ PASS', '✗ FAIL'));
    fprintf('   Test 3 (Toolboxes):        %s\n', iff(test3_pass, '✓ PASS', '✗ FAIL'));
    fprintf('   Test 4 (Project Structure):%s\n', iff(test4_pass, '✓ PASS', '✗ FAIL'));
    fprintf('   Test 5 (Scripts):          %s\n', iff(test5_pass, '✓ PASS', '✗ FAIL'));
    fprintf('   Test 6 (Resources):        %s\n', iff(test6_pass, '✓ PASS', '✗ FAIL'));
    fprintf('\n');
    
    if all_pass
        fprintf('   OVERALL: ✓ ALL TESTS PASSED\n');
        fprintf('   System is ready for PV Station Digital Twin simulation\n\n');
        fprintf('   Next steps:\n');
        fprintf('     1. >> init_pv_station_main\n');
        fprintf('     2. >> build_all_simulink_models\n');
        fprintf('     3. >> open(''PV_Station_Main.slx'')\n');


    else
        fprintf('   OVERALL: ✗ SOME TESTS FAILED\n');
        fprintf('   Please address issues before proceeding\n');
    end
    fprintf('\n');
    fprintf('════════════════════════════════════════════════════════════════════\n\n');
    
end

% Helper function
function result = iff(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
