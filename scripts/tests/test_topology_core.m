function test_topology_core()
%TEST_TOPOLOGY_CORE Regression tests for topology-dependent calculations.

    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(genpath(fullfile(root, 'scripts')));
    init_pv_station_main();
    S = load(fullfile(root, 'data', 'pv_station_parameters.mat'), 'PARAMS');

    central = create_topology_config('ModulesPerString', 10, 'NumberOfStrings', 6, ...
        'Topology', 'central', 'NumberOfInverters', 1, 'InverterRatedPower', 10e3, ...
        'DcCableLength', 20, 'AcCableLength', 0.5);
    string = create_topology_config('ModulesPerString', 10, 'NumberOfStrings', 6, ...
        'Topology', 'string', 'NumberOfInverters', 1, 'InverterRatedPower', 10e3, ...
        'DcCableLength', 20, 'AcCableLength', 0.5);
    rCentral = evaluate_pv_station(central, S.PARAMS, 1000, 25);
    rString = evaluate_pv_station(string, S.PARAMS, 1000, 25);
    assert(rString.configuration.number_of_inverters == 6, 'String topology must assign one inverter per string.');
    assert(rString.P_pcc_W > rCentral.P_pcc_W, 'Independent string inverters must reduce clipping in this case.');

    shortCable = create_topology_config('DcCableLength', 10, 'AcCableLength', 0.1);
    longCable = create_topology_config('DcCableLength', 100, 'AcCableLength', 1.0);
    rShort = evaluate_pv_station(shortCable, S.PARAMS, 1000, 25);
    rLong = evaluate_pv_station(longCable, S.PARAMS, 1000, 25);
    assert(rLong.P_ac_cable_loss_W > rShort.P_ac_cable_loss_W, 'AC cable length must affect losses.');
    assert(rLong.P_dc_loss_W > rShort.P_dc_loss_W, 'DC cable length must affect losses.');
    disp('test_topology_core: PASS');
end
