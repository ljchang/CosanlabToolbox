function [z,p] = two_proportion_ztest(v1,v2)

% [z,p] = two_proportion_ztest(v1,v2)
% -------------------------------------------------------------------------%
%   This function calculates a two proportion z interval test, in which the 
%   hypothesis is tested whether the proportions are significantly different 
%   from each other.  Uses pooled variance to calculate SE Assumes  data are 
%   independent.
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% v1:          vector of accurately classifed (1 vs 0) from sample 1
%
% v2:          vector of accurately classifed (1 vs 0) from sample 2
%
% -------------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
%
% z:           z - value of hypothesis comparing difference in proportions
%              from two vectors
%
% p:           two tailed p - value of hypothesis comparing difference in proportions
%              from two vectors
%
% Examples:
% -------------------------------------------------------------------------
%
% [z,p] = two_proportion_ztest([1,1,1,1,0],[1,0,1,0,1])
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

phat = sum([sum(v1),sum(v2)])/sum([length(v1),length(v2)]);
sehat_p1_p2 = sqrt(phat * (1 - phat) * ((1/length(v1)) + (1/length(v2))));
z = (mean(v1) - mean(v2)) / sehat_p1_p2;
p = normpdf(z,0,1);
p = 2 * min(p,1-p);

end



