## Архітектура багаторівневої кіберфізичної моделі Фотоелектричної Станції

## 1. ЗАГАЛЬНА СТРУКТУРА СИСТЕМИ

```
┌───────────────────────────────────────────────────────────────┐
│     MATLAB Simulink Digital Twin - Complete Framework         │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  РІВЕНЬ 0: Керуючий контролер й оптимізаційний модуль  │   │
│  │  • init_pv_station_main.m - Ініціалізація              │   │
│  │  • optimize_topology.m - Багатокритеріальна оптимізація│   │
│  │  • run_simulation_suite.m - Серія експериментів        │   │
│  │  • plot_analysis.m - Візуалізація результатів          │   │
│  └────────────────────────────────────────────────────────┘   │
│                    ↓ Fopt, Efficiency, LCOE ↓                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  РІВЕНЬ 1: Головна модель (PV_Station_Main.slx)      │     │
│  │  • Topology Configuration Manager                    │     │
│  │  • Automation Engine                                 │     │
│  │  • Measurement & Data Accumulation                   │     │
│  │  • Real-time Monitoring Dashboard                    │     │
│  └──────────────────────────────────────────────────────┘     │
│     ↓             ↓             ↓             ↓               │
│    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐             │
│    │ Level  │  │ Level  │  │ Level  │  │ Level  │             │
│    │ 2.1    │  │ 2.2    │  │ 2.3    │  │ 2.4    │             │
│    │  PV    │  │Inverter│  │Transf. │  │Network │             │
│    │Subsys  │  │ Subsys │  │ Subsys │  │ Subsys │             │
│    └────────┘  └────────┘  └────────┘  └────────┘             │
│     ↓             ↓             ↓             ↓               │
│  ┌────────────────────────────────────────────────────┐       │
│  │  РІВЕНЬ 3: Simscape Electrical Library             │       │
│  │  • Photovoltaic Array (Single Diode Model)         │       │
│  │  • DC-DC Boost Converter                           │       │
│  │  • 3-Phase IGBT Inverter                           │       │
│  │  • Transformer Model (Nonlinear Core)              │       │
│  │  • Cable Network (Temperature-dependent)           │       │
│  │  • Grid Interface                                  │       │
│  │  • Sensors & Measurement System                    │       │
│  └────────────────────────────────────────────────────┘       │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## 2. МАТЕМАТИЧНА ОСНОВА МОДЕЛІ

### 2.1 Структура системи (Рівняння 1 - Архітектура)

```
S = {M, I, T, C, P, L, A}

де:
  M - множина фотоелектричних модулів
  I - множина інвертрів
  T - множина трансформаторів
  C - множина кабельних з'єднань
  P - множина точок приєднання
  L - множина рівнів напруги
  A - множина архітектурних рішень
```

### 2.2 Орієнтований граф системи (Рівняння 2)

```
G = (V, E)

V = {v_PV, v_INV, v_TR, v_BUS, v_GRID}

Матриця суміжності:
a_ij = 1, якщо існує електричний зв'язок між вузлами i,j
       0, в іншому випадку
```

### 2.3 Цільова функція оптимізації (Рівняння 3)

```
Fopt = w1·Fcap + w2·Floss + w3·Frel + w4·Fopex + w5·Fpq → min

де:
  Fcap  - капітальні витрати [USD]
  Floss - втрати електроенергії [кВт·год]
  Frel  - показники надійності [EENS, кВт·год]
  Fopex - експлуатаційні витрати [USD/рік]
  Fpq   - якість електроенергії [%]
  
  w1 + w2 + w3 + w4 + w5 = 1    (нормування)
```

### 2.4 Обмеження балансу потужності

```
P_i^gen - P_i^load = Σ U_i·U_j·Y_ij·cos(θ_i - θ_j - ψ_ij)
Q_i^gen - Q_i^load = Σ U_i·U_j·Y_ij·sin(θ_i - θ_j - ψ_ij)

Обмеження напруги:
0.95·U_nom ≤ U_i ≤ 1.05·U_nom

Обмеження струму:
I_k ≤ I_k,max для кожної лінії k
```

### 2.5 Втрати енергії

```
ΔW = Σ(t=0 to T) Σ(k=1 to n) I_k(t)²·R_k(T(t))·Δt [кВт·год]

де R_k(T) = R_20·(1 + α·(T - 20))    [Ω]
```

### 2.6 Недопостачана енергія (EENS)

```
EENS = Σ(i=1 to m) λ_i·r_i·P_i [кВт·год]

де:
  λ_i - інтенсивність відмови елемента
  r_i - середній час відновлення
  P_i - потужність елемента
```

### 2.7 Собівартість електроенергії (LCOE)

```
LCOE = Σ(t=0 to N) (C_t + O_t + M_t)/(1+r)^t / Σ(t=0 to N) E_t/(1+r)^t [$/кВт·год]

де:
  C_t - капітальні витрати в році t
  O_t - експлуатаційні витрати
  M_t - витрати на ремонт
  E_t - генерована енергія
  r - дисконтна ставка
  N - розраховуючий період (20-25 років)
```

---

## 3. РІВНІ ІЄРАРХІЇ МОДЕЛІ

### **Рівень 0: Керуючий контролер (MATLAB M-файли)**

#### Файл: `init_pv_station_main.m`
**Функція:** Ініціалізація всіх параметрів системи та підготовка до симуляції

```matlab
% Параметри топології
pv_params.ns = 10;           % модулів у рядку (рівняння n_s)
pv_params.np = 5;            % паралельних рядків (рівняння n_p)
pv_params.Prated = 50e3;     % номінальна потужність [W]

% Параметри інвертора
inv_params.Prated = 50e3;    % номінальна потужність [W]
inv_params.Vdc = 600;        % вхідна DC напруга [V]
inv_params.fsw = 10e3;       % частота комутування [Hz]

% Параметри трансформатора (якщо потрібен)
tr_params.S_rated = 63e3;    % номінальна потужність [VA]
tr_params.U1 = 0.4;          % первинна напруга [kV]
tr_params.U2 = 10;           % вторинна напруга [kV]

% Параметри мережі
net_params.Ugrid = 10;       % напруга мережі [kV]
net_params.Zgrid = 0.1;      % імпеданс мережі [Ω]
net_params.Lcable = 0.5;     % довжина кабелю [km]

% Вектор змінних оптимізації X
X = [pv_params.ns, pv_params.np, ...
     inv_params.Prated, tr_params.S_rated, ...
     net_params.Ugrid, net_params.Lcable];
```

#### Файл: `optimize_topology.m`
**Функція:** Багатокритеріальна оптимізація структури

```matlab
% ग्र Використання geneticalgorithm або fmincon
options = optimoptions('ga', ...
    'PopulationSize', 50, ...
    'MaxGenerations', 100, ...
    'Display', 'iter');

[X_opt, Fopt_min] = ga(@objective_function, ...
    length(X), [], [], [], [], lb, ub, @constraints, options);
```

#### Файл: `run_simulation_suite.m`
**Функція:** Запуск серії експериментів з різними конфігураціями

```matlab
% Варіювання параметрів для дослідження чутливості
for ns = [5, 10, 15, 20]
    for Pinv = [25e3, 50e3, 75e3, 100e3]
        for Utr = [0.4, 10, 20]
            % Запуск однієї конфігурації
            sim('PV_Station_Main');
            
            % Збереження результатів
            save_results(ns, Pinv, Utr, tout, yout);
        end
    end
end
```

#### Файл: `plot_analysis.m`
**Функція:** Аналіз та візуалізація результатів

```matlab
% Порівняльні характеристики
figure('Position', [100 100 1200 800]);

subplot(2,3,1); plot(results.time, results.Ppv); 
title('PV Power Output'); ylabel('P [W]'); grid on;

subplot(2,3,2); plot(results.time, results.Vpv);
title('PV Voltage'); ylabel('V [V]'); grid on;

subplot(2,3,3); plot(results.time, results.Igrid);
title('Grid Current'); ylabel('I [A]'); grid on;

subplot(2,3,4); plot(results.time, results.THD);
title('THD'); ylabel('THD [%]'); ylim([0 5]); grid on;

subplot(2,3,5); plot(results.time, results.Efficiency);
title('System Efficiency'); ylabel('η [%]'); ylim([90 100]); grid on;

subplot(2,3,6); bar(categories, [Fopt, LCOE, efficiency]);
title('Comparative Metrics'); legend('Cost', 'LCOE', 'Efficiency'); grid on;
```

---

### **Рівень 1: Головна Simulink модель**

**Назва файлу:** `PV_Station_Main.slx`

#### Основні підсистеми:

1. **Configuration Manager Block**
   - Читає вектор X з робочої пам'яті MATLAB
   - Генерує конфігурацію топології
   - Активує/деактивує компоненти рівнів 2 та 3
   - Встановлює параметри в реальному часі

2. **PV Generation Subsystem**
   - Входить: Температура навколишнього середовища, Сонячна радіація
   - Виходить: DC напруга, DC струм, DC потужність
   - Сценарій: день/ніч, змінна хмарність, теплові умови

3. **Power Inverter Subsystem**
   - Входить: DC напруга, DC струм, напруга мережі (синфазна)
   - Виходить: AC напруга, AC струм, AC потужність (P, Q)
   - Контролер: PLL + Strominregelung + MPPT

4. **Transformer Subsystem** (Опціональний)
   - Входить: AC напруга (0.4 kV), AC струм
   - Виходить: AC напруга (10-20 kV), AC струм
   - Модель: Нелінійна з урахуванням гістерезису

5. **Network Interface Subsystem**
   - Входить: Виходящі AC параметри трансформатора
   - Виходить: Поточні параметри мережі (U, I, P, Q, f)
   - Модель: Еквівалентна схема мережі з узагальненим імпедансом

6. **Measurement & Monitoring System**
   - Вимірює 25+ параметрів на кожному кроці симуляції
   - Розраховує якість електроенергії (THD, ΔU, cosφ)
   - Накопичує дані в матрицю результатів

7. **Controller Unit**
   - Керує всіма підсистемами
   - Реалізує захист й обмеження
   - Формує рівні частотної модуляції (PWM)

---

### **Рівень 2: Підсистеми (Subsystems)**

#### **2.1 PV_Array_Subsystem.slx**

```
┌─ PV Module Model (Single Diode) ──────────────┐
│ • I-V крива (нелінійна 1-діодна модель)       │
│ • Температурна залежність (α_I, β_V)          │
│ • Швидша залежність від сонячної радіації     │
│ Входи: T_cell [°C], G [W/m²]                  │
│ Виходи: V_pv, I_pv, P_pv                      │
└───────────────────────────────────────────────┘
          ↓
┌─ Series/Parallel Configuration ───────────────┐
│ • Комбінує модулі в рядки й паралельні гілки  │
│ • Розрахунок еквівалентних параметрів         │
│ Параметри: n_s (кількість модулів у рядку)    │
│           n_p (кількість паралельних рядків)  │
└───────────────────────────────────────────────┘
          ↓
┌─ MPPT Controller (Perturb & Observe) ─────────┐
│ • Відслідковує максимум P-V кривої            │
│ • Видає опорну напругу V_ref                  │
│ • Період дискретизації: T_mppt = 1-10 ms      │
│ Вихід: V_ref для DC-DC перетворювача          │
└───────────────────────────────────────────────┘
          ↓
┌─ DC-DC Boost Converter ───────────────────────┐
│ • Підвищує напругу від V_pv до V_dc           │
│ • Коефіцієнт трансформації: M = 1/(1-D)       │
│ • Втрати в котушці, конденсаторі, ключах      │
│ • Вихід: V_dc ≈ 600 V (для інвертора)         │
└───────────────────────────────────────────────┘
```

**Основні параметри:**
- `I_ph0` = 8.5 A (фотострум при STC)
- `I0` = 1e-9 A (струм насичення діода)
- `Rs` = 0.2 Ω (послідовний опір)
- `Rsh` = 415 Ω (шунтуючий опір)
- `T_ref` = 25°C, `G_ref` = 1000 W/m²
- `α_I` = 0.0032 A/°C, `β_V` = -0.123 V/°C

---

#### **2.2 Inverter_Subsystem.slx**

```
┌─ DC Input Interface ──────────────────────────┐
│ • Фільтрація DC напруги (LC-фільтр)           │
│ • Захист від перенапруги (Zener діоди)        │
│ • Вхід: V_dc (~600V), I_dc                    │
└───────────────────────────────────────────────┘
          ↓
┌─ 3-Phase IGBT Inverter Bridge ────────────────┐
│ • 6 IGBT ключів + 6 зворотних діодів          │
│ • Топологія: 2-рівневий VSI                   │
│ • Параметри: V_sat_IGBT = 1.3V, t_on = 50ns   │
│ • Параметри: V_f_diode = 0.7V, t_rr = 100ns   │
└───────────────────────────────────────────────┘
          ↓
┌─ PWM Modulator (SVM) ─────────────────────────┐
│ • Space Vector Modulation (SVM)               │
│ • Частота комутування: f_sw = 10 kHz          │
│ • Виключене час: t_dead = 2 μs                │
│ • Вихід: 6 сигналів управління IGBT           │
└───────────────────────────────────────────────┘
          ↓
┌─ LCL Output Filter ───────────────────────────┐
│ • L1 = 5 mH (первинна індуктивність)          │
│ • C = 10 μF (кондесатор фільтра)              │
│ • L2 = 3 mH (вторинна індуктивність)          │
│ • Демпфування: R_damp = 5 Ω                   │
│ • Вхід: Модульовані напруги                   │
│ • Вихід: U_abc (синусоїдальні)                │
└───────────────────────────────────────────────┘
          ↓
┌─ PLL (Phase Locked Loop) ─────────────────────┐
│ • Синхронізація з напругою мережі             │
│ • Вхід: U_grid_abc (виміряна напруга мережі)  │
│ • Вихід: θ_grid (фазовий кут синхронізму)     │
│ • Коефіцієнти: K_p = 100, K_i = 5000          │
└───────────────────────────────────────────────┘
          ↓
┌─ Current Controller (PI) ──────────────────────┐
│ • Контроль вихідного струму інвертора          │
│ • Опорний струм: I_ref = P_ref / V_grid        │
│ • Зворотнього зв'язку: I_actual (вимірюється)  │
│ • Коефіцієнти: K_p = 50, K_i = 500             │
│ �� Вихід: V_ref для PWM модулятора             │
└────────────────────────────────────────────────┘
```

**Основні параметри:**
- `V_dc_rated` = 600 V
- `P_rated` = 50 kW
- `f_grid` = 50 Hz
- `f_sw` = 10 kHz
- `L_filter` = 5 mH, `C_filter` = 10 μF

---

#### **2.3 Transformer_Subsystem.slx** (опціонально)

```
┌─ Three-Phase Transformer Model ───────────────┐
│ • Моделю T-модель еквівалентної схеми         │
│ • Первинна сторона: 0.4 kV (низька напруга)   │
│ • Вторинна сторона: 10-20 kV (середня напруга)│
│ • Розрахункова потужність: S_tr (випадає)     │
│                                               │
│ Еквівалентна схема:                           │
│   ┌─ R_m (втрати гістерезису)                 │
│   ├─ X_m (реактивність холостого ходу)        │
│   ├─ R_k (первинний опір)                     │
│   └─ X_k (первинна реактивність)              │
└───────────────────────────────────────────────┘
          ↓
┌─ Temperature Model ───────────────────────────┐
│ • Локус гарячої точки (Hotspot)               │
│ • Тепловий баланс:                            │
│   dT_hs/dt = (P_loss - P_cooling)/(m·c)       │
│ • Обмеження: T_hs ≤ 80°C (клас H)             │
└───────────────────────────────────────────────┘
          ↓
┌─ Protection System ───────────────────────────┐
│ • Контроль перепаду струму (Overcurrent)      │
│ • Контроль температури (Overheat)             │
│ • Сигнал тривоги при порушенні обмежень       │
└───────────────────────────────────────────────┘
```

**Основні параметри:**
- `S_tr` = 63 kVA
- `U1/U2` = 0.4/10 kV
- `Z_uk` = 6% (напруга к.з.)
- `P_k0` = 500 W (втрати без навантаження)
- `P_km` = 1100 W (втрати номіналу)

---

#### **2.4 Network_Subsystem.slx**

```
┌─ Main Grid Model ──────────────────────────────┐
│ • Трифазне джерело напруги: 50 Hz              │
│ • Узагальнений імпеданс мережі: Z_grid         │
│ • Синфазна напруга: U_grid = 10 kV (змінюється)│
│ • Вхід: П'ять точок приєднання                 │
│   v_PV, v_INV, v_TR, v_BUS, v_GRID             │
└────────────────────────────────────────────────┘
          ↓
┌─ Cable Network Model ──────────────────────────┐
│ • Розподіл кабелів (RLC гілки)                 │
│ • Кожна гілка має: R(T), L, C                  │
│ • Температурна залежність: R(T) = R_20·(1+α·ΔT)│
│ • Довжина кабелю: L_cab [km]                   │
│ • Вхід: Граф з'єднань (G = (V, E))             │
└────────────────────────────────────────────────┘
          ↓
┌─ Power Flow Calculation ──────────────────────┐
│ • Трифазна система диференціальних рівнянь    │
│ • Розв'язання в реальному часі                │
│ • Вихід: V_i, I_ij для кожної гілки           │
│                                               │
│ Рівняння:                                     │
│ P_i = Σ U_i·U_j·Y_ij·cos(θ_i - θ_j - ψ_ij)    │
│ Q_i = Σ U_i·U_j·Y_ij·sin(θ_i - θ_j - ψ_ij)    │
└───────────────────────────────────────────────┘
          ↓
┌─ Load Model (Time-varying) ────────────────────┐
│ • Профіль добового навантаження                │
│ • Модель: P(t) = P_max·f(t), Q(t) = P(t)·tan(φ)│
│ • Типовий коефіцієнт потужності: cos(φ) = 0.95 │
└────────────────────────────────────────────────┘
          ↓
┌─ Measurement Points ──────────────────────────┐
│ • Напруга: U_abc в 5 точках                   │
│ • Струм: I_abc в 5 лініях                     │
│ • Активна потужність: P в кожній точці        │
│ • Реактивна потужність: Q                     │
│ • Частота: f_grid                             │
└───────────────────────────────────────────────┘
```

---

### **Рівень 3: Бібліотека компонентів Simscape Electrical**

| Компонент | Модель | Параметри | Симscape блок |
|-----------|--------|-----------|--------------|
| **PV Module** | Single Diode (1D) | I_ph0, I0, Rs, Rsh, n, α_I, β_V | `Foundation > Electrical > PV Source` |
| **IGBT Transistor** | Ideal Switch + On-state | V_sat, R_on, f_sw | `Semiconductor > IGBT` |
| **Diode** | 2D Model | V_f, R_on, τ_rr | `Semiconductor > Diode` |
| **Inductor** | Linear + Nonlinear | L, R_serial, I_saturation | `Passive > Inductor` |
| **Capacitor** | Linear | C, ESR, V_rated | `Passive > Capacitor` |
| **Resistor** | Linear, Temp-depend | R(T) = R_ref·(1+α·ΔT) | `Passive > Resistor` |
| **3-Ph Transformer** | Nonlinear Core | S, U1/U2, Z_uk, P_k0, P_km | `Fundamental > Transformer > 3-Ph Transformer` |
| **3-Ph AC Source** | Thevenin Equivalent | U_grid, f, Z_grid | `Fundamental > 3-Phase AC Source` |
| **Voltage Sensor** | Ideal | Portability: Voltage | `Fundamental > Voltage Sensor` |
| **Current Sensor** | Ideal | Portability: Current | `Fundamental > Current Sensor` |

---

## 4. СИСТЕМА ВИМІРЮВАННЯ ТА МОНІТОРИНГУ

### 4.1 Основні сигнали для реєстрації (25+ параметрів)

| # | Параметр | Одиниці | Блок вимірювання | Формула |
|---|----------|--------|------------------|---------|
| 1 | V_pv | V | PV Module Output | Прямий вихід |
| 2 | I_pv | A | PV Current Sensor | Прямий вихід |
| 3 | P_pv | W | Calculated | V_pv × I_pv |
| 4 | V_dc | V | DC-DC Output | Вихід бустера |
| 5 | I_dc | A | DC-DC Current | Вихід бустера |
| 6 | T_cell | °C | Temperature Sensor | Емпірична модель |
| 7 | G_solar | W/m² | Solar Irradiance | Вхідна послідовність |
| 8 | V_a, V_b, V_c | V | 3-Ph Voltage Sensors | Прямі виходи |
| 9 | I_a, I_b, I_c | A | 3-Ph Current Sensors | Прямі виходи |
| 10 | P_active | W | Power Analyzer | (V_a·I_a + V_b·I_b + V_c·I_c)/3 |
| 11 | Q_reactive | VAR | Power Analyzer | аналітично |
| 12 | S_apparent | VA | Power Analyzer | √(P² + Q²) |
| 13 | cos(φ) | - | Power Analyzer | P/S |
| 14 | f_grid | Hz | Frequency Meter | Нулі напруги |
| 15 | THD_I | % | Harmonic Analyzer | √(Σ I_n²)/I_1 × 100 |
| 16 | THD_V | % | Harmonic Analyzer | √(Σ V_n²)/V_1 × 100 |
| 17 | ΔU | % | Voltage Deviation | (U_i - U_nom)/U_nom × 100 |
| 18 | Efficiency | % | Calculated | P_out/P_in × 100 |
| 19 | T_transformer | °C | Temperature Sensor | Тепловий баланс |
| 20 | P_loss_cable | W | Calculated | Σ I²·R |
| 21 | ΔW_loss | kWh | Accumulated | ∫ P_loss dt |
| 22 | SAIDI | hours/year | Reliability Calc | Статистика |
| 23 | LOLP | % | Reliability Calc | (EENS/E_demand) × 100 |
| 24 | LCOE | $/kWh | Economic Calc | Див. Рівняння 7 |
| 25 | Fopt | USD | Optimization | Див. Рівняння 3 |

### 4.2 Алгоритм розрахунку якості електроенергії

```matlab
% THD (Total Harmonic Distortion)
V_fund = max(FFT(V_abc, 1));     % Фундаментальна гармоніка
V_harmonics = sqrt(sum(FFT(V_abc, 2:50).^2));
THD_V = V_harmonics / V_fund * 100;   % [%]

% Voltage Deviation
DeltaU = abs(V_rms - V_nom) / V_nom * 100;   % [%]
```

---

## 5. КОНФІГУРАЦІЯ СИМУЛЯЦІЇ

- **Тип розв'язувача**: ode23tb (stiff) або ode45
- **Крок часу**: Змінний крок (1-100 ms)
- **Часовий горизонт**: 24 години реального часу
- **Час обчислення**: ~10-20 хвилин на конфігурацію
- **Режим**: Accelerator Mode (рекомендується)

---

## 6. ПРОЦЕС ЗАПУСКУ СИМУЛЯЦІЇ

### 6.1 Іміціалізація
```matlab
% Крок 1: Добавити шляхи
addpath(genpath('./matlab_scripts'));
addpath(genpath('./simulink_models'));
addpath(genpath('./simscape_library'));

% Крок 2: Завантажити конфігурацію параметрів
init_pv_station_main;

% Крок 3: Встановити параметри топології
X = [ns, np, Pinv, Str, Umv, Atop, Lcab];
```

### 6.2 Запуск однієї конфігурації
```matlab
% Запуск симуляції
sim('PV_Station_Main');

% Отримання результатів
results = get(SIM_DATA, 'diagnostics');
```

### 6.3 Запуск оптимізації
```matlab
% Запуск генетичного алгоритму
[X_opt, Fopt_min] = ga(@objective_function, ...
    7, [], [], [], [], [5, 2, 25e3, 25e3, 0.4, 1, 0.5], ...
    [20, 20, 100e3, 100e3, 20, 3, 2], @constraints);
```

### 6.4 Аналіз результатів
```matlab
% Порівняльна таблиця
plot_analysis;

% Експорт результатів
save_to_excel;
```

---

## 7. ВАЛІДАЦІЯ ТА ВЕРИФІКАЦІЯ

### 7.1 Unit Testing
```matlab
% Тест моделі ФВ модуля
test_pv_model.m

% Тест інвертора
test_inverter_model.m

% Тест MPPT алгоритму
test_mppt_algorithm.m
```

### 7.2 Integration Testing
```matlab
% Комплексна валідація системи
test_integrated_model.m
```

### 7.3 Еталонні результати
- **Ефективність інвертора**: 96-98%
- **MPPT ефективність**: 99%
- **Системна ефективність**: 75-85%
- **THD (струм)**: < 3%
- **Voltage ripple**: < 1%
