%% ========================================================================
%  DIGITAL TWIN: REPORTING - Create summary report
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  ========================================================================

function create_summary_report(reports_dir, sim_output)
    
    report_file = fullfile(reports_dir, 'simulation_summary.txt');
    
    fid = fopen(report_file, 'w');
    fprintf(fid, '╔════════════════════════════════════════════════════════════════╗\n');
    fprintf(fid, '║  PV STATION DIGITAL TWIN - 24-HOUR SIMULATION SUMMARY          ║\n');
    fprintf(fid, '╚════════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf(fid, 'Simulation Date: %s\n\n', datestr(now));
    
    fprintf(fid, 'System Components:\n');
    fprintf(fid, '  • PV Array Subsystem (Single Diode Model with MPPT)\n');
    fprintf(fid, '  • 3-Phase Inverter (VSI with SVM, PLL, Current Control)\n');
    fprintf(fid, '  • Step-Up Transformer (0.4kV/10kV, 63 kVA)\n');
    fprintf(fid, '  • Grid Model (10kV distribution network)\n\n');
    
    fprintf(fid, 'Output Data Available:\n');
    if isfield(sim_output, 'P_pv_log')
        fprintf(fid, '  ✓ PV Power Data\n');
    end
    if isfield(sim_output, 'P_inv_log')
        fprintf(fid, '  ✓ Inverter Power Data\n');
    end
    if isfield(sim_output, 'V_pcc_log')
        fprintf(fid, '  ✓ PCC Voltage Data\n');
    end
    if isfield(sim_output, 'eta_log')
        fprintf(fid, '  ✓ System Efficiency Data\n');
    end
    
    fprintf(fid, '\n\nNext Steps:\n');
    fprintf(fid, '  1. Review plots in reports/ folder\n');
    fprintf(fid, '  2. Run post_processing.m for detailed analysis\n');
    fprintf(fid, '  3. Use optimize_topology.m for GA optimization\n');
    
    fclose(fid);
    fprintf('✓ Summary report saved to: %s\n', report_file);
    
end