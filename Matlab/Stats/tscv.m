function [trIdx, teIdx] = tscv(vectorlen, varargin)
% Create a crossvalidation test and train index for time series data.
% Larger h will ensure less dependence.  Larger v creates larger test sets
% Number of folds = vectorlen - (2*h + 2*v)
%
% -See http://robjhyndman.com/hyndsight/tscvexample/ for more info about rolling cv
% -See Racine, J. (2000). Consistent cross-validatory model-selection for dependent data: hv-block cross-validation. Journal of Econometrics, 99(1), 39-61.
%
% [trIdx, teIdx] = rollingcv(vectorlen, stepsize)
%
% Inputs:
% ---------------------------------------------------------------------
% vectorlen                 : length of vector to create holdout cross-validation set
%
% Optional inputs with their default values:
% :--------------------------------------------
% 'rolling' = [stepsize]    : use rolling cv with the number of
%                             observations as 'stepsize', test = 1
%                             observation
% 'hvblock' = [h,v]         : use hvblock cross-validation with a block
%                             size of 'h' (0 reduces to v-fold xval)and
%                             number of test observations 'v' (0 reduces
%                             to h-block xval)
%
% Outputs:
% ---------------------------------------------------------------------
% trIdx                     : structure with training label index
% teIdx                     : structure with test label index
%
% Examples:
% ---------------------------------------------------------------------
% [trIdx, teIdx] = tscv(100, 'hvblock',[5,2]); % use hvblock with h=5 and v=2
%
% Original version: Copyright Luke Chang & Hedwig Eisenbarth 11/2013

% Programmer's Notes:
% LC 11/28/13:
%       -changed input and documentation
%       -Don't use matlab functions as variable names (e.g., median) -
%       median > mid
%       rewrote the hv block so that it loops though all available data -
%       need to finish coding the rollingcv option

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'hvblock'}
                xval_type = varargin{i};
                inval = varargin{i + 1};
                h = inval(1);
                v = inval(2);
                varargin{i} = [];
                varargin{i + 1} = [];
                
            case {'rolling'}
                xval_type = varargin{i};
                stepsize = varargin{i + 1};
                varargin{i} = [];
                varargin{i + 1} = [];
        end
    end
end

switch xval_type
    case 'hvblock'
        %hv cross validation: leave completely out h steps around the test interval
        %See Racine, J. (2000). Consistent cross-validatory model-selection for dependent data: hv-block cross-validation. Journal of Econometrics, 99(1), 39-61.
        
        stepsize = 2*v + 2*h + 1;
        
        if stepsize > vectorlen;
            error('stepsize is too large, please decrease')
        end
        
        start = 1;
        stop = stepsize;
        while start <= vectorlen - stepsize + 1
            trIdx{start} = true(vectorlen,1);
            teIdx{start} = false(vectorlen,1);
            trIdx{start}(start:(start + 2*h + 2*v)) = false; %train set = everything - 2*v + 2*h + 1
            teIdx{start}((start + h):(start + h + 2*v)) = true; %test set = 2*v + 1
            start = start + 1;
            stop = stop + 1;
        end
        
    case 'rolling' % this needs to be fixed.
        %rolling cross validation: leave completely out h steps around the test interval
        %See http://robjhyndman.com/hyndsight/tscvexample/ for more info
        mid = median(1:stepsize);
        start = 1;
        stop = stepsize;
        for k = 1:vectorlen %create training and test for all step sizes, but treat last one differently to account for remainder.
            trIdx{k} = false(vectorlen,1);
            teIdx{k} = false(vectorlen,1);
            trIdx{k}(start:start-1+(mid-v-h)) = true;
            trIdx{k}(start-1+(mid+h):stop) = true;
            teIdx{k}(start-1+mid) = true;
            if rolling == 1
                start = start + stepsize;
                stop = stop + stepsize;
            else
            end
        end
end

