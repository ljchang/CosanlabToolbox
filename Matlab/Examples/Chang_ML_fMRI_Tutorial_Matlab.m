%% Configuration and Paths

fPath = '/Users/lukechang/Downloads/nv_tmp/Matlab';

addpath(genpath('~/Github/CanlabCore/CanlabCore'))


%% Load data and Create variables

load(fullfile(fPath,'heat_LMH.mat')); % load file with all data
dat = [heatlow_vs_rest, heatmed_vs_rest, heathigh_vs_rest]; % combine data into one object
dat.Y = [ones(size(heatlow_vs_rest.dat,2),1); 2*ones(size(heatlow_vs_rest.dat,2),1); 3*ones(size(heatlow_vs_rest.dat,2),1) ]; % training labels
holdout = repmat(1:size(heatlow_vs_rest.dat,2),1,3)'; % subject ID

%% Predict Pain using Principal Components Regression using 5 fold cross-validation

% Fit PCR model
[cverr, stats, optout] = predict(dat, 'algorithm_name', 'cv_lassopcr', 'nfolds', 5, 'error_type','mse');

% Evaluate Cross-validated predictive accuracy (e.g., correlation
stats.pred_outcome_r

% Plot weightmap
orthviews(stats.weight_obj)

% Save Results
save(fullfile(fPath,'Pain_PCR_5fold_Stats.mat'))

% Save Weight Map
stats.weight_obj.fullpath = fullfile(fPath, 'Pain_PCR_5fold_Wt.nii');
write(stats.weight_obj)

%% Predict Pain using Support Vector Regression using Leave One Subject Out cross-validation

% Fit SVR model
[cverr, stats, optout] = predict(dat, 'algorithm_name', 'cv_svr', 'nfolds', holdout, 'error_type','mse');

% Evaluate Cross-validated predictive accuracy (e.g., correlation)
stats.pred_outcome_r

% Plot weightmap
orthviews(stats.weight_obj)

% Save Results
save(fullfile(fPath,'Pain_SVR_LOSO_Stats.mat'))

% Save Weight Map
stats.weight_obj.fullpath = fullfile(fPath, 'Pain_SVR_LOSO_Wt.nii');
write(stats.weight_obj)

%% Apply Weight Map to Data 
% NOTE:  We are applying the weight map to the same dataset in which it was
% trained for convenience.  Do not do this with real data!  It will
% overfit, you must use cross-validated weight maps.

pain_wt = fmri_data(fullfile(fPath,'Pain_PCR_5fold.nii'));

pexp = apply_mask(dat, pain_wt, 'pattern_expression','ignore_missing');

% Save Pattern Response to .csv file
dlmwrite(fullfile(fPath,'Pain_Pattern_Response.csv'),[holdout, dat.Y, pexp])


%% Calculate ROC Plots

binary_outcome = logical([ones(sum(dat.Y==1),1); zeros(sum(dat.Y==3),1)]);
pattern_response = [pexp(dat.Y==3); pexp(dat.Y==1)];
pattern_response(2) = pattern_response(30);  % to account for random memory leak

% Single Interval Accuracy
ROC_si = roc_plot(pattern_response, binary_outcome, 'color', 'r');

% Forced Choice Accuracy
ROC_fc = roc_plot(pattern_response, binary_outcome, 'color', 'r', 'twochoice');



