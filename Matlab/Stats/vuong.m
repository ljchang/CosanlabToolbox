function [v, pVal] = vuong(m1, m2, p , q, varargin)

%   This function performs a non-nested model comparison of M2 to M1 by
%   calculating the Vuong statistic (Vuong, 1989).  No assumption that either
%   model is correctly specified.  Uses the adjusted version which
%   corrects for the number of free parameters.  Asymptotially distributed
%   N(0,1) or N(c,1) where c is a correction factor based on model
%   complexity.  Will use Akaike Information Crierion as correction.
%
% Usage:
% -------------------------------------------------------------------------
% [v, pVal ] = vuong(m1, m2, p, q)
%
% Author and copyright information:
% -------------------------------------------------------------------------
%     Copyright (C) 2013  Luke Chang
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
%
% Inputs:
% -------------------------------------------------------------------------
% m1            Vector containing log likelihood values from Model 1
%
% m2            Vector containing log likelihood values from Model 2
%               from Model 2
%
% p             Number of parameters in Model 1
%
% q             Number of parameters in Model 2
%
% Outputs:
% -------------------------------------------------------------------------
%
% pValue        p - value from normal distribution
%
% Examples:
% -------------------------------------------------------------------------
% To calculate difference between 30 subjects where m1 = 2 params and m2 =
% 3 params.
%
% [vuong, pValue] = vuong(m1, m2, 2, 3)
%
% [vuong, pValue] = vuong(m1, m2, 2, 3, 'AIC') %adjust using Akaike
% Information Criterion
% -------------------------------------------------------------------------

% Programmers' notes:

% optional inputs
% -------------------------------------------------------------------
doAIC = 0; %off by default
doNested = 0; %non-nested by default

for varg = 1:length(varargin)
    if ischar(varargin{varg})
        switch varargin{varg}
            % reserved keywords
            case 'AIC'
                doAIC = 1;
            case 'Nested'
                doNested = 1;
        end
    end
end


% Calculate Vuong Statistic
% -------------------------------------------------------------------

n = length(m1); %could add check to make sure m1 and m2 are same lengths

lr = sum((m1 - m2)); %likelihood ratio

if ~doAIC %run unadjusted vuong by default
    
    v = (1/sqrt(n)) * (lr / sqrt((sum((m1 - m2).^2)/n)));  %Vuong, 1989 pg 318
    
else %run adjusted vuong using AIC
    
    correction = (p/2) * log(n) - (q/2) * log(n);
    v = (1/sqrt(n)) * ((lr - correction) / sqrt((sum((m1 - m2).^2)/n)));
    
end

pVal = normpdf(v);


