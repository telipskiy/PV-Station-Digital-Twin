% ========================================================================
%  STARTUP SCRIPT FOR PV STATION DIGITAL TWIN
%  ========================================================================
%  Add this to MATLAB Startup Folder for automatic initialization
%  Platform: macOS with Apple Silicon | MATLAB R2025a
%  ========================================================================

disp(' ');
disp('╔════════════════════════════════════════════════════════════════════╗');
disp('║                                                                    ║');
disp('║     PV STATION DIGITAL TWIN - INITIALIZATION                       ║');
disp('║     macOS Apple Silicon | MATLAB R2025a                            ║');
disp('║                                                                    ║');
disp('╚════════════════════════════════════════════════════════════════════╝');
disp(' ');

% Get project root
project_root = fileparts(mfilename('fullpath'));
cd(project_root);

% Add paths
addpath(genpath(fullfile(project_root, 'matlab_scripts')));
addpath(genpath(fullfile(project_root, 'simulink_models')));
addpath(genpath(fullfile(project_root, 'data')));

disp('✓ Project paths configured');
disp(' ');

% Quick start instructions
disp('QUICK START:');
disp('───────────────────────────────────────────────────────────────');
disp(' ');
disp('1. Run compatibility check:');
disp('   >> COMPATIBILITY_CHECK');
disp(' ');
disp('2. Initialize parameters:');
disp('   >> init_pv_station_main');
disp(' ');
disp('3. Create all Simulink models:');
disp('   >> create_simulink_models');
disp(' ');
disp('4. Open main model:');
disp('   >> open(''PV_Station_Main.slx'')');
disp(' ');
disp('───────────────────────────────────────────────────────────────');
disp(' ');
