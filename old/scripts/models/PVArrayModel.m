%% ========================================================================
%  DIGITAL TWIN: PVARRAYMODEL - Удосконалена модель ФВ поля
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

classdef PVArrayModel < handle
    properties
        % Базові параметри
        n_s                 % Модулів у рядку
        n_p                 % Паралельних рядків
        n_total             % Всього модулів
        
        % Електричні параметри (STC)
        P_rated             % Номінальна потужність [W]
        V_oc                % Напруга розімкнення [V]
        V_mp                % Напруга при max power [V]
        I_sc                % Струм короткого замикання [A]
        I_mp                % Струм при max power [A]
        
        % Single Diode Model
        I_ph0               % Фотострум [A]
        I_0                 % Струм насичення [A]
        n_id                % Ideality factor
        Rs                  % Series resistance [Ω]
        Rsh                 % Shunt resistance [Ω]
        
        % Температурні коефіцієнти
        alpha_I             % Temperature coeff for current [A/°C]
        beta_V              % Temperature coeff for voltage [V/°C]
        gamma_P             % Temperature coeff for power [%/°C]
        
        % Удосконалення
        soiling_factor      % Забруднення (0-1)
        degradation_year    % Річна деградація (0-0.01)
        year_of_operation   % Років роботи
        mismatch_loss       % Невідповідність модулів (%)
        
        % MPPT контролер
        mppt_enabled        % Включити MPPT
        V_ref               % Опорна напруга [V]
        
        % Логування
        logger
    end
    
    methods
        function obj = PVArrayModel(pv_params, logger)
            % Конструктор
            if nargin < 2
                obj.logger = Logger('logs/pv_model.log', 'INFO');
            else
                obj.logger = logger;
            end
            
            % Ініціалізація параметрів
            obj.n_s = pv_params.n_s;
            obj.n_p = pv_params.n_p;
            obj.n_total = obj.n_s * obj.n_p;
            
            obj.P_rated = pv_params.P_rated;
            obj.V_oc = pv_params.V_oc * obj.n_s;
            obj.V_mp = pv_params.V_mp * obj.n_s;
            obj.I_sc = pv_params.I_sc * obj.n_p;
            obj.I_mp = pv_params.I_mp * obj.n_p;
            
            obj.I_ph0 = pv_params.I_ph0 * obj.n_p;
            obj.I_0 = pv_params.I_0;
            obj.n_id = pv_params.n_id;
            obj.Rs = pv_params.Rs / obj.n_p;
            obj.Rsh = pv_params.Rsh * obj.n_s;
            
            obj.alpha_I = pv_params.alpha_I * obj.n_p;
            obj.beta_V = pv_params.beta_V * obj.n_s;
            obj.gamma_P = pv_params.gamma_P;
            
            obj.soiling_factor = 0.95;
            obj.degradation_year = 0.005;  % 0.5% per year
            obj.year_of_operation = 0;
            obj.mismatch_loss = 0.02;  % 2%
            
            obj.mppt_enabled = true;
            obj.V_ref = obj.V_mp;
            
            obj.logger.info('PVArrayModel initialized: %d modules (%.1f kW)', ...
                obj.n_total, obj.P_rated/1000);
        end
        
        function [V, I, P] = calculate(obj, G_solar, T_cell)
            % Розрахувати V-I характеристику
            % G_solar: сонячна радіація [W/m²]
            % T_cell: температура клітини [°C]
            
            % Урахування деградації
            degradation = 1 - obj.degradation_year * obj.year_of_operation;
            
            % Урахування забруднення та невідповідності
            effective_G = G_solar * obj.soiling_factor * (1 - obj.mismatch_loss);
            
            % Фотострум з урахуванням температури
            I_ph = obj.I_ph0 * (effective_G / 1000) * (1 + obj.alpha_I * (T_cell - 25)) * degradation;
            
            % Струм насичення з урахуванням температури
            k_B = 1.381e-23;  % Boltzmann constant
            q_e = 1.602e-19;  % Elementary charge
            V_T = obj.n_s * k_B * (T_cell + 273.15) / q_e;
            I_0 = obj.I_0 * (T_cell / 25)^3 * exp((q_e * obj.V_oc) / (k_B * obj.n_id * (T_cell + 273.15)));
            
            % Опорна напруга
            V_op = linspace(0, obj.V_oc, 100);
            
            % Вирішити неявне рівняння Single Diode Model
            I = zeros(size(V_op));
            for i = 1:length(V_op)
                % I = I_ph - I_0*(exp(q_e*(V+I*Rs)/(k_B*n_id*(T+273.15)))-1) - (V+I*Rs)/Rsh
                % Простий ітераційний метод
                I_iter = I_ph;
                for j = 1:20  % Ітерації
                    I_iter = I_ph - I_0 * (exp((V_op(i) + I_iter * obj.Rs) / V_T) - 1) - ...
                        (V_op(i) + I_iter * obj.Rs) / obj.Rsh;
                end
                I(i) = max(I_iter, 0);
            end
            
            % Потужність
            P = V_op .* I;
            
            % Знайти точку максимальної потужності
            [P_max, idx_max] = max(P);
            V_mp_calc = V_op(idx_max);
            I_mp_calc = I(idx_max);
            
            % Переглянути до опорної напруги (MPPT)
            if obj.mppt_enabled
                idx_ref = find(abs(V_op - obj.V_ref) < 0.5, 1);
                if ~isempty(idx_ref)
                    V = obj.V_ref;
                    I = I(idx_ref);
                    P = V * I;
                else
                    V = V_mp_calc;
                    I = I_mp_calc;
                    P = P_max;
                end
            else
                V = V_mp_calc;
                I = I_mp_calc;
                P = P_max;
            end
        end
        
        function update_mppt_voltage(obj, V_ref)
            % Оновити опорну напругу MPPT
            if V_ref > 0 && V_ref < obj.V_oc
                obj.V_ref = V_ref;
            end
        end
        
        function efficiency = get_efficiency(obj, G_solar, T_cell)
            % Отримати ефективність ФВ модуля
            [~, ~, P] = obj.calculate(G_solar, T_cell);
            P_theoretical = G_solar * obj.n_total * 0.35;  % ~35% ефективність модуля
            efficiency = (P / P_theoretical) * 100;
        end
    end
end
