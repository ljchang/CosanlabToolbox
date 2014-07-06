function model_output = fit_model(data, model, param_min, param_max, nStart, type)

% model_output = fit_model(data, model, param_min, param_max, nStart)
%
% -------------------------------------------------------------------------
% This function will fit a model (model) using fmincon to a dataset (data) 
% multiple times with random start values (nStart) with the parameters being 
% constrained to a lower bound (param_min) and upper bound (param_max).
% Estimates a separate parameter to each subject (indicated in 1st column
% of dataset).  Requires some helper functions from my github repository 
% (https://github.com/ljchang/toolbox/tree/master/Matlab).  Clone this
% repository and add paths to Matlab.  Requires that the model be a
% named function.
%
% -------------------------------------------------------------------------
% INPUTS:
% -------------------------------------------------------------------------
% data              Dataset to fit model, assumes subject ID is the 1st column.
%
% model             Specify model to fit (see models)
% 
% param_min         Vector of minimum parameter values
% 
% param_max         Vector of maximum parameter values
% 
% nStart            Number of repetitions with random initial paramater.
%                   Larger numbers decrease likelihood of getting stuck in local minima
%
% type              Type of parameter estimation (e.g., maximizing LLE or
%                   minimizing 'SSE').
%
% -------------------------------------------------------------------------
% OUTPUTS:
% -------------------------------------------------------------------------
% model_output      Structure containing all of the trial-trial data and
%                   Parameter estimates
%
% -------------------------------------------------------------------------
% EXAMPLES:
% -------------------------------------------------------------------------
% model_output = fit_model(data, model, param_min, param_max, nStart)
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

global trialout

Subjects = unique(data(:,1));
allout = [];
for s = 1:length(Subjects)
    
    sdat = data(data(:,1)==Subjects(s),:); %Select subject's data
    
    xpar = zeros(nStart,length(param_min)); fval = zeros(nStart,1); exitflag = zeros(nStart,1); out = {nStart,1};  %Initialize values to workspace
    
    for iter = 1:nStart  %Loop through multiple iterations of nStart
        
        %generate random initial starting values for free parameters
        for ii = 1:length(param_min)
            ipar(ii) = random('Uniform',param_min(ii),param_max(ii),1,1);
        end
        
        eval(['[xpar(iter,1:length(param_min)) fval(iter) exitflag(iter) out{iter}]=fmincon(@' model ', ipar, [], [], [], [], param_min, param_max, [], [], sdat);'])
        
    end
    
    %Find Best fitting parameter if running multiple starting parameters
    [xParMin, fvalMin] = FindParamMin(xpar, fval);
    
    %output parameters
    params(s,1) = Subjects(s);
    params(s,2:length(xParMin) + 1) = xParMin;
    params(s,length(xParMin) + 2) = fvalMin;
    if type == 'LLE'
        params(s,length(xParMin) + 3:length(xParMin) + 4) = penalizedmodelfit(-fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'BOTH');
    elseif type =='SSE'
        params(s,length(xParMin) + 3:length(xParMin) + 4) = penalizedmodelfit(fvalMin, size(sdat,1), length(xParMin), 'type', type, 'metric', 'BOTH');
    end
    
    %aggregate trials
    allout = [allout; trialout];
end

%Create output structure
model_output = struct;
model_output.params = params;
model_output.trial = allout;

end %Function end

