function model_output = fit_model(data, model, param_min, param_max, nStart, type, varargin)

% model_output = fit_model(data, model, param_min, param_max, nStart, type)
%
% -------------------------------------------------------------------------
% This function will fit a model (model) using fmincon to a dataset (data)
% multiple times with random start values (nStart) with the parameters being
% constrained to a lower bound (param_min) and upper bound (param_max).
% Estimates a separate parameter to each subject (indicated in 1st column
% of dataset).  Requires some helper functions from my github repository
% (https://github.com/ljchang/toolbox/tree/master/Matlab).  Clone this
% repository and add paths to Matlab.  Requires that the model be a
% named function and that it can parse the input data.
%
% -------------------------------------------------------------------------
% INPUTS:
% -------------------------------------------------------------------------
% data                  Dataset to fit model, assumes subject ID is the 1st column.
%
% model                 Specify model to fit (see models)
%
% param_min             Vector of minimum parameter values
%
% param_max             Vector of maximum parameter values
%
% nStart                Number of repetitions with random initial paramater.
%                       Larger numbers decrease likelihood of getting stuck in local minima
%
% type                  Type of parameter estimation (e.g., maximizing LLE or
%                       minimizing 'SSE').
%
% -------------------------------------------------------------------------
% OPTIONAL INPUTS:
% -------------------------------------------------------------------------
% show_subject          Displays Subject ID for every iteration.  Helpful for
%                       debugging.  Off by default.
%
% persistent_fmincon    Continues running fmincon despite error.  Good for
%                       salvaging data if a model is having difficulty converging
%
% -------------------------------------------------------------------------
% OUTPUTS:
% -------------------------------------------------------------------------
% model_output          Structure containing all of the trial-trial data and
%                       Parameter estimates
%
% -------------------------------------------------------------------------
% EXAMPLES:
% -------------------------------------------------------------------------
% model_output = fit_model(data, model, param_min, param_max, nStart, type)
% model_output = fit_model(data, 'linear_expect_model', [0.01 -10,-20], [1 10,20], 100, 'SSE')
%
% -------------------------------------------------------------------------
% Author and copyright information:
% -------------------------------------------------------------------------
%     Copyright (C) 2014  Luke Chang
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Setup
%--------------------------------------------------------------------------

global trialout

% Defaults
showSubject = 0;
persist = 0;

% Parse Inputs
for varg = 1:length(varargin)
    if ischar(varargin{varg})
        if strcmpi(varargin(varg),'show_subject')
            showSubject = 1;
            varargin(varg) = [];
        elseif strcmpi(varargin,'persistent_fmincon')
            persist = 1;
            varargin(varg) = [];
        end
    end
end

%--------------------------------------------------------------------------
% Run Model separately for every subject
%--------------------------------------------------------------------------

Subjects = unique(data(:,1));
allout = [];
for s = 1:length(Subjects)
    if showSubject; display(['Subject ', num2str(Subjects(s))]); end %Show Subject ID for every iteration if requested
    
    sdat = data(data(:,1)==Subjects(s),:); %Select subject's data
    
    xpar = zeros(nStart,length(param_min)); fval = zeros(nStart,1); exitflag = zeros(nStart,1); out = {nStart,1};  %Initialize values to workspace
    
    for iter = 1:nStart  %Loop through multiple iterations of nStart
        
        %generate random initial starting values for free parameters
        for ii = 1:length(param_min)
            ipar(ii) = random('Uniform',param_min(ii),param_max(ii),1,1);
        end
        
        if ~persist
            eval(['[xpar(iter,1:length(param_min)) fval(iter) exitflag(iter) out{iter}]=fmincon(@' model ', ipar, [], [], [], [], param_min, param_max, [], [], sdat);'])
        else
            try
                eval(['[xpar(iter,1:length(param_min)) fval(iter) exitflag(iter) out{iter}]=fmincon(@' model ', ipar, [], [], [], [], param_min, param_max, [], [], sdat);'])
            catch
                display('Fmincon Could Not Converge.  Skipping Iteration')
                xpar(iter,1:length(param_min)) = nan(1,length(param_min));
                fval(iter) = nan;
                exitflag(iter) = nan;
                out{iter} = nan;
            end
        end
    end
    
    %Find Best fitting parameter if running multiple starting parameters
    [xParMin, fvalMin] = FindParamMin(xpar, fval);
    
    %output parameters
    params(s,1) = Subjects(s);
    params(s,2:length(xParMin) + 1) = xParMin;
    params(s,length(xParMin) + 2) = fvalMin;
    if type == 'LLE'
        params(s,length(xParMin) + 3) = penalizedmodelfit(-fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'AIC');
        params(s,length(xParMin) + 4) = penalizedmodelfit(-fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'BIC');
    elseif type =='SSE'
        params(s,length(xParMin) + 3) = penalizedmodelfit(fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'AIC');
        params(s,length(xParMin) + 4) = penalizedmodelfit(fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'BIC');
    end
    
    %aggregate trials
    allout = [allout; trialout];
end

%--------------------------------------------------------------------------
% Collate Output
%--------------------------------------------------------------------------

model_output = struct;
model_output.params = params;
model_output.trial = allout;
model_output.param_min = param_min;
model_output.param_max = param_max;
model_output.nStart = nStart;
model_output.type = type;


end %Function end

