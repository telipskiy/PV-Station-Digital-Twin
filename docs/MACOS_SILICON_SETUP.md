# Setup Guide for PV Station Digital Twin


## Project Setup

### 2. Configure MATLAB Startup

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

### 3. Initialize Project

```matlab
% In MATLAB:
>> cd /path/to/PV-Station-Digital-Twin
>> test_compatibility
>> init_pv_station_main
```

---

## Running Simulations

### Quick Start

```matlab
% 1. Check system compatibility
>> test_compatibility

% 2. Create all models programmatically
>> create_simulink_models

% 3. Run single 24-hour simulation
>> sim('PV_Station_Main')

% 4. Run complete simulation suite
>> [sim_results, analysis_results] = run_complete_simulation()
```

### Performance Tips for Apple Silicon

**Use Accelerator Mode**

```matlab
set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
```

**Enable Parallel Computing**
```matlab
% Open parallel pool
parpool('Threads');
```

**Monitor CPU Usage**
```bash
# In Terminal:
top -P -l 1 | head -20
```

---

## Troubleshooting

### Issue: Models not found

**Solution:**
```matlab
>> create_simulink_models;
```

### Issue: Slow Simulation

**Solution:**
```matlab
% Use Accelerator mode
set_param('PV_Station_Main', 'SimulationMode', 'Accelerator');
```

### Issue: Out of Memory

**Solution:**
```matlab
% Close unnecessary figures
close all;
```

