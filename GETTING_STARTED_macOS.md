# Getting Started - macOS with Apple Silicon (M1/M2/M3/M4)

## PV Station Digital Twin - MATLAB R2025a

---

## Швидкий старт / Quick Start

### 1. Ініціалізація
```matlab
% Додати шляхи та завантажити параметри
cd /path/to/PV-Station-Digital-Twin
init_pv_station_main
```

### 2. Запуск однієї симуляції
```matlab
% Симулювати однієї конфігурації
sim('PV_Station_Main')
```

### 3. Запуск дослідження чутливості
```matlab
% Параметричне дослідження всіх комбінацій
results = run_simulation_suite();
```

### 4. Оптимізація топології
```matlab
% Багатокритеріальна оптимізація з Genetic Algorithm
[X_opt, Fopt] = optimize_topology();
```

### 5. Аналіз результатів
```matlab
% Створити виходи для аналізу
plot_analysis(results);
generate_comprehensive_report();
```

---

## Quick Start

### Project Setup

```matlab
% Step 1: Navigate to project directory
cd /path/to/PV-Station-Digital-Twin

% Step 2: Add paths
addpath(genpath('./matlab_scripts'));
addpath(genpath('./simulink_models'));

% Step 3: Run compatibility test
test_compatibility();

% Step 4: Initialize parameters
init_pv_station_main();

% Step 5: Build models (programmatic)
build_pv_array_subsystem('SavePath', './simulink_models');
build_inverter_subsystem('SavePath', './simulink_models');
build_main_model('SavePath', './simulink_models');

% Step 6: Run simulation
sim('PV_Station_Main');
```

---

## Running Simulations

### Option 1: Single Simulation (24 hours)

```matlab
% Load model and run
simout = sim('PV_Station_Main', 'accelerator');

% Analyze results
plot_analysis(simout);
```

### Option 2: Sensitivity Analysis

```matlab
% Run parameter sweep (30-60 minutes)
results = run_simulation_suite();
```

### Option 3: Multi-Criteria Optimization

```matlab
% Run genetic algorithm (2-4 hours)
[X_opt, Fopt] = optimize_topology();
```

### Option 4: Full Workflow

```matlab
% Complete workflow with all analyses
results = run_full_workflow('ConfigType', 'optimization');
```

---

## Key Parameters

### PV Array
- **Module:** Canadian Solar CS6K-350MS (350W)
- **Configuration:** 10×5 = 50 modules
- **Total Power:** 17.5 kW
- **Array Voltage:** 391 V (typical)

### Inverter
- **Type:** 3-phase VSI (50 kW rated)
- **DC Link:** 600 V
- **Switching Frequency:** 10 kHz
- **Efficiency:** 98%

### Transformer (optional)
- **Power Rating:** 63 kVA
- **Voltage Ratio:** 0.4/10 kV
- **Impedance:** 6%

### Grid
- **Voltage:** 10 kV, 50 Hz
- **Cable Length:** 0.5 km
- **Cable Type:** NYC 3×150 mm²

---

## Performance Optimization for macOS Silicon

### Simulation Mode

```matlab
set_param('PV_Station_Main', 'SimulationMode', 'accelerator');
```

### Solver Configuration

```matlab
set_param('PV_Station_Main', 'SolverType', 'Variable-step');
set_param('PV_Station_Main', 'SolverName', 'ode23tb');
set_param('PV_Station_Main', 'RelTol', '1e-4');
set_param('PV_Station_Main', 'MaxStep', '0.1');
```

### Parallel Processing

```matlab
% For optimization with GA
options = optimoptions('ga', 'UseParallel', true);
```

---

## Troubleshooting

### Issue: Models not found
**Solution:** Run build scripts to create models
```matlab
build_pv_array_subsystem('SavePath', './simulink_models');
```

### Issue: Out of memory
**Solution:** Reduce simulation time or use smaller step size
```matlab
sim_config.StopTime = 3600;  % 1 hour instead of 24
```

### Issue: Slow simulation
**Solution:** Enable accelerator mode
```matlab
set_param(model_name, 'SimulationMode', 'accelerator');
```

---

## Project Structure Overview

```
PV-Station-Digital-Twin/
├── matlab_scripts/              - Control scripts
├── simulink_models/             - Simulink models (.slx)
├── data/                        - Input data and results
├── docs/                        - Documentation
└── reports/                     - Generated reports
```
