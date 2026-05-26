# Цифровий Двійник Фотоелектричної Станції
## Digital Twin of PV Station

### Дисертація: "Обґрунтування раціональної структури електричної схеми станцій із сонячною генерацією"
**Dissertation:** "Justification of rational structure of electrical circuit of stations with solar generation"

**Рівень:** PhD (G3 Електрична інженерія)  
**Level:** PhD (G3 Electrical Engineering)

---

## Опис / Description

Цей проект реалізує комплексний цифровий двійник фотоелектричної станції (ПЕС) у середовищі **MATLAB Simulink** з використанням бібліотеки **Simscape Electrical**.

Digital twin system of photovoltaic (PV) station implemented in **MATLAB Simulink** using **Simscape Electrical** library.

### Ключові можливості / Key Features:

✅ **Багаторівнева ієрархічна архітектура** - Multi-level hierarchical architecture  
✅ **Нелінійна модель ФВ поля** - Nonlinear PV array model (Single Diode)  
✅ **Трьохфазний інвертор з PWM** - 3-phase inverter with PWM modulation  
✅ **Система управління (PLL, MPPT)** - Control system (PLL, MPPT)  
✅ **Трансформатор з урахуванням втрат** - Transformer model with losses  
✅ **Багатокритеріальна оптимізація** - Multi-criteria optimization (Genetic Algorithm)  
✅ **Аналіз якості електроенергії** - Power quality analysis (THD, Voltage deviation)  
✅ **Економічна оцінка (LCOE)** - Economic evaluation (LCOE calculation)  
✅ **24-годинне моделювання** - 24-hour simulation cycle  
✅ **Порівняльний аналіз топологій** - Topology comparative analysis  

---

## С��руктура проекту / Project Structure

```
PV-Station-Digital-Twin/
├── ARCHITECTURE.md              # Детальна архітектура
├── README.md                    # Цей файл
├── LICENSE                      # MIT License
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

## Вимоги до системи / System Requirements

### Програмне забезпечення / Software
- **MATLAB**: R2023b або новіше
- **Toolboxes**:
  - Simulink
  - Simscape Electrical
  - Control System Toolbox
  - Optimization Toolbox
  - Signal Processing Toolbox

### Апаратура / Hardware
- **ОЗУ**: 32 ГБ (мінімум), 64 ГБ (рекомендовано)
- **CPU**: Intel Core i7/i9 або AMD Ryzen 7/9 (6+ ядер)
- **HDD**: 200 ГБ для моделей та результатів
- **GPU**: NVIDIA CUDA (опціонально, для прискорення)

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

### Наукові основи / Scientific Basis:
1. De Soto W., Klein S.A., Beckman W.A. (2006). "Improvement and validation of a model for photovoltaic array performance."
2. Teodorescu R., Liserre M., Rodríguez P. (2011). "Grid Converters for Photovoltaic and Wind Power Systems."
3. IEEE 1547-2018. "IEEE Standard for Interconnection and Interoperability of Distributed Energy Resources."
4. EN 50160:2010. "Voltage characteristics of electricity supplied by public distribution systems."

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

## Ліцензія / License

MIT License - див. `LICENSE` файл для деталей

---

## Контактна інформація / Contact

**Автор / Author:** Телипський Т.В. (Telipskiy T.V.)  
**GitHub:** [@telipskiy](https://github.com/telipskiy)  
**E-mail:** 6349353+telipskiy@users.noreply.github.com  

---

**Версія / Version:** 1.0  
**Дата оновлення / Last Updated:** 2026-05-26  
**Статус / Status:** Beta Release  
