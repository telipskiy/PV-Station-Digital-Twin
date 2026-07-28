# Початок роботи

## Статус моделі

Основний відтворюваний сценарій — квазіусталений часовий розрахунок структури СЕС. Він придатний для порівняння кількості модулів, стрінгів, інверторів і кабельних трас. Він не є результатом моделювання гармонік, комутаційних перехідних процесів або відповідності мережевому коду. Деталі наведено у [межах застосовності](MODEL_SCOPE_AND_VALIDATION.md).

## Підготовка

```matlab
cd /Users/denis/Documents/MATLAB/PV-Station-Digital-Twin
addpath(genpath(fullfile(pwd, 'scripts')));
addpath(fullfile(pwd, 'simulink_models'));

test_compatibility();
test_topology_core();
```

## Один розрахунок топології

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

Параметр `DcCableLength` є скаляром або вектором з одним значенням для кожного стрінгу. Це дозволяє моделювати нерівні колекторні траси.

## Параметрична серія

```matlab
results = run_simulation_suite( ...
    'ModulesPerString', [8 10 12], ...
    'NumberOfStrings', [2 5 10], ...
    'Topology', {'string','multi-string','central'}, ...
    'InverterRatedPower', [10e3 25e3 50e3], ...
    'AcCableLengthKm', [0.1 0.5 1.0]);
```

У результати включено `Feasible`, максимальні струми та напругу стрінгу. Недопустимі варіанти не слід використовувати для порівняльних висновків.

## Вибір найкращої альтернативи

```matlab
[X_opt, lifecycleCost, study] = optimize_topology( ...
    'ModulesPerString', [8 10 12], ...
    'NumberOfStrings', [2 5 10], ...
    'Topology', {'string','multi-string','central'});

study.optimum
```

Критерій оптимізації — дисконтовані життєві витрати за введених економічних припущень. Перед публікацією замініть сценарні ціни і профілі на дані з документованими джерелами.

## Simulink

```matlab
init_pv_station_main();
build_all_models();
load_simulink_models();
```

Згенеровані Simulink-моделі компілюються. Їхній повний динамічний та гармонічний аналіз ще не верифіковано; не застосовуйте його результати як доказ THD, поведінки PLL або відповідності IEEE/IEC.
