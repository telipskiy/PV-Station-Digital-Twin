%% ========================================================================
%  DIGITAL TWIN: CONFIGVALIDATOR - Валідація конфігурації системи
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

classdef ConfigValidator
    properties (Constant)
        % Мінімальні та максимальні значення
        PV_LIMITS = struct(...
            'ns', [1, 50], ...
            'np', [1, 50], ...
            'P_rated', [1e3, 500e3]);
        
        INV_LIMITS = struct(...
            'P_rated', [1e3, 500e3], ...
            'V_dc', [200, 1000], ...
            'f_sw', [1e3, 50e3]);
        
        TR_LIMITS = struct(...
            'S_rated', [10e3, 1e6], ...
            'U1', [0.2, 1.0], ...
            'U2', [0.4, 50]);
        
        GRID_LIMITS = struct(...
            'f_nom', [49, 51], ...
            'U_nom', [0.1, 100], ...
            'Z_grid', [0, 10]);
        
        SIM_LIMITS = struct(...
            'StopTime', [1, 86400], ...
            'RelTol', [1e-6, 1e-2], ...
            'MaxStep', [1e-6, 1]);
    end
    
    methods (Static)
        function is_valid = validate_pv_params(pv_params, logger)
            % Валідація параметрів ФВ
            is_valid = true;
            
            if nargin < 2
                logger = [];
            end
            
            try
                % Перевірка обов'язкових полів
                required_fields = {'n_s', 'n_p', 'P_rated', 'V_oc', 'I_sc'};
                for i = 1:length(required_fields)
                    if ~isfield(pv_params, required_fields{i})
                        msg = sprintf('Missing field: %s', required_fields{i});
                        if ~isempty(logger)
                            logger.error(msg);
                        else
                            error('%s', msg);
                        end
                        is_valid = false;
                        return;
                    end
                end
                
                % Перевірка діапазонів
                if pv_params.n_s < 1 || pv_params.n_s > 50
                    throw(MException('Validation:InvalidValue', 'n_s out of range'));
                end
                if pv_params.n_p < 1 || pv_params.n_p > 50
                    throw(MException('Validation:InvalidValue', 'n_p out of range'));
                end
                if pv_params.P_rated < 1e3 || pv_params.P_rated > 500e3
                    throw(MException('Validation:InvalidValue', 'P_rated out of range'));
                end
                
                % Перевірка логічних зв'язків
                if pv_params.V_oc <= 0 || pv_params.I_sc <= 0
                    throw(MException('Validation:InvalidValue', 'V_oc or I_sc <= 0'));
                end
                
                if ~isempty(logger)
                    logger.info('PV parameters validation passed');
                end
                
            catch ME
                if ~isempty(logger)
                    logger.error('PV validation failed: %s', ME.message);
                else
                    rethrow(ME);
                end
                is_valid = false;
            end
        end
        
        function is_valid = validate_inverter_params(inv_params, logger)
            % Валідація параметрів інвертора
            is_valid = true;
            
            if nargin < 2
                logger = [];
            end
            
            try
                required_fields = {'P_rated', 'V_dc', 'f_sw', 'f_grid'};
                for i = 1:length(required_fields)
                    if ~isfield(inv_params, required_fields{i})
                        throw(MException('Validation:MissingField', ....
                            sprintf('Missing field: %s', required_fields{i})));
                    end
                end
                
                if inv_params.P_rated < 1e3 || inv_params.P_rated > 500e3
                    throw(MException('Validation:OutOfRange', 'P_rated out of range'));
                end
                if inv_params.V_dc < 200 || inv_params.V_dc > 1000
                    throw(MException('Validation:OutOfRange', 'V_dc out of range'));
                end
                if inv_params.f_sw < 1e3 || inv_params.f_sw > 50e3
                    throw(MException('Validation:OutOfRange', 'f_sw out of range'));
                end
                
                if ~isempty(logger)
                    logger.info('Inverter parameters validation passed');
                end
                
            catch ME
                if ~isempty(logger)
                    logger.error('Inverter validation failed: %s', ME.message);
                else
                    rethrow(ME);
                end
                is_valid = false;
            end
        end
        
        function is_valid = validate_simulation_config(sim_config, logger)
            % Валідація конфігурації симуляції
            is_valid = true;
            
            if nargin < 2
                logger = [];
            end
            
            try
                if sim_config.StopTime < 1 || sim_config.StopTime > 86400
                    throw(MException('Validation:OutOfRange', 'StopTime out of range'));
                end
                if sim_config.RelTol < 1e-6 || sim_config.RelTol > 1e-2
                    throw(MException('Validation:OutOfRange', 'RelTol out of range'));
                end
                
                if ~isempty(logger)
                    logger.info('Simulation config validation passed');
                end
                
            catch ME
                if ~isempty(logger)
                    logger.error('Simulation validation failed: %s', ME.message);
                else
                    rethrow(ME);
                end
                is_valid = false;
            end
        end
    end
end
