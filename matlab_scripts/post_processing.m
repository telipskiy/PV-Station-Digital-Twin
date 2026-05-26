%% ========================================================================
%  POST PROCESSING - STATISTICAL ANALYSIS AND REPORTING
%  ========================================================================

function generate_comprehensive_report()
    
    % Load all results
    load('simulation_results.mat');
    load('pv_optimization_full_results.mat');
    
    % Generate LaTeX report
    fid = fopen('simulation_report.tex', 'w');
    
    fprintf(fid, '\\documentclass{article}\n');
    fprintf(fid, '\\usepackage{booktabs}\n');
    fprintf(fid, '\\usepackage{graphicx}\n');
    fprintf(fid, '\\begin{document}\n');
    fprintf(fid, '\\title{PV Station Digital Twin - Simulation Results}\n');
    fprintf(fid, '\\maketitle\n');
    
    % Summary statistics table
    fprintf(fid, '\\section{Summary Statistics}\n');
    fprintf(fid, '\\begin{table}[h]\n');
    fprintf(fid, '\\centering\n');
    fprintf(fid, '\\begin{tabular}{ll}\n');
    fprintf(fid, '\\toprule\n');
    fprintf(fid, 'Metric & Value \\\\\n');
    fprintf(fid, '\\midrule\n');
    fprintf(fid, 'Avg LCOE & %.3f \\$/kWh \\\\\n', mean(results_table.LCOE_USD_kWh));
    fprintf(fid, 'Avg Efficiency & %.2f \\%% \\\\\n', mean(results_table.Efficiency_percent));
    fprintf(fid, 'Avg Capacity Factor & %.2f \\%% \\\\\n', mean(results_table.Capacity_Factor_percent));
    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '\\end{table}\n');
    
    fprintf(fid, '\\end{document}\n');
    fclose(fid);
    
end
