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
% 'SSE':            Type of model fit - Residual Sum of Squares
%
% 'LLE':            Type of model fit - Log Likelihood Estimate (default)
%
% 'LE':             Type of model fit - Likelihood Estimate
%
% 'AIC':            Calculate Akaike Information Criterion (default)
%
% 'BIC':            Calculate Bayesian Information Criterion
%
% 'BOTH':           Calculate both AIC and BIC
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
% [z,p] = two_proportion_ztest([1,1,1,1,0],[1,0,1,0,1]) %independent samples
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
type = 'LLE';
metric = 'AIC';  %or 'BIC', or 'BOTH'

% Parse Input
if strcmpi(varargin,'AIC'); metric = 'AIC'; end
if strcmpi(varargin,'BIC'); metric = 'BIC'; end
if strcmpi(varargin,'BOTH'); metric = 'BOTH'; end
if strcmpi(varargin,'SSE'); type = 'SSE'; end
if strcmpi(varargin,'LLE'); type = 'LLE'; end
if strcmpi(varargin,'LE'); type = 'LE'; end

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
