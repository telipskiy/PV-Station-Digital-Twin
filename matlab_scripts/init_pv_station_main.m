%% ========================================================================
%  DIGITAL TWIN: PV STATION - MAIN INITIALIZATION SCRIPT
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  Subject: Initialization of all system parameters for MATLAB Simulink
%  ========================================================================

clear all;
close all; 
clc;

% ========================================================================
% 0. ДОДАТИ ШЛЯХИ ДО ПРОЕКТУ
% ========================================================================

project_root = pwd;
addpath(genpath(fullfile(project_root, 'matlab_scripts')));
addpath(genpath(fullfile(project_root, 'simulink_models')));
addpath(genpath(fullfile(project_root, 'simscape_library')));

% ========================================================================
% 1. ПАРАМЕТРИ ФОТОВОЛЬТАЇЧНОГО ПОЛЯ
% ========================================================================

% Стандартні умови тестування (STC)
STC.T = 25;         % °C
STC.G = 1000;       % W/m²
STC.AM = 1.5;       % Air Mass

% Параметри модуля (типовий 350W модуль)
PV.model = 'Generic 350W';
PV.Pmax_stc = 350;              % Максимальна потужність [W]
PV.Voc_stc = 40.2;              % Напруга холостого ходу [V]
PV.Isc_stc = 9.56;              % Струм короткого замикання [A]
PV.Vmp_stc = 32.5;              % Напруга в точці максимуму [V]
PV.Imp_stc = 10.77;             % Струм в точці максимуму [A]
PV.Ns = 60;                     % Кількість елементів послідовно
PV.Np = 1;                      % Кількість елементів паралельно (обичайно 1)

% Температурні коефіцієнти
PV.alpha_I = 0.0032;            % Коефіцієнт для Isc [A/°C]
PV.beta_V = -0.123;             % Коефіцієнт для Voc [V/°C]
PV.gamma_P = -0.5;              % Коефіцієнт для Pmax [%/°C]

% Параметри для Single Diode Model (видобуті з параметрів)
PV.I_ph_ref = PV.Isc_stc * 1.01;            % Фотострум при STC
PV.I0 = 1e-10;                              % Струм насичення діода [A]
PV.Rs = 0.2;                                % Послідовний опір [Ω]
PV.Rsh = 415;                               % Шунтуючий опір [Ω]
PV.n = 1.2;                                 % Коефіцієнт ідеальності
PV.T_ref = 25;                              % Опорна температура [°C]
PV.G_ref = 1000;                            % Опорна радіація [W/m²]

% КОНФІГУРАЦІЯ ПОЛЯ
% Вектор змінних для оптимізації: n_s (модулів у ряді), n_p (паралельних рядів)
PV.ns_default = 10;             % Модулів у ряді
PV.np_default = 5;              % Паралельних рядів

PV.Pfield_rated = PV.Pmax_stc * PV.ns_default * PV.np_default;   % [W]
PV.Vfield_oc = PV.Voc_stc * PV.ns_default;                       % [V]
PV.Ifield_sc = PV.Isc_stc * PV.np_default;                       % [A]
PV.Vfield_mp = PV.Vmp_stc * PV.ns_default;                       % [V]
PV.Ifield_mp = PV.Imp_stc * PV.np_default;                       % [A]

disp('=== PV Field Parameters ===');
fprintf('Rated Power: %.1f kW\n', PV.Pfield_rated/1e3);
fprintf('Number of Modules (series): %d\n', PV.ns_default);
fprintf('Number of Strings (parallel): %d\n', PV.np_default);
fprintf('Total Modules: %d\n', PV.ns_default * PV.np_default);

% ========================================================================
% 2. ПАРАМЕТРИ DC-DC BOOST КОНВЕРТЕРА
% ========================================================================

DCDC.V_in_min = 250;            % Мінімальна вхідна напруга [V]
DCDC.V_in_max = 500;            % Максимальна вхідна напруга [V]
DCDC.V_out = 600;               % Вихідна напруга [V]
DCDC.P_rated = PV.Pfield_rated; % Номінальна потужність [W]
DCDC.L = 5e-3;                  % Індуктивність [H]
DCDC.C_out = 500e-6;            % Вихідна ємність [F]
DCDC.fsw = 20e3;                % Частота комутування [Hz]
DCDC.t_dead = 100e-9;           % Мертвий час [s]

% MOSFET параметри
DCDC.MOSFET.Rds_on = 0.02;      % Опір в режимі провідження [Ω]
DCDC.MOSFET.Vth = 2;            % Напруга пороку [V]

% Діод параметри
DCDC.Diode.Vf = 0.7;            % Падіння напруги [V]
DCDC.Diode.Rs = 0.01;           % Послідовний опір [Ω]

disp('=== DC-DC Boost Converter Parameters ===');
fprintf('Output Voltage: %.0f V\n', DCDC.V_out);
fprintf('Switching Frequency: %.0f kHz\n', DCDC.fsw/1e3);

% ========================================================================
% 3. ПАРАМЕТРИ ТРЬОХФАЗНОГО ІНВЕРТОРА
% ========================================================================

INV.model = 'Three-Phase, 6-Pulse VSI';
INV.P_rated = 50e3;             % Номінальна потужність [W]
INV.V_dc_nominal = 600;         % Номінальна DC напруга [V]
INV.V_ac_rated = 230;           % Номінальна AC напруга (фазна) [V]
INV.f_grid = 50;                % Частота мережі [Hz]
INV.fsw = 10e3;                 % Частота комутування [Hz]

% LCL фільтр
INV.L1 = 5e-3;                  % Первинна індуктивність [H]
INV.C_filter = 10e-6;           % Ємність фільтра [F]
INV.L2 = 3e-3;                  % Вторинна індуктивність [H]
INV.R_damp = 5;                 % Опір демпфування [Ω]

% Контролер (PI параметри)
INV.PLL.Kp = 100;
INV.PLL.Ki = 5000;

INV.Current_Control.Kp = 50;
INV.Current_Control.Ki = 500;

INV.Voltage_Control.Kp = 10;
INV.Voltage_Control.Ki = 100;

% IGBT параметри
INV.IGBT.Vsat = 1.3;            % Напруга насичення [V]
INV.IGBT.Eon = 50e-6;           % Енергія включення [J]
INV.IGBT.Eoff = 100e-6;         % Енергія вимкнення [J]

disp('=== Inverter Parameters ===');
fprintf('Rated Power: %.1f kW\n', INV.P_rated/1e3);
fprintf('DC Voltage: %.0f V\n', INV.V_dc_nominal);
fprintf('Grid Frequency: %.0f Hz\n', INV.f_grid);
fprintf('Switching Frequency: %.0f kHz\n', INV.fsw/1e3);

% ========================================================================
% 4. ПАРАМЕТРИ ТРАНСФОРМАТОРА (опціонально)
% ========================================================================

TR.model = '3-Phase, Yz, Oil-immersed';
TR.S_rated = 63e3;              % Номінальна потужність [VA]
TR.U1_rated = 0.4;              % Первинна напруга [kV]
TR.U2_rated = 10;               % Вторинна напруга [kV]
TR.Zk = 6;                      % Напруга короткого замикання [%]
TR.P_k0 = 500;                  % Втрати без навантаження [W]
TR.P_km = 1100;                 % Втрати при номіналу [W]
TR.I0 = 3;                      % Струм холостого ходу [%]

% Температурні параметри
TR.Delta_Theta_rated = 55;      % Номіналь. зростання темпер. [°C]
TR.Theta_amb_rated = 20;        % Номіналь. темпер. навколи [°C]
TR.Theta_hs_max = 80;           % Макс. температура гаячої точки [°C]

disp('=== Transformer Parameters ===');
fprintf('Rated Power: %.0f kVA\n', TR.S_rated/1e3);
fprintf('Voltage Ratio: %.1f/%.0f kV\n', TR.U1_rated, TR.U2_rated);
fprintf('Short-circuit Voltage: %.1f %%\n', TR.Zk);

% ========================================================================
% 5. ПАРАМЕТРИ ЕЛЕКТРИЧНОЇ МЕРЕЖІ
% ========================================================================

GRID.U_rated = 10;              % Напруга мережі [kV]
GRID.f_rated = 50;              % Частота мережі [Hz]
GRID.P_short_circuit = 100e6;   % Потужність короткого замикання [W]
GRID.Scc_base = 100e6;          % Базова Scc [VA]

% Еквівалентний імпеданс мережі (X/R = 10, типово)
GRID.Zcc = (GRID.U_rated*1e3)^2 / GRID.P_short_circuit;  % [Ω]
GRID.X_grid = GRID.Zcc * 10/11;  % [Ω]
GRID.R_grid = GRID.Zcc / 11;     % [Ω]

% Кабельна мережа (параметри)
CABLE.length = 0.5;             % Довжина кабелю [km]
CABLE.type = 'NYC 3x150';       % Тип кабелю
CABLE.R_per_km = 0.206;         % Опір [Ω/km]
CABLE.X_per_km = 0.083;         % Реактивність [Ω/km]
CABLE.C_per_km = 200e-9;        % Ємність [F/km]

CABLE.R = CABLE.R_per_km * CABLE.length;  % [Ω]
CABLE.X = CABLE.X_per_km * CABLE.length;  % [Ω]
CABLE.C = CABLE.C_per_km * CABLE.length;  % [F]

% Температурна залежність опору кабелю
CABLE.R_ref = CABLE.R;          % Опір при 20°C
CABLE.T_ref = 20;               % Опорна температура
CABLE.alpha = 0.00403;          % Температурний коефіцієнт [1/°C]

disp('=== Network Parameters ===');
fprintf('Grid Voltage: %.0f kV\n', GRID.U_rated);
fprintf('Grid Frequency: %.0f Hz\n', GRID.f_rated);
fprintf('Cable Length: %.2f km\n', CABLE.length);
fprintf('Cable Resistance: %.4f Ω\n', CABLE.R);

% ========================================================================
% 6. ПРОФІЛЬ НАВАНТАЖЕННЯ (добовий цикл)
% ========================================================================

% Часовий вектор (24 години, крок 15 хвилин)
time_step = 15;                               % Крок [хвилин]
t_sim = (0:time_step:24*60-time_step)' * 60;  % Перевести в секунди
n_samples = length(t_sim);

% Типовий профіль навантаження (нормалізований)
hour = mod(t_sim/3600, 24);
P_load_norm = 0.4 + 0.35*sin(2*pi*(hour-6)/24) + 0.15*randn(n_samples, 1);
P_load_norm = max(0.2, min(1, P_load_norm));  % Клипування [0.2, 1.0]
Q_load_norm = P_load_norm * tan(acos(0.95));  % cos(φ) = 0.95

LOAD.P_base = 30e3;                           % Базове активне навантаження [W]
LOAD.Q_base = LOAD.P_base * tan(acos(0.95));  % [VAR]

LOAD.P_demand = LOAD.P_base * P_load_norm;
LOAD.Q_demand = LOAD.Q_base * Q_load_norm;

disp('=== Load Profile ===');
fprintf('Base Active Load: %.1f kW\n', LOAD.P_base/1e3);
fprintf('Base Power Factor: 0.95\n');

% ========================================================================
% 7. ПРОФІЛЬ СОНЯЧНОЇ РАДІАЦІЇ (добовий цикл)
% ========================================================================

% Типовий солярний день (ясна погода)
sunrise = 6;                    % Схід сонця
sunset = 18;                    % Захід сонця
G_max = 1000;                   % Максимальна радіація [W/m²]

% Косинусна крива для ясного дня
G_profile = zeros(n_samples, 1);
for i = 1:n_samples
    h = hour(i);
    if h >= sunrise && h <= sunset
        G_profile(i) = G_max * cos(pi*(h-sunrise)/(sunset-sunrise) - pi/2) * 0.9 + 50*randn;
        G_profile(i) = max(0, G_profile(i));
    end
end

SOLAR.G_profile = G_profile;                                         % [W/m²]
SOLAR.T_cell = 25 + 30*(G_profile/G_max).^2 + 5*randn(n_samples,1);  % Температура елемента
SOLAR.T_cell = max(0, SOLAR.T_cell);

disp('=== Solar Irradiance Profile ===');
fprintf('Peak Irradiance: %.0f W/m²\n', max(SOLAR.G_profile));
fprintf('Average Irradiance (6-18h): %.0f W/m²\n', mean(SOLAR.G_profile(hour>=6 & hour<=18)));

% ========================================================================
% 8. ВЕКТОР ЗМІННИХ ОПТИМІЗАЦІЇ
% ========================================================================

% X = [n_s, n_p, n_inv, P_inv, S_tr, U_mv, A_top, L_cab]
% де:
%   n_s     - модулів у ряді (5-20)
%   n_p     - паралельних рядів (2-20)
%   n_inv   - кількість інвертрів (1-3)
%   P_inv   - потужність інвертора (25-100 kW)
%   S_tr    - потужність трансформатора (25-100 kVA)
%   U_mv    - напруга середньої сторони (0.4, 10, 20 kV)
%   A_top   - архітектурне рішення (1=string, 2=multi-string, 3=central)
%   L_cab   - довжина кабелю (0.1-2 km)

X_opt.lower_bounds = [5, 2, 1, 25e3, 25e3, 0.4, 1, 0.1];
X_opt.upper_bounds = [20, 20, 3, 100e3, 100e3, 20, 3, 2];
X_opt.default = [PV.ns_default, PV.np_default, 1, INV.P_rated, TR.S_rated, TR.U2_rated, 1, CABLE.length];

% Вагові коефіцієнти для цільової функції (нормовані на 1)
WEIGHT.w_cap = 0.30;            % Капітальні витрати
WEIGHT.w_loss = 0.20;           % Втрати енергії
WEIGHT.w_rel = 0.15;            % Надійність
WEIGHT.w_opex = 0.20;           % Експлуатаційні витрати
WEIGHT.w_pq = 0.15;             % Якість електроенергії
WEIGHT.total = WEIGHT.w_cap + WEIGHT.w_loss + WEIGHT.w_rel + WEIGHT.w_opex + WEIGHT.w_pq;

% Перевірка нормування
WEIGHT.w_cap = WEIGHT.w_cap / WEIGHT.total;
WEIGHT.w_loss = WEIGHT.w_loss / WEIGHT.total;
WEIGHT.w_rel = WEIGHT.w_rel / WEIGHT.total;
WEIGHT.w_opex = WEIGHT.w_opex / WEIGHT.total;
WEIGHT.w_pq = WEIGHT.w_pq / WEIGHT.total;

disp('=== Optimization Weights (Normalized) ===');
fprintf('Capital Cost Weight: %.3f\n', WEIGHT.w_cap);
fprintf('Energy Loss Weight: %.3f\n', WEIGHT.w_loss);
fprintf('Reliability Weight: %.3f\n', WEIGHT.w_rel);
fprintf('OPEX Weight: %.3f\n', WEIGHT.w_opex);
fprintf('Power Quality Weight: %.3f\n', WEIGHT.w_pq);

% ========================================================================
% 9. ЕКОНОМІЧНІ ПАРАМЕТРИ
% ========================================================================

ECONOMICS.study_period = 20;      % років
ECONOMICS.discount_rate = 0.08;   % %
ECONOMICS.inflation_rate = 0.02;  % %

% Вартість компонентів (USD/kW або USD/кВА)
ECONOMICS.C_PV = 500;           % $/kW (модулі)
ECONOMICS.C_INV = 300;          % $/kW (інвертор)
ECONOMICS.C_TR = 50;            % $/kVA (трансформатор)
ECONOMICS.C_CABLE = 200;        % $/km (кабель)
ECONOMICS.C_INSTALL = 0.2;      % Коефіцієнт від капіталу (20%)

% Експлуатаційні витрати (% від капіталу на рік)
ECONOMICS.annual_opex_rate = 0.01;  % 1% від капіталу

disp('=== Economic Parameters ===');
fprintf('Study Period: %d years\n', ECONOMICS.study_period);
fprintf('Discount Rate: %.1f %%\n', ECONOMICS.discount_rate*100);
fprintf('PV Cost: %.0f $/kW\n', ECONOMICS.C_PV);

% ========================================================================
% 10. ПАРАМЕТРИ СИМУЛЯЦІЇ
% ========================================================================

SIM.solver = 'ode23tb';         % Розв'язувач (для stiff систем)
SIM.start_time = 0;             % Час початку [s]
SIM.stop_time = 24*3600;        % Час завершення [s] (24 години)
SIM.max_step = 1;               % Максимальний крок часу [s]
SIM.sample_time = 0.01;         % Період дискретизації [s]
SIM.mode = 'Accelerator';       % Режим симуляції (Normal, Accelerator, Rapid)

disp('=== Simulation Parameters ===');
fprintf('Simulation Time: %.1f hours\n', (SIM.stop_time - SIM.start_time)/3600);
fprintf('Solver: %s\n', SIM.solver);
fprintf('Mode: %s\n', SIM.mode);

% ========================================================================
% 11. ПАРАМЕТРИ МІСЦЕПОЛОЖЕННЯ (для MPPT і прогнозу)
% ========================================================================

SITE.location = 'Ukraine, Kyiv';
SITE.latitude = 50.45;          % °N
SITE.longitude = 30.52;         % °E
SITE.altitude = 179;            % m
SITE.tz_offset = 2;             % Часовий пояс UTC+2

disp('Site Location: Ukraine, Kyiv');
disp(['Latitude: ' num2str(SITE.latitude) '°N, Longitude: ' num2str(SITE.longitude) '°E']);

% ========================================================================
% 12. ЗБЕРЕЖЕННЯ ВСІХ ПАРАМЕТРІВ
% ========================================================================

% Збереження в структурі даних
save('pv_station_parameters.mat', 'PV', 'DCDC', 'INV', 'TR', 'GRID', 'CABLE', ...
'LOAD', 'SOLAR', 'X_opt', 'WEIGHT', 'ECONOMICS', 'SIM', 'SITE', 't_sim', 'hour');

disp(' ');
disp('=========================================================================');
disp('✓ INITIALIZATION COMPLETE');
disp('All parameters saved to: pv_station_parameters.mat');
disp(' ');
disp('=========================================================================');
disp('-> Next steps:');
disp(' ');
disp('Build models:');
disp('  >> build_pv_array_subsystem(''SavePath'', ''./simulink_models'')');
disp('  >> build_inverter_subsystem(''SavePath'', ''./simulink_models'')');
disp('  >> build_main_model(''SavePath'', ''./simulink_models'')');
disp(' ');
disp('Run simulation with:');
disp('  >> sim(''PV_Station_Main'')');
disp(' ');

%% ========================================================================
% КІНЕЦЬ ІНІЦІАЛІЗАЦІЇ
% ========================================================================
