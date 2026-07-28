%  ========================================================================
%  DIGITAL TWIN: PV STATION - MAIN PARAMS INITIALIZATION SCRIPT
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  
%  Purpose: Initialization of all system parameters for MATLAB Simulink
%  ========================================================================

function init_pv_station_main()

    % Reproducible synthetic profiles. Replace these profiles with measured
    % meteorological data for a case study and record the data provenance.
    rng(20260728, 'twister');

    % ========================================================================
    % 1. ПАРАМЕТРИ ФОТОВОЛЬТАЇЧНОГО ПОЛЯ
    % Мета: Визначити всі параметри для фотоелектричних модулів та конфігурації масиву.
    % До них належать електричні характеристики за стандартних випробувальних умов (STC),
    % температурні коефіцієнти та параметри моделі одного діода для точного
    % моделювання поведінки фотоелектричних систем за різних умов освітлення та температури.
    % ========================================================================
    
    % Стандартні умови тестування (STC)
    STC.T = 25;         % Температура елемента [°C]
    STC.G = 1000;       % Сонячна радіація [Вт/м²]
    STC.AM = 1.5;       % Співвідношення маси повітря

    % Параметри модуля (типовий 350W модуль)
    PV.model = 'Generic 350W';
    PV.Pmax_stc = 350;              % Максимальна потужність [W]
    PV.Voc_stc = 40.2;              % Напруга холостого ходу [V]
    PV.Isc_stc = 9.56;              % Струм короткого замикання [A]
    PV.Vmp_stc = 32.5;              % Напруга в точці максимуму [V]
    PV.Imp_stc = 10.77;             % Струм в точці максимуму [A]
    PV.Ns = 60;                     % Кількість елементів послідовно
    PV.Np = 1;                      % Кількість елементів паралельно (звичайно 1)

    % Температурні коефіцієнти – відносна зміна електричних параметрів на °C
    % Ці значення використовуються в моделі одного діода для налаштування електричних
    % властивостей на основі фактичної температури елемента
    PV.alpha_I = 0.0032;            % Коефіцієнт для Isc [A/°C]
    PV.beta_V = -0.123;             % Коефіцієнт для Voc [V/°C]
    PV.gamma_P = -0.5;              % Коефіцієнт для Pmax [%/°C]
    
    % Параметри моделі одного діода - Математична модель для фотоелектричного елемента:
    % I = I_ph - I_0*(exp(qV/nkT) - 1) - V/Rsh
    % де I_ph - фотострум, I_0 - струм насичення, n - коефіцієнт ідеальності
    PV.I_ph_ref = PV.Isc_stc * 1.01;            % Фотострум при STC
    PV.I0 = 1e-10;                              % Струм насичення діода [A]
    PV.Rs = 0.2;                                % Послідовний опір [Ω]
    PV.Rsh = 415;                               % Шунтуючий опір [Ω]
    PV.n = 1.2;                                 % Коефіцієнт ідеальності
    PV.T_ref = 25;                              % Опорна температура [°C]
    PV.G_ref = 1000;                            % Опорна радіація [W/m²]

    % КОНФІГУРАЦІЯ ПОЛЯ - Змінні проектування для оптимізації
    % Вектор змінних для оптимізації: n_s (модулів у ряді), n_p (паралельних рядів)
    PV.ns_default = 10;             % Модулів у ряді
    PV.np_default = 5;              % Паралельних рядів
    
    % Похідні параметри масиву (розраховані з модуля + конфігурації)
    PV.Pfield_rated = PV.Pmax_stc * PV.ns_default * PV.np_default;   % Загальна номінальна потужність [Вт]
    PV.Vfield_oc = PV.Voc_stc * PV.ns_default;                       % Напруга холостого ходу масиву [В]
    PV.Ifield_sc = PV.Isc_stc * PV.np_default;                       % Струм короткого замикання масиву [A]
    PV.Vfield_mp = PV.Vmp_stc * PV.ns_default;                       % Напруга MPP масиву [В]
    PV.Ifield_mp = PV.Imp_stc * PV.np_default;                       % Струм MPP масиву [A]
    
    disp('=== PV Field Parameters ===');
    fprintf('Rated Power: %.1f kW\n', PV.Pfield_rated/1e3);
    fprintf('Number of Modules (series): %d\n', PV.ns_default);
    fprintf('Number of Strings (parallel): %d\n', PV.np_default);
    fprintf('Total Modules: %d\n', PV.ns_default * PV.np_default);
    fprintf('\n');
    
    % ========================================================================
    % 2. ПАРАМЕТРИ DC-DC BOOST КОНВЕРТЕРА
    % Мета: Визначити параметри для підвищувального перетворювача, який підвищує напругу фотоелектричних систем
    % від ~300-500 В (фотоелектрична батарея) до ~600 В (ланцюг постійного струму інвертора). Це забезпечує
    % достатній запас напруги для генерації 3-фазного змінного струму та зменшує струм.
    % ========================================================================
    
    DCDC.V_in_min = 250;            % Мінімальна вхідна напруга [V]
    DCDC.V_in_max = 500;            % Максимальна вхідна напруга [V]
    DCDC.V_out = 600;               % Вихідна напруга [V]
    DCDC.P_rated = PV.Pfield_rated; % Номінальна потужність [W]
    DCDC.L = 5e-3;                  % Індуктивність [H]
    DCDC.C_out = 500e-6;            % Вихідна ємність [F]
    DCDC.fsw = 20e3;                % Частота комутування [Hz]
    DCDC.t_dead = 100e-9;           % Мертвий час [s]
    
    % Параметри MOSFET (метал-оксид-напівпровідниковий польовий транзистор) для підвищувального перемикача
    DCDC.MOSFET.Rds_on = 0.02;      % Опір в режимі провідження [Ω]
    DCDC.MOSFET.Vth = 2;            % Напруга пороку [V]
    
    % Параметри діода вільного ходу (проводить, коли MOSFET вимкнений)
    DCDC.Diode.Vf = 0.7;            % Падіння напруги [V]
    DCDC.Diode.Rs = 0.01;           % Послідовний опір [Ω]
    
    disp('=== DC-DC Boost Converter Parameters ===');
    fprintf('Output Voltage: %.0f V\n', DCDC.V_out);
    fprintf('Switching Frequency: %.0f kHz\n', DCDC.fsw/1e3);
    fprintf('\n');
    
    % ========================================================================
    % 3. ПАРАМЕТРИ ТРЬОХФАЗНОГО ІНВЕРТОРА
    % Мета: Визначити параметри для мережевого 3-фазного інвертора, який перетворює
    % постійний струм на змінний. Включає параметри силової електроніки (IGBT-перемикачі), фільтра (LCL),
    % та системи керування (PLL, керування струмом).
    % ========================================================================
    
    INV.model = 'Three-Phase, 6-Pulse VSI';
    INV.P_rated = 50e3;             % Номінальна потужність [W]
    INV.V_dc_nominal = 600;         % Номінальна DC напруга [V]
    INV.V_ac_rated = 230;           % Номінальна AC напруга (фазна) [V]
    INV.f_grid = 50;                % Частота мережі [Hz]
    INV.fsw = 10e3;                 % Частота комутування [Hz]
    
    % LCL Вихідний фільтр (L-C-L) - Зменшує комутаційні гармоніки
    % L1 = індуктор на стороні інвертора, C = конденсатор, L2 = індуктор на стороні мережі
    INV.L1 = 5e-3;                  % Первинна індуктивність [H]
    INV.C_filter = 10e-6;           % Ємність фільтра [F]
    INV.L2 = 3e-3;                  % Вторинна індуктивність [H]
    INV.R_damp = 5;                 % Опір демпфування [Ω]
    
    % Параметри контролера фазового автопідстроювання частоти (ФАПЧ)
    % ФАПЧ фіксує вихідну частоту перетворювача відповідно до частоти мережі
    INV.PLL.Kp = 100;
    INV.PLL.Ki = 5000;
    
    % Параметри контуру керування струмом (внутрішній контур для стабільної роботи)
    INV.Current_Control.Kp = 50;
    INV.Current_Control.Ki = 500;
    
    % Параметри контуру регулювання напруги (зовнішній контур для регулювання напруги)
    INV.Voltage_Control.Kp = 10;
    INV.Voltage_Control.Ki = 100;
    
    % Параметри IGBT (біполярного транзистора з ізольованим затвором) - головний вимикач живлення
    INV.IGBT.Vsat = 1.3;            % Напруга насичення [V]
    INV.IGBT.Eon = 50e-6;           % Енергія включення [J]
    INV.IGBT.Eoff = 100e-6;         % Енергія вимкнення [J]
    
    disp('=== Inverter Parameters ===');
    fprintf('Rated Power: %.1f kW\n', INV.P_rated/1e3);
    fprintf('DC Voltage: %.0f V\n', INV.V_dc_nominal);
    fprintf('Grid Frequency: %.0f Hz\n', INV.f_grid);
    fprintf('Switching Frequency: %.0f kHz\n', INV.fsw/1e3);
    fprintf('\n');
    
    % ========================================================================
    % 4. ПАРАМЕТРИ ТРАНСФОРМАТОРА (опціонально)
    % Мета: Визначити параметри для підвищувального трансформатора (від 0,4 кВ до 10 кВ),
    % який використовується для підключення фотоелектричної системи до мережі середньої напруги.
    % Включає втрати в осерді, втрати в міді та теплові характеристики.
    % ========================================================================
    
    TR.model = '3-Phase, Yz, Oil-immersed';
    TR.S_rated = 63e3;              % Номінальна потужність [VA]
    TR.U1_rated = 0.4;              % Первинна напруга [kV]
    TR.U2_rated = 10;               % Вторинна напруга [kV]
    TR.Zk = 6;                      % Напруга короткого замикання [%]
    TR.P_k0 = 500;                  % Втрати без навантаження [W]
    TR.P_km = 1100;                 % Втрати при номіналу [W]
    TR.I0 = 3;                      % Струм холостого ходу [%]
    
    % Теплові параметри для розрахунку підвищення температури
    TR.Delta_Theta_rated = 55;      % Номіналь. зростання темпер. [°C]
    TR.Theta_amb_rated = 20;        % Номіналь. темпер. навколи [°C]
    TR.Theta_hs_max = 80;           % Макс. температура гаячої точки [°C]
    
    disp('=== Transformer Parameters ===');
    fprintf('Rated Power: %.0f kVA\n', TR.S_rated/1e3);
    fprintf('Voltage Ratio: %.1f/%.0f kV\n', TR.U1_rated, TR.U2_rated);
    fprintf('Short-circuit Voltage: %.1f %%\n', TR.Zk);
    fprintf('\n');
    
    % ========================================================================
    % 5. ПАРАМЕТРИ ЕЛЕКТРИЧНОЇ МЕРЕЖІ
    % Мета: Визначити параметри мережі, включаючи рівень напруги, частоту,
    % потужність короткого замикання та імпеданс кабелю для точного
    % аналізу потоку потужності та стабільності.
    % ========================================================================
    
    GRID.U_rated = 10;              % Напруга мережі [kV]
    GRID.f_rated = 50;              % Частота мережі [Hz]
    GRID.P_short_circuit = 100e6;   % Потужність короткого замикання [W]
    GRID.Scc_base = 100e6;          % Базова Scc [VA]
    
    % Еквівалентний імпеданс мережі (X/R = 10, типово для мереж середньої напруги)
    GRID.Zcc = (GRID.U_rated*1e3)^2 / GRID.P_short_circuit;  % [Ω]
    GRID.X_grid = GRID.Zcc * 10/11;  % [Ω]
    GRID.R_grid = GRID.Zcc / 11;     % [Ω]
    
    % Параметри силового кабелю, що з'єднує вторинну лінію трансформатора з мережею
    CABLE.length = 0.5;             % Довжина кабелю [km]
    CABLE.type = 'NYC 3x150';       % Тип кабелю
    CABLE.R_per_km = 0.206;         % Опір [Ω/km]
    CABLE.X_per_km = 0.083;         % Реактивність [Ω/km]
    CABLE.C_per_km = 200e-9;        % Ємність [F/km]
    
    % Загальний імпеданс кабелю (частотно-незалежна модель для 50 Гц)
    CABLE.R = CABLE.R_per_km * CABLE.length;  % [Ω]
    CABLE.X = CABLE.X_per_km * CABLE.length;  % [Ω]
    CABLE.C = CABLE.C_per_km * CABLE.length;  % [F]
    
    % Температурна залежність опору кабелю
    % R(T) = R_ref * (1 + альфа * (T - T_ref))
    CABLE.R_ref = CABLE.R;          % Опір при 20°C
    CABLE.T_ref = 20;               % Опорна температура
    CABLE.alpha = 0.00403;          % Температурний коефіцієнт [1/°C]
    CABLE.T_operating = 20;         % Температура провідника для базового сценарію [°C]
    
    disp('=== Network Parameters ===');
    fprintf('Grid Voltage: %.0f kV\n', GRID.U_rated);
    fprintf('Grid Frequency: %.0f Hz\n', GRID.f_rated);
    fprintf('Cable Length: %.2f km\n', CABLE.length);
    fprintf('Cable Resistance: %.4f Ω\n', CABLE.R);
    fprintf('\n');
    
    % ========================================================================
    % 6. ПРОФІЛЬ НАВАНТАЖЕННЯ (добовий цикл)
    % Мета: Визначити реалістичний профіль електричного навантаження, 
    % що відображає споживання споживача протягом 24 годин.
    % Включає змінну в часі активну та реактивну потужність.
    % ========================================================================
    
    % Часовий вектор (24 години, крок 15 хвилин)
    time_step = 15;                               % Крок [хвилин]
    t_sim = (0:time_step:24*60-time_step)' * 60;  % Перевести в секунди
    n_samples = length(t_sim);
    
    % Типовий профіль навантаження (нормалізований) - типова картина з піками о 8:00 та 18:00
    hour = mod(t_sim/3600, 24);
    P_load_norm = 0.4 + 0.35*sin(2*pi*(hour-6)/24) + 0.15*randn(n_samples, 1);
    P_load_norm = max(0.2, min(1, P_load_norm));  % Клипування [0.2, 1.0]

    % Реактивна складова потужності (коефіцієнт потужності cos(φ) = 0,95, типовий для промислових навантажень)
    Q_load_norm = P_load_norm * tan(acos(0.95));
    
    LOAD.P_base = 30e3;                           % Базове активне навантаження [W]
    LOAD.Q_base = LOAD.P_base * tan(acos(0.95));  % Базове реактивне навантаження [VAR]
    
    % Масштабування нормалізованого профілю до фактичних значень
    LOAD.P_demand = LOAD.P_base * P_load_norm;
    LOAD.Q_demand = LOAD.Q_base * Q_load_norm;
    
    disp('=== Load Profile ===');
    fprintf('Base Active Load: %.1f kW\n', LOAD.P_base/1e3);
    fprintf('Base Power Factor: 0.95\n');
    fprintf('\n');
    
    % ========================================================================
    % 7. ПРОФІЛЬ СОНЯЧНОЇ РАДІАЦІЇ (добовий цикл)
    % Мета: Визначити реалістичні профілі сонячної радіації та температури елемента.
    % Використовує косинусоподібну криву для ясного дня з типовим часом сходу/заходу сонця.
    % ========================================================================
    
    % Типовий солярний день (ясна погода)
    sunrise = 6;                    % Схід сонця
    sunset = 18;                    % Захід сонця
    G_max = 1000;                   % Максимальна радіація [W/m²]
    
    % Створення профілю опроміненості за допомогою косинусної кривої (ясна погода)
    G_profile = zeros(n_samples, 1);
    for i = 1:n_samples
        h = hour(i);
        if h >= sunrise && h <= sunset
            % Косинусна крива досягає піку опівдні
            G_profile(i) = G_max * cos(pi*(h-sunrise)/(sunset-sunrise) - pi/2) * 0.9 + 50*randn;
            G_profile(i) = max(0, G_profile(i));
        end
    end
    
    SOLAR.G_profile = G_profile; % Сонячна радіація [Вт/м²]

    % Модель температури елемента: T_cell = 25 + 30*(G/G_max)² + випадковий шум
    % Вища опроміненість → вища температура елемента (знижує ефективність)
    SOLAR.T_cell = 25 + 30*(G_profile/G_max).^2 + 5*randn(n_samples,1);
    SOLAR.T_cell = max(0, SOLAR.T_cell);
    
    disp('=== Solar Irradiance Profile ===');
    fprintf('Peak Irradiance: %.0f W/m²\n', max(SOLAR.G_profile));
    fprintf('Average Irradiance (6-18h): %.0f W/m²\n', mean(SOLAR.G_profile(hour>=6 & hour<=18)));
    fprintf('\n');
    
    % ========================================================================
    % 8. ВЕКТОР ЗМІННИХ ОПТИМІЗАЦІЇ
    % Мета: Визначити змінні рішення для багатоцільової оптимізації.
    % Це параметри, які можна налаштувати для мінімізації вартості системи, водночас
    % дотримуючись обмежень продуктивності та надійності.
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
    X_opt.upper_bounds = [20, 20, 20, 100e3, 100e3, 20, 3, 2];
    X_opt.default = [PV.ns_default, PV.np_default, 1, INV.P_rated, TR.S_rated, TR.U2_rated, 1, CABLE.length];

    % Єдина конфігурація топології для стаціонарних і Simulink-дослідів.
    % string: інвертор на кожен стрінг; multi-string: групи стрінгів;
    % central: один інвертор для всього поля.
    TOPOLOGY = create_topology_config( ...
        'ModulesPerString', PV.ns_default, ...
        'NumberOfStrings', PV.np_default, ...
        'Topology', 'central', ...
        'NumberOfInverters', 1, ...
        'InverterRatedPower', INV.P_rated, ...
        'DcCableLength', 20, ...
        'AcCableLength', CABLE.length);
    
    % Вагові коефіцієнти цільової функції нормовані на 1 (багатокритеріальна оптимізація)
    % Загальна вартість = w_cap*Fcap + w_loss*Floss + w_rel*Frel + w_opex*Fopex + w_pq*Fpq
    WEIGHT.w_cap = 0.30;            % Капітальні витрати
    WEIGHT.w_loss = 0.20;           % Втрати енергії
    WEIGHT.w_rel = 0.15;            % Надійність
    WEIGHT.w_opex = 0.20;           % Експлуатаційні витрати
    WEIGHT.w_pq = 0.15;             % Якість електроенергії
    WEIGHT.total = WEIGHT.w_cap + WEIGHT.w_loss + WEIGHT.w_rel + WEIGHT.w_opex + WEIGHT.w_pq;
    
    % Перевірка нормування суми до 1,0 (найкраща практика для багатоцільової оптимізації)
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
    fprintf('\n');
    
    % ========================================================================
    % 9. ЕКОНОМІЧНІ ПАРАМЕТРИ
    % Мета: Визначити всі параметри витрат та економічні показники для розрахунків LCOE
    % (приведеної вартості енергії) та NPV (чистої приведеної вартості).
    % ========================================================================
    
    ECONOMICS.study_period = 20;      % Тривалість проекту [роки]
    ECONOMICS.discount_rate = 0.08;   % Дисконтна ставка для чистої поточної вартості [%]
    ECONOMICS.inflation_rate = 0.02;  % Річний рівень інфляції [%]
    
    % Капітальних витрат. Вартість компонентів (USD/kW або USD/кВА) по типовим цінам на 2026 рік
    ECONOMICS.C_PV = 500;           % $/kW (модулі)
    ECONOMICS.C_INV = 300;          % $/kW (інвертор)
    ECONOMICS.C_TR = 50;            % $/kVA (трансформатор)
    ECONOMICS.C_CABLE = 200;        % $/km (кабель)
    ECONOMICS.C_INSTALL = 0.2;      % Вартість встановлення як % від вартості обладнання (20%)
    
    % Експлуатаційні витрати, як відсоток від капітальних витрат: 
    % профілактичне обслуговування, страхування (% від капіталу на рік)
    ECONOMICS.annual_opex_rate = 0.01;  % 1% від капіталу
    
    disp('=== Economic Parameters ===');
    fprintf('Study Period: %d years\n', ECONOMICS.study_period);
    fprintf('Discount Rate: %.1f %%\n', ECONOMICS.discount_rate*100);
    fprintf('PV Cost: %.0f $/kW\n', ECONOMICS.C_PV);
    fprintf('\n');
    
    % ========================================================================
    % 10. ПАРАМЕТРИ СИМУЛЯЦІЇ
    % Мета: Визначити параметри числового розв'язувача та моделювання для Simulink.
    % Критично важливо для точності та обчислювальної ефективності динамічного моделювання.
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
    fprintf('\n');
    
    % ========================================================================
    % 11. ПАРАМЕТРИ МІСЦЕПОЛОЖЕННЯ (для MPPT і прогнозу)
    % Мета: Визначити географічне розташування для оцінки сонячних ресурсів та
    % обробки часового поясу. Важливо для моделей прогнозування опромінення.
    % ========================================================================
    
    SITE.location = 'Ukraine, Dnipro';
    SITE.latitude = 48.46;          % °N
    SITE.longitude = 35.05;         % °E
    SITE.altitude = 155;            % m
    SITE.tz_offset = 2;             % Часовий пояс UTC+2
    
    disp('Site Location: Ukraine, Dnipro');
    disp(['Latitude: ' num2str(SITE.latitude) '°N, Longitude: ' num2str(SITE.longitude) '°E']);
    fprintf('\n');
    
    % ========================================================================
    % 12. ЗБЕРЕЖЕННЯ ВСІХ ПАРАМЕТРІВ
    % Мета: Зберегти всі ініціалізовані параметри у файл даних MATLAB для
    % швидкого завантаження в наступних скриптах без повторного запуску ініціалізації.
    % ========================================================================
    
    % Збереження в структурі даних
    PARAMS = struct('PV', PV, 'DCDC', DCDC, 'INV', INV, 'TR', TR, 'GRID', GRID, 'CABLE', CABLE);
    save('./data/pv_station_parameters.mat', 'PV', 'DCDC', 'INV', 'TR', 'GRID', 'CABLE', 'TOPOLOGY', 'PARAMS', ...
    'LOAD', 'SOLAR', 'X_opt', 'WEIGHT', 'ECONOMICS', 'SIM', 'SITE', 't_sim', 'hour');

    % Referenced Simulink models evaluate block parameters in the base
    % workspace.  Publish the same parameter objects that were archived.
    baseVariables = {'PV','DCDC','INV','TR','GRID','CABLE','TOPOLOGY','PARAMS', ...
        'LOAD','SOLAR','X_opt','WEIGHT','ECONOMICS','SIM','SITE','t_sim','hour'};
    for k = 1:numel(baseVariables)
        assignin('base', baseVariables{k}, eval(baseVariables{k}));
    end
    
    % ========================================================================
    % РЕЗУЛЬТАТ
    % ========================================================================
    
    disp('✓ Parameters initialization complete');
    disp('✓ All parameters saved to: ./data/pv_station_parameters.mat');

end
