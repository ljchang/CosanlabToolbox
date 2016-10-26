function RES = binotest_dependent(X, p)

% RES = binotest_dependent(X, p)
% -------------------------------------------------------------------------%
% Test the number of "hits" for each subject (row in X) against a null-hypothesis
% proportion p, across all subjects using a one sample t-test (two-tailed).
% The second level null hypothesis should be approximated by a normal
% distribution with a mean of p.  This approach assumes that each subject
% has an equal number of independent Bernoulli trials (columns in X) and
% that the number of subjects exceeds n=20 the test will be more accurate as n -> infinity.
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% X:          X is a matrix of "hits" and "misses", coded as 1s and 0s.
%             where rows = subjects and columns = subject trials
%
% p:          p is the null hypothesis proportion of "hits", e.g., often p = 0.5
%
% -----------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
%
% RES:         a structure containing the output of the stats, t, df, p,
%              se and also the average number of hits per subject and the overal
%              proportion of hits in the sample
%
% Examples:
% -------------------------------------------------------------------------
%
% RES = binotest_dependent([1,1,1,1,0; 1,0,1,0,1]',.5)
%
% -------------------------------------------------------------------------
% Author and copyright information:
% -------------------------------------------------------------------------
%     Copyright (C) 2014  Luke Chang & Tor Wager
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

X = double(X); % just in case

%two-tailed one sample t-test comparing deviation from p
[H,P,CI,STATS] = ttest(mean(X,2), p, 'tail','both');

n = size(X,1);
se = STATS.sd/sqrt(n);
prop = mean(mean(X,2)); %average accuracy across all subjects
hits = mean(sum(X)); %average number of hits per subject

RES = struct('n', n, 'hits', hits, 'prop', prop, 'p_val', P, 'SE', se,'t',STATS.tstat,'df',STATS.df);

end
