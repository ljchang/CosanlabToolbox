function params = FitGuiltModel2(datafile, varargin)
% -------------------------------------------------------------------------
% Usage:
% -------------------------------------------------------------------------
% [params = FitGuiltModel2(datafile, varargin)
%
%   This function Fits the Guilt Aversion Model (Dufwenberg, 2003) to
%   datafile using least squares estimation as described in Chang, Smith, 
%   Dufwenberg, & Sanfey (2011) Triangulating the neural, psychological, 
%   and economic bases of guilt-aversion. 
%
%   Basically, the algorithm works by trying to find the best fitting theta 
%   parameter that minimizes the difference between the model predicted 
%   Trustee Decision and the actual decision.  It assumes a specific choice
%   set, so this may need to be adjusted in the model section of the code.
%
%   Will try multiple starting
%   locations to prevent getting stuck in local minima.  Parameter
%   estimation for this model does not work great as it is linear and
%   parameters can only be [0,1] or > 1 (i.e., Guilt inaverse, or guilt
%   averse).  Not sure the parameters should be interpreted beyond that as
%   they don't seem to be particularly stable. Also, using least squares
%   estimation, but maximum likelihood for ordered probit probably makes more sense.
%   Please email author with any improvements, suggestions, or comments.
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% datafile          path to data txt file where columns =
%                   {'Subject','OfferAmount','SecondOrderBelief','Player2Decision'} and
%                    missing data is indicated by '99'
%
% -------------------------------------------------------------------------
% Optional Inputs:
% -------------------------------------------------------------------------
% 'nRepetitions'    followed by number of repetitions to run algorithm (default = 100)
%
% 'parameterBounds' followed by array of lower and upper bounds (e.g., [0.001, 20])
%
% -------------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
%
% params            a data structure with paramaters for each subject {Subject, theta, SSE, AIC}
%
% Examples:
% -------------------------------------------------------------------------
%
% params = FitGuiltModel2('/Users/lukechang/Research/Guilt/MatlabFiles/Guilt/Guilt_Behav.txt', 'nRepetitions', 100, 'parameterBounds', [0.001, 20])
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

% Defaults
% -------------------------------------------------------------------
% {'Subject','OfferAmount','SecondOrderBelief','Player2Decision'};  %Column headers
datafile = '/Users/lukechang/Research/Guilt/MatlabFiles/Guilt/Guilt_Behav.txt';

%number of repetitions to run the estimation procedure - helps prevent getting stuck in local minima
nRep = 100;

%Parameter Estimation Specification
parBound = [0.001, 20];

for varg = 1:length(varargin)
    if ischar(varargin{varg})
        switch varargin{varg}
            % reserved keywords
            case 'nRepetitions'
                nRep = varargin{varg + 1};
                varargin{varg} = [];
                varargin{varg + 1} = [];
            case 'parameterBounds'
                parBound = varargin{varg + 1};
                varargin{varg} = [];
                varargin{varg + 1} = [];        
        end
    end
end
    


%Load Guilt Data and strip header
dat = importdata(datafile);
data = dat.data;

%Remove trials with missing data
data(find(sum((data(:,:)==99)')'==1),:)=[];

%create vector of subject IDs
sub=unique(data(:,1)); 

% Parameter bounds
lbound = parBound(1);
ubound = parBound(2);
ipar = random('Uniform',lbound,ubound,1,nRep); %initial starting parameter

%Loop through all subjects and estimate theta using fmincon
subdataout=[];
for i = 1:length(sub)
    for j = 1:nRep
        subdata=data(find(data(:,1)==sub(i)),:);
        [xpar(j) fval(j) exitflag(j) output(j)]=fmincon(@Guilt_Model, ipar(j), [], [], [], [], [lbound], [ubound], [], [], subdata); %Use fmincon to estimate parameter
    end
        [xParMin, SSEMin] = FindParamMin(xpar',fval');
        params(i,1) = sub(i);
        params(i,2) = xParMin;
        params(i,3) = SSEMin;
        params(i,4) = 2 * size(ipar,2) + length(subdata) * (log((2 * pi * SSEMin) / length(subdata))+1); %AIC-smaller is better
%         disp([ 'Subject ' num2str(sub(i)) ':' num2str(exitflag) ])    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [xParMin, SSEMin] = FindParamMin(xPar,SSE)
        % Find parameters associated with lowest SSE.
        % input: xPar is vector of free parameters, SSE is vector of SSE
        %Pick Min for output
        nMin=sum(SSE==min(SSE));
        if nMin == 1
            xParMin=xPar(SSE==min(SSE),:);
            SSEMin=SSE(SSE==min(SSE));
        elseif nMin > 1 %Pick the first if there are multiple local min of the same value
            minSSE=find(SSE==min(SSE));
            xParMin=xPar(minSSE(1),:);
            SSEMin=SSE(minSSE(1));
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function SqError=Guilt_Model(xpar,dat)
        %data=[sub,s1,E2E1s2,s2]
        
        SqError = 0; %initialize squared error
        theta = xpar(1);
        
        for trialnum = 1:length(dat) %Loop through all trials
           
            % Create choice set
            invest = dat(trialnum,2) * 4;
            if invest <= 10  
                choice_set = 0:invest;
            else
                choice_set = 0:round(dat(trialnum,2)*4/10):dat(trialnum,2) * 4; %need to check if this is correct: were there 10 choices or 11?
            end
            
            % Calculate utility function given choiceset
            u2 = choice_set + theta * max(dat(trialnum,3)-choice_set, 0); 
    
            % Select model predicted choice
            predicted_choice = choice_set(find(u2==max(u2)));
            if length(predicted_choice > 1)  %choose the lowest choice if the model finds multiple maxima - totally arbitrary.
                predicted_choice = min(predicted_choice);
            end
            
            % Update Squared Error
            SqError = SqError + (predicted_choice -  dat(trialnum,4))^2; %update squared error based on deviation from actual choice - eventually this could be updated to maximum likelihood with ordered probit
        end
    end
end