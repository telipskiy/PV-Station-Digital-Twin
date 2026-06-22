%  ========================================================================
%  LOAD AND CONFIGURE SIMULINK MODELS
%  ========================================================================
%  Purpose: Open and configure Simulink models after creation
%  Platform: MATLAB R2025a on macOS with Apple Silicon
%  Date: 2026-05-27
%  ========================================================================

function load_simulink_models()
    
    disp(' ');
    disp('=========================================================================');
    disp('LOADING SIMULINK MODELS');
    disp('=========================================================================');
    disp(' ');
    
    % Change to simulink_models directory
    if ~isfolder('simulink_models')
        mkdir('simulink_models');
        disp('Created simulink_models directory');
    end
    
    % Load main model
    try
        load_system('PV_Station_Main');
        disp('✓ PV_Station_Main.slx loaded successfully');
    catch e
        warning(e.identifier, 'Failed to load PV_Station_Main.slx: %s', e.message);
    end
    
    % Load subsystems
    subsystems = {...
        'PV_Array_Subsystem', ...
        'Inverter_Subsystem', ...
        'Transformer_Subsystem', ...
        'Network_Subsystem'
    };
    
    for i = 1:length(subsystems)
        try
            load_system(subsystems{i});
            fprintf('✓ %s.slx loaded successfully', subsystems{i});
        catch e
            fprintf('Warning: Failed to load %s.slx: %s', subsystems{i}, e.message);
        end
    end
    
    disp(' ');
    disp('All models loaded. Ready for simulation.');
    disp(' ');
    
end
