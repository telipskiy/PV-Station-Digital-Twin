%  ========================================================================
%  DIGITAL TWIN: CREATE ALL SIMULINK MODELS
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 2026-07-14
%  
%  Purpose: Generate all Simulink models with complete signal connections
%   
%   Builds in order:
%   1. Network_Subsystem - Grid model
%   2. Transformer_Subsystem - Step-up transformer
%   3. Inverter_Subsystem - 3-phase VSI with control
%   4. PV_Array_Subsystem - Solar array with MPPT
%   5. PV_Station_Main - Top-level integration
%  ========================================================================

function build_all_models()
    
    clc;
    disp(' ');
    disp('╔════════════════════════════════════════════════════════════════════╗');
    disp('║                                                                    ║');
    disp('║        CREATING SIMULINK MODELS FOR PV STATION DIGITAL TWIN        ║');
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
        disp('[1/6] Creating Network_Subsystem.slx...');
        build_network_subsystem('SavePath', models_dir);
        disp('[2/6] Creating Transformer_Subsystem.slx...');
        build_transformer_subsystem('SavePath', models_dir);
        disp('[3/6] Creating Inverter_Subsystem.slx...');
        build_inverter_subsystem('SavePath', models_dir);
        disp('[4/6] Creating PV_Array_Subsystem.slx...');
        build_pv_array_subsystem('SavePath', models_dir);
        disp('[5/6] Creating PV_Station_Main.slx...');
        build_digital_twin_model('SavePath', models_dir);
        
        % ====================================================================
        % GENERATE SAMPLE INPUT DATA
        % ====================================================================
        disp('[6/6] Generating 24-Hour Profile Data...');
        init_sample_profiles();
        
        % ====================================================================
        % COMPLETION
        % ====================================================================
        elapsed_time = toc;
        
        disp('=========================================================================');
        disp('✓ ALL SIMULINK MODELS CREATED SUCCESSFULLY');
        disp('   • Single Diode PV model with MPPT (Perturb & Observe)');
        disp('   • 3-phase VSI with SVM, PLL, and current control');
        disp('   • Transformer T-equivalent model with saturation & losses');
        disp('   • Grid impedance model with temperature dependency');
        disp('   • Complete signal routing & feedback loops');
        disp('   • 24-hour simulation capability');
        disp('=========================================================================');
        disp(' ');
        fprintf('✓ Build time: %.2f seconds\n', elapsed_time);
        fprintf('✓ Models location: %s\n', models_dir);
        disp(' ');
        disp('Next steps:');
        disp('  1. Review models in Simulink: PV_Station_Main.slx');
        disp('  2. Configure input data profiles (G_profile, T_profile, Load_profile)');
        disp('  3. Run simulation: sim(''PV_Station_Main'')');
        disp('  4. Analyze results');
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
