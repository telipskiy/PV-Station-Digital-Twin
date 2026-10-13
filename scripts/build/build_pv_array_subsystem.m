%  ========================================================================
%  DIGITAL TWIN: BUILD PV ARRAY SUBSYSTEM (Simscape-enabled)
%  ========================================================================
%  Author: Denys Telipskyi (adapted by GitHub Copilot)
%  Date: 2026-10-13
%  
% Description:
%   Builds the PV Array Subsystem (Level 2.1) with signal routing.
%   - Prefer Simscape Electrical Solar Plant (from examples) when present
%   - Falls back to a minimal placeholder single-diode structure (warns user)
%   - Adds optional validation/run helper (doValidation)
%   - Outputs: PV_Array_Subsystem.slx
%  ========================================================================

function hModel = build_pv_array_subsystem(varargin)
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ModelName', 'PV_Array_Subsystem', @ischar);
    addParameter(p, 'SavePath', './simulink_models', @ischar);
    addParameter(p, 'DoValidation', true, @islogical);
    parse(p, varargin{:});

    model_name = p.Results.ModelName;
    save_path = p.Results.SavePath;
    doValidation = p.Results.DoValidation;

    % Create new model (on specified branch this will create the .slx when run in MATLAB)
    try
        close_system(model_name, 0);
    catch
    end
    hModel = new_system(model_name, 'Model');
    load_system(hModel);

    % Configure solver for realistic power electronics simulation
    set_param(hModel, 'SolverType', 'Variable-step');
    set_param(hModel, 'SolverName', 'ode45');
    set_param(hModel, 'RelTol', '1e-5');
    set_param(hModel, 'AbsTol', '1e-8');
    set_param(hModel, 'MaxStep', '1e-4');
    set_param(hModel, 'MinStep', '1e-8');
    set_param(hModel, 'StopTime', '86400');  % 24-hour simulation by default

    % ====================================================================
    % INPUTS
    % ====================================================================

    % Input 1: Solar irradiance [W/m²]
    G_in = add_block('simulink/Sources/In1', [model_name '/G_Solar_in']);
    set_param(G_in, 'Position', [20 50 50 70]);
    set_param(G_in, 'Port', '1');

    % Input 2: Cell temperature [°C]
    T_in = add_block('simulink/Sources/In1', [model_name '/T_cell_in']);
    set_param(T_in, 'Position', [20 120 50 140]);
    set_param(T_in, 'Port', '2');

    % Input 3: Demanded voltage from boost converter [V]
    V_boost_demand = add_block('simulink/Sources/In1', [model_name '/V_boost_demand']);
    set_param(V_boost_demand, 'Position', [20 190 50 210]);
    set_param(V_boost_demand, 'Port', '3');

    % ====================================================================
    % Try to reuse MathWorks SolarPVMPPTBoost example Solar Plant if available
    % ====================================================================

    % Construct example model path relative to this script
    scriptDir = fileparts(mfilename('fullpath'));
    exampleModelPath = fullfile(scriptDir, '..', '..', 'examples', 'R2025a', 'simscapeelectrical', 'SolarPVMPPTBoost', 'SolarPVMPPTBoost.slx');
    exampleModelPath = matlab.lang.makeValidName(exampleModelPath); % no-op safeguard

    useExampleSolarPlant = false;
    % Prefer using the example Solar Plant if the file exists on the MATLAB path or as a file
    try
        if exist(exampleModelPath, 'file') == 2
            load_system(exampleModelPath);
            % The example model's name is 'SolarPVMPPTBoost' (as in the examples)
            % Add the Solar Plant subsystem
            try
                add_block('SolarPVMPPTBoost/Solar Plant', [model_name '/Solar Plant'], 'Position', [220 40 420 240]);
                useExampleSolarPlant = true;
            catch ME
                warning('Could not add Solar Plant block from example: %s', ME.message);
                useExampleSolarPlant = false;
            end
        else
            % Try to see if the example is on MATLAB path by model name
            if bdIsLoaded('SolarPVMPPTBoost') || exist('SolarPVMPPTBoost', 'file')
                try
                    add_block('SolarPVMPPTBoost/Solar Plant', [model_name '/Solar Plant'], 'Position', [220 40 420 240]);
                    useExampleSolarPlant = true;
                catch ME
                    warning('SolarPVMPPTBoost found on path but failed to insert Solar Plant: %s', ME.message);
                    useExampleSolarPlant = false;
                end
            else
                useExampleSolarPlant = false;
            end
        end
    catch ME
        warning('Error while checking for SolarPVMPPTBoost example: %s', ME.message);
        useExampleSolarPlant = false;
    end

    if useExampleSolarPlant
        % Connect irradiance & temperature inputs (assumes Solar Plant has two inports: G and T)
        try
            add_line(model_name, 'G_Solar_in/1', 'Solar Plant/1', 'autorouting','on');
        catch
            warning('Failed to connect G_Solar_in to Solar Plant input 1. Please connect manually.');
        end
        try
            add_line(model_name, 'T_cell_in/1', 'Solar Plant/2', 'autorouting','on');
        catch
            warning('Failed to connect T_cell_in to Solar Plant input 2. Please connect manually.');
        end

        % Create Outports to expose key signals expected by the rest of the station
        outVpv = add_block('simulink/Sinks/Out1', [model_name '/V_pv']); set_param(outVpv,'Position',[640 40 670 60]);
        outIpv = add_block('simulink/Sinks/Out1', [model_name '/I_pv']); set_param(outIpv,'Position',[640 80 670 100]);
        outPpv = add_block('simulink/Sinks/Out1', [model_name '/P_pv']); set_param(outPpv,'Position',[640 120 670 140]);
        outVdc = add_block('simulink/Sinks/Out1', [model_name '/V_dc']); set_param(outVdc,'Position',[640 160 670 180]);
        outIdc = add_block('simulink/Sinks/Out1', [model_name '/I_dc']); set_param(outIdc,'Position',[640 200 670 220]);
        outIref = add_block('simulink/Sinks/Out1', [model_name '/I_ref']); set_param(outIref,'Position',[640 240 670 260]);

        % Try to connect example Solar Plant outputs to these Outports. The exact
        % output port numbers depend on the example subsystem layout; attempt
        % common mappings and otherwise warn for manual wiring.
        try
            % Common mapping attempt: measurement outputs often follow the electrical
            % ports. Try connecting ports 3..8 to the Outports 1..6
            add_line(model_name, 'Solar Plant/3', 'V_pv/1', 'autorouting','on');
            add_line(model_name, 'Solar Plant/4', 'I_pv/1', 'autorouting','on');
            add_line(model_name, 'Solar Plant/5', 'P_pv/1', 'autorouting','on');
            add_line(model_name, 'Solar Plant/6', 'V_dc/1', 'autorouting','on');
            add_line(model_name, 'Solar Plant/7', 'I_dc/1', 'autorouting','on');
            add_line(model_name, 'Solar Plant/8', 'I_ref/1', 'autorouting','on');
        catch
            % If automatic mapping fails, leave the Outports unconnected and notify
            warning(['Automatic wiring from example Solar Plant to PV_Array_Subsystem outports failed.
                     Open the generated model and connect the appropriate measurement outputs to V_pv, I_pv, P_pv, V_dc, I_dc, I_ref.']);
        end

    else
        % Fallback: build a minimal single-diode style PV block skeleton
        % This fallback preserves the model interface but is simplified. For
        % accurate Simscape simulations, ensure the example Solar Plant is
        % available and re-run this builder.
        warning('MathWorks example Solar Plant not found. Creating a simplified PV skeleton. For full Simscape Solar PV use, add the SolarPVMPPTBoost example to the MATLAB path or repository examples.');

        % Constants (STC)
        G_ref = add_block('simulink/Sources/Constant', [model_name '/G_ref_const']);
        set_param(G_ref, 'Value', '1000');
        set_param(G_ref, 'Position', [100 50 140 70]);

        T_ref = add_block('simulink/Sources/Constant', [model_name '/T_ref_const']);
        set_param(T_ref, 'Value', '25');
        set_param(T_ref, 'Position', [100 90 140 110]);

        % Placeholder PV electrical interface: expose Outports but no internal
        % electrical network. The user should replace with full single-diode
        % implementation or use the Simscape example.
        outVpv = add_block('simulink/Sinks/Out1', [model_name '/V_pv']); set_param(outVpv,'Position',[420 40 450 60]);
        outIpv = add_block('simulink/Sinks/Out1', [model_name '/I_pv']); set_param(outIpv,'Position',[420 80 450 100]);
        outPpv = add_block('simulink/Sinks/Out1', [model_name '/P_pv']); set_param(outPpv,'Position',[420 120 450 140]);
        outVdc = add_block('simulink/Sinks/Out1', [model_name '/V_dc']); set_param(outVdc,'Position',[420 160 450 180]);
        outIdc = add_block('simulink/Sinks/Out1', [model_name '/I_dc']); set_param(outIdc,'Position',[420 200 450 220]);
        outIref = add_block('simulink/Sinks/Out1', [model_name '/I_ref']); set_param(outIref,'Position',[420 240 450 260]);

        % Connect G and T to constants for demonstration (so the model runs without errors)
        try
            add_line(model_name, 'G_Solar_in/1', 'G_ref_const/1', 'autorouting','on');
            add_line(model_name, 'T_cell_in/1', 'T_ref_const/1', 'autorouting','on');
        catch
        end
    end

    % Save model to SavePath
    if ~isfolder(save_path)
        mkdir(save_path);
    end
    save_file = fullfile(save_path, [model_name '.slx']);
    try
        save_system(hModel, save_file);
    catch ME
        warning('Failed to save model: %s', ME.message);
    end

    % Optional validation and plotting (run the example validation if available)
    if doValidation
        try
            fprintf('Running PV validation/plotting helper...\n');
            plottingHelper = fullfile(scriptDir, '..', 'utils', 'plotting', 'plot_pv_iv_pv_curves.m');
            if exist(plottingHelper, 'file') == 2
                run(plottingHelper);
            else
                % Attempt to run the MathWorks example validation script if available
                exampleValidationScript = fullfile(scriptDir, '..', '..', 'examples', 'R2025a', 'simscapeelectrical', 'SolarPanelValidationExample', 'SolarPanelValidationExample.m');
                if exist(exampleValidationScript, 'file') == 2
                    run(exampleValidationScript);
                else
                    warning('No plotting helper or example validation script found. Skipping validation.');
                end
            end
        catch ME
            warning('Validation helper failed: %s', ME.message);
        end
    end

    fprintf('\nPV Array Subsystem built and saved to: %s\n', save_file);
end
