# Цифровий Двійник Фотоелектричної Станції (Digital Twin of PV Station)

## Опис / Description

Цей проект реалізує комплексний цифровий двійник сонячної електростанції станції у середовищі **MATLAB Simulink** з використанням бібліотеки **Simscape Electrical**.

Digital twin system of photovoltaic station implemented in **MATLAB Simulink** using **Simscape Electrical** library.

**Версія:** 1.0  
**Дата створення:** 26.05.2026  

- Архітектура: Багаторівнева ієрархічна модель (Рівні 0-3)
- Симуляція: 24-годинний цикл у реальному часі/прискореному режимі
- Оптимізація: Багатокритеріальна оптимізація з GA

## Вимоги до системи / System Requirements

- **Платформа**: macOS з Apple Silicon
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

### Ключові можливості / Key Features:

✅ **Багаторівнева ієрархічна архітектура** - Multi-level hierarchical architecture  
✅ **Нелінійна модель фотоелектричного поля** - Nonlinear PV array model (Single Diode)  
✅ **Трьохфазний інвертор з PWM** - 3-phase inverter with PWM modulation  
✅ **Система управління (PLL, MPPT)** - Control system (PLL, MPPT)  
✅ **Трансформатор з урахуванням втрат** - Transformer model with losses  
✅ **Багатокритеріальна оптимізація** - Multi-criteria optimization (Genetic Algorithm)  
✅ **Аналіз якості електроенергії** - Power quality analysis (THD, Voltage deviation)  
✅ **Економічна оцінка (LCOE)** - Economic evaluation (LCOE calculation)  
✅ **24-годинне моделювання** - 24-hour simulation cycle  
✅ **Порівняльний аналіз топологій** - Topology comparative analysis  


### Функціональність:

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

---

## Структура проекту / Project Structure

```
PV-Station-Digital-Twin/
├── README.md                    # Цей файл
│
├── matlab_scripts/              # MATLAB керуючі скрипти
│   ├── init_pv_station_main.m  # Ініціалізація параметрів
│   ├── optimize_topology.m     # Оптимізація топологій (GA)
│   ├── run_simulation_suite.m  # Запуск серій експериментів
│   ├── plot_analysis.m         # Візуалізація результатів
│   ├── post_processing.m       # Пост-обробка даних
│   └── helper_functions.m      # Допоміжні функції
│
├── simulink_models/             # Simulink моделі
│   ├── PV_Station_Main.slx     # Головна модель (Рівень 1)
│   ├── PV_Array_Subsystem.slx  # ФВ поле (Рівень 2.1)
│   ├── Inverter_Subsystem.slx  # Інвертор (Рівень 2.2)
│   ├── Transformer_Subsystem.slx # Трансформатор (Рівень 2.3)
│   └── Network_Subsystem.slx   # Мережа (Рівень 2.4)
│
├── data/                        # Дані та результати
│   ├── solar_irradiance_profile.mat
│   ├── temperature_profile.mat
│   ├── load_profile.mat
│   ├── simulation_results.xlsx
│   └── optimization_results.xlsx
│
├── docs/                        # Документація
│   ├── ARCHITECTURE.md          # Архітектура системи
│   ├── implementation_guide.md  # Керівництво реалізації
│   └── parameter_specs.xlsx     # Специфікація параметрів
│
└── reports/                     # Звіти й аналіз
    ├── topology_comparison.pdf
    ├── optimization_results.pdf
    ├── power_quality_analysis.pdf
    └── sensitivity_analysis.pdf
```


---

## ОПИСАННЯ ФАЙЛІВ ПРОЕКТУ

```
PV-Station-Digital-Twin/
│
├── README.md                          # Документація проекту
├── ARCHITECTURE.md                    # Цей файл (архітектура)
│
├── /matlab_scripts/                   # Керуючі скрипти (Рівень 0)
│   ├── init_pv_station_main.m        # Ініціалізація параметрів
│   ├── optimize_topology.m           # Багатокритеріальна оптимізація
│   ├── run_simulation_suite.m        # Запуск серій експериментів
│   ├── plot_analysis.m               # Візуалізація результатів
│   ├── post_processing.m             # Пост-обробка результатів
│   ├── helper_functions.m            # Допоміжні функції
│   └── config_parameters.m           # Глобальні параметри
│
├── /simulink_models/                  # Simulink моделі
│   ├── PV_Station_Main.slx           # Головна модель (Рівень 1)
│   ├── PV_Array_Subsystem.slx        # ФВ поле (Рівень 2.1)
│   ├── Inverter_Subsystem.slx        # Інвертор (Рівень 2.2)
│   ├── Transformer_Subsystem.slx     # Трансформатор (Рівень 2.3)
│   └── Network_Subsystem.slx         # Мережа (Рівень 2.4)
│
├── /simscape_library/                 # Бібліотека компонентів (Рівень 3)
│   ├── pv_module_model.m             # Модель ФВ модуля
│   ├── inverter_control.m            # Контролер інвертора
│   ├── mppt_algorithm.m              # MPPT алгоритм
│   └── component_library.slx          # Переносна бібліотека
│
├── /data/                             # Дані та результати
│   ├── solar_irradiance_profile.mat   # Профіль сонячної радіації
│   ├── temperature_profile.mat        # Профіль температури
│   ├── load_profile.mat               # Профіль навантаження
│   ├── results_log.xlsx               # Таблиця результатів
│   └── comparison_metrics.csv         # Порівняльні метрики
│
├── /reports/                          # Звіти й аналіз
│   ├── topology_comparison.pdf        # Порівняння топологій
│   ├── optimization_results.pdf       # Результати оптимізації
│   ├── sensitivity_analysis.pdf       # Аналіз чутливості
│   └── power_quality_analysis.pdf     # Якість електроенергії
│
└── /docs/                             # Додаткова документація
    ├── mathematical_model.pdf         # Математична модель (PhD)
    ├── implementation_guide.md        # Керівництво реалізації
    ├── parameter_specifications.xlsx  # Специфікація параметрів
    └── troubleshooting.md             # Ріш��ння проблем
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

### PV_Array_Subsystem
- **Модель**: Single Diode Model (нелінійна)
- **Параметри модуля**: 350W @ STC
- **Температурні коефіцієнти**: α_I, β_V, γ_P
- **Контролер**: MPPT (Perturb & Observe)
- **DC-DC Бустер**: Boost Converter 250V → 600V

### Inverter_Subsystem
- **Топологія**: 3-phase, 6-pulse VSI
- **Номінальна потужність**: 50 kW
- **Частота комутування**: 10 kHz
- **Модуляція**: SVM (Space Vector Modulation)
- **Фільтр**: LCL (L1=5mH, C=10μF, L2=3mH)
- **Контролер**: PLL + Current Control

### Transformer_Subsystem
- **Номінальна потужність**: 63 kVA
- **Коефіцієнт трансформації**: 0.4/10 kV
- **Напруга к.з.**: 6%
- **Втрати без навантаження**: 500 W
- **Модель**: T-еквівалентна схема з ядром

### Network_Subsystem
- **Напруга мережі**: 10 kV, 50 Hz
- **Кабель**: NYC 3x150, 0.5 км
- **Імпеданс**: Z = R + jX (температурна залежність)
- **Навантаження**: Профіль 24 години

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

---

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

---

## Статус розробки / Development Status

| Компонент | Статус | Прогрес |
|-----------|--------|----------|
| ARCHITECTURE.md | ✅ Готово | 100% |
| init_pv_station_main.m | ✅ Готово | 100% |
| optimize_topology.m | ✅ Готово | 100% |
| run_simulation_suite.m | ✅ Готово | 100% |
| plot_analysis.m | ✅ Готово | 100% |
| PV_Station_Main.slx | 📋 Структура | 50% |
| PV_Array_Subsystem.slx | 📋 Структура | 50% |
| Inverter_Subsystem.slx | 📋 Структура | 50% |
| Transformer_Subsystem.slx | 📋 Структура | 50% |
| Network_Subsystem.slx | 📋 Структура | 50% |
| Тестування | 🔄 В процесі | 30% |
| Документація | 🔄 В процесі | 80% |

---

Наступні кроки:
1    Розробити Simulink моделі - використовуйте створені скрипти як основу
2    Налаштувати параметри - редагуйте init_pv_station_main.m під ваші потреби
3    Запустити симуляцію - команда: sim('PV_Station_Main')
4    Аналізувати результати - використовуйте plot_analysis.m

Q3 2026:
✅ Рефакторинг коду в OOP
✅ Unit tests (>80% coverage)
✅ Документація API
✅ Публікація у MATLAB File Exchange

Q4 2026:
⏳ Machine Learning MPPT
⏳ Advanced PQ analysis
⏳ Cloud integration
⏳ Performance benchmarking

Q1 2027:
⏳ Real-time hardware integration
⏳ HIL (Hardware-in-the-Loop) testing
⏳ FPGA code generation
⏳ Industrial certification prep

КРИТИЧНІ ПОКРАЩЕННЯ (ПРІОРИТЕТ)
🔴 HIGH PRIORITY:
✅ Об'єктно-орієнтоване проектування - перепишіть на класи
✅ Валідація вхідних даних - перевірка параметрів
✅ Обробка помилок - try-catch в критичних місцях
✅ Логування - додати систему логування
✅ Unit тести - покриття >70%

🟡 MEDIUM PRIORITY:
Паралельне обчислення - GA speedup 5-8x
Адаптивний MPPT - Fuzzy або ML
Розширений аналіз PQ - 20+ метрик
Детекція відмов - real-time diagnostics

🟢 LOW PRIORITY:
GPU acceleration - для FFT
Cloud integration - AWS/Azure
Web dashboard - візуалізація онлайн
Mobile app - контроль на мобілці
