function timing = geometric_progression(minTime, nTrials, meanTime)

% timing = geometric_progression(minTime, nTrials, meanTime)
%
% This function will find a set of nTrial times that follow an exponential 
% distribution are greater than minTime and that approximate the meanTime/
% This is useful for generating ISI that are unpredictible for a subject.
%
% -------------------------------------------------------------------------
% INPUTS:
% -------------------------------------------------------------------------
% minTime:          Minimum value of time allowed
% nTrials:          Number of trials to find timings for
% meanTime:         Mean time across all trials to try and approximate
%
% -------------------------------------------------------------------------
% OUTPUTS:
% -------------------------------------------------------------------------
% timing:           a vector of nTrials times with mean meanTime that are
%                   all greater than minTime
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

p = 0.0001:.001:1;

mn = meanTime + 1;
i = 1;
while round(mn) > meanTime
    timing = [];
    Trials = nTrials;
    Time = minTime;
    while length(timing) < nTrials
        timing = [timing; repmat(Time,ceil(Trials * p(i)),1)];
        Time = Time + 1;
        Trials = nTrials - length(timing);
    end
    mn = mean(timing);
    i = i + 1;
end
