classdef design_matrix
    % design_matrix: data class for creating a design matrix to be used with a linear model including fmri data.
    %
    %
    % Inputs:
    % ---------------------------------------------------------------------
    % dat                       : M x N numeric matrix containing Observations and Variables
    %
    % varname                   : Cell array containing variable names.  Must
    %                             match number of column in data matrix
    %
    % Examples:
    % ---------------------------------------------------------------------
    % DM = design_matrix([ones(10,1), (1:10)', (1:10).^2'],{'Intercept','X','X2'})
    %
    % Original version: Copyright Luke Chang 2/2014
    
    % Notes:
    % Need to add these Methods:
    % -create regressor from stim times
    % -pca
    
    properties
        dat = [];
        varname = {};
        fname = '';
    end
    
    methods
        function obj = design_matrix(dat, varname)
            class constructor
            
            % Initialize instance of design_matrix
            
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
        
        function names(obj)
            % List variable names for each regressor
            display(obj.varname)
        end
        
        function dim = size(obj, varargin)
            % Return dimensions of design matrix
            % Optional Input: Indicate Dimension(row = 1 or column = 2)
            
            if nargin > 1
                dim = size(obj.dat, varargin{1});
            else
                dim = size(obj.dat);
            end
        end
        
        function plot(obj)
            % Plot design matrix
            imagesc(obj.dat)
        end
        
        function save(obj, fname)
            save(fname, obj)
        end
        
        function obj = addvariable(obj, x, varargin)
            % Add regressor to design matrix
            %
            % optional inputs
            % -------------------------------------------------------------------
            % 'Name'        : 'Name' followed by Variable name
            %                  Default is 'newVx'
            %
            % 'Order'       : 'Order' followed by where to insert new data columns location
            %                  Default is end
            
            % Check Inputs
            if size(x,1) ~= size(obj,1)
                error('Make sure new variable column is the same length as design matrix')
            end
            
            % Defaults
            for i = 1:size(x,2)
                newname{i} = ['newV' num2str(i)];
            end
            isnewname = 0;
            varorder = size(obj,2); %add to end
            
            % Parse inputs
            % -------------------------------------------------------------------
            for varg = 1:length(varargin)
                if ischar(varargin{varg})
                    % reserved keywords
                    if strcmpi('name',varargin{varg})
                        if ischar(varargin{varg + 1}) && length(varargin{varg + 1}) == size(x,2)
                            newname = varargin{varg + 1};
                            isnewname = 1;
                        else
                            error('Make sure ''Name'' is follwed by a valid variable name')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                    
                    if strcmpi('order',varargin{varg})
                        if isnumeric(varargin{varg + 1}) && varargin{varg + 1} <= size(obj,2)
                            varorder = varargin{varg + 1};
                        else
                            error('Make sure ''Order'' is follwed by a valid column number')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                end
            end
            % -------------------------------------------------------------------
            
            % Update Name vector if not empty
            if ~isempty(obj.varname)
                if varorder == 1 %begin
                    obj.varname = [newname, obj.varname];
                elseif varorder == size(obj,2) %end
                    obj.varname = [obj.varname, newname];
                else %Somewhere inbetween
                    obj.varname = [obj.varname(1:varorder), newname, obj.varname(varorder + 1 : end)];
                end
            end
            
            % Add new variables to design Matrix
            if varorder == 1 %begin
                obj.dat = [x, obj.dat];
            elseif varorder == size(obj,2) %end
                obj.dat = [obj.dat, x];
            else %Somewhere inbetween
                obj.dat = [obj.dat(:,1:varorder), x, obj.dat(:,varorder + 1 : end)];
            end
        end
        
        function obj = zscore(obj, varargin)
            % Standardize columns of design matrix
            %
            % optional inputs
            % -------------------------------------------------------------------
            % 'center'        : Only remove mean, don't standardize
            
            % Defaults
            center = 0; %Only remove mean
            
            % optional inputs
            % -------------------------------------------------------------------
            for varg = 1:length(varargin)
                if ischar(varargin{varg})
                    % reserved keywords
                    if strcmpi('center',varargin{varg})
                        center=1;
                        varargin{varg} = {};
                    end
                end
            end
            % -------------------------------------------------------------------
            
            if center
                obj.dat = obj.dat - repmat(mean(obj.dat),size(obj,1),1);
            else
                obj.dat = zscore(obj.dat);
            end
        end
        
        function obj = removevariable(obj, x)
            % Remove columns from design_matrix
            %
            % Inputs
            % -------------------------------------------------------------------
            % x             : Input vector of columns to remove
            
            obj.dat(:,x) = [];
            obj.varname(x) = [];
        end
        
        function obj = addintercept(obj)
            % Add intercept to design matrix
            
            %Check if Intercept exists
            if sum(strcmpi(obj.varname,'intercept')) > 0
                error('Intercept Name already included in obj.varname')
            end
            
            %Check if any variable only includes ones
            for i = 1:size(obj,2)
                if sum(obj.dat(:,i)==1) == size(obj,1)
                    error('There is already a column of ones that resembles an intercept')
                end
            end
            
            obj.dat = [obj.dat, ones(size(obj,1),1)];
            obj.varname = [obj.varname, 'Intercept'];
        end
        
        function obj = removeintercept(obj)
            % Remove intercept from design matrix
            
            %Check if any variable only includes ones or if intercept is in varname
            for i = 1:size(obj,2)
                whereint(i) = sum(obj.dat(:,i)==1) == size(obj,1);
            end
            if sum(whereint) == 0
                error('There does not appear to be any column of ones that resembles an intercept')
            elseif sum(strcmpi('intercept',obj.varname)) == 0
                error('Intercept Name is not included in obj.varname')
            end
            
            % now remove intercept
            obj.dat(:,whereint) = [];
            obj.varname(whereint) = [];
        end
        
        function vif = vif(obj, varargin)
            % Check for multicollinearity by getting variance inflation factors
            %
            % See original getvif.m in canlab repository - OptimizeDesign11/core_functions/getvif.m
            %
            % optional inputs
            % -------------------------------------------------------------------
            % 'nointercept'       : Remove intercept (turned off by default)
            
            % Defaults
            noint = 0;
            if strcmpi('nointercept',varargin)
                noint = 1;
            end
            
            %Remove intercept if asked
            if noint
                obj = removeintercept(obj);
            end
            
            %Calculate VIF
            for i = 1:size(obj.dat,2)
                X = obj.dat;
                y = X(:,i);
                X(:,i) = [];
                b = X\y;
                fits = X * b;
                rsquare = var(fits) / var(y);
                
                if rsquare == 1,rsquare = .9999999;end
                
                vif(i) = 1 / (1 - rsquare);
            end
        end
        
        function r = corr(obj)
            % Calculate pairwise correlation of regressors in design_matrix
            
            r = corr(obj.dat);
        end
        
        function obj = normalizedrank(obj, varargin)
            % Rank each regressor and normalize between [0,1]
            %
            % See normalizedrank.m for optional inputs
            
            obj.dat = normalizedrank(obj.dat, varargin);
        end
        
        function obj = conv_hrf(obj, varargin)
            % Convolve each regressors with hemodynamic response function
            % Uses spm_hrf.m
            %
            % optional inputs
            % -------------------------------------------------------------------
            % 'tr'           : Input TR to use for creating HRF
            %                  (e.g., 'tr', 3)
            %
            % 'select'       : Select Input vector of regressors to convolve
            %                  (e.g., 'select', [2,4])
            
            % Defaults
            include = (1:size(obj,2)); %Convolve entire Design Matrix by default
            tr = 2;
            
            % Check if spm_hrf is on path
            checkspm =  which('spm_hrf.m');
            if isempty(checkspm), error('Make sure spm is in matlab path'); end
            
            % Parse inputs
            % -------------------------------------------------------------------
            for varg = 1:length(varargin)
                if ischar(varargin{varg})
                    % reserved keywords
                    if strcmpi('tr',varargin{varg})
                        if isnumeric(varargin{varg + 1})
                            tr = varargin{varg + 1};
                        else
                            error('Make sure ''tr'' is followed by valid number')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                    
                    if strcmpi('select',varargin{varg})
                        if isnumeric(varargin{varg + 1}) && varargin{varg + 1} <= size(obj,2)
                            include = varargin{varg + 1};
                        else
                            error('Make sure ''select'' is followed by a valid column number')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                end
            end
            % -------------------------------------------------------------------
            
            %Convolution of task
            for i = 1:length(include)
                convdat = conv(obj.dat(:,include(i)),spm_hrf(tr));
                %Cut off extra data from convolution
                obj.dat(:,include(i)) = convdat(1:size(obj,1));
            end
        end
        
        function obj = hpfilter(obj, varargin)
            % Add High pass filter design matrix using spm's discrete
            % cosine Transform (spm_filter.m)
            %
            % optional inputs
            % -------------------------------------------------------------------
            % 'tr'           : Input TR to use for creating HRF
            %                  (e.g., 'tr', 3) Default = 2;
            %
            % 'duration'     : Duration of high pass filter in seconds
            %                  (e.g., 'duration', 100) Default = 180;
            
            % Defaults
            tr = 2;
            filterlength = 180;
            
            % Check if spm_hrf is on path
            checkspm =  which('spm_filter.m');
            if isempty(checkspm), error('Make sure spm is in matlab path'); end
            
            % Parse inputs
            % -------------------------------------------------------------------
            for varg = 1:length(varargin)
                if ischar(varargin{varg})
                    % reserved keywords
                    if strcmpi('tr',varargin{varg})
                        if isnumeric(varargin{varg + 1})
                            tr = varargin{varg + 1};
                        else
                            error('Make sure ''tr'' is followed by valid number')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                    if strcmpi('duration',varargin{varg})
                        if isnumeric(varargin{varg + 1})
                            filterlength = varargin{varg + 1};
                        else
                            error('Make sure ''duration'' is followed by valid number')
                        end
                        varargin{varg} = {}; varargin{varg + 1} = {};
                    end
                end
            end
            % -------------------------------------------------------------------
            
            %create high pass filter
            K.RT = tr;
            K.row = 1:size(obj,1);
            K.HParam = filterlength;
            nK = spm_filter(K);
            if isempty(nK.X0), error('Check if filter duration is too long'); end
            
            %Add filter to design_matrix
            obj.dat = [obj.dat, nK.X0];
            
            %Add variable names
            for i = 1:size(nK.X0,2)
                filtname{i} = ['hpfilter' num2str(i)];
            end
            obj.varname = [obj.varname, filtname];
        end
        
        function [B,BINT,R,RINT,STATS] = regress(obj, Y)
            % Regress design matrix on vector Y
            % Uses matlab's regress function
            
            [B,BINT,R,RINT,STATS] = regress(Y, obj.dat);
        end
        
        function obj = onsettimes(obj, onset, names, tr, timing )
            %Create stimulus regressor from onset times
            %
            % Inputs
            % -------------------------------------------------------------------
            % onset        : Input cell array of onset times for each
            %                   regressor in FSL's 3 column format (e.g., onset in sec, duration in sec, weight).
            %
            % names        : Cell array of variable names corresponding
            %                to each onset cell (e.g., {'BlueOn','RedOn'})
            %
            % tr           : Repetition time (e.g., 2)
            %
            % timing       : Timing converstion from onset array to design matrix
            %                  (e.g., 'sec2tr','tr2sec','sec2sec',or
            %                  'tr2tr'). Need to know which format each
            %                  array is in.

            %Convert Onset Times Into Boxcar Regressors
            r = zeros(size(obj,1),length(onset));
            for i = 1:length(onset)
                for j = 1:size(onset{i},1)
                    switch timing
                        case 'sec2tr'
                            if floor(onset{i}(j,1)/tr) == 0
                                r(1 : 1 + ceil(onset{i}(j,2)), i) = onset{i}(j,3);
                            else
                                r(floor(onset{i}(j,1) / tr) : floor(onset{i}(j,1) / tr) + ceil(onset{i}(j,2) / tr) - 1, i) = onset{i}(j,3);
                            end
                        case 'tr2sec'
                            r(floor(onset{i}(j,1) * tr) : floor(onset{i}(j,1) * tr) + ceil(onset{i}(j,2) * tr) - 1, i) = onset{i}(j,3);
                        case {'sec2sec', 'tr2tr'}
                            r(floor(onset{i}(j,1)) : floor(onset{i}(j,1)) + ceil(onset{i}(j,2)) - 1, i) = onset{i}(j,3);
                    end
                end
            end 
            obj.dat = [obj.dat, r];
            
            %Add Variable names
            obj.varname = [obj.varname, names];
        end
        
    end %methods
end %class