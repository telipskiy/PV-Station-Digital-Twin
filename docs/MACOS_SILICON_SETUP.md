# Setup Guide for PV Station Digital Twin

## Platform Information

- **OS**: macOS (Monterey, Ventura, or Sonoma)
- **Architecture**: Apple Silicon (ARM64)
- **MATLAB Version**: R2025a
- **Compatibility**: Native ARM64 support

---

## Installation Steps

### 1. MATLAB R2025a Setup on macOS

```bash
# Check MATLAB installation
matlab -r "ver"

# Verify toolboxes
matlab -r "license('test', 'Simulink')"
```

### 2. Install Required Toolboxes

Required toolboxes for this project:

1. **Simulink**
2. **Simscape Electrical**
3. **Control System Toolbox**
4. **Optimization Toolbox**
5. **Signal Processing Toolbox**
6. **Parallel Computing Toolbox** (optional, for speed-up)

### 3. Verify Installation

```bash
# In MATLAB:
>> matlab.addons.toolbox.installedToolboxes
```

---

## Project Setup

### 1. Clone Repository

```bash
git clone https://github.com/telipskiy/PV-Station-Digital-Twin.git
cd PV-Station-Digital-Twin
```

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
>> COMPATIBILITY_CHECK
>> init_pv_station_main
```

---

## Running Simulations

### Quick Start

```matlab
% 1. Check system compatibility
>> COMPATIBILITY_CHECK

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

---

## File Structure

```
PV-Station-Digital-Twin/
├── matlab_scripts/
│   ├── init_pv_station_main.m
│   ├── create_simulink_models.m
│   ├── load_simulink_models.m
│   ├── configure_macos_compatibility.m
│   └── run_complete_simulation.m
│
├── simulink_models/  (auto-generated)
│   ├── PV_Station_Main.slx
│   ├── PV_Array_Subsystem.slx
│   ├── Inverter_Subsystem.slx
│   ├── Transformer_Subsystem.slx
│   └── Network_Subsystem.slx
│
├── data/
│   └── pv_station_parameters.mat
│
├── startup_pv_station.m
└── README.md
```

---

**Version:** 1.0  
**Last Updated:** 2026-05-27  
**Status:** Production Ready for MATLAB R2025a on macOS Apple Silicon


"}, "path": "COMPATIBILITY_CHECK.m", "content": "%