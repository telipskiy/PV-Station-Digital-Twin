%  ========================================================================
%  DIGITAL TWIN: CREATE SAMPLE 24-HOUR PROFILES
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-07-14
%  
%  Purpose: Function to generate sample 24-hour profiles
%   
%   Builds in order:
%   1. Network_Subsystem - Grid model
%   2. Transformer_Subsystem - Step-up transformer
%   3. Inverter_Subsystem - 3-phase VSI with control
%   4. PV_Array_Subsystem - Solar array with MPPT
%   5. PV_Station_Main - Top-level integration
%  ========================================================================

function init_sample_profiles()
    
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
    Load_profile = 5000 + 8000 * sin((t_hours - 6) * pi / 12);  % 5-13 kW
    Load_profile(t_hours < 6 | t_hours > 18) = 3000;  % Night load (lighting, etc)
    Load_profile(t_hours >= 12 & t_hours <= 14) = Load_profile(t_hours >= 12 & t_hours <= 14) + 2000;  % Lunch peak
    Load_profile(Load_profile < 0) = 0;
    
    fprintf('  ✓ Load profile: 0-%.0f W\n', max(Load_profile));
    
    % Create time vector for Simulink
    time_vector = [t, ones(length(t), 1)];  % Time with ones for From Workspace
    
    % Save to workspace variables
    assignin('base', 'G_profile', [time_vector(:, 1), G_profile]);
    assignin('base', 'T_profile', [time_vector(:, 1), T_profile]);
    assignin('base', 'Load_profile', [time_vector(:, 1), Load_profile]);
    assignin('base', 't_sim', t);
    
    % Also save to MAT file for reference
    data_dir = fileparts(fileparts(mfilename('fullpath')));
    matfile = fullfile(data_dir, 'data', 'profiles_24h.mat');
    if ~exist(fullfile(data_dir, 'data'), 'dir')
        mkdir(fullfile(data_dir, 'data'));
    end
    
    save(matfile, 'G_profile', 'T_profile', 'Load_profile', 't');
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
    plot(t_hours, Load_profile/1000, 'g-', 'LineWidth', 2);
    grid on; xlabel('Time [hours]'); ylabel('Load Power [kW]');
    title('Load Demand Profile - 24 Hours');
    axis([0 24 0 15]);

    % Also save to FIG file for reference
    savefig(fullfile(data_dir, 'data', 'profiles_24h.fig'));
    fprintf('  ✓ Profile plots saved\n');
    
end
