function varargout = penalizedmodelfit(modelfit,nObs,nPar,varargin)
% varargout = modelfit(modelfit,nObs,nPar,varargin)
% -------------------------------------------------------------------------%
%
%   This function calculates model fit penalizing for free parameters using
%   AIC (default) or BIC for either residual sum of squares (SSE) or
%   maximum log likelihood (default).
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
% 'SSE':            Type of model fit - Residual Sum of Squares (default is 'LLE')
%
% 'LLE':            Type of model fit - Log Likelihood (default is 'LLE')
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
% [z,p] = two_proportion_ztest([1,1,1,1,0],[1,0,1,0,1],'dependent') %dependent samples
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

switch type
    
    case 'SSE'
        switch metric
            case 'AIC'
                
            case 'BIC'
                
            case 'BOTH'
        end
        
    case 'LLE'
        switch metric
            case 'AIC'
                varargout{1} = 2*nPar+fval;
            case 'BIC'
                varargout{1} = 2*fval+nPar*log(length(subdata));
            case 'BOTH'
                varargout{1} = 2*length(ipar)+fval;
                varargout{2} = 2*fval+length(ipar)*log(length(subdata));
        end
end

end %function end

BICMin=length(nObs)*log(SSEMin)-nObs*log(length(nObs))+log(length(nObs))*size(xPar,2);

params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
