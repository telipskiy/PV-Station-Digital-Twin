function [X_opt, Fopt_min, study] = optimize_topology(varargin)
%OPTIMIZE_TOPOLOGY Transparent discrete topology optimisation.
%   Evaluates physically screened alternatives with the quasi-static model.
%   Fopt_min is discounted lifecycle cost, not a surrogate for power quality
%   or reliability.  Such criteria need separately calibrated source data.

    p = inputParser;
    addParameter(p, 'ModulesPerString', [8 10 12 15]);
    addParameter(p, 'NumberOfStrings', [2 5 10 15]);
    addParameter(p, 'Topology', {'string','multi-string','central'});
    addParameter(p, 'InverterRatedPower', [10e3 25e3 50e3]);
    addParameter(p, 'TransformerRatedPower', [25e3 63e3 100e3]);
    addParameter(p, 'AcCableLengthKm', [0.1 0.5 1.0]);
    addParameter(p, 'AnnualisationDays', 365, @(x) validateattributes(x, {'numeric'}, {'scalar','positive'}));
    addParameter(p, 'EnergyValueUSDPerKWh', 0.10, @(x) validateattributes(x, {'numeric'}, {'scalar','nonnegative'}));
    addParameter(p, 'Export', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(root, 'scripts')));
    parameterFile = fullfile(root, 'data', 'pv_station_parameters.mat');
    if ~isfile(parameterFile), init_pv_station_main(); end
    S = load(parameterFile, 'PV', 'INV', 'TR', 'CABLE', 'SOLAR', 't_sim', 'ECONOMICS');
    params = struct('PV', S.PV, 'INV', S.INV, 'TR', S.TR, 'CABLE', S.CABLE);

    [mps, nstr, topology, pinv, str, lac] = ndgrid( ...
        p.Results.ModulesPerString, p.Results.NumberOfStrings, p.Results.Topology, ...
        p.Results.InverterRatedPower, p.Results.TransformerRatedPower, p.Results.AcCableLengthKm);
    n = numel(mps);
    rows = cell(n, 15);

    for k = 1:n
        topologyName = char(topology{k});
        nInv = local_inverter_count(topologyName, nstr(k));
        cfg = create_topology_config( ...
            'ModulesPerString', mps(k), 'NumberOfStrings', nstr(k), ...
            'Topology', topologyName, 'NumberOfInverters', nInv, ...
            'InverterRatedPower', pinv(k), 'DcCableLength', 20, ...
            'AcCableLength', lac(k));
        candidateParams = params;
        candidateParams.TR.S_rated = str(k);
        r = evaluate_pv_station(cfg, candidateParams, S.SOLAR.G_profile, S.SOLAR.T_cell, ...
            'CableTemperature', S.CABLE.T_operating);
        Eday = trapz(S.t_sim, r.P_pcc_W) / 3.6e6;
        lossDay = trapz(S.t_sim, r.P_pv_W - r.P_pcc_W) / 3.6e6;
        capex = local_capex(cfg, candidateParams, str(k));
        lifecycleCost = local_lifecycle_cost(capex, Eday, lossDay, S.ECONOMICS, ...
            p.Results.AnnualisationDays, p.Results.EnergyValueUSDPerKWh);
        if ~r.constraints.is_feasible, lifecycleCost = Inf; end
        rows(k, :) = {k, mps(k), nstr(k), topologyName, nInv, pinv(k)/1e3, ...
            str(k)/1e3, lac(k), Eday, lossDay, r.constraints.is_feasible, ...
            r.constraints.max_string_voltage_V, r.constraints.max_string_current_A, ...
            r.constraints.transformer_loading_pu, lifecycleCost};
    end

    alternatives = cell2table(rows, 'VariableNames', { ...
        'Alternative_ID','Modules_per_string','Number_of_strings','Topology', ...
        'Number_of_inverters','Inverter_rating_kW','Transformer_rating_kVA', ...
        'AC_cable_length_km','E_PCC_day_kWh','E_losses_day_kWh','Feasible', ...
        'Max_string_voltage_V','Max_string_current_A','Transformer_loading_pu', ...
        'Lifecycle_cost_USD'});
    feasible = alternatives(alternatives.Feasible, :);
    if isempty(feasible)
        error('PVStation:NoFeasibleDesign', 'No feasible topology in the specified design space.');
    end
    feasible = sortrows(feasible, 'Lifecycle_cost_USD');
    optimum = feasible(1, :);
    Fopt_min = optimum.Lifecycle_cost_USD;
    X_opt = [optimum.Modules_per_string, optimum.Number_of_strings, ...
        optimum.Number_of_inverters, optimum.Inverter_rating_kW*1e3, ...
        optimum.Transformer_rating_kVA*1e3, params.TR.U2_rated, ...
        local_topology_id(char(optimum.Topology)), optimum.AC_cable_length_km];
    study = struct('alternatives', alternatives, 'ranked_feasible', feasible, ...
        'optimum', optimum, 'criterion', 'Discounted lifecycle cost [USD]');

    if p.Results.Export
        writetable(alternatives, fullfile(root, 'reports', 'topology_optimisation_alternatives.csv'));
        save(fullfile(root, 'reports', 'topology_optimisation.mat'), 'X_opt', 'Fopt_min', 'study');
    end
end

function n = local_inverter_count(topology, nStrings)
    switch topology
        case 'string', n = nStrings;
        case 'multi-string', n = ceil(nStrings / 2);
        otherwise, n = 1;
    end
end

function id = local_topology_id(topology)
    id = find(strcmp({'string','multi-string','central'}, topology), 1);
end

function capex = local_capex(cfg, params, transformerRating)
    pvKW = cfg.total_modules * params.PV.Pmax_stc / 1e3;
    inverterKW = cfg.number_of_inverters * cfg.inverter_rated_power / 1e3;
    equipment = 500*pvKW + 300*inverterKW + 50*(transformerRating/1e3) + 200*cfg.ac_cable_length_km;
    capex = equipment * 1.2;
end

function cost = local_lifecycle_cost(capex, Eday, lossDay, economics, days, energyValue)
    annualOpex = capex * economics.annual_opex_rate;
    annualLossCost = lossDay * days * energyValue;
    years = 1:economics.study_period;
    annuityPV = sum(1 ./ (1 + economics.discount_rate) .^ years);
    cost = capex + (annualOpex + annualLossCost) * annuityPV;
end
