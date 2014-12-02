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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2014 Luke Chang
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"), 
% to deal in the Software without restriction, including without limitation 
% the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the 
% Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
% DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
