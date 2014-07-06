function varargout = SoftMax(vChoice,beta)
% pChoice = SoftMax(vChoice,beta)
% -------------------------------------------------------------------------%
% Calculate probability of selecting each choice given beta
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% vChoice       Vector of Values of each possible Choice
% beta          Temperature parameter of softmax (close to 0 means
%               exploit closer to 1 means explore
%
% -------------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
% varargout     Separate output for probability of selecting each choice
%
% -------------------------------------------------------------------------
% Examples:
% -------------------------------------------------------------------------
% [p1,p2,p3] = SoftMax([2,1,.1], .9);
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

nChoice = length(vChoice);

% Calculate Regularization
for i = 1:nChoice
    reg(i) = exp(vChoice(i)/beta);
end
reg = sum(reg);

% Calculate probability of selecting each choice given beta
for i = 1:nChoice
    varargout{i} = exp(vChoice(i)/beta)/reg;
end
end