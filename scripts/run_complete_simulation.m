% ========================================================================
%  DIGITAL TWIN: Execute the validated quasi-static station workflow.
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 28.07.2026
%
%   This function does not claim a switching-transient Simulink simulation.
%   Use build_all_models separately while developing the dynamic model.
%  ========================================================================

function [sim_results, analysis_results] = run_complete_simulation(varargin)
    
    p = inputParser;
    addParameter(p, 'Topology', 'central');
    addParameter(p, 'ModulesPerString', 10);
    addParameter(p, 'NumberOfStrings', 5);
    addParameter(p, 'NumberOfInverters', 1);
    addParameter(p, 'InverterRatedPower', 50e3);
    addParameter(p, 'DcCableLength', 20);
    addParameter(p, 'AcCableLength', 0.5);
    addParameter(p, 'Export', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(root, 'scripts')));
    init_pv_station_main();
    S = load(fullfile(root, 'data', 'pv_station_parameters.mat'), ...
        'PARAMS', 'SOLAR', 't_sim', 'CABLE');
    cfg = create_topology_config( ...
        'Topology', p.Results.Topology, ...
        'ModulesPerString', p.Results.ModulesPerString, ...
        'NumberOfStrings', p.Results.NumberOfStrings, ...
        'NumberOfInverters', p.Results.NumberOfInverters, ...
        'InverterRatedPower', p.Results.InverterRatedPower, ...
        'DcCableLength', p.Results.DcCableLength, ...
        'AcCableLength', p.Results.AcCableLength);
    sim_results = evaluate_pv_station(cfg, S.PARAMS, S.SOLAR.G_profile, S.SOLAR.T_cell, ...
        'CableTemperature', S.CABLE.T_operating);
    sim_results.time_s = S.t_sim;

    analysis_results = struct();
    analysis_results.E_pv_day_kWh = trapz(S.t_sim, sim_results.P_pv_W) / 3.6e6;
    analysis_results.E_pcc_day_kWh = trapz(S.t_sim, sim_results.P_pcc_W) / 3.6e6;
    analysis_results.E_loss_day_kWh = analysis_results.E_pv_day_kWh - analysis_results.E_pcc_day_kWh;
    analysis_results.average_efficiency_percent = 100 * analysis_results.E_pcc_day_kWh / ...
        max(analysis_results.E_pv_day_kWh, eps);
    analysis_results.constraints = sim_results.constraints;
    analysis_results.model_scope = 'Quasi-static topology and loss study; not a switching-transient or harmonic result.';

    if p.Results.Export
        save(fullfile(root, 'reports', 'single_topology_result.mat'), 'sim_results', 'analysis_results');
    end
    
end
