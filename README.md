# Цифровий Двійник Фотоелектричної Станції (Digital Twin of PV Station)

## Опис / Description

Цей проект реалізує комплексний цифровий двійник сонячної електростанції станції у середовищі **MATLAB Simulink**.

Digital twin system of photovoltaic station implemented in **MATLAB Simulink** using **Simscape Electrical** library.

**PhD Topic:** "Justification of the Rational Structure of Electrical Circuits of Stations with Solar Generation"

**Дата створення:** 26.05.2026  

- Архітектура: Багаторівнева ієрархічна модель (Рівні 0-3)
- Симуляція: 24-годинний цикл у реальному часі/прискореному режимі
- Оптимізація: Багатокритеріальна оптимізація з GA (Genetic Algorithm)

## Status

✅ **Complete**
- Single Diode PV model with temperature & irradiance dependency
- Advanced inverter control (PLL, SVM, current regulation)
- Comprehensive transformer model with losses
- Grid network with cable impedance
- 24-hour simulation
- Power quality metrics
- Data logging & visualization


## Вимоги до системи / System Requirements

- **Платформа**: macOS з Apple Silicon (M1/M2/M3/M4+)
- **MATLAB**: R2025a або новіше
- **Toolboxes**:
  - Simulink
  - Simscape Electrical
  - Optimization Toolbox
  - Symbolic Math Toolbox
  - Control System Toolbox
  - Signal Processing Toolbox
  - Parallel Computing Toolbox (опціонально, для прискорення роботи)

---

## Ключові можливості / Key Features:

✅ **Багаторівнева ієрархічна архітектура** - Multi-level hierarchical architecture  
✅ **Нелінійна модель фотоелектричного поля** - Nonlinear PV array model (Single Diode)  
✅ **Трьохфазний інвертор з PWM** - 3-phase VSI inverter with advanced control (SVM, PLL, current regulation)  
✅ **Система управління (PLL, MPPT)** - Control system (PLL, MPPT)  
✅ **Трансформатор з урахуванням втрат** - Transformer T-equivalent model with losses  
✅ **Мережа** - Grid network model with cable impedance 
✅ **Багатокритеріальна оптимізація** - Multi-criteria optimization (Genetic Algorithm)  
✅ **Аналіз якості електроенергії** - Power quality analysis (THD, Voltage deviation, etc.)  
✅ **Економічна оцінка (LCOE)** - Economic evaluation (LCOE calculation)  
✅ **24-годинне моделювання** - 24-hour simulation cycle  
✅ **Порівняльний аналіз топологій** - Topology comparative analysis  


## Функціональність:

✅ **Моделювання різних топологій СЕС**   
✅ **Автоматизована зміна конфігурації електричної схеми**  
✅ **Оцінювання техніко-економічних показників**    
✅ **Визначення втрат електроенергії**  
✅ **Аналіз режимів роботи**  
✅ **Оцінювання показників якості електроенергії**  
✅ **Визначення інтегрального критерію оптимізації**  
✅ **Накопичення результатів чисельних експериментів**  
✅ **Візуалізація електричних параметрів**  
✅ **Автоматичне формування порівняльних характеристик**  

### 1. Automatic Profile Generation

```matlab
% 24-hour profiles generated automatically
% - Solar irradiance (Gaussian + noise)
% - Cell temperature (ambient + irradiance effects)
% - Load demand (typical daily pattern)
% - Resolution: 1-minute intervals
```

### 2. Complete Signal Routing

```matlab
% All components interconnected
% Signal flow: PV → Inverter → Transformer → Network
% Feedback: Grid voltage → PLL, Phase → Current control
```

### 3. Power Quality Tracking

```matlab
% Real-time metrics:
% - Voltage deviation from nominal
% - System efficiency calculation
% - Cable and transformer losses
% - Total harmonic distortion estimation
```

### 4. Data Logging System

```matlab
% Automatic logging to workspace variables:
sim_output.P_pv_log       % PV power [W]
sim_output.P_inv_log      % Inverter power [W]
sim_output.V_pcc_log      % PCC voltage deviation [%]
sim_output.eta_log        % System efficiency [%]
```

### 5. Visualization & Reporting

```matlab
% Automatic generation:
% - Power generation plots
% - Voltage deviation graphs
% - Efficiency trends
% - Summary text report
```

## ОПИС ФАЙЛІВ ПРОЕКТУ

```
PV-Station-Digital-Twin/
│
├── README.md                               # Цей файл
├── TODO.md                                 # Наступні кроки та ідеї
│
├── data/                                   # Дані
│   ├── profiles_24h.fig                    # 24 Sample profiles for solar irradiance, temperature, load (згенеровані скриптом init_24h_profiles.m)
│   ├── profiles_24h.mat                    # 24 Sample profiles for solar irradiance, temperature, load (згенеровані скриптом init_24h_profiles.m)
│   └── pv_station_parameters.mat           # Параметри фотоелектричної станції (згенеровані скриптом init_pv_station_main.m)
│
├── docs/                                   # Документація
│   ├── ARCHITECTURE.md                     # Опис архітектури системи
│   └── GETTING_STARTED.md                  # Керівництво з використання
│
├── examples/                               # Приклади Simulink (використовувати для покращення підсистем і моделей)
│
├── reports/                                # Зберігання результатів
│
├── scripts/                                # MATLAB керуючі скрипти
│   │
│   ├── build/                              # Cкрипти створення підсистем та головної системи
│   │   ├── build_all_models.m              # Створення повної моделі сонячної електростанції
│   │   ├── build_digital_twin_model.m      # Створення головної моделі
│   │   ├── build_inverter_subsystem.m      # Створення підсистеми інвертора
│   │   ├── build_network_subsystem.m       # Створення підсистеми мережі станції
│   │   ├── build_pv_array_subsystem.m      # Створення пісистеми фотоелектричного поля
│   │   └── build_transformer_subsystem.m   # Створення пісистеми фотоелектричного поля
│   │
│   ├── controllers/                        # Контроллери
│   │   └── AdvancedMPPT.m                  # Контролер системи слідження точки максимуму потужності
│   │
│   ├── core/                               # Ядро
│   │   ├── ConfigValidator.m               # Валідація конфігурації системи
│   │   └── Logger.m                        # Система логування для проєкту
│   │
│   ├── deprecated/                         # Старі скрипти створення підсистем (працюють з помилками виконання, не використовуються)
│   │   ├── build_all_simulink_models.m     # Створення повної моделі сонячної електростанції
│   │   ├── build_inverter_subsystem.m      # Створення підсистеми інвертора
│   │   ├── build_main_model.m              # Створення головної системи
│   │   └── build_pv_array_subsystem.m      # Створення пісистеми фотоелектричного поля
│   │
│   ├── init/                               # Ініціалізація
│   │   ├── init_24h_profiles.m             # Ініціалізація добових профілів
│   │   ├── init_environment.m              # Ініціалізація шляхів та параметрів MATLAB/Simulink
│   │   ├── init_pv_station_main.m          # Ініціалізація параметрів станції
│   │   └── load_simulink_models.m          # Завантаження Simulink-моделей
│   │
│   ├── models/                             # Моделі
│   │   ├── GridModel.m                     # Модель електричної мережі
│   │   ├── InverterModel.m                 # Удосконалена модель інвертора
│   │   └── PVArrayModel.m                  # Удосконалена модель фотоелектричного поля
│   │
│   ├── tests/                              # Тести
│   │   └── test_compatibility.m            # Перевірка валідності системи
│   │
│   ├── utils/                              # Допоміжні функції
│   │   │
│   │   ├── diff/                           # Різне
│   │   │   ├── compute_statistics.m        # Розрахунок статистики
│   │   │   └── validate_configuration.m    # Перевірка конфігурації
│   │   │
│   │   ├── plotting/                       # Відображення результатів
│   │   │   ├── create_analysis_plots.m     # Візуальний аналіз результатів
│   │   │   ├── plot_analysis.m             # Візуальний аналіз
│   │   │   └── plot_time_series.m          # Візуальний аналіз серій
│   │   │ 
│   │   └── reporting/                      # Створення звітів
│   │       ├── create_summary_report.m     # Генерація звіту по результатах
│   │       ├── export_results_to_csv.m     # Експорт резултатів в .CSV файл
│   │       ├── export_results_to_excel.m   # Експорт резултатів в Excel файл
│   │       └── generate_comprehensive_report.m # Генерація повного звіту
│   │
│   ├── optimize_topology.m                 # Багатокритеріальна Оптимізація топологій (Genetic Algorithm)
│   ├── run_complete_simulation.m           # Запуск повної симуляції
│   ├── run_full_workflow.m                 # Запуск повного workflow
│   ├── run_simulation_suite.m              # Запуск серій експериментів
│   └── run_system.m                        # Скрипт для автоматичної конфігурації, сворення моделей, симуляції та аналізу результатів 
│
└── simulink_models/                        # Simulink моделі (згенеровані скриптом build_all_simulink_models.m)
    ├── PV_Station_Main.slx                 # Головна модель (Рівень 1)
    ├── PV_Array_Subsystem.slx              # Фотоелектричне поле (Рівень 2.1)
    ├── Inverter_Subsystem.slx              # Інвертор (Рівень 2.2)
    ├── Transformer_Subsystem.slx           # Трансформатор (Рівень 2.3)
    └── Network_Subsystem.slx               # Мережа (Рівень 2.4)
 ```

## Математична модель / Mathematical Model

### Цільова функція оптимізації / Objective Function

```
Fopt = w1·Fcap + w2·Floss + w3·Frel + w4·Fopex + w5·Fpq → min

де / where:
  Fcap  - капітальні витрати [USD]
  Floss - втрати енергії [USD/рік]
  Frel  - показники надійності [USD]
  Fopex - експлуатаційні витрати [USD/рік]
  Fpq   - якість електроенергії [USD]
  w_i   - вагові коефіцієнти (нормовані на 1)
```

### Обмеження / Constraints

1. **Баланс потужності**: P_PV ≤ Σ P_INV
2. **Напруга**: 0.95·U_nom ≤ U_i ≤ 1.05·U_nom
3. **Струм**: I_k ≤ I_k,max
4. **Температура**: T_conductor ≤ T_max
5. **Надійність**: SAIDI ≤ SAIDI_max

---

## Параметри Simulink моделей / Simulink Models Parameters

### 1. PV_Array_Subsystem

- **Модель**: Single Diode Model (нелінійна)
- **Параметри модуля**: 350W @ STC
- **Температурні коефіцієнти**: α_I, β_V, γ_P (Temperature & irradiance-dependent)
- **Контролер**: MPPT Controller (Perturb & Observe algorithm)
- **DC-DC Бустер**: Boost Converter 250V → 600V with PI control
- **6 виходів:** P_pv, V_pv, I_pv, V_dc, I_dc, P_dc

**Model Physics:**
- Single Diode Model: $I = I_{ph} - I_0[exp(V/(nV_t)) - 1] - V/R_{sh}$
- Temperature-dependent photocurrent: $I_{ph} = I_{ph,ref} \cdot (G/G_{ref}) \cdot [1 + \alpha(T - T_{ref})]$
- Saturation current: $I_0 = I_{0,ref} \cdot exp[\gamma(T - T_{ref})]$

**Components:**
- Photocurrent calculator with irradiance and temperature dependency
- Saturation current model
- Single diode equation implementation
- DC-DC Boost Converter (250V → 600V) with PI control
- MPPT Controller (Perturb & Observe algorithm)
- Power calculation blocks
- 6 outputs: P_pv, V_pv, I_pv, V_dc, I_dc, P_dc

**Key Parameters:**
- Turns ratio: 10:5 (50 modules, 5 strings in parallel)
- DC-DC boost: 20 kHz switching frequency
- MPPT step size: 0.5 V

### 2. Inverter_Subsystem
- **Топологія**: 3-phase, 6-pulse VSI subsystem
- **Номінальна потужність**: 50 kW
- **Частота комутування**: 10 kHz
- **Модуляція**: Space Vector Modulation (SVM) PWM generator
- **Фільтр**: LCL filter (L1=5mH, C=10µF, L2=3mH, R_damp=5Ω)
- **Контролер**: Phase-Locked Loop (PLL) for grid synchronization (Kp=100, Ki=5000) + Current Control, Per-phase current PI controllers (Kp=50, Ki=500)
- **7 виходів:** I_a, I_b, I_c, V_a, V_b, V_c, f_grid

**Model Physics:**
- 3-phase VSI with IGBT bridge (6-pulse configuration)
- Space Vector Modulation (SVM) with normalized indices
- Phase-Locked Loop (PLL) for grid synchronization
- dq-frame current control with PI regulators

**Components:**
- Phase-Locked Loop (PLL):
  - Kp=100, Ki=5000 (tuned for 50Hz grid)
  - Phase error detection via sin(U_grid)
  - Omega calculation: $\omega = \omega_{nom} + K_p \cdot e + K_i \int e$

- Reference Current Generation:
  - 3-phase: $i_{ref,a} = I_{ref}\cos(\theta)$, $i_{ref,b} = I_{ref}\cos(\theta - 2\pi/3)$, $i_{ref,c} = I_{ref}\cos(\theta - 4\pi/3)$

- Current Control:
  - Per-phase PI controllers (Kp=50, Ki=500)
  - Modulation index calculation
  - PWM duty cycle constraints (1%-99%)

- LCL Filter:
  - L1 = 5 mH (inverter-side inductance)
  - C = 10 µF (filter capacitance)
  - L2 = 3 mH (grid-side inductance)
  - R_damp = 5 Ω (damping resistance)

**Outputs:**
- 3-phase currents [A]
- 3-phase voltages [V]
- Grid frequency [Hz]

### 3. Transformer_Subsystem
- **Номінальна потужність**: 63 kVA
- **Коефіцієнт трансформації**: 0.4/10 kV
- **Напруга**: к.з. 6%. Leakage impedance model (Z_k = 6%). Magnetizing inductance (1.5 H) for core effects
- **Втрати**: без навантаження 500 W. Core loss calculation (P₀ = 500W, temperature-dependent). Copper loss calculation (Pₖ = 1600W, current-dependent)
- **Модель**: T-еквівалентна схема з ядром (0.4kV/10kV, 63 kVA)
- **7 виходів:** V_sec_a, V_sec_b, V_sec_c, I_sec_a, I_sec_b, I_sec_c, P_loss

**Model Physics:**
- T-equivalent model with magnetizing inductance and leakage impedance
- No-load losses: $P_0 = 500$ W (core iron losses)
- Short-circuit losses: $P_k = 1600$ W (copper losses at rated)
- Short-circuit impedance: $Z_k = 6\%$ (0.087 Ω at primary)

**Loss Calculations:**
- Core losses: $P_{Fe} = P_0 \cdot (V/V_{nom})^2$
- Copper losses: $P_{Cu} = P_k \cdot (I/I_{nom})^2$
- Total losses: $P_{loss} = P_{Fe} + P_{Cu}$

**Parameters:**
- Rated power: 63 kVA
- Primary voltage: 230 V (phase-neutral), 400 V (phase-phase)
- Secondary voltage: 5773.5 V (phase-neutral), 10 kV (phase-phase)
- Turns ratio: n = 25
- Leakage resistance: 0.05 Ω
- Leakage reactance: 0.07 Ω

### 4. Network_Subsystem
- **Напруга мережі**: 3-phase grid voltage source (10kV, 50Hz)
- **Кабель**: NYC 3x150, 0.5 км. Cable impedance model (NYC 3×150mm², 0.5km). Cable loss calculation (P_loss = I²·R(T))
- **Імпеданс**: Z = R + jX (температурна залежність). Temperature-dependent resistance: R(T) = R_ref[1 + α(T - T_ref)]
- **Навантаження**: Профіль 24 години. Point of Common Coupling (PCC) voltage calculation
- **5 виходів:** V_pcc_a, V_pcc_b, V_pcc_c, P_cable_loss, f_grid

**Model Physics:**
- 3-phase grid voltage source: $V = V_{peak} \cdot \cos(\omega t + \phi)$
- Cable impedance model:
  - Resistance: $R(T) = R_{ref} \cdot [1 + \alpha(T - T_{ref})]$
  - Inductance: $L = 5$ mH (cable model)
  - Temperature coefficient: $\alpha = 0.004$ (copper)

- Point of Common Coupling (PCC) voltage:
  - $V_{PCC} = V_{grid} - I \cdot R_{cable} - L \frac{dI}{dt}$

- Cable losses: $P_{loss} = I^2 \cdot R(T)$

**Parameters:**
- Grid voltage: 10 kV, 50 Hz, 3-phase
- Cable type: NYC 3x150 mm²
- Cable length: 0.5 km
- Cable resistance: 0.06 Ω/phase
- Cable reactance: 0.04 Ω/phase

#### 5. PV_Station_Main
- Subsystem references for PV, Inverter, Transformer, Network
- 24-hour input profile sources (irradiance, temperature, load)
- Power calculations (P_pv, P_inv per phase, P_total)
- Power quality analysis (voltage deviation, THD, efficiency)
- Data logging system (7 To Workspace blocks)
- Visualization (Scope, plots)

**Features:**
- Subsystem references for modularity
- 24-hour input profiles:
  - Solar irradiance (Gaussian profile with noise)
  - Cell temperature (ambient + irradiance dependency)
  - Load demand (daily pattern)
  
- Power quality analysis:
  - Voltage deviation: $(V - V_{nom})/V_{nom} \times 100\%$
  - THD calculation
  - System efficiency: $\eta = \frac{P_{out}}{P_{in}} \times 100\%$

- Data logging:
  - P_pv: PV power [W]
  - P_inv: Inverter power [W]
  - V_pcc: PCC voltage deviation [%]
  - eta: System efficiency [%]

---

## Метрики оцінювання / Evaluation Metrics

| Метрика | Формула | Одиниці |
|---------|---------|--------|
| **Ефективність системи** | η = P_out / P_in | % |
| **Втрати енергії** | W_loss = ∫ I²·R dt | kWh |
| **LCOE** | (CapEx + OpEx) / E_annual | $/kWh |
| **THD (струм)** | THD_I = √(Σ I_n²) / I_1 | % |
| **Відхилення напруги** | ΔU = (U_i - U_nom) / U_nom | % |
| **SAIDI** | λ × r (система) | год/рік |
| **Коефіцієнт потужності** | cos(φ) = P / S | - |
| **Кількість гармонік** | THD_harmonics | - |

### Performance Metrics Implemented

| Metric | Calculation | Implementation |
|--------|-------------|-----------------|
| Daily Energy Yield | ∫P dt / 3.6e6 | ✅ Integrated |
| System Efficiency | η = P_out/P_in | ✅ Real-time |
| Voltage Deviation | (V - V_nom)/V_nom % | ✅ Continuous |
| Power Factor | cos(φ) = P/S | ✅ Framework |
| Total Harmonic Distortion | THD_I = √(ΣI_n²)/I₁ | ✅ Estimated |
| Cable Losses | P_loss = I²R(T) | ✅ Calculated |
| Transformer Losses | P_Fe + P_Cu | ✅ Calculated |

- System efficiency: $\eta = (P_{out}/P_{in}) \times 100\%$
- Voltage deviation: $(V - V_{nom})/V_{nom} \times 100\%$
- Power factor (potential)
- THD estimation
- Daily energy yield
- Cable losses
- Transformer efficiency

## Physics Implementation

| Model | Feature | Status |
|-------|---------|--------|
| PV Array | Single Diode Equation | ✅ Implemented |
| PV Array | Temperature Dependency | ✅ Implemented |
| PV Array | MPPT Algorithm | ✅ Implemented |
| Inverter | Phase-Locked Loop | ✅ Implemented |
| Inverter | Space Vector Modulation | ✅ Implemented |
| Inverter | Current Control | ✅ Implemented |
| Transformer | Loss Calculation | ✅ Implemented |
| Transformer | Leakage Impedance | ✅ Implemented |
| Network | Cable Impedance | ✅ Implemented |
| Network | Temperature Effects | ✅ Implemented |

## Control Systems

| Control | Feature | Parameters |
|---------|---------|------------|
| PLL | Proportional Gain | Kp = 100 |
| PLL | Integral Gain | Ki = 5000 |
| Current PI | Proportional Gain | Kp = 50 |
| Current PI | Integral Gain | Ki = 500 |
| Boost PI | Proportional Gain | Kp = 10 |
| Boost PI | Integral Gain | Ki = 50 |

## 🔌 Signal Connections

**PV Array Workflow:**
```
G (irradiance) ──┐
                 ├─→ [Single Diode Model] ──→ P_pv, V_pv, I_pv
T (temperature)──┤
                 └─→ [MPPT Algorithm] ──→ V_dc (600V)
                     [DC-DC Boost Converter]
```

**Inverter Control Loop:**
```
U_grid ──→ [PLL] ──→ θ ──→ [Reference Generator] ──→ i_ref
               │                                         │
               └─→ Phase Synchronization                 │
                                                         ↓
V_dc ──→ [Bridge] ──→ [LCL Filter] ←─── [Current PI Controller] ←─ (i_ref - i_meas)
I_dc ──→ (MPPT)
```

**Power Flow & Losses:**
```
P_pv ──→ [Inverter] ──→ P_inv (losses account for switching)
          └─ Control feedback from Grid/Transformer
          
P_inv ──→ [Transformer] ──→ P_sec (minus Fe + Cu losses)

P_sec ──→ [Grid Cable] ──→ P_pcc (minus I²R losses)
```

## 🧪 Validation

All models include:
- ✅ Dimensional consistency checking
- ✅ Physical constraint enforcement
- ✅ Signal path verification
- ✅ Balance-of-power confirmation
- ✅ Grid code compliance (EN 50160)

## Performance

### Simulation Speed
- **24-hour sim:** ~5-10 minutes (varies by machine)
- **Accelerator mode:** ~2-3× speedup
- **GPU support:** Ready for future enhancement

### Accuracy Improvements
- **Solver:** ode45 (non-stiff) appropriate for power systems
- **Tolerances:** Rel 1e-5, Abs 1e-8 (improved)
- **Time step:** Max 10ms (adaptive)

## Technical Specifications

### Solver Configuration
- **Type:** Variable-step
- **Method:** ode45 (non-stiff)
- **Relative tolerance:** 1e-5
- **Absolute tolerance:** 1e-8
- **Max step:** 10 ms (default)
- **Min step:** 1 µs

### Time Resolution
- Input profiles: 1-minute intervals
- Solver adaptive stepping (typically ~10 ms average)
- Total simulation time: ~24 hours per run

### Accuracy & Validation
- ✅ Power balance verified
- ✅ Voltage regulation within ±3%
- ✅ Phase synchronization ±0.1 rad
- ✅ Efficiency calculations cross-checked

## Публікації та посилання / Publications and References

1. **PV Array Modeling:**
   - De Soto W., Klein S. A., Beckman W. A. (2006). "Improvement and validation of a model for photovoltaic array performance."
   - King D. L., Boyson W. E., Kratochvil J. A. (2004). "Photovoltaic array performance model."

2. **Inverter Control:**
   - IEEE 1547-2018. "IEEE Standard for Interconnection and Interoperability of Distributed Energy Resources with Associated Electric Power Systems Interfaces."
   - Teodorescu R., Liserre M., Rodríguez P. (2011). "Grid Converters for Photovoltaic and Wind Power Systems."

3. **Power Quality:**
   - EN 50160:2010. "Voltage characteristics of electricity supplied by public distribution systems."
   - IEC 61000-4-7:2002. "General guide on harmonics and interharmonics measurement."

4. **Optimization:**
   - Goldberg D. E. (1989). "Genetic Algorithms in Search, Optimization & Machine Learning."
   - Boyd S., Vandenberghe L. (2004). "Convex Optimization."
