%% ========================================================================
%  DIGITAL TWIN: PV STATION - STARTUP SCRIPT
%  ========================================================================
%  Author: Denys Telipskyi
%  Date: 01.06.2026
%  
%  Add this to MATLAB Startup Folder for automatic initialization
%  ========================================================================

clc;
disp(' ');
disp('╔════════════════════════════════════════════════════════════════════╗');
disp('║                                                                    ║');
disp('║            PV STATION DIGITAL TWIN - INITIALIZATION                ║');
disp('║                                                                    ║');
disp('╚════════════════════════════════════════════════════════════════════╝');
disp(' ');

% Get project root
project_root = fileparts(mfilename('fullpath'));
cd(project_root);

% Add paths
addpath(genpath(fullfile(project_root, 'data')));
addpath(genpath(fullfile(project_root, 'docs')));
addpath(genpath(fullfile(project_root, 'matlab_scripts')));
addpath(genpath(fullfile(project_root, 'simulink_models')));

disp('✓ Project paths configured');
disp(' ');

% Quick start instructions
disp('QUICK START:');
disp('──────────────────────────────────────────────────────────────────────');
disp(' ');
disp('1. Run compatibility test:');
disp('   >> test_compatibility');
disp(' ');
disp('2. Initialize parameters:');
disp('   >> init_pv_station_main');
disp(' ');
disp('3. Create all Simulink models:');
disp('   >> build_all_simulink_models');
disp(' ');
disp('4. Open main model:');
disp('   >> open(''PV_Station_Main.slx'')');
disp(' ');
disp('──────────────────────────────────────────────────────────────────────');
disp(' ');
