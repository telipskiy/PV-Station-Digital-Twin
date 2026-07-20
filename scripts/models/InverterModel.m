%% ========================================================================
%  DIGITAL TWIN: INVERTERMODEL - Удосконалена модель інвертора
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

classdef InverterModel < handle
    properties
        % Базові параметри
        P_rated             % Номінальна потужність [W]
        V_dc                % DC link voltage [V]
        U_nom               % Номінальна AC напруга [V]
        f_grid              % Частота мережі [Hz]
        
        % Параметри комутації
        f_sw                % Частота комутування [Hz]
        t_dead              % Dead time [s]
        
        % Ефективність
        efficiency_nom      % Номінальна ефективність
        efficiency_map      % 2D таблиця ефективності P vs V
        P_loss_nom          % Номінальні втрати [W]
        
        % Температура
        temperature         % Поточна температура [°C]
        temp_derating_coeff % Коефіцієнт температурної деградації [%/°C]
        T_max               % Максимальна температура [°C]
        
        % Гармоніки
        THD_nom             % Номінальне THD [%]
        harmonics_enabled   % Включити розрахунок гармонік
        harmonics_profile   % Профіль гармонік
        
        % Режим роботи
        mode                % 'Grid-Connected', 'Islanding', 'Off'
        power_available     % Доступна потужність [W]
        reactive_power      % Реактивна потужність [VAR]
        
        % Контролери
        pll_sync            % PLL синхронізація
        current_controller  % PI контролер струму
        reactive_control    % Q(P) контролер
        
        % Захист
        antiislanding_enabled
        overcurrent_protection
        overvoltage_protection
        
        % Логування
        logger
    end
    
    methods
        function obj = InverterModel(inv_params, logger)
            % Конструктор
            if nargin < 2
                obj.logger = Logger('logs/inverter_model.log', 'INFO');
            else
                obj.logger = logger;
            end
            
            obj.P_rated = inv_params.P_rated;
            obj.V_dc = inv_params.V_dc;
            obj.U_nom = inv_params.U_nom;
            obj.f_grid = inv_params.f_grid;
            obj.f_sw = inv_params.f_sw;
            obj.t_dead = inv_params.t_dead;
            
            obj.efficiency_nom = 0.98;
            obj.P_loss_nom = obj.P_rated * (1 - obj.efficiency_nom);
            obj.temperature = 25;  % °C
            obj.temp_derating_coeff = 0.5;  % 0.5%/°C
            obj.T_max = 80;  % °C
            
            obj.THD_nom = 0.03;  % 3% THD
            obj.harmonics_enabled = true;
            obj.harmonics_profile = obj.init_harmonics();
            
            obj.mode = 'Grid-Connected';
            obj.power_available = obj.P_rated;
            obj.reactive_power = 0;
            
            obj.antiislanding_enabled = true;
            obj.overcurrent_protection = true;
            obj.overvoltage_protection = true;
            
            obj.logger.info('InverterModel initialized: %.1f kW @ %.0f V DC', ...
                obj.P_rated/1000, obj.V_dc);
        end
        
        function [P_out, I_out, U_out, THD] = calculate(obj, P_in, U_grid, I_grid, T_heatsink)
            % Розрахувати вихід інвертора
            
            if nargin < 5
                T_heatsink = 25;
            end
            
            % Оновити температуру
            obj.temperature = T_heatsink;
            
            % Температурна деградація ефективності
            temp_factor = 1 - obj.temp_derating_coeff * (obj.temperature - 25) / 100;
            efficiency = obj.efficiency_nom * max(temp_factor, 0.85);  % Мінімум 85%
            
            % Обмеження потужності при перегріві
            if obj.temperature > obj.T_max
                derating = (obj.T_max - obj.temperature) / 10;  % -10% на кожні 10°C
                obj.power_available = obj.P_rated * max(derating, 0.5);
            else
                obj.power_available = obj.P_rated;
            end
            
            % Вихідна потужність
            P_out = min(P_in * efficiency, obj.power_available);
            
            % Вихідний струм
            if U_grid > 0
                I_out = P_out / U_grid;
            else
                I_out = 0;
            end
            
            % Вихідна напруга (синусоїдальна)
            U_out = U_grid * sqrt(2) * sin(2 * pi * obj.f_grid * rand());
            
            % Розрахунок гармонік
            if obj.harmonics_enabled
                [THD, ~] = obj.calculate_thd(P_out);
            else
                THD = obj.THD_nom;
            end
            
            % Логування
            if P_in > 0 && mod(round(rand()*1000), 100) == 0  % Рідко
                obj.logger.debug('P_in: %.1f W, P_out: %.1f W, Eff: %.2f%%, T: %.1f°C', ...
                    P_in, P_out, efficiency*100, obj.temperature);
            end
        end
        
        function [THD, harmonics] = calculate_thd(obj, P_level)
            % Розрахувати THD на основі рівня потужності
            % THD зазвичай найменший при 50% номіналу
            
            load_factor = P_level / obj.P_rated;
            
            % Профіль гармонік
            if load_factor < 0.1
                THD = 0.08;  % Високе THD при низькому навантаженні
            elseif load_factor < 0.5
                THD = 0.03 - 0.01 * load_factor;  % Мінімум біля 50%
            else
                THD = 0.025 + 0.01 * (load_factor - 0.5);
            end
            
            % Гармоніки (% від основної)
            harmonics = struct();
            harmonics.h3 = 2.5 * load_factor;
            harmonics.h5 = 3.0 * load_factor;
            harmonics.h7 = 1.5 * load_factor;
            harmonics.h9 = 0.8 * load_factor;
            harmonics.h11 = 1.0 * load_factor;
        end
        
        function is_islanding = detect_islanding(obj, f_grid, U_grid)
            % Детекція острівного режиму
            
            % Частотна захист
            if f_grid < 59.3 || f_grid > 60.7  % Hz (для 60 Hz системи)
                is_islanding = true;
                obj.logger.warning('Frequency deviation detected: %.2f Hz', f_grid);
                return;
            end
            
            % Напругова захист
            if U_grid < 0.88 || U_grid > 1.12  % pu (для 10 kV системи)
                is_islanding = true;
                obj.logger.warning('Voltage deviation detected: %.2f pu', U_grid);
                return;
            end
            
            is_islanding = false;
        end
        
        function lvrt_factor = get_lvrt_factor(obj, U_grid)
            % Low Voltage Ride Through - залишитися приєднаним при просаданні
            % Вимога IEEE 1547: залишитися при 0.5 pu на 1 сек
            
            if U_grid >= 0.9
                lvrt_factor = 1.0;  % Нормальна робота
            elseif U_grid >= 0.7
                lvrt_factor = 0.9;  % 90% потужності
            elseif U_grid >= 0.5
                lvrt_factor = 0.5;  % 50% потужності
            else
                lvrt_factor = 0;  % Відключити
            end
        end
        
        function harmonics_struct = init_harmonics(obj)
            % Ініціалізувати структуру гармонік
            harmonics_struct = struct();
            for h = [3, 5, 7, 9, 11, 13, 15, 17, 19, 21]
                harmonics_struct.(sprintf('h%d', h)) = 0;
            end
        end
    end
end
