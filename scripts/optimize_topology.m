%  ========================================================================
%  DIGITAL TWIN: PV STATION - MULTI-CRITERIA OPTIMIZATION ENGINE
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  
%  Purpose: Genetic Algorithm-based multi-criteria optimization
%
%  DESCRIPTION:
%    This function performs multi-objective optimization of PV station
%    topology using a Genetic Algorithm (GA). It minimizes total lifecycle
%    cost by optimizing design decisions subject to physical and operational
%    constraints. Uses weighted combination of capital cost, energy losses,
%    reliability, operating expenses, and power quality.
%
%  INPUTS:
%    None (loads parameters from 'pv_station_parameters.mat')
%
%  OUTPUTS:
%    X_opt - Optimal design variables:
%      * X_opt(1): n_s (series modules per string) [5-20]
%      * X_opt(2): n_p (parallel strings) [2-20]
%      * X_opt(3): n_inv (number of inverters) [1-3]
%      * X_opt(4): P_inv (inverter power) [25-100 kW]
%      * X_opt(5): S_tr (transformer power) [25-100 kVA]
%      * X_opt(6): U_mv (medium voltage level) [0.4-20 kV]
%      * X_opt(7): A_top (topology type) [1-3]
%      * X_opt(8): L_cab (cable length) [0.1-2 km]
%
%    Fopt_min - Minimum objective function value [USD] (lifecycle cost)
%    population_history - Convergence data for visualization
%
%  OPTIMIZATION METRICS:
%    - Capital cost (CapEx): Equipment and installation [USD]
%    - Energy losses: Annual energy dissipation cost [USD/year]
%    - Reliability: Cost of potential outages (EENS model) [USD]
%    - Operating expenses (OpEx): Maintenance and insurance [USD/year]
%    - Power quality: THD and voltage deviation penalties [USD]
%
%  CONSTRAINTS:
%    1. PV power ≤ total inverter capacity (power balance)
%    2. Minimum 2 modules per string (technical requirement)
%    3. Transformer capacity ≥ PV power (sizing requirement)
%
%  USAGE:
%    >> [X_opt, Fopt, history] = optimize_topology();
%    >> fprintf('Optimal n_s=%d, n_p=%d, P_inv=%.1f kW\n', ...
%           X_opt(1), X_opt(2), X_opt(4)/1000);
%
%  FILES CREATED:
%    - optimization_results.mat (design variables and cost breakdown)
%    - pv_optimization_full_results.mat (complete results and history)
%    - optimization_results.fig / .png (convergence plots)
%
%  COMPUTATION TIME: 30-60 minutes on standard workstation
%  ========================================================================

function [X_opt, Fopt_min, population_history] = optimize_topology()

    % Load initialization parameters - Required for all component specs
    % and economic data used in the objective function
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
    % Purpose: Define search space and problem dimensionality for GA.
    % Each decision variable has physical bounds representing feasible designs.
    
    % Decision variables (Design Space):
    % X = [n_s, n_p, n_inv, P_inv, S_tr, U_mv, A_top, L_cab]
    % These represent all major design choices for the PV system
    % ====================================================================
    
    % Decision variables (Design Space):
    % X = [n_s, n_p, n_inv, P_inv, S_tr, U_mv, A_top, L_cab]
    
    lb = X_opt.lower_bounds;  % Lower bounds for each variable
    ub = X_opt.upper_bounds;  % Upper bounds for each variable
    n_var = length(lb);
    
    disp(['Number of Decision Variables: ', num2str(n_var)]);
    disp('Variable Ranges:');
    for i = 1:n_var
        fprintf('  X(%d): [%.0f, %.0f]\n', i, lb(i), ub(i));
    end
    disp(' ');
    
    % ====================================================================
    % 2. GENETIC ALGORITHM OPTIONS
    % Purpose: Configure GA parameters for balance between solution quality
    % and computational efficiency. Key parameters explained:
    % - PopulationSize: Larger = more exploration but slower
    % - MaxGenerations: More generations = better convergence but slower
    % - EliteCount: Best solutions automatically carry to next generation
    % ====================================================================
    
     options = optimoptions('ga', ...
         'PopulationSize', 40, ...          % Population size for each generation
        'MaxGenerations', 100, ...         % Stop after N generations or convergence
        'EliteCount', 4, ...               % Preserve best 4 solutions
        'FunctionTolerance', 1e-4, ...     % Convergence tolerance
        'ConstraintTolerance', 1e-3, ...   % Constraint violation tolerance
        'Display', 'iter', ...             % Show progress in command window
        'PlotFcn', {@gaplotbestf, @gaplotexpectation}, ...  % Live convergence plots
        'InitialPopulation', [], ...       % Use custom initialization
        'CreationFcn', @create_initial_population, ...
        'MutationFcn', @mutate_variables, ...
        'CrossoverFcn', @crossover_real, ...
        'SelectionFcn', @selectiontournament, ...
        'UseVectorized', true, ...         % Evaluate population in batch
        'UseParallel', false);             % Set true to use parallel computing

    disp('Genetic Algorithm Settings:');
    disp(['  Population Size: ', num2str(options.PopulationSize)]);
    disp(['  Max Generations: ', num2str(options.MaxGenerations)]);
    disp(['  Elite Count: ', num2str(options.EliteCount)]);
    disp(' ');
    
    % ====================================================================
    % 3. DEFINE OBJECTIVE FUNCTION & CONSTRAINTS
    % Purpose: Create function handles that GA will use to evaluate
    % candidate solutions. Store global data for fitness function.
    % ====================================================================
    
    % Store all parameters in structure for efficient passing to fitness function
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
    
    % Objective function (minimization): Calculate lifecycle cost for each design
    objective = @(X) evaluate_topology(X, global_data);
    
    % Constraints function: Ensure design feasibility (returns violation amounts)
    constraints = @(X) apply_constraints(X, global_data);
    
    % ====================================================================
    % 4. LAUNCH GENETIC ALGORITHM
    % Purpose: Execute GA to search for optimal solution. This is the
    % computationally intensive step (typically 30-60 minutes).
    % ====================================================================
    
    tic;
    disp('Starting Genetic Algorithm...');
    disp('This may take 30-60 minutes. Please wait...');
    disp(' ');
    
    [X_opt, Fopt_min, exitflag, output, population, scores] = ga(...
        objective, ...           % Function to minimize
        n_var, ...               % Number of variables
        [], [], [], [], ...      % Linear constraints (A, b, Aeq, beq) - none
        lb, ub, ...              % Variable bounds
        constraints, ...         % Nonlinear constraints (inequality and equality)
        options);
    
    opt_time = toc;
    
    % ====================================================================
    % 5. SAVE OPTIMIZATION RESULTS
    % Purpose: Store optimization results for post-processing and archival.
    % Convert normalized variables back to physical values.
    % ====================================================================
    
    % Convert decision variables from normalized [0,1] space to to actual values [lb, ub]
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
    % Purpose: Present optimal solution in human-readable format.
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
    
    % Calculate Levelized Cost of Energy (LCOE) - Standard PV industry metric
    annual_energy = sum(SOLAR.G_profile) / 1000 * PV.Pfield_rated / 1e3; % Approximate
    LCOE = (Fcap + Fopex * ECONOMICS.study_period) / (annual_energy * ECONOMICS.study_period);
    fprintf('Levelized Cost of Energy (LCOE): %.3f $/kWh\n', LCOE);
    disp(' ');
    
    % ====================================================================
    % 7. SAVE OPTIMIZATION HISTORY
    % Purpose: Store convergence history for visualization and analysis.
    % ====================================================================
    
    population_history.generations = 1:output.generations;
    population_history.best_fitness = output.bestfval;   % Best cost per generation
    population_history.mean_fitness = output.meanfval;   % Average cost per generation
    
    % Save all data to file
    save('pv_optimization_full_results.mat', 'results', 'population_history', ...
        'X_opt_physical', 'Fcap', 'Floss', 'Frel', 'Fopex', 'Fpq', 'LCOE');
    
    disp('Results saved to: pv_optimization_full_results.mat');
    disp(' ');
    
    % ====================================================================
    % VISUALIZATION
    % Purpose: Create publication-quality plots of optimization results.
    % ====================================================================
    
    create_optimization_plots(population_history, X_opt_physical, ...
        Fcap, Floss, Frel, Fopex, Fpq);

end

% ========================================================================
% EVALUATE TOPOLOGY (FITNESS FUNCTION)
% Purpose: Calculate total lifecycle cost for given design. This is the
% objective function that GA minimizes. Called thousands of times during
% optimization, so computational efficiency is important.
%
% INPUTS:
%   X - Normalized design variables [0,1]
%   global_data - Structure containing all parameters
%
% OUTPUTS:
%   Fopt - Total lifecycle cost [USD]
% ========================================================================

function Fopt = evaluate_topology(X, global_data)
    
    % Decode solution from normalized [0,1] space to physical space
    lb = [5, 2, 1, 25e3, 25e3, 0.4, 1, 0.1];
    ub = [20, 20, 3, 100e3, 100e3, 20, 3, 2];
    X_physical = decode_solution(X, lb, ub);
    
    % Extract individual cost components
    [Fcap, Floss, Frel, Fopex, Fpq] = evaluate_components(X_physical, global_data);
    
    % Combined objective
    % Weighted sum of objectives (multi-criteria optimization)
    % Each criterion is scaled by importance weight and combined
    Fopt = global_data.WEIGHT.w_cap * Fcap + ...
           global_data.WEIGHT.w_loss * Floss + ...
           global_data.WEIGHT.w_rel * Frel + ...
           global_data.WEIGHT.w_opex * Fopex + ...
           global_data.WEIGHT.w_pq * Fpq;
    
    % Add penalty term for constraint violations to enforce feasibility
    % Infeasible solutions get large penalty, driving GA away from them
    [c, ceq] = apply_constraints(X, global_data);
    penalty = 1e6 * sum(max(0, c).^2 + ceq.^2);
    Fopt = Fopt + penalty;
    
end

% ========================================================================
% EVALUATE COMPONENTS (DETAILED METRICS)
% Purpose: Calculate all five objective function components from design
% variables. Models economic, technical, and reliability aspects.
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
    
    % 1. CAPITAL COSTS - Initial equipment and installation investment
    P_pv = PV.Pmax_stc * n_s * n_p / 1000;  % Total PV power [kW]
    C_pv_total = P_pv * ECONOMICS.C_PV;     % PV module cost
    C_inv_total = n_inv * (P_inv / 1000) * ECONOMICS.C_INV;  % Inverter cost
    C_tr_total = (S_tr / 1000) * ECONOMICS.C_TR;  % Transformer cost
    C_cable_total = L_cab * ECONOMICS.C_CABLE;    % Cable cost
    C_install = (C_pv_total + C_inv_total + C_tr_total + C_cable_total) * ECONOMICS.C_INSTALL;
    
    Fcap = C_pv_total + C_inv_total + C_tr_total + C_cable_total + C_install;
    
    % 2. ENERGY LOSSES - Annual energy dissipation cost
    % Approximate: System losses ~20% based on typical values
    annual_generation = P_pv * 1000 * 365 * 4;  % Average 4 peak hours/day [Wh]
    P_loss_avg = annual_generation * 0.15 / (365*24);  % Average loss power [W]
    annual_loss_kwh = P_loss_avg * 365 * 24 / 1000;  % Annual losses [kWh]
    cost_per_kwh = 0.1;  % Cost of wasted energy [USD/kWh]
    Floss = annual_loss_kwh * cost_per_kwh * ECONOMICS.study_period;

    % 3. RELIABILITY - Cost of potential energy not supplied (EENS)
    % Simplified model: Failure rate increases with system complexity
    failure_rate = 0.001 * (n_inv + n_s/10);  % Annual failure probability
    availability = exp(-failure_rate * ECONOMICS.study_period);
    EENS = (1 - availability) * annual_generation / 1000 * 0.5;  % Energy not supplied [kWh]
    Frel = EENS * 1;  % Cost equivalent [USD]
    
    % 4. OPEX (Operating Expenses) - Annual maintenance, insurance, etc.
    annual_opex = Fcap * ECONOMICS.annual_opex_rate;  % Assume 1% of capital
    Fopex = annual_opex * ECONOMICS.study_period;
    
    % 5. POWER QUALITY - Penalty for harmonic distortion and voltage deviation
    % Simplified: Assumes good inverter (~3% THD), standard grid voltage deviation
    THD = 3;  % Total Harmonic Distortion [%]
    DU = 2;   % Voltage deviation [%]
    power_quality_penalty = (THD/5 + DU/5) * 10000;  % Normalized penalty
    Fpq = power_quality_penalty;
    
end

% ========================================================================
% APPLY CONSTRAINTS
% Purpose: Enforce physical and operational constraints. GA uses constraint
% violations as penalty to guide search toward feasible region.
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
    
    % Constraint 1: Power balance (critical for stability)
    % PV power must be <= total inverter capacity (each inverter rated at P_inv)
    P_pv = PV.Pmax_stc * n_s * n_p;
    c(1) = P_pv - n_inv * P_inv;  % Should be <= 0 (violated if > 0)
    
    % Constraint 2: Minimum modules per string (technical requirement)
    % At least 2 modules needed to avoid overvoltage conditions
    c(2) = 2 - n_s;  % n_s >= 2
    if c(2) > 0
        c(2) = -c(2);
    else
        c(2) = 0;
    end
    
    % Constraint 3: Transformer sizing (must accommodate PV power)
    % Transformer power >= PV power (normalized comparison)
    c(3) = P_pv / 1000 - S_tr / 1000;
    
    % Equality constraints (none for this problem)
    ceq = [];
    
end

% ========================================================================
% DECODE SOLUTION
% Purpose: Convert normalized [0,1] variables to physical [lb, ub] values
% Linear transformation: x_phys = lb + x_norm * (ub - lb)
% ========================================================================

function X_physical = decode_solution(X_normalized, lb, ub)
    % Convert normalized [0,1] to actual values [lb, ub]
    X_physical = lb + X_normalized .* (ub - lb);
end

% ========================================================================
% CREATE INITIAL POPULATION
% Purpose: Initialize GA population with random feasible solutions
% ========================================================================

function pop = create_initial_population(nvars, options)
    % Custom population initialization
    pop_size = 40;
    pop = rand(pop_size, nvars);  % Random [0,1]
end

% ========================================================================
% MUTATION
% Purpose: Small random perturbations to maintain population diversity
% ========================================================================

function xnew = mutate_variables(xold, options)
    % Custom mutation operator (Gaussian perturbation)
    mutation_rate = 0.1;
    xnew = xold + mutation_rate * randn(size(xold));
    xnew = max(0, min(1, xnew));  % Clip to [0,1]
end

% ========================================================================
% CROSSOVER (REAL-VALUED)
% Purpose: Blend crossover (BLX) - creates offspring between parents
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
% CREATE OPTIMIZATION PLOTS
% Purpose: Generate publication-quality visualization of results
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
    text(0.1, 0.7, 'Optimization Complete', 'FontSize', 14, 'FontWeight', 'bold');
    text(0.1, 0.5, ['Minimum Cost: $' num2str(sum(components), '%.2f')], 'FontSize', 12);
    text(0.1, 0.3, ['LCOE: $' num2str(sum(components)/1000, '%.3f') '/kWh'], 'FontSize', 12);
    axis off;
    
    savefig('optimization_results.fig');
    saveas(gcf, 'optimization_results.png');
    
end
