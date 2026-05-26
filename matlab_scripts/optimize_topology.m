%% ========================================================================
%  OPTIMIZE TOPOLOGY - MULTI-CRITERIA OPTIMIZATION ENGINE
%  ========================================================================
%  PhD Research: Rational Structure Design of PV Stations
%  Purpose: Genetic Algorithm-based multi-criteria optimization
%  Date: 2025
%  ========================================================================

function [X_opt, Fopt_min, population_history] = optimize_topology()

    % Load initialization parameters
    if ~exist('pv_station_parameters.mat', 'file')
        init_pv_station_main;
    end
    load('pv_station_parameters.mat');
    
    disp(' ');
    disp('=========================================================================');
    disp('MULTI-CRITERIA OPTIMIZATION ENGINE');
    disp('=========================================================================');
    disp(' ');
    
    % ====================================================================
    % 1. SETUP OPTIMIZATION PARAMETERS
    % ====================================================================
    
    % Decision variables (Design Space):
    % X = [n_s, n_p, n_inv, P_inv, S_tr, U_mv, A_top, L_cab]
    
    lb = X_opt.lower_bounds;  % Lower bounds
    ub = X_opt.upper_bounds;  % Upper bounds
    n_var = length(lb);
    
    disp(['Number of Decision Variables: ', num2str(n_var)]);
    disp('Variable Ranges:');
    for i = 1:n_var
        fprintf('  X(%d): [%.0f, %.0f]\n', i, lb(i), ub(i));
    end
    disp(' ');
    
    % ====================================================================
    % 2. GENETIC ALGORITHM OPTIONS
    % ====================================================================
    
    options = optimoptions('ga', ...
        'PopulationSize', 40, ...
        'MaxGenerations', 100, ...
        'EliteCount', 4, ...
        'FunctionTolerance', 1e-4, ...
        'ConstraintTolerance', 1e-3, ...
        'Display', 'iter', ...
        'PlotFcn', {@gaplotbestf, @gaplotexpectation}, ...
        'InitialPopulation', [], ...
        'CreationFcn', @create_initial_population, ...
        'MutationFcn', @mutate_variables, ...
        'CrossoverFcn', @crossover_real, ...
        'SelectionFcn', @selectiontournament, ...
        'UseVectorized', true, ...
        'UseParallel', false);
    
    disp('Genetic Algorithm Settings:');
    disp(['  Population Size: ', num2str(options.PopulationSize)]);
    disp(['  Max Generations: ', num2str(options.MaxGenerations)]);
    disp(['  Elite Count: ', num2str(options.EliteCount)]);
    disp(' ');
    
    % ====================================================================
    % 3. DEFINE OBJECTIVE FUNCTION & CONSTRAINTS
    % ====================================================================
    
    % Store global data for fitness function
    global_data.PV = PV;
    global_data.DCDC = DCDC;
    global_data.INV = INV;
    global_data.TR = TR;
    global_data.GRID = GRID;
    global_data.CABLE = CABLE;
    global_data.LOAD = LOAD;
    global_data.SOLAR = SOLAR;
    global_data.WEIGHT = WEIGHT;
    global_data.ECONOMICS = ECONOMICS;
    global_data.SIM = SIM;
    global_data.t_sim = t_sim;
    
    % Objective function (minimization)
    objective = @(X) evaluate_topology(X, global_data);
    
    % Constraints function
    constraints = @(X) apply_constraints(X, global_data);
    
    % ====================================================================
    % 4. LAUNCH GENETIC ALGORITHM
    % ====================================================================
    
    tic;
    disp('Starting Genetic Algorithm...');
    disp('This may take 30-60 minutes. Please wait...');
    disp(' ');
    
    [X_opt, Fopt_min, exitflag, output, population, scores] = ga(...
        objective, ...
        n_var, ...
        [], [], [], [], ...  % Linear constraints (none)
        lb, ub, ...          % Bounds
        constraints, ...     % Nonlinear constraints
        options);
    
    opt_time = toc;
    
    % ====================================================================
    % 5. SAVE OPTIMIZATION RESULTS
    % ====================================================================
    
    % Convert decision variables to actual values
    X_opt_physical = decode_solution(X_opt, lb, ub);
    
    results.X_optimal = X_opt_physical;
    results.Fopt_minimum = Fopt_min;
    results.exitflag = exitflag;
    results.generations = output.generations;
    results.funccount = output.funccount;
    results.optimization_time = opt_time;
    
    % Save results
    save('optimization_results.mat', 'results', 'population', 'scores');
    
    % ====================================================================
    % 6. DISPLAY RESULTS
    % ====================================================================
    
    disp(' ');
    disp('=========================================================================');
    disp('OPTIMIZATION RESULTS');
    disp('=========================================================================');
    disp(' ');
    
    disp('Optimal Configuration:');
    fprintf('  n_s (Series Modules):        %d\n', round(X_opt_physical(1)));
    fprintf('  n_p (Parallel Strings):      %d\n', round(X_opt_physical(2)));
    fprintf('  n_inv (Number of Inverters): %d\n', round(X_opt_physical(3)));
    fprintf('  P_inv (Inverter Power):      %.1f kW\n', X_opt_physical(4)/1e3);
    fprintf('  S_tr (Transformer Power):    %.1f kVA\n', X_opt_physical(5)/1e3);
    fprintf('  U_mv (Medium Voltage):       %.1f kV\n', X_opt_physical(6));
    fprintf('  A_top (Topology Type):       %d\n', round(X_opt_physical(7)));
    fprintf('  L_cab (Cable Length):        %.2f km\n', X_opt_physical(8));
    disp(' ');
    
    fprintf('Minimum Objective Function: %.2f USD\n', Fopt_min);
    fprintf('Optimization Time: %.1f minutes\n', opt_time/60);
    fprintf('Generations: %d\n', output.generations);
    fprintf('Function Evaluations: %d\n', output.funccount);
    disp(' ');
    
    % Calculate and display detailed metrics
    [Fcap, Floss, Frel, Fopex, Fpq] = evaluate_components(X_opt_physical, global_data);
    
    disp('Objective Function Components:');
    fprintf('  Capital Cost (Fcap):         %.2f USD (weight: %.1f%%)\n', ...
        Fcap, WEIGHT.w_cap*100);
    fprintf('  Energy Loss Cost (Floss):    %.2f USD (weight: %.1f%%)\n', ...
        Floss, WEIGHT.w_loss*100);
    fprintf('  Reliability Cost (Frel):     %.2f USD (weight: %.1f%%)\n', ...
        Frel, WEIGHT.w_rel*100);
    fprintf('  OPEX (Fopex):                %.2f USD (weight: %.1f%%)\n', ...
        Fopex, WEIGHT.w_opex*100);
    fprintf('  Power Quality Cost (Fpq):    %.2f USD (weight: %.1f%%)\n', ...
        Fpq, WEIGHT.w_pq*100);
    disp(' ');
    
    % Calculate LCOE
    annual_energy = sum(SOLAR.G_profile) / 1000 * PV.Pfield_rated / 1e3; % Approximate
    LCOE = (Fcap + Fopex * ECONOMICS.study_period) / (annual_energy * ECONOMICS.study_period);
    fprintf('Levelized Cost of Energy (LCOE): %.3f $/kWh\n', LCOE);
    disp(' ');
    
    % ====================================================================
    % 7. SAVE OPTIMIZATION HISTORY
    % ====================================================================
    
    population_history.generations = 1:output.generations;
    population_history.best_fitness = output.bestfval;
    population_history.mean_fitness = output.meanfval;
    
    % Save all data to file
    save('pv_optimization_full_results.mat', 'results', 'population_history', ...
        'X_opt_physical', 'Fcap', 'Floss', 'Frel', 'Fopex', 'Fpq', 'LCOE');
    
    disp('Results saved to: pv_optimization_full_results.mat');
    disp(' ');
    
    % ====================================================================
    % VISUALIZATION
    % ====================================================================
    
    create_optimization_plots(population_history, X_opt_physical, ...
        Fcap, Floss, Frel, Fopex, Fpq);

end

%% ========================================================================
% NESTED FUNCTION: EVALUATE TOPOLOGY (FITNESS FUNCTION)
% ========================================================================

function Fopt = evaluate_topology(X, global_data)
    
    % Decode solution
    lb = [5, 2, 1, 25e3, 25e3, 0.4, 1, 0.1];
    ub = [20, 20, 3, 100e3, 100e3, 20, 3, 2];
    X_physical = decode_solution(X, lb, ub);
    
    % Extract components
    [Fcap, Floss, Frel, Fopex, Fpq] = evaluate_components(X_physical, global_data);
    
    % Combined objective
    Fopt = global_data.WEIGHT.w_cap * Fcap + ...
           global_data.WEIGHT.w_loss * Floss + ...
           global_data.WEIGHT.w_rel * Frel + ...
           global_data.WEIGHT.w_opex * Fopex + ...
           global_data.WEIGHT.w_pq * Fpq;
    
    % Add penalty for infeasible solutions
    [c, ceq] = apply_constraints(X, global_data);
    penalty = 1e6 * sum(max(0, c).^2 + ceq.^2);
    Fopt = Fopt + penalty;
    
end

%% ========================================================================
% NESTED FUNCTION: EVALUATE COMPONENTS (DETAILED METRICS)
% ========================================================================

function [Fcap, Floss, Frel, Fopex, Fpq] = evaluate_components(X_phys, global_data)
    
    PV = global_data.PV;
    ECONOMICS = global_data.ECONOMICS;
    WEIGHT = global_data.WEIGHT;
    
    n_s = X_phys(1);
    n_p = X_phys(2);
    n_inv = X_phys(3);
    P_inv = X_phys(4);
    S_tr = X_phys(5);
    U_mv = X_phys(6);
    A_top = X_phys(7);
    L_cab = X_phys(8);
    
    % 1. CAPITAL COSTS
    P_pv = PV.Pmax_stc * n_s * n_p / 1000;  % [kW]
    C_pv_total = P_pv * ECONOMICS.C_PV;     % [USD]
    C_inv_total = n_inv * (P_inv / 1000) * ECONOMICS.C_INV;
    C_tr_total = (S_tr / 1000) * ECONOMICS.C_TR;
    C_cable_total = L_cab * ECONOMICS.C_CABLE;
    C_install = (C_pv_total + C_inv_total + C_tr_total + C_cable_total) * ECONOMICS.C_INSTALL;
    
    Fcap = C_pv_total + C_inv_total + C_tr_total + C_cable_total + C_install;
    
    % 2. ENERGY LOSSES (Annual)
    % Approximate: System losses ~ 20% at STC
    annual_generation = P_pv * 1000 * 365 * 4;  % Average 4 peak hours/day [Wh]
    P_loss_avg = annual_generation * 0.15 / (365*24);  % [W]
    annual_loss_kwh = P_loss_avg * 365 * 24 / 1000;  % [kWh]
    cost_per_kwh = 0.1;  % [USD/kWh]
    Floss = annual_loss_kwh * cost_per_kwh * ECONOMICS.study_period;
    
    % 3. RELIABILITY (EENS - Energy Not Supplied)
    % Simplified: Failure rate proportional to complexity
    failure_rate = 0.001 * (n_inv + n_s/10);  % [1/year]
    availability = exp(-failure_rate * ECONOMICS.study_period);
    EENS = (1 - availability) * annual_generation / 1000 * 0.5;  % [kWh]
    Frel = EENS * 1;  % [USD equivalent]
    
    % 4. OPEX (Operating Expenses)
    annual_opex = Fcap * ECONOMICS.annual_opex_rate;
    Fopex = annual_opex * ECONOMICS.study_period;
    
    % 5. POWER QUALITY
    % Simplified: THD ~ 3% (good inverter), ΔU ~ 2%
    THD = 3;
    DU = 2;
    power_quality_penalty = (THD/5 + DU/5) * 10000;  % [USD]
    Fpq = power_quality_penalty;
    
end

%% ========================================================================
% NESTED FUNCTION: APPLY CONSTRAINTS
% ========================================================================

function [c, ceq] = apply_constraints(X, global_data)
    
    PV = global_data.PV;
    lb = [5, 2, 1, 25e3, 25e3, 0.4, 1, 0.1];
    ub = [20, 20, 3, 100e3, 100e3, 20, 3, 2];
    X_physical = decode_solution(X, lb, ub);
    
    n_s = X_physical(1);
    n_p = X_physical(2);
    n_inv = X_physical(3);
    P_inv = X_physical(4);
    S_tr = X_physical(5);
    
    % PV power must be <= Sum of inverter powers
    P_pv = PV.Pmax_stc * n_s * n_p;
    c(1) = P_pv - n_inv * P_inv;  % Should be <= 0
    
    % Minimum 2 modules per string
    c(2) = 2 - n_s;  % n_s >= 2
    if c(2) > 0
        c(2) = -c(2);
    else
        c(2) = 0;
    end
    
    % Transformer power >= PV power (normalized)
    c(3) = P_pv / 1000 - S_tr / 1000;
    
    % Equality constraints
    ceq = [];
    
end

%% ========================================================================
% HELPER FUNCTION: DECODE SOLUTION
% ========================================================================

function X_physical = decode_solution(X_normalized, lb, ub)
    % Convert normalized [0,1] to actual values [lb, ub]
    X_physical = lb + X_normalized .* (ub - lb);
end

%% ========================================================================
% HELPER FUNCTION: CREATE INITIAL POPULATION
% ========================================================================

function pop = create_initial_population(nvars, options)
    % Custom population initialization
    pop_size = 40;
    pop = rand(pop_size, nvars);  % Random [0,1]
end

%% ========================================================================
% HELPER FUNCTION: MUTATION
% ========================================================================

function xnew = mutate_variables(xold, options)
    % Custom mutation operator (Gaussian perturbation)
    mutation_rate = 0.1;
    xnew = xold + mutation_rate * randn(size(xold));
    xnew = max(0, min(1, xnew));  % Clip to [0,1]
end

%% ========================================================================
% HELPER FUNCTION: CROSSOVER (REAL-VALUED)
% ========================================================================

function xpop = crossover_real(parents, options, nvars, ~, xpop)
    % Real-valued crossover (Blend crossover - BLX)
    nkids = size(xpop, 1);
    alpha = 0.1;  % Blend factor
    for i = 1:2:nkids
        r1 = rand;
        r2 = rand;
        p1 = parents(i, :);
        p2 = parents(i+1, :);
        
        xmin = min(p1, p2);
        xmax = max(p1, p2);
        range = xmax - xmin;
        
        xpop(i, :) = xmin - alpha*range + (1 + 2*alpha)*range*rand(1, nvars);
        xpop(i+1, :) = xmin - alpha*range + (1 + 2*alpha)*range*rand(1, nvars);
        
        xpop(i, :) = max(0, min(1, xpop(i, :)));
        xpop(i+1, :) = max(0, min(1, xpop(i+1, :)));
    end
end

%% ========================================================================
% HELPER FUNCTION: CREATE OPTIMIZATION PLOTS
% ========================================================================

function create_optimization_plots(pop_hist, X_opt, Fcap, Floss, Frel, Fopex, Fpq)
    
    figure('Position', [100 100 1400 900]);
    
    % Convergence curve
    subplot(2,3,1);
    plot(pop_hist.generations, pop_hist.best_fitness, 'b-', 'LineWidth', 2);
    hold on;
    plot(pop_hist.generations, pop_hist.mean_fitness, 'r--', 'LineWidth', 1.5);
    xlabel('Generation'); ylabel('Fitness (USD)');
    title('Optimization Convergence');
    legend('Best', 'Mean'); grid on;
    
    % Objective function components
    subplot(2,3,2);
    components = [Fcap, Floss, Frel, Fopex, Fpq];
    names = {'Capital', 'Loss', 'Reliability', 'OPEX', 'Power Quality'};
    bar(components);
    set(gca, 'XTickLabel', names);
    ylabel('Cost (USD)');
    title('Objective Function Components');
    grid on;
    
    % Configuration visualization
    subplot(2,3,3);
    config_text = sprintf('Optimal Configuration:\nn_s=%d, n_p=%d\nP_inv=%.1f kW\nS_tr=%.1f kVA\nU_mv=%.1f kV', ...
        round(X_opt(1)), round(X_opt(2)), X_opt(4)/1e3, X_opt(5)/1e3, X_opt(6));
    text(0.1, 0.5, config_text, 'FontSize', 12, 'FontWeight', 'bold');
    axis off;
    
    % Objective function composition
    subplot(2,3,4);
    total = sum(components);
    pie(components, names);
    title('Cost Distribution');
    
    % Variable values
    subplot(2,3,5);
    var_names = {'n_s', 'n_p', 'n_{inv}', 'P_{inv}', 'S_{tr}', 'U_{mv}', 'A_{top}', 'L_{cab}'};
    bar(X_opt);
    set(gca, 'XTickLabel', var_names);
    ylabel('Value');
    title('Optimal Design Variables');
    grid on;
    
    subplot(2,3,6);
    text(0.1, 0.7, ['Optimization Complete'], 'FontSize', 14, 'FontWeight', 'bold');
    text(0.1, 0.5, ['Minimum Cost: $' num2str(sum(components), '%.2f')], 'FontSize', 12);
    text(0.1, 0.3, ['LCOE: $' num2str(sum(components)/1000, '%.3f') '/kWh'], 'FontSize', 12);
    axis off;
    
    savefig('optimization_results.fig');
    saveas(gcf, 'optimization_results.png');
    
end
