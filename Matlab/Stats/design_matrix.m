classdef design_matrix
% design_matrix: data class for creating a design matrix to be used with a linear model including fmri data.
%
% Example: DM = design_matrix({'Intercept','X','X2'},[ones(10,1), (1:10)', (1:10).^2'])

% vrc = CalinskiHarabasz(X, IDX, C, SUMD)
%
% Inputs:
% ---------------------------------------------------------------------
% dat                       : M x N numeric matrix containing Observations and Variables 
%
% varname                   : Cell array containing variable names.  Must
%                             match number of column in data matrix
%
%
% Examples:
% ---------------------------------------------------------------------
% DM = design_matrix({'Intercept','X','X2'},[ones(10,1), (1:10)', (1:10).^2'])
%
% Original version: Copyright Luke Chang 2/2014
    properties
        dat = [];
        varname = {};
        fname = '';
    end
    
    methods
        function obj = design_matrix(dat, varname)
            class constructor

            %initialize instance of design_matrix
            
            if(nargin > 1)
                try
                    if(~ismatrix(dat) || ~isnumeric(dat) || iscell(dat))
                        error('Make sure input data is a matrix')
                    end
                    if(length(varname) ~= size(dat,2) || ~iscell(varname));
                        error('Make sure the number of variable names corresponds to number of data columns.')
                    end
                    obj.dat = dat;
                    obj.varname = varname;
                catch err
                    error('Make sure input variable names are in a cell array with length equal to number of data columns and data is a matrix.')
                end
                obj.varname = varname;
            elseif(nargin > 0)
                try
                    if(~ismatrix(dat) || ~isnumeric(dat) || iscell(dat))
                        error('Make sure input data is a matrix')
                    end
                    obj.dat = dat;
                catch
                    error('Make sure input data is a matrix')
                end
            end
        end
        
        function [row, column] = size(obj)
            %Return dimensions of design matrix
            [row, column] = size(obj.dat);
        end
        
        function plot(obj)
            %Plot design matrix
            imagesc(obj.dat)
        end
        
        function save(obj, fname)
            save(fname, obj)
        end
        
        function names(obj)
            %List variable names for each regressor
            display(obj.varname)
        end
        
        function addvariable()
            %add regressor
        end
        %function plot, glm, filter, convolve, zscore, save, load, add regressor
        %using stim, glm, size
        %
        
    end %methods
end %class