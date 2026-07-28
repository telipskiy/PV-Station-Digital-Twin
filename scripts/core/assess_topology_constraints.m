%  ========================================================================
%  DIGITAL TWIN: Screen a topology against electrical limits.
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 28.07.2026
%  
%   Ampacity values are design inputs, not tabulated defaults: their valid
%   values depend on installation method, ambient temperature and grouping.
%  ========================================================================

function assessment = assess_topology_constraints(result, params)
    
    cfg = result.configuration;
    Pinv = result.P_inverter_ac_W(:);
    Imv = result.I_mv_A(:);
    Vstr = result.V_string_mpp_V(:);
    Istr = result.I_string_mpp_A(:);

    inverterLoading = max(Pinv, [], 1) / max(cfg.number_of_inverters * cfg.inverter_rated_power, eps);
    transformerLoading = max(Pinv, [], 1) / max(params.TR.S_rated, eps);
    voltageOK = min(Vstr) >= cfg.dc_voltage_range_V(1) && max(Vstr) <= cfg.dc_voltage_range_V(2);

    assessment = struct();
    assessment.max_string_voltage_V = max(Vstr);
    assessment.min_string_voltage_V = min(Vstr);
    assessment.max_string_current_A = max(Istr);
    assessment.max_mv_current_A = max(Imv);
    assessment.inverter_loading_pu = inverterLoading;
    assessment.transformer_loading_pu = transformerLoading;
    assessment.voltage_within_dc_range = voltageOK;
    assessment.dc_ampacity_ok = assessment.max_string_current_A <= cfg.dc_cable_ampacity_A;
    assessment.ac_ampacity_ok = assessment.max_mv_current_A <= cfg.ac_cable_ampacity_A;
    assessment.inverter_loading_ok = inverterLoading <= 1;
    assessment.transformer_loading_ok = transformerLoading <= 1;
    assessment.is_feasible = voltageOK && assessment.dc_ampacity_ok && ...
        assessment.ac_ampacity_ok && assessment.inverter_loading_ok && assessment.transformer_loading_ok;
    assessment.notes = 'Screening only; voltage drop, insulation, protection and thermal calculations require project-specific inputs.';
    
end
