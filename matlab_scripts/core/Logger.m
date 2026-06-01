%% ============================================================================
% LOGGER - Система логування для проєкту
% Version: 1.0
% Date: 2026-06-01
% ==============================================================================

classdef Logger < handle
    properties (Access = private)
        log_file        % Шлях до файлу логу
        log_level       % Рівень логування: DEBUG, INFO, WARNING, ERROR
        fid             % File identifier
        start_time      % Час запуску
        messages        % Масив повідомлень
    end
    
    properties (Constant)
        LEVELS = struct('DEBUG', 0, 'INFO', 1, 'WARNING', 2, 'ERROR', 3);
    end
    
    methods
        function obj = Logger(log_file, log_level)
            % Конструктор
            if nargin < 1
                log_file = 'logs/default.log';
            end
            if nargin < 2
                log_level = 'INFO';
            end
            
            obj.log_file = log_file;
            obj.log_level = log_level;
            obj.messages = {};
            obj.start_time = datetime('now');
            
            % Створити директорію якщо не існує
            log_dir = fileparts(log_file);
            if ~exist(log_dir, 'dir') && ~isempty(log_dir)
                mkdir(log_dir);
            end
            
            % Відкрити файл
            obj.fid = fopen(log_file, 'a');
            if obj.fid == -1
                error('Не можна відкрити файл логу: %s', log_file);
            end
            
            obj.write_header();
        end
        
        function debug(obj, message, varargin)
            obj.log('DEBUG', message, varargin{:});
        end
        
        function info(obj, message, varargin)
            obj.log('INFO', message, varargin{:});
        end
        
        function warning(obj, message, varargin)
            obj.log('WARNING', message, varargin{:});
        end
        
        function error(obj, message, varargin)
            obj.log('ERROR', message, varargin{:});
        end
        
        function log(obj, level, message, varargin)
            % Основна функція логування
            
            % Перевірити рівень
            current_level = obj.LEVELS.(obj.log_level);
            msg_level = obj.LEVELS.(level);
            
            if msg_level < current_level
                return;
            end
            
            % Форматування повідомлення
            if ~isempty(varargin)
                try
                    formatted_msg = sprintf(message, varargin{:});
                catch
                    formatted_msg = message;
                end
            else
                formatted_msg = message;
            end
            
            % Створити рядок логу
            timestamp = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            log_entry = sprintf('[%s] [%s] %s\n', timestamp, level, formatted_msg);
            
            % Записати у файл
            fprintf(obj.fid, log_entry);
            fflush(obj.fid);
            
            % Вивести на екран
            fprintf(log_entry);
            
            % Зберегти у масив
            obj.messages{end+1} = struct('timestamp', timestamp, ...
                'level', level, 'message', formatted_msg);
        end
        
        function write_header(obj)
            % Написати заголовок логу
            header = sprintf('\n%s\n', repmat('=', 1, 80));
            header = [header, sprintf('PV Station Digital Twin - Simulation Log\n')];
            header = [header, sprintf('Start Time: %s\n', datetime('now'))];
            header = [header, sprintf('Platform: %s (%s)\n', computer, computer('arch'))];
            header = [header, sprintf('MATLAB: %s\n', version('-release'))];
            header = [header, sprintf('%s\n', repmat('=', 1, 80))], header = [header, '\n'];
            
            fprintf(obj.fid, header);
            fprintf(header);
        end
        
        function summary = get_summary(obj)
            % Отримати статистику логів
            summary = struct();
            summary.total_messages = length(obj.messages);
            summary.elapsed_time = seconds(datetime('now') - obj.start_time);
            
            % Підрахувати за рівнями
            levels = {'DEBUG', 'INFO', 'WARNING', 'ERROR'};
            for i = 1:length(levels)
                level_count = sum(cellfun(@(m) strcmp(m.level, levels{i}), obj.messages));
                summary.(lower(levels{i})) = level_count;
            end
        end
        
        function close(obj)
            % Закрити файл
            if obj.fid > 0
                fprintf(obj.fid, '\n%s\n', repmat('=', 1, 80));
                fprintf(obj.fid, 'End Time: %s\n', datetime('now'));
                summary = obj.get_summary();
                fprintf(obj.fid, 'Total Messages: %d | Elapsed: %.2f s\n', ...
                    summary.total_messages, summary.elapsed_time);
                fclose(obj.fid);
            end
        end
        
        function delete(obj)
            % Деструктор
            obj.close();
        end
    end
end
