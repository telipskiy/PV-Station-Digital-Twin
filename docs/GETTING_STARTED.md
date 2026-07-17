# Setup Guide for PV Station Digital Twin

### 1. Installation

```bash
# Clone repository
git clone https://github.com/telipskiy/PV-Station-Digital-Twin.git
cd PV-Station-Digital-Twin

# Open in MATLAB
matlab
```

### 2. Automatic Project Startup

Copy `startup_pv_station.m` to MATLAB startup folder:

```bash
cp startup_pv_station.m ~/Documents/MATLAB/
```

Or set in MATLAB:

```matlab
% In MATLAB Preferences:
% Home > Preferences > General > Startup File
% Point to: ~/PV-Station-Digital-Twin/startup_pv_station.m
```

### 3. Manual Project Setup

```matlab
% Navigate to project directory
cd /Users/denis/Documents/MATLAB/PV-Station-Digital-Twin

% Complete workflow
run_simulation_complete

% Or step-by-step

% Step 1: Add paths
addpath(genpath('./data'));
addpath(genpath('./docs'));
addpath(genpath('./matlab_scripts'));
addpath(genpath('./simulink_models'));

% Step 2: Run compatibility test
test_compatibility();

% Step 3: Initialize parameters
init_pv_station_main();

% Step 4: Build models (programmatic)
build_all_models();

% Step 4.1: Set topology params (not sure if needed)
X = [ns, np, Pinv, Str, Umv, Atop, Lcab];

% Step 5: Run single 24-hour simulation
simout = sim('PV_Station_Main', 'accelerator'); % Results automatically logged and analyzed

% Step 6: Analyze and plot results
plot_analysis(simout);

% Analyze results
P_pv_daily = trapz(time, P_pv) / 3.6e6    % Daily energy [kWh]
system_eta = mean(efficiency)             % Average efficiency

% Step 7: Run complete simulation suite
[sim_results, analysis_results] = run_complete_simulation()
```

### 4. Running Simulations

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

Option 5: Full Workflow
```matlab
% Complete workflow with all analyses
results = run_full_workflow('ConfigType', 'optimization');
```

### 5. Available Operations

| Operation | Command | Duration |
|-----------|---------|----------|
| Single Simulation | `sim('PV_Station_Main')` | 20-30 min |
| Sensitivity Analysis | `run_simulation_suite()` | 30-60 min |
| Optimization | `optimize_topology()` | 2-4 hours |
| Full Workflow | `run_full_workflow()` | 4-6 hours |

## 6. Key System Parameters

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

## 7. Troubleshooting

| Problem | Solution |
|---------|----------|
| Model files not found | Run build scripts |
| Slow simulation | Use accelerator mode |
| Compatibility warnings | Normal for ARM64, ignore |
| Out of memory | Reduce StopTime parameter |

### Issue: Models not found

```matlab
>> build_all_simulink_models();
```

### Issue: Slow Simulation

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

```matlab
% Reduce simulation time or use smaller step size
sim_config.StopTime = 3600;  % 1 hour instead of 24
```

```matlab
% Close unnecessary figures
close all;
```