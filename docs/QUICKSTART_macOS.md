# macOS Silicon: Getting Started Guide

## PV Station Digital Twin for MATLAB R2025a

### Quick Reference

**Platform:** macOS with Apple Silicon (M1/M2/M3/M4+)  
**MATLAB:** R2025a  
**Project:** PV Station Digital Twin (PhD Dissertation)  

---

## 1. Installation & Setup

```bash
# Clone repository
git clone https://github.com/telipskiy/PV-Station-Digital-Twin.git
cd PV-Station-Digital-Twin

# Open in MATLAB
matlab
```

---

## 2. First Steps in MATLAB

```matlab
% Add project paths
addpath(genpath('./matlab_scripts'));
addpath(genpath('./simulink_models'));

% Test system compatibility
test_compatibility();

% Initialize all parameters
init_pv_station_main();
```

---

## 3. Build Simulink Models

```matlab
% Create models programmatically
build_pv_array_subsystem('SavePath', './simulink_models');
build_inverter_subsystem('SavePath', './simulink_models');
build_main_model('SavePath', './simulink_models');
```

---

## 4. Run Simulation

```matlab
% Single 24-hour simulation
simout = sim('PV_Station_Main', 'accelerator');

% Analyze and plot results
plot_analysis(simout);
```

---

## 5. Available Operations

| Operation | Command | Duration |
|-----------|---------|----------|
| Single Simulation | `sim('PV_Station_Main')` | 20-30 min |
| Sensitivity Analysis | `run_simulation_suite()` | 30-60 min |
| Optimization | `optimize_topology()` | 2-4 hours |
| Full Workflow | `run_full_workflow()` | 4-6 hours |

---

## Key System Parameters

- **PV Array:** 50 modules, 17.5 kW total
- **Inverter:** 50 kW, 3-phase, SVM control
- **Transformer:** 63 kVA, 0.4/10 kV
- **Grid:** 10 kV, 50 Hz

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Model files not found | Run build scripts |
| Out of memory | Reduce StopTime parameter |
| Slow simulation | Use accelerator mode |
| Compatibility warnings | Normal for ARM64, ignore |

---

**Documentation:** See README.md and ARCHITECTURE.md  
**Repository:** github.com/telipskiy/PV-Station-Digital-Twin
