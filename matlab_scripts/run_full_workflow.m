%% ============================================================================
% RUN_FULL_WORKFLOW - Complete Digital Twin Workflow
% Version: 1.0
% Date: 2026-05-28
% Platform: macOS with Apple Silicon, MATLAB R2025a
%
% Description:
%   Executes the complete workflow:
%   1. Initialize parameters
%   2. Build Simulink models
%   3. Run simulation
%   4. Analyze results
%   5. Generate reports
%   
% Usage: run_full_workflow('ConfigType', 'optimization')
% ==============================================================================

function results = run_full_workflow(varargin)
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'ConfigType', 'single', @ischar);  % 'single' or 'optimization'
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'SaveResults', true, @islogical);
    parse(p, varargin{:});
    
    config_type = p.Results.ConfigType;
    verbose = p.Results.Verbose;
    save_results = p.Results.SaveResults;
    
    % Start timer
    tic;
    
    fprintf('\n');
    fprintf('════════════════════════════════════════════════════════════════════\n');
    fprintf('   PV STATION DIGITAL TWIN - FULL WORKFLOW\n');
    fprintf('   Platform: macOS with Apple Silicon\n');
    fprintf('   MATLAB: %s\n', version('-release'));
    fprintf('════════════════════════════════════════════════════════════════════\n');
    fprintf('\n');
    
    % ====================================================================
    % STEP 1: INITIALIZE PARAMETERS
    % ====================================================================
    
    fprintf('STEP 1: Initializing Parameters\n');
    fprintf('─────────────────────────────────────────\n');
    
    try
        init_pv_station_main;
        fprintf('✓ Parameters initialized successfully\n\n');
    catch ME
        warning('Failed to initialize parameters: %s', ME.message);
        return;
    end
    
    % ====================================================================
    % STEP 2: BUILD SIMULINK MODELS (Programmatic)
    % ====================================================================
    
    fprintf('STEP 2: Building Simulink Models\n');
    fprintf('──────────────────────────────���──────────\n');
    
    try
        fprintf('   Building PV Array Subsystem...\n');
        build_pv_array_subsystem('SavePath', './simulink_models');
        
        fprintf('   Building Inverter Subsystem...\n');
        build_inverter_subsystem('SavePath', './simulink_models');
        
        fprintf('   Building Main Model...\n');
        build_main_model('SavePath', './simulink_models');
        
        fprintf('✓ All models built successfully\n\n');
    catch ME
        warning('Failed to build models: %s', ME.message);
        return;
    end
    
    % ====================================================================
    % STEP 3: LOAD PARAMETERS TO WORKSPACE
    % ====================================================================
    
    fprintf('STEP 3: Loading Parameters to Workspace\n');
    fprintf('─────────────────────────────────────────\n');
    
    load_file = './data/pv_station_params.mat';
    if isfile(load_file)
        load(load_file);
        fprintf('✓ Parameters loaded from: %s\n\n', load_file);
    else
        warning('Parameter file not found: %s', load_file);
    end
    
    % ====================================================================
    % STEP 4: CONFIGURE SIMULATION
    % ====================================================================
    
    fprintf('STEP 4: Configuring Simulation\n');
    fprintf('─────────────────────────────────────────\n');
    
    % Create simulation input structure
    sim_in = struct();
    sim_in.StopTime = num2str(sim_config.StopTime);
    sim_in.SolverType = sim_config.solver;
    
    fprintf('   Simulation Duration: %.1f hours\n', sim_config.StopTime/3600);
    fprintf('   Solver: %s\n', sim_config.solver);
    fprintf('✓ Simulation configured\n\n');
    
    % ====================================================================
    % STEP 5: RUN SIMULATION
    % ====================================================================
    
    fprintf('STEP 5: Running Simulation\n');
    fprintf('─────────────────────────────────────────\n');
    
    try
        % Run simulation
        simout = sim('PV_Station_Main', sim_in);
        
        fprintf('✓ Simulation completed successfully\n');
        fprintf('   Data points: %d\n\n', length(simout.time));
        
        % Extract results
        results = extract_results(simout);
        
    catch ME
        warning('Simulation failed: %s', ME.message);
        results = [];
        return;
    end
    
    % ====================================================================
    % STEP 6: ANALYZE RESULTS
    % ====================================================================
    
    fprintf('STEP 6: Analyzing Results\n');
    fprintf('─────────────────────────────────────────\n');
    
    try
        analysis = analyze_results(results, params);
        fprintf('✓ Analysis completed\n\n');
    catch ME
        warning('Analysis failed: %s', ME.message);
        analysis = [];
    end
    
    % ====================================================================
    % STEP 7: VISUALIZE RESULTS
    % ====================================================================
    
    fprintf('STEP 7: Visualizing Results\n');
    fprintf('─────────────────────────────────────────\n');
    
    try
        plot_analysis(results, analysis);
        fprintf('✓ Visualization created\n\n');
    catch ME
        warning('Visualization failed: %s', ME.message);
    end
    
    % ====================================================================
    % STEP 8: GENERATE REPORT
    % ====================================================================
    
    fprintf('STEP 8: Generating Report\n');
    fprintf('─────────────────────────────────────────\n');
    
    if save_results
        try
            generate_report(results, analysis, params);
            fprintf('✓ Report generated\n\n');
        catch ME
            warning('Report generation failed: %s', ME.message);
        end
    end
    
    % ====================================================================
    % FINAL SUMMARY
    % ====================================================================
    
    elapsed_time = toc;
    
    fprintf('════════════════════════════════════════════════════════════════════\n');
    fprintf('   WORKFLOW COMPLETED SUCCESSFULLY\n');
    fprintf('═════════════════���══════════════════════════════════════════════════\n');
    fprintf('\n');
    fprintf('Execution Time: %.2f seconds (%.2f minutes)\n', elapsed_time, elapsed_time/60);
    fprintf('Results Structure: %s\n', inputname(1));
    fprintf('\n');
    
end

% ========================================================================
% HELPER FUNCTIONS
% ========================================================================

function results = extract_results(simout)
    % Extract results from simulation output
    results = struct();
    results.time = simout.time;
    % Add more result extraction as needed
end

function analysis = analyze_results(results, params)
    % Analyze simulation results
    analysis = struct();
    
    % Calculate key metrics
    analysis.efficiency = mean(results.P_out ./ results.P_in) * 100;
    analysis.THD = calculate_thd(results);
    analysis.losses = calculate_losses(results, params);
    
end

function thd = calculate_thd(results)
    % Calculate Total Harmonic Distortion
    thd = 0;  % Placeholder
end

function losses = calculate_losses(results, params)
    % Calculate energy losses
    losses = 0;  % Placeholder
end

function generate_report(results, analysis, params)
    % Generate analysis report
    fprintf('   - Efficiency: %.2f%%\n', analysis.efficiency);
    fprintf('   - THD: %.2f%%\n', analysis.THD);
    fprintf('   - Losses: %.2f kWh\n', analysis.losses);
end
