function [chisquare pValue] = lrt(m1, m2, df)

%   This function performs model comparison of M2 to M1 by calculating a 
%   likelihood ratio test for each voxel in an fmri data object.  Will take
%   the difference between models for each subject multiply by 2 and then
%   sum the differences.  DF should reflect the difference in the number of
%   parameters between the two models (i.e., number of subjects in Model 1 
%   + number of free parameters in Model 1 - the same in model 2)
%
% Usage:
% -------------------------------------------------------------------------
% [chisquare pValue] = LikelihoodRatioTest(m1Dat, m2dat, df)
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
% m1Dat         Data object containing [vox x subjects] log likelihood values
%               from Model 1
%
% m2Dat         Data object containing [vox x subjects] log likelihood values
%               from Model 2
%
% df            Degrees of freedom = number of parameters in Model 2 minus number of
%               parameters in Model 1
%
% Outputs:
% -------------------------------------------------------------------------
% chisquare     fmri_data object containing chi square values 
%
% pValue        fmri_data object containing p - Values
%
% Examples:
% -------------------------------------------------------------------------
% To calculate difference between 30 subjects where m1 = 31 params and m2 =
% 93 params.
%
% [chisquare pValue] = LikelihoodRatioTest(m1, m2, 62)
%
% -------------------------------------------------------------------------

% Programmers' notes:
% 3/13/13 : LC : removed values below df.  p-values are meaningly according
% to Matt Jones.

chisquare = sum((2 * (m2 - m1)));
pValue = chi2pdf(chisquare, df);

% %Remove lower tail p - values
% pValue.dat(chisquare.dat < df) = nan;
% chisquare.dat(chisquare.dat < df) = nan;
