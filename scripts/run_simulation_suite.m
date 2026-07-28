function results_table = run_simulation_suite(varargin)
%RUN_SIMULATION_SUITE Reproducible parametric study of PV-station topology.
%   This is a quasi-static time-series study.  It must not be presented as a
%   switching-transient or harmonic study; those questions require a validated
%   Simscape Electrical implementation and a suitable sampling frequency.

    p = inputParser;
    addParameter(p, 'ModulesPerString', [8 10 12 15]);
    addParameter(p, 'NumberOfStrings', [2 5 10 15]);
    addParameter(p, 'Topology', {'string','multi-string','central'});
    addParameter(p, 'InverterRatedPower', [10e3 25e3 50e3]);
    addParameter(p, 'AcCableLengthKm', [0.1 0.5 1.0]);
    addParameter(p, 'Export', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(root, 'scripts')));
    parameterFile = fullfile(root, 'data', 'pv_station_parameters.mat');
    if ~isfile(parameterFile)
        init_pv_station_main();
    end
    S = load(parameterFile, 'PV', 'INV', 'TR', 'CABLE', 'SOLAR', 't_sim');
    params = struct('PV', S.PV, 'INV', S.INV, 'TR', S.TR, 'CABLE', S.CABLE);

    [nsm, nst, topology, pinv, lac] = ndgrid( ...
        p.Results.ModulesPerString, p.Results.NumberOfStrings, ...
        p.Results.Topology, p.Results.InverterRatedPower, p.Results.AcCableLengthKm);
    nCases = numel(nsm);
    records = cell(nCases, 11);

    for i = 1:nCases
        name = char(topology{i});
        switch name
            case 'string', nInv = nst(i);
            case 'multi-string', nInv = min(ceil(nst(i)/2), nst(i));
            otherwise, nInv = 1;
        end
        cfg = create_topology_config( ...
            'ModulesPerString', nsm(i), 'NumberOfStrings', nst(i), ...
            'Topology', name, 'NumberOfInverters', nInv, ...
            'InverterRatedPower', pinv(i), 'DcCableLength', 20, ...
            'AcCableLength', lac(i));
        r = evaluate_pv_station(cfg, params, S.SOLAR.G_profile, S.SOLAR.T_cell, ...
            'CableTemperature', S.CABLE.T_operating);

        E_pv = trapz(S.t_sim, r.P_pv_W) / 3.6e6;
        E_pcc = trapz(S.t_sim, r.P_pcc_W) / 3.6e6;
        E_loss = E_pv - E_pcc;
        capex = local_capex(cfg, params);
        records(i, :) = {i, nsm(i), nst(i), name, nInv, pinv(i)/1e3, lac(i), ...
            E_pv, E_pcc, E_loss, 100 * E_pcc / max(E_pv, eps)};
        capexValues(i, 1) = capex; %#ok<AGROW>
    end

    results_table = cell2table(records, 'VariableNames', { ...
        'Scenario_ID', 'Modules_per_string', 'Number_of_strings', 'Topology', ...
        'Number_of_inverters', 'Inverter_rating_kW', 'AC_cable_length_km', ...
        'E_PV_day_kWh', 'E_PCC_day_kWh', 'E_losses_day_kWh', 'Efficiency_percent'});
    results_table.CapEx_USD = capexValues;

    if p.Results.Export
        writetable(results_table, fullfile(root, 'reports', 'topology_study_results.csv'));
        save(fullfile(root, 'reports', 'topology_study_results.mat'), 'results_table');
    end
end

function capex = local_capex(cfg, params)
    pvKW = cfg.total_modules * params.PV.Pmax_stc / 1e3;
    invKW = cfg.number_of_inverters * cfg.inverter_rated_power / 1e3;
    trKVA = max(invKW, pvKW);
    % These unit costs are assumptions, not current market quotations.
    capex = 1.2 * (500 * pvKW + 300 * invKW + 50 * trKVA + 200 * cfg.ac_cable_length_km);
end
