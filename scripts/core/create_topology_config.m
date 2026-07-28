function cfg = create_topology_config(varargin)
%CREATE_TOPOLOGY_CONFIG Configuration of a PV station electrical topology.
%   The configuration is deliberately independent of Simulink so that the
%   same design point can be used in steady-state studies and dynamic models.

    p = inputParser;
    addParameter(p, 'ModulesPerString', 10, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','positive'}));
    addParameter(p, 'NumberOfStrings', 5, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','positive'}));
    addParameter(p, 'Topology', 'central', @(x) any(strcmpi(string(x), ["string", "multi-string", "central"])));
    addParameter(p, 'NumberOfInverters', 1, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','positive'}));
    addParameter(p, 'InverterRatedPower', 50e3, @(x) validateattributes(x, {'numeric'}, {'scalar','positive'}));
    addParameter(p, 'DcCableLength', 20, @(x) validateattributes(x, {'numeric'}, {'vector','nonnegative'}));
    addParameter(p, 'AcCableLength', 0.5, @(x) validateattributes(x, {'numeric'}, {'scalar','nonnegative'}));
    parse(p, varargin{:});

    cfg.modules_per_string = p.Results.ModulesPerString;
    cfg.number_of_strings = p.Results.NumberOfStrings;
    cfg.topology = char(lower(string(p.Results.Topology)));
    cfg.number_of_inverters = p.Results.NumberOfInverters;
    cfg.inverter_rated_power = p.Results.InverterRatedPower;
    cfg.dc_cable_length_m = p.Results.DcCableLength;
    cfg.ac_cable_length_km = p.Results.AcCableLength;

    switch cfg.topology
        case 'string'
            requiredInverters = cfg.number_of_strings;
        case 'multi-string'
            requiredInverters = cfg.number_of_inverters;
        otherwise % central
            requiredInverters = 1;
    end
    if strcmp(cfg.topology, 'string')
        cfg.number_of_inverters = requiredInverters;
    elseif cfg.number_of_inverters > cfg.number_of_strings
        error('PVStation:Topology', 'NumberOfInverters cannot exceed NumberOfStrings.');
    end

    cfg.string_to_inverter = mod(0:cfg.number_of_strings-1, cfg.number_of_inverters) + 1;
    cfg.total_modules = cfg.modules_per_string * cfg.number_of_strings;
end
