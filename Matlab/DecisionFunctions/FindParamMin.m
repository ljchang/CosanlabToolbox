function [xParMin, fvalMin] = FindParamMin(xPar, fval)
% varargout = modelfit(modelfit,nObs,nPar,varargin)
% -------------------------------------------------------------------------
%
%   This function finds the paramaters associated with the lowest finalized
%   model fit value. Used when using multiple starting values with fmincon.
%   Helps prevent getting stuck in local minima.
%
% -------------------------------------------------------------------------
% Inputs:
% -------------------------------------------------------------------------
% xPar:             Matrix of estimated free parameters from fmincon 
%
% fval:             Vector of final model fit values from fmincon
%
% -------------------------------------------------------------------------
% Outputs:
% -------------------------------------------------------------------------
%
% xParMin:          Free parameters associated with best fitting model
%
% fvalMin:          Best model fit from fval input vector
%
% -------------------------------------------------------------------------
% Examples:
% -------------------------------------------------------------------------
%
% [xParMin, fvalMin] = FindParamMin([.3, .9; .4, .85], [100, 80])
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


nMin = sum(fval == min(fval));

if nMin == 1
    xParMin = xPar(fval == min(fval),:);
    fvalMin = fval(fval == min(fval));
elseif nMin > 1 %Pick the first if there are multiple local min of the same value
    minfval = find(fval == min(fval));
    xParMin = xPar(minfval(1),:);
    fvalMin = fval(minfval(1));
end

end %function end