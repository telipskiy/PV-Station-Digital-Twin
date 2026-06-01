%% ============================================================================
% GRIDMODEL - Модель електричної мережі
% Version: 1.0
% Date: 2026-06-01
% ==============================================================================

classdef GridModel < handle
    properties
        % Параметри мережі
        U_nom               % Номінальна напруга [kV]
        f_nom               % Номінальна частота [Hz]
        S_scc               % Short-circuit power [VA]
        Z_grid              % Impedance [Ω]
        
        % Кабель
        cable_length        % Довжина [km]
        R_cable             % Активний опір [Ω]
        X_cable             % Реактивний опір [Ω]
        L_cable             % Індуктивність [H]
        C_cable             % Ємність [F]
        
        % Динамічні параметри
        voltage_actual      % Поточна напруга [V]
        frequency_actual    % Поточна частота [Hz]
        short_circuit_power % Поточна потужність КЗ [VA]
        
        % Навантаження
        load_active         % Активне навантаження [W]
        load_reactive       % Реактивне навантаження [VAR]
        
        % Якість енергії
        voltage_unbalance   % Несиметрія напруги [%]
        frequency_deviation % Відхилення частоти [Hz]
        harmonics           % Фоновий рівень гармонік
        
        % Логування
        logger
    end
    
    methods
        function obj = GridModel(grid_params, logger)
            % Конструктор
            if nargin < 2
                obj.logger = Logger('logs/grid_model.log', 'INFO');
            else
                obj.logger = logger;
            end
            
            obj.U_nom = grid_params.U_nom;
            obj.f_nom = grid_params.f_nom;
            obj.S_scc = grid_params.S_scc;
            obj.Z_grid = grid_params.Z_grid;
            
            obj.cable_length = grid_params.Lcable;
            obj.R_cable = grid_params.R_cable_20 * (1 + 0.004 * (25 - 20));
            obj.X_cable = grid_params.X_cable_km * obj.cable_length;
            obj.L_cable = obj.X_cable / (2 * pi * obj.f_nom);
            obj.C_cable = 250e-9;  % Типовий NYC кабель
            
            obj.voltage_actual = obj.U_nom;
            obj.frequency_actual = obj.f_nom;
            obj.short_circuit_power = obj.S_scc;
            
            obj.load_active = 30e3;  % 30 kW
            obj.load_reactive = 10e3 * tan(acos(0.95));  % Q для cos(φ) = 0.95
            
            obj.voltage_unbalance = 0.01;  % 1%
            obj.frequency_deviation = 0;
            obj.harmonics = obj.init_harmonics();
            
            obj.logger.info('GridModel initialized: %.0f kV, SCpower: %.0f MVA', ...
                obj.U_nom, obj.S_scc/1e6);
        end
        
        function [U_grid, f_grid, I_grid] = update(obj, P_inj, Q_inj)
            % Оновити параметри мережі після ін'єкції потужності
            
            if nargin < 3
                Q_inj = 0;
            end
            
            % Відхилення напруги
            % ΔU = (P·R + Q·X) / U_nom
            Delta_U = (P_inj * obj.R_cable + Q_inj * obj.X_cable) / (obj.U_nom * 1000);
            obj.voltage_actual = obj.U_nom * (1 - Delta_U);
            
            % Обмеження напруги
            if obj.voltage_actual > obj.U_nom * 1.1
                obj.voltage_actual = obj.U_nom * 1.1;
            elseif obj.voltage_actual < obj.U_nom * 0.9
                obj.voltage_actual = obj.U_nom * 0.9;
            end
            
            % Відхилення частоти (Rate of Change of Frequency - RoCoF)
            % Спрощена модель: ΔP впливає на частоту
            Delta_f = -0.1 * (P_inj - obj.load_active) / obj.S_scc;  % Hz
            obj.frequency_actual = obj.f_nom + Delta_f;
            
            % Обмеження частоти
            obj.frequency_actual = max(min(obj.frequency_actual, obj.f_nom + 0.5), obj.f_nom - 0.5);
            
            % Струм
            S_total = sqrt(P_inj^2 + Q_inj^2);
            I_grid = (S_total * 1000) / (obj.voltage_actual * 1000 * sqrt(3));
            
            % Неконтрольовані коливання
            obj.frequency_deviation = randn() * 0.01;  % ±0.01 Hz
            obj.voltage_unbalance = 0.01 + randn() * 0.005;  % ~1% ±0.5%
            
            U_grid = obj.voltage_actual;
            f_grid = obj.frequency_actual;
        end
        
        function harmonics = init_harmonics(obj)
            % Фоновий рівень гармонік у мережі (IEC 61000-3-6)
            harmonics = struct();
            harmonics.h3 = 2.5;    % %
            harmonics.h5 = 5.0;    % %
            harmonics.h7 = 3.5;    % %
            harmonics.h9 = 1.5;    % %
            harmonics.h11 = 3.0;   % %
            harmonics.h13 = 1.5;   % %
        end
        
        function is_fault = detect_fault(obj, U_grid, f_grid, I_grid)
            % Детекція несправності у мережі
            is_fault = false;
            
            % Перевірка напруги
            if U_grid < obj.U_nom * 0.5
                obj.logger.warning('Grid fault detected: U = %.2f kV (critical)', U_grid);
                is_fault = true;
            end
            
            % Перевірка частоти
            if f_grid < 57 || f_grid > 63
                obj.logger.warning('Grid fault detected: f = %.2f Hz (critical)', f_grid);
                is_fault = true;
            end
        end
    end
end
