%% ========================================================================
%  DIGITAL TWIN: ADVANCEDMPPT - контролер системи слідження точки максимуму потужності
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

classdef AdvancedMPPT < handle
    properties
        algorithm           % 'P&O', 'IncCond', 'Fuzzy', 'ML'
        step_size           % Кок обхідних зі вперед [V]
        step_adaptive       % Адаптивний крок
        convergence_time    % Час сходження [s]
        efficiency          % Ефективність [%]
        
        % Історія
        V_history           % Історія напруги
        I_history           % Історія струму
        P_history           % Історія потужності
        
        % Fuzzy Logic
        fuzzy_rules         % Fuzzy правила
        membership_fcn      % Функції приналежності
        
        % Logging
        logger
        update_count
    end
    
    methods
        function obj = AdvancedMPPT(algorithm, logger)
            % Конструктор
            if nargin < 1
                algorithm = 'IncCond';  % До замовчування
            end
            if nargin < 2
                obj.logger = Logger('logs/mppt.log', 'INFO');
            else
                obj.logger = logger;
            end
            
            obj.algorithm = algorithm;
            obj.step_size = 1;          % 1 V
            obj.step_adaptive = true;
            obj.convergence_time = 0;
            obj.efficiency = 0.99;      % Мінімум 99%
            
            obj.V_history = [];
            obj.I_history = [];
            obj.P_history = [];
            obj.update_count = 0;
            
            obj.logger.info('AdvancedMPPT initialized with algorithm: %s', algorithm);
        end
        
        function V_ref = update(obj, V, I, V_old, I_old, dt)
            % Оновити опорну напругу
            
            if nargin < 6
                dt = 0.01;  % 10 ms
            end
            
            obj.update_count = obj.update_count + 1;
            obj.convergence_time = obj.convergence_time + dt;
            
            % Накопичувати історію
            obj.V_history = [obj.V_history, V];
            obj.I_history = [obj.I_history, I];
            obj.P_history = [obj.P_history, V * I];
            
            % Одинячти історію до 1000 точок
            if length(obj.V_history) > 1000
                obj.V_history = obj.V_history(end-999:end);
                obj.I_history = obj.I_history(end-999:end);
                obj.P_history = obj.P_history(end-999:end);
            end
            
            % Вибрати алгоритм
            switch obj.algorithm
                case 'P&O'
                    V_ref = obj.perturbation_observe(V, I, V_old, I_old);
                case 'IncCond'
                    V_ref = obj.incremental_conductance(V, I, V_old, I_old);
                case 'Fuzzy'
                    V_ref = obj.fuzzy_logic(V, I, V_old, I_old);
                case 'ML'
                    V_ref = obj.machine_learning(V, I);
                otherwise
                    V_ref = V;  % Повернути поточне значення
            end
            
            % Адаптивний крок
            if obj.step_adaptive
                obj.step_size = obj.adaptive_step(obj.P_history);
            end
        end
        
        function V_ref = perturbation_observe(obj, V, I, V_old, I_old)
            % Perturb & Observe алгоритм
            dV = V - V_old;
            dI = I - I_old;
            dP = V*I - V_old*I_old;
            
            if abs(dP) < 0.1  % Поріг
                V_ref = V;
            elseif dP > 0
                if dV > 0
                    V_ref = V + obj.step_size;
                else
                    V_ref = V - obj.step_size;
                end
            else
                if dV > 0
                    V_ref = V - obj.step_size;
                else
                    V_ref = V + obj.step_size;
                end
            end
        end
        
        function V_ref = incremental_conductance(obj, V, I, V_old, I_old)
            % Інкрементальна провідність
            
            if abs(V - V_old) < 0.01
                V_ref = V;
                return;
            end
            
            dI = I - I_old;
            dV = V - V_old;
            
            % Поточна та інкрементальна провідності
            conductance = I / V;
            incremental = dI / dV;
            
            % Помісця максимуму коли: dI/dV = -I/V
            if abs(incremental + conductance) < 0.01
                V_ref = V;  % На максимумі
            elseif incremental > -conductance
                V_ref = V - obj.step_size;  % Праворуч
            else
                V_ref = V + obj.step_size;  % Ліворуч
            end
        end
        
        function V_ref = fuzzy_logic(obj, V, I, V_old, I_old)
            % Fuzzy Logic MPPT
            
            dV = V - V_old;
            dI = I - I_old;
            P = V * I;
            P_old = V_old * I_old;
            dP = P - P_old;
            
            % Кримина: 'NB', 'NM', 'NS', 'Z', 'PS', 'PM', 'PB'
            
            % Членство для dP
            if dP > 1
                dP_member = 'PB';  % Positive Big
            elseif dP > 0.1
                dP_member = 'PS';  % Positive Small
            else
                dP_member = 'NS';  % Negative Small
            end
            
            % Членство для dV
            if dV > 0.5
                dV_member = 'PB';
            elseif dV > 0.1
                dV_member = 'PS';
            else
                dV_member = 'NS';
            end
            
            % Правила
            if strcmp(dP_member, 'PB')
                if strcmp(dV_member, 'PB')
                    action = 'PB';  % Малень
                else
                    action = 'PS';
                end
            elseif strcmp(dP_member, 'PS')
                action = 'PS';
            else
                action = 'NB';
            end
            
            % Повернути нове значення
            switch action
                case 'PB'
                    V_ref = V + 2 * obj.step_size;
                case 'PS'
                    V_ref = V + obj.step_size;
                case 'Z'
                    V_ref = V;
                case 'NS'
                    V_ref = V - obj.step_size;
                case 'NB'
                    V_ref = V - 2 * obj.step_size;
            end
        end
        
        function V_ref = machine_learning(obj, V, I)
            % Machine Learning MPPT (спрощена версія)
            
            P = V * I;
            
            if length(obj.P_history) > 10
                P_smooth = movmean(obj.P_history, 10);
                dP_trend = P_smooth(end) - P_smooth(max(1, end-10));
                
                if dP_trend > 1
                    V_ref = V + obj.step_size;
                elseif dP_trend < -1
                    V_ref = V - obj.step_size;
                else
                    V_ref = V;
                end
            else
                V_ref = V;
            end
        end
        
        function step = adaptive_step(obj, P_history)
            % Адаптивний розмір кроку
            
            if length(P_history) < 10
                step = obj.step_size;
                return;
            end
            
            % Обчислити стабільність
            P_recent = P_history(end-9:end);
            P_variance = var(P_recent);
            
            % Якщо стабільне - збільшити крок, якщо коливається - зменшити
            if P_variance < 100
                step = obj.step_size * 1.5;  % Збільшити
            elseif P_variance > 1000
                step = obj.step_size * 0.5;  % Зменшити
            else
                step = obj.step_size;
            end
            
            % Обмежити крок
            step = max(min(step, 5), 0.1);
        end
        
        function metrics = get_metrics(obj)
            % Отримати метрики MPPT
            metrics = struct();
            metrics.update_count = obj.update_count;
            metrics.convergence_time = obj.convergence_time;
            metrics.current_step = obj.step_size;
            
            if ~isempty(obj.P_history)
                metrics.max_power = max(obj.P_history);
                metrics.current_power = obj.P_history(end);
                
                % Обчислити MPPT efficiency
                if metrics.max_power > 0
                    metrics.efficiency = (metrics.current_power / metrics.max_power) * 100;
                else
                    metrics.efficiency = 0;
                end
            else
                metrics.efficiency = 0;
            end
        end
    end
end
