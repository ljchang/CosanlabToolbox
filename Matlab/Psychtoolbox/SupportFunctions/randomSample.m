function x = randomSample(mu,sigma, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% x = randomSample(mu,sigma, varargin)
%
% randomly select a value from a normal distribution
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs:
%
% mu                        mean of distribution
% sigma                     standard deviation  of distribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional Inputs:
%
% 'sign'                    Followed by 'negative' or 'positive' to Select 
%                           a value above or below mu.
% 'cutoff'                  Followed by a cutoff in std 
%                           (i.e., values must excced cutoff; default = 2).
%                           a vector indicates upper and lower bounds [1.5,2.5]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output:
%
% x                         Randomly selected value
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

% Defaults
cutoff = 2;

% Parse Inputs
if nargin > 5
    if any(strcmpi('sign',varargin))
        select_sign = varargin{find(strcmpi('sign',varargin)) + 1};
        if ~strcmpi(select_sign, 'negative') & ~strcmpi(select_sign, 'positive')
            error('Please make sure that ''sign'' is followed by ''positive'' or ''negative''')
        end
    end
    if any(strcmpi('cutoff',varargin))
        cutoff = varargin{find(strcmpi('cutoff',varargin)) + 1};
    end
end


% Create normal distribution from input parameters
distribution = mu + sigma.*randn(5000,1);

% Remove samples that exceed bounds of [0, 1]
distribution(distribution < 0) = [];
distribution(distribution > 1) = [];

% Remove samples that are within the bounds of the cutoff
if length(cutoff) == 1
    distribution(distribution < (mu + cutoff*sigma) & distribution > (mu - cutoff*sigma)) = [];
elseif length(cutoff) == 2 %user specified upper and lower bounds
    distribution(distribution < (mu + cutoff(1)*sigma) & distribution > (mu - cutoff(1)*sigma)) = [];
    distribution(distribution > (mu + cutoff(2)*sigma) & distribution > (mu - cutoff(2)*sigma)) = [];
    
end
% Select values
if strcmpi(select_sign,'positive')
    distribution(distribution < mu) = [];
elseif strcmpi(select_sign,'negative')
    distribution(distribution > mu) = [];
end

% Select Random Sample from remaining values
% if no values remain than return original rating
if ~isempty(distribution)
    x = RandSample(distribution);
else
    x = mu;
end


