clear all; close all;

addpath(genpath('support_files'));

global USE_COVAS
USE_COVAS=1;
global PARALLEL_PORT
if USE_COVAS==1
    %initialize parallel port
    PARALLEL_PORT=digitalio('parallel', 'LPT1');
    addline(PARALLEL_PORT, 0:7, 'out');
end

for i=1:24
    fprintf('\nTrial %d\n',i)
    t=input('What now?  ');
    psych_trigger_heat_CO(t);
end

a=input('bye!')
a