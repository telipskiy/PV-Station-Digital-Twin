%% ============================================================================
% BUILD_ALL_MODELS_ENHANCED - Master script for PhD-level model generation
% Version: 2.0
% Date: 2026-07-14
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Master script that builds all enhanced Simulink models with complete
%   signal connections and PhD-level implementation.
%   
%   Builds in order:
%   1. Network_Subsystem - Grid model
%   2. Transformer_Subsystem - Step-up transformer
%   3. Inverter_Subsystem - 3-phase VSI with control
%   4. PV_Array_Subsystem - Solar array with MPPT
%   5. PV_Station_Main - Top-level integration
% ==============================================================================

function build_all_models_enhanced()
    
    clc;
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║    BUILDING PV STATION DIGITAL TWIN - PhD-Level Models             ║');
    disp('║    With Complete Signal Connections & PhD-Level Physics            ║');
    disp('║                                                                    ║');
    disp('╚════════════════════════════════════════════════════════════════════╝');
    disp(' ');
    
    % Get script directory
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(script_dir);
    models_dir = fullfile(project_root, 'simulink_models');
    
    % Create models directory if needed
    if ~exist(models_dir, 'dir')
        mkdir(models_dir);
    end
    
    % Add paths
    addpath(genpath(fullfile(project_root, 'matlab_scripts')));
    
    tic;
    
    try
        % ====================================================================
        % BUILD SUBSYSTEMS (Depends on each other)
        % ====================================================================
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 1: Building Network Subsystem (Foundation)              ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        build_network_subsystem_enhanced('SavePath', models_dir);
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 2: Building Transformer Subsystem                       ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        build_transformer_subsystem_enhanced('SavePath', models_dir);
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 3: Building Inverter Subsystem with Control             ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        build_inverter_subsystem_enhanced('SavePath', models_dir);
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 4: Building PV Array Subsystem with MPPT                ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        build_pv_array_subsystem_enhanced('SavePath', models_dir);
        
        % ====================================================================
        % BUILD MAIN MODEL (Integrates all subsystems)
        % ====================================================================
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 5: Building Main Integration Model                      ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        build_main_model_enhanced('SavePath', models_dir);
        
        % ====================================================================
        % GENERATE SAMPLE INPUT DATA
        % ====================================================================
        
        disp('╔────────────────────────────────────────────────────────────────╗');
        disp('║ PHASE 6: Generating 24-Hour Profile Data                      ║');
        disp('╚────────────────────────────────────────────────────────────────╝');
        
        generate_sample_profiles();
        
        % ====================================================================
        % COMPLETION
        % ====================================================================
        
        elapsed_time = toc;
        
        disp(' ');
        disp('╔════════════════════════════════════════════════════════════════════╗');
        disp('║                                                                    ║');
        disp('║               ✓ ALL MODELS BUILT SUCCESSFULLY!                   ║');
        disp('║                                                                    ║');
        disp('║  PhD-Level Digital Twin Implementation with:                     ║');
        disp('║  • Single Diode PV model with MPPT (Perturb & Observe)           ║');
        disp('║  • 3-phase VSI with SVM, PLL, and current control               ║');
        disp('║  • Transformer T-equivalent model with saturation & losses      ║');
        disp('║  • Grid impedance model with temperature dependency             ║');
        disp('║  • Complete signal routing & feedback loops                     ║');
        disp('║  • 24-hour simulation capability                                 ║');
        disp('║                                                                    ║');
        disp('╚════════════════════════════════════════════════════════════════════╝');
        disp(' ');
        fprintf('✓ Build time: %.2f seconds\n', elapsed_time);
        fprintf('✓ Models location: %s\n', models_dir);
        disp(' ');
        disp('Next steps:');
        disp('  1. Review models in Simulink: PV_Station_Main.slx');
        disp('  2. Configure input data profiles (G_profile, T_profile, Load_profile)');
        disp('  3. Run simulation: sim(''PV_Station_Main'')');
        disp('  4. Analyze results with post_processing.m');
        disp(' ');
        
    catch ME
        fprintf('\n✗ ERROR during model building:\n');
        fprintf('   %s\n', ME.message);
        fprintf('\n   Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('     File: %s, Line %d\n', ME.stack(i).file, ME.stack(i).line);
        end
        rethrow(ME);
    end
    
end

%% ========================================================================
% Helper function to generate sample 24-hour profiles
%% ========================================================================

function generate_sample_profiles()
    
    fprintf('\n>> Generating 24-hour solar irradiance profile...\n');
    
    % Time vector: 0 to 86400 seconds (24 hours), 1-minute resolution
    t = (0:60:86400)';
    
    % Solar irradiance: Gaussian bell curve peaking at noon (12:00)
    % G(t) = G_max * exp(-(t-t_peak)²/σ²)
    t_hours = t / 3600;  % Convert to hours
    t_peak = 12;  % Peak at noon
    G_max = 1000;  % W/m²
    sigma = 6;  % Spread (hours)
    
    G_profile = G_max * exp(-((t_hours - t_peak).^2) / (2 * sigma^2));
    G_profile(G_profile < 5) = 0;  % No generation at night (< 5 W/m²)
    
    % Add slight variations (clouds)
    G_profile = G_profile + 20 * sin(t/1000);
    G_profile(G_profile < 0) = 0;
    
    fprintf('  ✓ Solar profile: 0-%.0f W/m² (peak at noon)\n', max(G_profile));
    
    % Cell temperature: Ambient + rise due to irradiance
    % T_cell ≈ T_amb + 0.05 * G (rough model)
    fprintf('\n>> Generating 24-hour temperature profile...\n');
    
    % Ambient temperature: cool at night, warm during day
    T_amb = 20 + 10 * sin((t_hours - 6) * pi / 12);  % Min 10°C at 6:00, max 30°C at 18:00
    T_amb(t_hours < 6 | t_hours > 18) = 15;  % Night temperature
    
    % Cell temperature rises with irradiance
    T_profile = T_amb + 0.05 * G_profile;
    T_profile(T_profile > 60) = 60;  % Cap at 60°C
    
    fprintf('  ✓ Temperature profile: %.0f-%.0f°C\n', min(T_profile), max(T_profile));
    
    % Load demand: typical daily pattern
    fprintf('\n>> Generating 24-hour load profile...\n');
    
    % Low at night, peak in morning and evening
    P_load = 5000 + 8000 * sin((t_hours - 6) * pi / 12);  % 5-13 kW
    P_load(t_hours < 6 | t_hours > 18) = 3000;  % Night load (lighting, etc)
    P_load(t_hours >= 12 & t_hours <= 14) = P_load(t_hours >= 12 & t_hours <= 14) + 2000;  % Lunch peak
    P_load(P_load < 0) = 0;
    
    fprintf('  ✓ Load profile: 0-%.0f W\n', max(P_load));
    
    % Create time vector for Simulink
    time_vector = [t, ones(length(t), 1)];  % Time with ones for From Workspace
    
    % Save to workspace variables
    assignin('base', 'G_profile', [time_vector(:, 1), G_profile]);
    assignin('base', 'T_profile', [time_vector(:, 1), T_profile]);
    assignin('base', 'Load_profile', [time_vector(:, 1), P_load]);
    assignin('base', 't_sim', t);
    
    % Also save to MAT file for reference
    data_dir = fileparts(fileparts(mfilename('fullpath')));
    matfile = fullfile(data_dir, 'data', 'profiles_24h.mat');
    if ~exist(fullfile(data_dir, 'data'), 'dir')
        mkdir(fullfile(data_dir, 'data'));
    end
    
    save(matfile, 'G_profile', 'T_profile', 'Load_profile', 't_sim');
    fprintf('\n  ✓ Profiles saved to: %s\n', matfile);
    
    % Plot profiles for visualization
    fprintf('\n>> Plotting profiles...\n');
    
    figure('Name', 'PV Station 24-Hour Profiles', 'NumberTitle', 'off');
    
    % Solar irradiance
    subplot(3, 1, 1);
    plot(t_hours, G_profile, 'b-', 'LineWidth', 2);
    grid on; xlabel('Time [hours]'); ylabel('Irradiance [W/m²]');
    title('Solar Irradiance Profile - 24 Hours');
    axis([0 24 0 1100]);
    
    % Temperature
    subplot(3, 1, 2);
    plot(t_hours, T_profile, 'r-', 'LineWidth', 2);
    grid on; xlabel('Time [hours]'); ylabel('Temperature [°C]');
    title('Cell Temperature Profile - 24 Hours');
    axis([0 24 0 65]);
    
    % Load
    subplot(3, 1, 3);
    plot(t_hours, P_load/1000, 'g-', 'LineWidth', 2);
    grid on; xlabel('Time [hours]'); ylabel('Load Power [kW]');
    title('Load Demand Profile - 24 Hours');
    axis([0 24 0 15]);
    
    savefig(fullfile(data_dir, 'reports', 'profiles_24h.fig'));
    fprintf('  ✓ Profile plots saved\n');
    
end
