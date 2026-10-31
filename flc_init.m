% =========================================================================
% MPPT FUZZY INFERENCE SYSTEM (FIS) GENERATOR - TUNED FOR STABILITY
% =========================================================================
clear; clc;

mppt_fuzzy = mamfis('Name', 'mppt_fuzzy');

% -------------------------------------------------------------------------
% 1. INPUT 1: Error (E = dP/dV) -> Range [-1 to 1]
% -------------------------------------------------------------------------
mppt_fuzzy = addInput(mppt_fuzzy, [-1 1], 'Name', 'E');
mppt_fuzzy = addMF(mppt_fuzzy, 'E', 'zmf',   [-1 -0.5],     'Name', 'NB');
mppt_fuzzy = addMF(mppt_fuzzy, 'E', 'trimf', [-0.8 -0.4 0],  'Name', 'NS');
mppt_fuzzy = addMF(mppt_fuzzy, 'E', 'trimf', [-0.4 0 0.4],   'Name', 'ZE');
mppt_fuzzy = addMF(mppt_fuzzy, 'E', 'trimf', [0 0.4 0.8],    'Name', 'PS');
mppt_fuzzy = addMF(mppt_fuzzy, 'E', 'smf',   [0.5 1],        'Name', 'PB');

% -------------------------------------------------------------------------
% 2. INPUT 2: Change in Error (dE) -> Range [-1 to 1]
% -------------------------------------------------------------------------
mppt_fuzzy = addInput(mppt_fuzzy, [-1 1], 'Name', 'dE');
mppt_fuzzy = addMF(mppt_fuzzy, 'dE', 'zmf',   [-1 -0.5],     'Name', 'NB');
mppt_fuzzy = addMF(mppt_fuzzy, 'dE', 'trimf', [-0.8 -0.4 0],  'Name', 'NS');
mppt_fuzzy = addMF(mppt_fuzzy, 'dE', 'trimf', [-0.4 0 0.4],   'Name', 'ZE');
mppt_fuzzy = addMF(mppt_fuzzy, 'dE', 'trimf', [0 0.4 0.8],    'Name', 'PS');
mppt_fuzzy = addMF(mppt_fuzzy, 'dE', 'smf',   [0.5 1],        'Name', 'PB');

% -------------------------------------------------------------------------
% 3. OUTPUT: Change in Duty Cycle (dD) -> Scaled to [-0.005 to 0.005]
% -------------------------------------------------------------------------
mppt_fuzzy = addOutput(mppt_fuzzy, [-0.005 0.005], 'Name', 'dD');
mppt_fuzzy = addMF(mppt_fuzzy, 'dD', 'trapmf', [-0.006 -0.006 -0.004 -0.002], 'Name', 'NB');
mppt_fuzzy = addMF(mppt_fuzzy, 'dD', 'trimf',  [-0.004 -0.002 0],             'Name', 'NS');
mppt_fuzzy = addMF(mppt_fuzzy, 'dD', 'trimf',  [-0.002 0 0.002],              'Name', 'ZE');
mppt_fuzzy = addMF(mppt_fuzzy, 'dD', 'trimf',  [0 0.002 0.004],               'Name', 'PS');
mppt_fuzzy = addMF(mppt_fuzzy, 'dD', 'trapmf', [0.002 0.004 0.006 0.006],     'Name', 'PB');

% -------------------------------------------------------------------------
% 4. STANDARD MPPT RULE BASE
% Output key: 1=NB, 2=NS, 3=ZE, 4=PS, 5=PB
% -------------------------------------------------------------------------
ruleList = [
    % E = NB (Right of MPP: V > Vmpp -> Need to decrease V -> Increase D)
    1 1 5 1 1; 1 2 5 1 1; 1 3 5 1 1; 1 4 4 1 1; 1 5 3 1 1;

    % E = NS
    2 1 5 1 1; 2 2 4 1 1; 2 3 4 1 1; 2 4 3 1 1; 2 5 2 1 1;

    % E = ZE (At MPP -> Maintain D)
    3 1 4 1 1; 3 2 4 1 1; 3 3 3 1 1; 3 4 2 1 1; 3 5 2 1 1;

    % E = PS
    4 1 4 1 1; 4 2 3 1 1; 4 3 2 1 1; 4 4 2 1 1; 4 5 1 1 1;

    % E = PB (Left of MPP: V < Vmpp -> Need to increase V -> Decrease D)
    5 1 3 1 1; 5 2 2 1 1; 5 3 1 1 1; 5 4 1 1 1; 5 5 1 1 1;
    ];

mppt_fuzzy = addRule(mppt_fuzzy, ruleList);

% Save to file & Workspace
writeFIS(mppt_fuzzy, 'mppt_fuzzy.fis');
assignin('base', 'mppt_fuzzy', mppt_fuzzy);
fprintf('Updated mppt_fuzzy created successfully with reduced step bounds!\n');
% Original coarse time vector and irradiance data for 1 second
t_coarse = linspace(0, 1.0, 25); 
irradiance_coarse = [0, 0, 0, 0, 0, 50, 250, 600, 850, 980, 1000, ...
    950, 800, 550, 350, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0];

% Fine time vector evaluated continuously across 1 second (1000 time steps)
t_sim = linspace(0, 1.0, 1001); 

% Smooth interpolation to remove sharp step transitions
irradiance_day = pchip(t_coarse, irradiance_coarse, t_sim);


% Ensure no negative irradiance values from spline rounding
irradiance_day(irradiance_day < 0) = 0;
% Apply a tiny floor so the panel never transitions from absolute zero
irradiance_day(irradiance_day < 0.1) = 0.1;