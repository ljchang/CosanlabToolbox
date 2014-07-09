%%==========================================================================
% Computational Model Class: comp_model
% 
% This object is used to fit a computational model to a multi-subject
% dataset.  The object uses the design_matrix() class to for the data set
% and has additional fields for the model and parameters for the model
% fitting procedure such as the parameter constraints, number of
% iterations, and type of estimation (e.g., maximum likelihood or least
% squares).
%==========================================================================


%==========================================================================
% Current Methods for comp_model (inherits from design_matrix class too)
%==========================================================================

%avg_aic - display average AIC value
%avg_bic - display average BIC value
%avg_params - display average parameter estimates
%comp_model - class constructor
%fit_model - estimate parameters using model
%plot - plot average model predictions across subjects
%summary - display summary table for model
%save - save object as .mat file
%write_tables - write out parameter estimates and trial-to-trial predictions to csv data frame.

%==========================================================================
% Example Useage
%==========================================================================
%
% Load data
basedir = '~/Dropbox/TreatmentExpectations';
dat = importdata(fullfile(basedir, 'Data','Seattle_Sona','seattle_ses_by_session.csv'));
data = dat.data;

% Set optimization parameters for fmincon (OPTIONAL)
options = optimset(@fmincon);
options = optimset(options, 'TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 900000000, 'LargeScale','off');

%--------------------------------------------------------------------------
% Create class instance for example linear model
%--------------------------------------------------------------------------
%
% requires data frame, cell array of column names, and model name.  
% ModelName: must refer to function with the model on matlab path.  See
% example 'linear_model' function below.
%
% Can also specify additional parameters for model fitting.
% nStart: is the number of iterations to repeat model estimation, will pick
% the iteration with the best model fit.
% param_min: vector of lower bound of parameters
% param_max: vector of upper bound of parameters
% esttype: type of parameter estimation ('SSE' - minimize sum of squared
% error; 'LLE' - maximize log likelihood; 'LE' - maximize likelihood

lin = comp_model(data,dat.textdata,'linear_model','nStart',10, 'param_min',[-5, -20], 'param_max', [60, 20], 'esttype','SSE');

%   911x8 comp_model array with properties:
% 
%         model: 'linear_model'
%     param_min: [-5 -20]
%     param_max: [60 20]
%        nStart: 10
%       esttype: 'SSE'
%        params: []
%         trial: []
%           dat: [911x8 double]
%       varname: {'subj'  'group'  'sess'  'se_count'  'se_sum_intensity'  'any_action_taken'  'hamtot'  'bditot'}
%         fname: ''
%--------------------------------------------------------------------------
  

%--------------------------------------------------------------------------
% Fit Model to Data
%--------------------------------------------------------------------------
%
% once object has been created with all of the necessary setup parameters,
% the model can be fit to the data with following command.

lin = lin.fit_model();

%   911x8 comp_model array with properties:
% 
%         model: 'linear_model'
%     param_min: [-5 -20]
%     param_max: [60 20]
%        nStart: 10
%       esttype: 'SSE'
%        params: [77x6 double]
%         trial: [911x4 double]
%           dat: [911x8 double]
%       varname: {'subj'  'group'  'sess'  'se_count'  'se_sum_intensity'  'any_action_taken'  'hamtot'  'bditot'}
%         fname: ''
        
% This adds two new fields.
% Params: is the parameters estimated for each subject.  Rows are
% individual subjects. Columns are {'Subject', 'Estimated Parameters (specific to each model)', 'Model Fit', 'AIC', 'BIC'}
% trial: is the trial by trial data and predicted values for all subjects
% stacked together.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% View Results
%--------------------------------------------------------------------------
% The overall average results from the model can be quickly viewed using
% the summary() method.

summary(lin)

% Summary of Model: linear_model
% -----------------------------------------
% Average Parameters:	18.1073
% Average AIC:		35.8264
% Average BIC:		36.3802
% Average SSE:		-1.86
% Number of Subjects:	77
% -----------------------------------------
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Write out results to .csv file
%--------------------------------------------------------------------------

% The 'params' and 'trial' data frames can be written to separate .csv files

lin.write_tables(fullfile(basedir,'Analysis','Modeling'))

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Save Object to .mat file
%--------------------------------------------------------------------------

% The overall object instance can be saved as .mat file.  Helpful as
% sometimes model estimation can take a long time especially if using
% multiple iterations.

lin.save(fullfile(basedir,'Analysis','Modeling','Linear_ModelFit.mat'))

%--------------------------------------------------------------------------
% Plot Model
%--------------------------------------------------------------------------

% The average predicted values from the model can be quickly plotted, but
% must specifiy the columns to plot as these will be specific to the data
% set and model.  This method has some rudimentary options to customize the
% plot

plot(lin, [3,4], 'title', 'Linear Model', 'xlabel','session', 'ylabel', 'Average BDI', 'legend', {'Predicted','Observed'})

%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Example Model Function
%--------------------------------------------------------------------------
%
% Here is an example function of a very simple linear model.  
% Functions can be completely flexible, but need to have the free parameter (xpar) 
% and data inputs and the model fit (sse here) as the output. 
% This is so fmincon can optimize the parameters for this function by
% minimizing the Sum of Squared Error (sse - for this example)
% This function needs to be in a separate file.  

function sse = linear_model(xpar, data)
% Fit Linear Decay Treatment Model

global trialout %this allows trial to be saved to comp_model() object

% Model Parameters
beta0 = xpar(1); % Intercept
beta1 = xpar(2); % Slope

% Parse Data
obssx = data(:,8); %use BDI for now

%Model Initial Values
sse = 0; %sum of squared error
time = 1:size(data,1);
time = time - mean(time);

% This model is looping through every trial.  Obviously this isn't
% necessary for this specific model, but it is for more dynamic models that
% change with respect to time.
for t = 1:length(obssx)
    
    %Calculate symptom decay using linear or exponential decay
    predsx(t) = beta0 + beta1 * time(t); %linear trend of symptom change
    
    % update sum of squared error (sse)
    sse = sse + (predsx(t) - obssx(t))^2;
    
end

%Output results - can add this as a global variable later
trialout = [ones(t,1)*data(1,1) (1:t)', obssx, predsx(1:t)'];

end % model

