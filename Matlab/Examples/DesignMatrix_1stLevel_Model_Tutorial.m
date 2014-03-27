%% This is a tutorial for running a single subject 1st level model with random data

%Generate random covariate data
nvol = 100;
tr = 2;
headmotion = rand(nvol,6);

%Generate random onset data for 3 regressors
names = {'Cond1', 'Cond2', 'Cond3'};
onset{1} = [4, 30, 60, 70; 4, 4, 4, 4; 1, 1, 1, 1]';
onset{2} = [17, 50, 55; 4, 4, 4; 1, 1, 1]';
onset{3} = [11, 21, 31, 41, 51, 61, 71, 81, 91; repmat(2, 1, 9); repmat(1,1,9)]';


%Initialize design_matrix object with head motion covariates
DM = design_matrix(headmotion,{'hm1','hm2','hm3','hm4','hm5','hm6'});

%Add Onset Regressors
DM = DM.onsettimes(onset, names, tr, 'tr2tr');

%Convolve Onset Regressors
cDM = DM.conv_hrf('tr', tr, 'select', [7:9]);

%Add High Pass Filter
hpcDM = cDM.hpfilter('tr',tr, 'duration', 100);

%Add Intercept
ihpcDM = hpcDM.addintercept;

%Check Variance Inflation
vif = ihpcDM.vif;
any(vif>2)

%View Design Matrix
plot(ihpcDM)

%Add Model to fmri_data object - this could be better integrated at some point
%This is an example 1st level data
dat.y = ihpcDM.dat;

%Run univariate regression - threshold p < .05 uncorrected for plotting
[out, statimg] = regress(dat, .05, 'unc');

%write out a nifti file with 3 condition beta images 
b = dat; %initialize fmri_data object
b.dat = out.b(7:9,:)'; %grab betas from task regressors
b.fullpath = fullfile(fPath, 'Sub1_Condition_Betas.nii');
write(b,'mni'); 
