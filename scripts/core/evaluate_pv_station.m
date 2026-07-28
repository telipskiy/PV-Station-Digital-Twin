% ========================================================================
%  DIGITAL TWIN: Quasi-static, energy-balanced PV-station calculation.
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 28.07.2026
%
%   G and Tcell may be scalars or equally sized vectors.  The calculation
%   preserves the topology explicitly: each string is assigned to an
%   inverter, and both DC and AC cable losses depend on their lengths.
%  ========================================================================

function result = evaluate_pv_station(cfg, params, G, Tcell, varargin)

    p = inputParser;
    
    addParameter(p, 'CableTemperature', 20, @(x) validateattributes(x, {'numeric'}, {'scalar'}));
    addParameter(p, 'PowerFactor', 1, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0,'<=',1}));
    parse(p, varargin{:});
    validateattributes(G, {'numeric'}, {'nonnegative'});
    validateattributes(Tcell, {'numeric'}, {'size', size(G)});

    if ~isfield(params, 'PV') || ~isfield(params, 'CABLE') || ~isfield(params, 'INV') || ~isfield(params, 'TR')
        error('PVStation:Parameters', 'params must contain PV, INV, TR and CABLE structures.');
    end
    if numel(cfg.dc_cable_length_m) == 1
        dcLength = repmat(cfg.dc_cable_length_m, cfg.number_of_strings, 1);
    else
        dcLength = cfg.dc_cable_length_m(:);
        if numel(dcLength) ~= cfg.number_of_strings
            error('PVStation:DCCableLength', 'DcCableLength must be scalar or have one value per string.');
        end
    end

    % String MPP model. Coefficients are specified at STC; gamma_P is %/K.
    g = G(:); t = Tcell(:);
    irradianceFactor = g / params.PV.G_ref;
    temperatureFactor = max(0, 1 + (params.PV.gamma_P / 100) .* (t - params.PV.T_ref));
    Vstring = cfg.modules_per_string * (params.PV.Vmp_stc + params.PV.beta_V .* (t - params.PV.T_ref));
    Istring = params.PV.Imp_stc .* irradianceFactor .* (1 + params.PV.alpha_I .* (t - params.PV.T_ref));
    Istring = max(Istring, 0);
    Pstring = max(Vstring .* Istring .* temperatureFactor, 0);

    % DC losses are evaluated per string so unequal collector lengths matter.
    rhoCu = 0.0175; % ohm mm^2/m at 20 C
    rdc = 2 * rhoCu .* dcLength / cfg.dc_cable_cross_section_mm2 .* ...
        (1 + 0.00393 * (p.Results.CableTemperature - 20));
    PdcLoss = sum((Istring.^2) * rdc.', 2);
    PdcAvailable = max(cfg.number_of_strings * Pstring - PdcLoss, 0);

    % Allocate DC power to inverters according to their connected strings.
    PinvIn = zeros(numel(g), cfg.number_of_inverters);
    for k = 1:cfg.number_of_inverters
        connected = find(cfg.string_to_inverter == k);
        PinvIn(:, k) = max(numel(connected) * Pstring - ...
            (Istring.^2) * sum(rdc(connected)), 0);
    end
    etaInv = 0.985 - 0.015 * exp(-PinvIn / max(cfg.inverter_rated_power, 1));
    PinvOut = min(PinvIn, cfg.inverter_rated_power) .* etaInv;
    Pclip = sum(max(PinvIn - cfg.inverter_rated_power, 0), 2);
    PacLv = sum(PinvOut, 2);

    % Transformer and MV collector losses.  Cable R uses configured length.
    PtransformerLoss = params.TR.P_k0 * double(PacLv > 0) + params.TR.P_km .* (PacLv / params.TR.S_rated).^2;
    UmvLL = params.TR.U2_rated * 1e3;
    Imv = PacLv ./ (sqrt(3) * UmvLL * p.Results.PowerFactor);
    Rac = params.CABLE.R_per_km * cfg.ac_cable_length_km * ...
        (1 + params.CABLE.alpha * (p.Results.CableTemperature - params.CABLE.T_ref));
    PacCableLoss = 3 * Imv.^2 * Rac;
    Ppcc = max(PacLv - PtransformerLoss - PacCableLoss, 0);

    result = struct();
    result.P_pv_W = reshape(cfg.number_of_strings * Pstring, size(G));
    result.P_dc_loss_W = reshape(PdcLoss, size(G));
    result.P_inverter_ac_W = reshape(PacLv, size(G));
    result.P_inverter_clipping_W = reshape(Pclip, size(G));
    result.P_transformer_loss_W = reshape(PtransformerLoss, size(G));
    result.P_ac_cable_loss_W = reshape(PacCableLoss, size(G));
    result.P_pcc_W = reshape(Ppcc, size(G));
    result.efficiency = reshape(Ppcc ./ max(cfg.number_of_strings * Pstring, eps), size(G));
    result.R_ac_ohm_per_phase = Rac;
    result.I_mv_A = reshape(Imv, size(G));
    result.V_string_mpp_V = reshape(Vstring, size(G));
    result.I_string_mpp_A = reshape(Istring, size(G));
    result.configuration = cfg;
    result.constraints = assess_topology_constraints(result, params);
    
end
