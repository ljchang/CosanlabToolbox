function [D, varargout] = tjur_r2(isS1, predPS1, varargin)
% tjur = get_tjur(obj,isS1, predPS1,predPS2)
%
% Calculate Coefficient of Discrimation (binary pseudo-R^2 metric)
%
% Tjur, T. (2009). Coefficients of determination in logistic regression models?
% A new proposal: The coefficient of discrimination. The American Statistician,
% 63(4), 366-372.
%
%--------------------------------------------------------------------------
% Inputs:
% ---------------------------------------------------------------------
% isS1                      : logical vector indicating state 1 (S1)
% predPS1                   : vector of probabilities predicting state 1 (S1)
%
%--------------------------------------------------------------------------
% Optional Inputs:
% ---------------------------------------------------------------------
% SubID                     : A vector indicating subject ID.  If included
%                             will return average D across subjects
%
%--------------------------------------------------------------------------
% Outputs:
% ---------------------------------------------------------------------
% D                          : scalar Tjur's pseudo R^2 metric, mean across
%                               subjects if SubID is included
%
%--------------------------------------------------------------------------
% Optional Outputs:
% ---------------------------------------------------------------------
% std(D)                     : scalar Tjur's pseudo R^2 metric, std across
%                               subjects if SubID is included
%--------------------------------------------------------------------------
% Examples:
% ---------------------------------------------------------------------
% D = tjur_r2(st.trial(:,3)==1,st.trial(:,end-1))
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

doMeanSubject = 0;
if nargin > 2
    doMeanSubject = 1;
    SubID = varargin{1};
end

if ~isequal(length(isS1),length(predPS1))
    'make sure length of each input variable is the same'
end

if ~doMeanSubject
D = mean(predPS1(isS1)) - mean(predPS1(~isS1));
else
   subnum = unique(SubID);
   for i = 1:length(subnum)
       sdat = [isS1(SubID==subnum(i)),predPS1(SubID==subnum(i))];
       D_sub(i) = mean(sdat(sdat(:,1)==1,2)) - mean(sdat(sdat(:,1)==0,2));
   end
   D = mean(D_sub);
   varargout{1} = std(D_sub);
end


