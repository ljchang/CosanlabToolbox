function varargout = penalizedmodelfit(modelfit, nObs, nPar, varargin)
% varargout = modelfit(modelfit,nObs,nPar,varargin)
% -------------------------------------------------------------------------%
%
%   This function calculates model fit penalizing for free parameters using
%   AIC (default) or BIC for either residual sum of squares (SSE) or
%   maximum log likelihood (default). Make sure modelfit has negative sign in
%   front of it being output from fmincon which can only minimize
%   likelihoods.
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% modelfit:         Value of Model Fit
%
% nObs:             Number of Observations
%
% nPar:             Number of Parameters
%
% -------------------------------------------------------------------------
% Optional Inputs:
% -------------------------------------------------------------------------
% 'type':           Followed by type of model fit: Residual Sum of Squares (SSE),
%                   Log Likelihood Estimate (LLE; default), Likelihood
%                   Estimate (LE)
%
% 'metric':         Followed by type of metric to output: Akaike Information Criterion ('AIC'; default)
%                   Bayesian Information Criterion ('BIC'), or both AIC & BIC ('BOTH')
%
% -------------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
%
% varargout:         Either AIC, BIC, or both
%
% -------------------------------------------------------------------------
% Examples:
% -------------------------------------------------------------------------
%
% AIC = penalizedmodelfit(200, 100, 2, 'type','SSE','metric','AIC')
%
% [AIC, BIC] = penalizedmodelfit(200, 100, 2, 'type','LLE','metric','BOTH')
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

% defaults
type = 'LLE'; %or 'LE' or 'SSE'
metric = 'AIC'; %or 'BIC', or 'BOTH'

% Parse Input
for varg = 1:length(varargin)
    if ischar(varargin{varg})
        if strcmpi('type',varargin{varg})
            type = varargin{varg + 1};
            varargin{varg} = {}; varargin{varg + 1} = {};
        end
        if strcmpi('metric',varargin{varg})
            metric = varargin{varg + 1};
            varargin{varg} = {}; varargin{varg + 1} = {};
        end
    end
end

switch type
    case 'SSE' %residual sum of squared error
        switch metric
            case 'AIC'
                varargout{1} = nObs * log(modelfit / nObs) + 2 * nPar; % the real formula also has a constant added, but it's not necessary for model comparisons
            case 'BIC'
                varargout{1} = nObs * log(modelfit / nObs) + nPar * log(nObs);
            case 'BOTH'
                varargout{1} = nObs * log(modelfit / nObs) + 2 * nPar; % the real formula also has a constant added, but it's not necessary for model comparisons
                varargout{2} = nObs * log(modelfit / nObs) + nPar * log(nObs);
        end
        
    case 'LLE' %log-likelihood estimate
        switch metric
            case 'AIC'
                varargout{1} = 2 * nPar - 2 * modelfit;
            case 'BIC'
                varargout{1} = -2 * modelfit + nPar * log(nObs);
            case 'BOTH'
                varargout{1} = 2 * nPar - 2 * modelfit;
                varargout{2} = -2 * modelfit + nPar * log(nObs);
        end
        
    case 'LE' %likelihood estimate
        switch metric
            case 'AIC'
                varargout{1} = 2 * nPar - 2 * log(modelfit);
            case 'BIC'
                varargout{1} = -2 * log(modelfit) + nPar * log(nObs);
            case 'BOTH'
                varargout{1} = 2 * nPar - 2 * log(modelfit);
                varargout{2} = -2 * log(modelfit) + nPar * log(nObs);
        end
end

end %function end
