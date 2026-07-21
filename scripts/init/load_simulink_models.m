%  ========================================================================
%  DIGITAL TWIN: LOAD AND CONFIGURE SIMULINK MODELS
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 23.06.2026
%  
%  Purpose: Open and configure Simulink models after creation
%  ========================================================================

function load_simulink_models()
    
    % Load subsystems
    subsystems = {'Inverter_Subsystem', 'Network_Subsystem', 'PV_Array_Subsystem', 'Transformer_Subsystem'};
    
    for i = 1:length(subsystems)
        fprintf('Loading %s...\n', subsystems{i});
        try
            load_system(subsystems{i});
            fprintf('✓ %s.slx loaded successfully\n', subsystems{i});
        catch e
            fprintf('Warning: Failed to load %s.slx: %s', subsystems{i}, e.message);
        end
    end

    % Load main model
    fprintf('Loading PV_Station_Main...\n');
    try
        load_system('PV_Station_Main');
        disp('✓ PV_Station_Main.slx loaded successfully');
    catch e
        fprintf('Warning: Failed to load PV_Station_Main.slx: %s', e.message);
    end
    
    disp(' ');
    disp('All models loaded. Ready for simulation.');
    
end
