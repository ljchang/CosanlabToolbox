function rankdat = normalizedrank(dat, varargin)
% Create a rank ordered vector or matrix and normalize by max rank [0,1].
%
%
% rankdat = normalizedrank(dat, varargin)
%
% Inputs:
% ---------------------------------------------------------------------
% dat                    : input data
%
% Optional inputs with their default values:
% :--------------------------------------------
% 'nonorm'               : turn off default normalization and output raw rank
%
% Outputs:
% ---------------------------------------------------------------------
% rankdat                : ranked data
%
% Examples:
% ---------------------------------------------------------------------
% rankdat = normalizedrank(dat); % normalized rank
% rankdat = normalizedrank(dat, 'nonorm'); % rank
%
% Original version: Copyright Luke Chang 2/2014

% Programmer's Notes:

%Defaults
nonorm = 0;

%Parse Varargin
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'nonorm'}
               nonorm = 1;
                varargin{i} = [];
        end
    end
end

%Sort Input Data
[Y,I] = sort(dat,'ascend');

%Calculate normalized rank
if nonorm
    r = 1:size(dat,1);
else
    r = (1:size(dat,1))/size(dat,1);
end

%Resort output data
%need to loop through all columns for some reason - but doesn't seem to
%take too long.
rankdat = zeros(size(dat));
for i = 1:size(dat,2)
    rankdat(I(:,i),i) = r;
end
