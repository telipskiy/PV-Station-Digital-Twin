# Початок роботи

## Статус моделі

Основний відтворюваний сценарій — квазіусталений часовий розрахунок структури СЕС. 
Він придатний для порівняння кількості модулів, стрінгів, інверторів і кабельних трас.
Він не є результатом моделювання гармонік, комутаційних перехідних процесів або відповідності мережевому коду. 
Деталі наведено у [межах застосовності](MODEL_SCOPE_AND_VALIDATION.md).

### 1. Підготовка

```bash
# Clone repository
git clone https://github.com/telipskiy/PV-Station-Digital-Twin.git
cd PV-Station-Digital-Twin
```

### 2. Запуск проєкту

```matlab
% Navigate to project directory
cd /Users/denis/Documents/MATLAB/PV-Station-Digital-Twin

% Step 1: Add paths
addpath(genpath('./'));

% Step 2: Run compatibility test
test_compatibility();

% Step 3: Initialize parameters & test topology
test_topology_core();

% Step 4: Build models (programmatic)
build_all_models();

% Step 5: Load all created Simulink models
load_simulink_models();

```

Згенеровані Simulink-моделі компілюються.
Їхній повний динамічний та гармонічний аналіз ще не верифіковано;
не застосовувати його результати як доказ THD, поведінки PLL або відповідності IEEE/IEC.

### Not verified for now

```matlab
% Step 7: Run single 24-hour simulation
sim('PV_Station_Main');

% Results are automatically saved to workspace:
% P_pv_log              - PV power [W]
% P_inv_log             - Inverter power [W]
% P_loss_trans_log      - Transformer losses [W]
% f_grid_log            - Grid frequency [Hz]
% V_pcc_log             - PCC voltage [V]

% Step 8: Analyze and plot results
create_analysis_plots();

% Export to Excel
export_results_to_excel();

% Generate comprehensive report
generate_comprehensive_report();

% Analyze results
P_pv_daily = trapz(time, P_pv) / 3.6e6    % Daily energy [kWh]
system_eta = mean(efficiency)             % Average efficiency

% OR Step 8: Run complete simulation suite
[sim_results, analysis_results] = run_complete_simulation()
```

### 3. Один розрахунок топології

```matlab
[result, analysis] = run_complete_simulation( ...
    'Topology', 'multi-string', ...
    'ModulesPerString', 10, ...
    'NumberOfStrings', 6, ...
    'NumberOfInverters', 3, ...
    'InverterRatedPower', 10e3, ...
    'DcCableLength', 20, ...
    'AcCableLength', 0.5);

analysis.E_pcc_day_kWh
analysis.E_loss_day_kWh
analysis.average_efficiency_percent
analysis.constraints
```

Параметр `DcCableLength` є скаляром або вектором з одним значенням для кожного стрінгу. 
Це дозволяє моделювати нерівні колекторні траси.

### 4. Параметрична серія

```matlab
results = run_simulation_suite( ...
    'ModulesPerString', [8 10 12], ...
    'NumberOfStrings', [2 5 10], ...
    'Topology', {'string','multi-string','central'}, ...
    'InverterRatedPower', [10e3 25e3 50e3], ...
    'AcCableLengthKm', [0.1 0.5 1.0]);
```

У результати включено `Feasible`, максимальні струми та напругу стрінгу.
Недопустимі варіанти не слід використовувати для порівняльних висновків.

### 5. Вибір найкращої альтернативи

```matlab
[X_opt, lifecycleCost, study] = optimize_topology( ...
    'ModulesPerString', [8 10 12], ...
    'NumberOfStrings', [2 5 10], ...
    'Topology', {'string','multi-string','central'});

study.optimum
```

Критерій оптимізації — дисконтовані життєві витрати за введених економічних припущень.
Перед публікацією замінити сценарні ціни і профілі на дані із документованих джерелами.

### 5. Parameter Customization

Edit `init_pv_station_main.m` to modify:
- PV module parameters (Pmax, Voc, Isc, etc.)
- Inverter settings (rated power, switching frequency)
- Transformer parameters (power rating, impedance)
- Grid parameters (voltage, frequency)
- Cable properties (length, cross-section)

### 6. Running Simulations

Option 1: Single Simulation (24 hours)
```matlab
% Load model and run
simout = sim('PV_Station_Main')

% OR Load model and run with accelerator
simout = sim('PV_Station_Main', 'accelerator');

% Analyze results
plot_analysis(simout);
```

Option 2: Sensitivity Analysis
```matlab
% Run parameter sweep for all combinations (30-60 minutes)
results = run_simulation_suite();
```

Option 3: Multi-Criteria Optimization with Genetic Algorithm
```matlab
% Run genetic algorithm (2-4 hours)
[X_opt, Fopt] = optimize_topology();
```

Option 3.1: Run Genetic Algorithm optimization (not sure if needed)
```matlab
% Run genetic algorithm
[X_opt, Fopt_min] = ga(@objective_function, ...
    7, [], [], [], [], [5, 2, 25e3, 25e3, 0.4, 1, 0.5], ...
    [20, 20, 100e3, 100e3, 20, 3, 2], @constraints);
```

Option 4: Results Analysis
```matlab
% Create analysis outlets
plot_analysis(results);

% Export to Excel
export_results_to_excel(results);

generate_comprehensive_report();
```

```matlab
% After simulation Extract results
P_pv = sim_output.P_pv_log;      % PV power [W]
P_inv = sim_output.P_inv_log;    % Inverter power [W]
V_pcc = sim_output.V_pcc_log;    % PCC voltage [%]
eta = sim_output.eta_log;        % Efficiency [%]

% Calculate daily energy
E_daily = trapz(time, power) / 3.6e6  % [kWh]
```

Option 5: Full Workflow
```matlab
% Complete workflow with all analyses
results = run_full_workflow('ConfigType', 'optimization');
```

### 6. Available Operations

| Operation | Command | Duration |
|-----------|---------|----------|
| Single Simulation | `sim('PV_Station_Main')` | 20-30 min |
| Sensitivity Analysis | `run_simulation_suite()` | 30-60 min |
| Optimization | `optimize_topology()` | 2-4 hours |
| Full Workflow | `run_full_workflow()` | 4-6 hours |

## 7. Key System Parameters

### PV Array
- **Module:** Canadian Solar CS6K-350MS (350W)
- **Configuration:** 10×5 = 50 modules
- **Total Power:** 17.5 kW
- **Array Voltage:** 391 V (typical)

### Inverter
- **Type:** 3-phase VSI (50 kW rated), SVM control
- **DC Link:** 600 V
- **Switching Frequency:** 10 kHz
- **Efficiency:** 98%

### Transformer
- **Power Rating:** 63 kVA
- **Voltage Ratio:** 0.4/10 kV
- **Impedance:** 6%

### Grid
- **Voltage:** 10 kV, 50 Hz
- **Cable Length:** 0.5 km
- **Cable Type:** NYC 3×150 mm²

## 8. Troubleshooting

| Problem | Solution |
|---------|----------|
| Model files not found | Run build scripts |
| Slow simulation | Use accelerator mode |
| Compatibility warnings | Normal for ARM64, ignore |
| Out of memory | Reduce StopTime parameter |

### Convergence Issues
- Check input signal continuity
- Verify parameter ranges
- Adjust solver tolerances

### Issue: Models not found

```matlab
% Clear and restart
clear all; close all; clc;
rehash toolboxcache
build_all_models
```

### Issue: Slow Simulation

- Reduce max step size (improves convergence)
- Use SimulationMode: 'Accelerator' (faster execution)
- Pre-compile models

```matlab
% Solver Configuration
set_param('PV_Station_Main', 'SolverType', 'Variable-step');
set_param('PV_Station_Main', 'SolverName', 'ode23tb');
set_param('PV_Station_Main', 'RelTol', '1e-4');
set_param('PV_Station_Main', 'MaxStep', '0.1');
```

```matlab
% Use Accelerator mode
set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
```

```matlab
% Enable Parallel Computing (Open parallel pool)
parpool('Threads');
```

```matlab
% Parallel Processing for optimization with GA
options = optimoptions('ga', 'UseParallel', true);
```

```bash
# Monitor CPU Usage in Terminal:
top -P -l 1 | head -20
```

### Issue: Out of Memory

- Use shorter simulation times
- Reduce logging frequency
- Save results incrementally

```matlab
% Reduce simulation time or use smaller step size
sim_config.StopTime = 3600;  % 1 hour instead of 24
```

```matlab
% Close unnecessary figures
close all;
```

### Issue: "Results look wrong" (e.g., V_pcc = 0)

**Cause:** Workspace profiles not loaded  
**Solution:**
```matlab
init_pv_station_main();   % Load parameters
sim('PV_Station_Main');   % Run simulation
```

### Issue: "Inverter currents are constant instead of varying"

**Cause:** MPPT current reference not updating  
**Solution:** Check that G_profile and T_profile are time-varying (not constants)
