classdef image_data
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Data class for working with 2D matrices in vector form.  Useful for
    % working with images, or matrices.
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
    
    properties
        Y
        X
        dat
        fname
        transformation
    end
    
    methods
        function obj = image_data(data)
            class constructor
            
            % check data type
            if ~isnumeric(data) && size(data,1) < 2 && size(data,2) < 2 % matrix
                error('Make sure that you are inputting a numeric matrix')
            elseif isstr(data) %load image if string
                f_exist = exist(data);
                if f_exist == 2
                    data = dlmread(data);
                    
                    % transform data into vector
                    obj.dat = data(:);
                    obj.transformation = size(data);
                else
                    error('File does not exist. Make sure you enter a valid data file.')
                end
            elseif iscell(data)
                for i = 1:length(data)
                    if ~isnumeric(data{i}) && size(data{i},1) < 2 && size(data{i},2) < 2 % matrix
                        error('Make sure that you are inputting a numeric matrix')
                    elseif isstr(data{i}) %load image if string, might need to check if matrix file
                        f_exist = exist(data{i});
                        if f_exist ==2
                            data_tmp = dlmread(data{i});
                        else
                            error('File does not exist. Make sure you enter a valid data file.')
                        end
                    end
                    obj.dat(:,i) = data_tmp(:);
                    obj.transformation = size(data_tmp);
                end
            else %matrix
                % transform data into vector
                obj.dat = data(:);
                obj.transformation = size(data);
            end
            
            % populate fields
            obj.Y = [];
            obj.X = [];
            obj.fname = [];
        end
        
        function obj = plot(obj, varargin)
            % obj = plot(obj, image_number)
            %
            % This function plots the data in matrix form
            % -------------------------------------------------------------------
            % Optional Input:
            % image number:             Image number to plot (i.e., column)
            % -------------------------------------------------------------------
            
            figure;
            if nargin > 1
                imagesc(reshape(obj.dat(:,varargin{1}),obj.transformation))
            elseif size(obj.dat,2) > 1
                sprintf('Warning: more than one datafile, plotting the first image for now. Please select which image to use.')
                imagesc(reshape(obj.dat(:,1),obj.transformation))
            else
                imagesc(reshape(obj.dat,obj.transformation))
            end
            colorbar
            
        end
        
        function obj = write(obj,varargin)
            % obj = write(obj,file_name)
            %
            % write out object to file.  Will use input file name,
            % otherwise obj.fname.  If there are multiple images, then will
            % write out a separate file for each image (enumerated '_1' ... '_n').
            
            if nargin > 1
                obj.fname = varargin{1};
            end
            
            if size(obj.dat,2)>1
                for i = 1:size(obj.dat,2)
                    tmp_name = strsplit(obj.fname,'.');
                    dlmwrite([tmp_name{1} '_' num2str(i) '.' tmp_name{2}],reshape(obj.dat(:,i),obj.transformation))
                end
            else
                dlmwrite(obj.fname,reshape(obj.dat,obj.transformation))
            end
        end
        
        function stats = regress(obj, varargin)
            % [stats] = regress(obj, Y)
            %
            % Regress obj.Y on obj.dat
            %
            % Optional inputs
            % -------------------------------------------------------------------
            % 'robust'          : use robust regression
            % -------------------------------------------------------------------
            % Output:
            % -------------------------------------------------------------------
            % b                 : beta
            % se                : standard error
            % t                 : t-statistic
            % p                 : p-value
            % sigma             : sigma (variance of residual)
            % df                : degrees of freedom
            % -------------------------------------------------------------------
            
            
            % Defaults
            doRobust = 0;
            for i = 1:length(varargin)
                if strcmpi(varargin(i),'robust')
                    doRobust = 1;
                    find_robust = exist('robustfit');
                    if find_robust ~= 2
                        error('Make sure robustfit is on your path, requires the stats toolbox')
                    end
                    varargin(i) = [];
                end
            end
            
            % Grab Design matrix X
            if isa(obj.X,'design_matrix')
                X = obj.X.dat;
            else
                X = obj.X;
            end
            
            % Check to make sure data matches design matrix
            if size(obj.dat, 2) ~= size(X, 1)
                error('dat.dat must have same number of columns as dat.X has rows.')
            end
            
            % Check if Rank Deficient
            if rank(X) < size(X,2)
                sprintf('Warning:  dat.X is rank deficient.')
            end
            
            if ~doRobust %OLS
                
                % Estimate Betas in vector
                [n, k] = size(X);
                b = pinv(X) * obj.dat';
                
                % Error
                r = obj.dat' - X * b;
                sigma = std(r);
                se = ( diag(inv(X' * X)) .^ .5 ) * sigma;  % params x voxels matrix of std. errors
                
                % Inference
                t = b ./ se;
                df = n - k;
                p = 2 * (1 - tcdf(abs(t), df));
                
                sigma(sigma == 0) = Inf;
                t(isnan(t)) = 0;
                p(isnan(p)) = 0;
                df = repmat(df,1,size(t,2));
                
            else %Robust
                for ii = 1:size(obj.dat,1)
                    [b(:,ii), STATS] = robustfit(X, obj.dat(ii,:)',[],[],'off');
                    t(:,ii) = STATS.t;
                    p(:,ii) = STATS.p;
                    df(ii) = STATS.dfe;
                    se(:,ii) = STATS.se;
                    sigma(ii) = STATS.robust_s;
                end
            end
            
            % Collect outputs
            stats.b = obj;
            stats.b.dat = b';
            stats.se = obj;
            stats.se.dat = se';
            stats.sigma = obj;
            stats.sigma.dat = sigma';
            stats.t = obj;
            stats.t.dat = t';
            stats.p = obj;
            stats.p.dat = p';
            stats.df = obj;
            stats.df.dat = df';
        end
        
    end
end


