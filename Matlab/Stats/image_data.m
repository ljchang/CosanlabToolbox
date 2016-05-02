classdef image_data
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % Data class for working with 2D matrices in vector form.  Useful for
    % working with images, or matrices.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2015 Luke Chang
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
        function obj = image_data(varargin)
            class constructor
            
            % check data type
            if nargin == 0
                obj.dat = [];
            else
                
                data = varargin{1};
                
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
                            
                        else
                            data_tmp = data{i};
                        end
                        
                        obj.dat(:,i) = data_tmp(:);
                        obj.transformation = size(data_tmp);
                    end
                else %matrix
                    % transform data into vector
                    obj.dat = data(:);
                    obj.transformation = size(data);
                end
            end
            
            % populate fields
            obj.Y = [];
            obj.X = [];
            obj.fname = [];
        end
        
        function matrix2d = oned2twod(obj,varargin)
            % matrix2d = oned2twod(obj)
            % -------------------------------------------------------------------
            % This function converts 1-D image_data object to 2-D matrix.
            % Will output cell array if multiple data.
            % -------------------------------------------------------------------
            % Optional Input:
            % image number:             Image number to plot (i.e., column)
            % -------------------------------------------------------------------
            
            if nargin > 1
                matrix2d = reshape(obj.dat(:,varargin{1}),obj.transformation);
            else
                if size(obj,2) > 1
                    for i = 1:size(obj,2)
                        matrix2d{i} =  reshape(obj.dat(:,i),obj.transformation);
                    end
                else
                    matrix2d = reshape(obj.dat,obj.transformation);
                end
            end
        end
        
        function obj = plot(obj, varargin)
            % obj = plot(obj, image_number)
            % -------------------------------------------------------------------
            % This function plots the data in matrix form
            % -------------------------------------------------------------------
            % Optional Input:
            % image number:             Image number to plot (i.e., column)
            % 'sig':                    Followed by binary image_data()
            %                           object indicating significant pixels
            % 'line_col:                Followed by Line Color
            % 'line_width':             Follwed by Line Width
            % -------------------------------------------------------------------
            
            % Defaults
            doSig = 0;
            doPlotNum = 0;
            line_color = 'r';
            line_width = 3;
            
            % Parse inputs
            for i = 1:length(varargin)
                if isnumeric(varargin{i})
                    doPlotNum = 1;
                    plotnum = varargin{i};
                    varargin{i} = {};
                end
                if ischar(varargin{i})
                    if strcmpi(varargin(i),'sig')
                        doSig = 1;
                        sig = varargin{i+1};
                        if ~isa(sig,'image_data')
                            error('Make sure ''sig'' is followed by a binary image_data() object indicating areas to threshold')
                        end
                        find_draw_outline = exist('draw_outline');
                        if find_draw_outline ~= 2
                            error('Make sure draw_outline.m is on your path, requires the cosanlab toolbox')
                        end
                        varargin{i} = {}; varargin{i + 1} = {};
                    end
                    
                    if strcmpi(varargin{i},'line_color')
                        line_color = varargin(i+1);
                        varargin{i} = {}; varargin{i + 1} = {};
                    end
                    
                    if strcmpi(varargin{i},'line_width')
                        line_width = varargin(i+1);
                        varargin{i} = {}; varargin{i + 1} = {};
                    end
                end
            end
            
            figure;
            if doPlotNum
                imagesc(oned2twod(obj,plotnum))
            elseif size(obj.dat,2) > 1
                sprintf('Warning: more than one datafile, plotting the first image for now. Please select which image to use.')
                imagesc(oned2twod(obj,1))
            else
                imagesc(oned2twod(obj))
            end
            
            if doSig
                draw_outline(logical(oned2twod(sig)),line_color,line_width)
            end
            
            colorbar
            
        end
        
        function obj = write(obj,varargin)
            % obj = write(obj,file_name)
            % -------------------------------------------------------------------
            % write out object to file.  Will use input file name,
            % otherwise obj.fname.  If there are multiple images, then will
            % write out a separate file for each image (enumerated '_1' ... '_n').
            % -------------------------------------------------------------------
            
            if nargin > 1
                obj.fname = varargin{1};
            end
            
            if size(obj.dat,2)>1
                for i = 1:size(obj.dat,2)
                    tmp_name = strsplit(obj.fname,'.');
                    dlmwrite([tmp_name{1} '_' num2str(i) '.' tmp_name{2}],oned2twod(obj,i))
                end
            else
                dlmwrite(obj.fname,oned2twod(obj))
            end
        end
        
        function stats = regress(obj, varargin)
            % [stats] = regress(obj, Y)
            % -------------------------------------------------------------------
            % Regress obj.Y on obj.dat
            % -------------------------------------------------------------------
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
        
        function mn_obj = mean(obj)
            % obj = mean(obj)
            % -------------------------------------------------------------------
            % Returns mean of image_data() object
            % -------------------------------------------------------------------
            
            mn_obj = obj;
            mn_obj.dat = mean(obj.dat,2);
        end
        
        function dim = size(obj, varargin)
            % dim = size(obj, varargin)
            % -------------------------------------------------------------------
            % Return dimensions of image_data
            % -------------------------------------------------------------------
            % Optional Input: Indicate Dimension(row = 1 or column = 2)
            % -------------------------------------------------------------------
            
            if nargin > 1
                dim = size(obj.dat, varargin{1});
            else
                dim = size(obj.dat);
            end
        end
        
        function c = horzcat(varargin)
            % function c = horzcat(varargin)
            % -------------------------------------------------------------------
            % Implements the horzcat ([a b]) operator on image_data objects across variables.
            % Requires that each object has an equal number of rows
            % -------------------------------------------------------------------
            % Examples:
            % c = [obj1 obj2];
            % -------------------------------------------------------------------
            
            %check if number of rows is the same
            nrow = [];
            for i = 1:nargin
                nrow(i) = size(varargin{i},1);
            end
            for i = 1:nargin
                for j = 1:nargin
                    if nrow(i)~=nrow(j)
                        error('Objects have a different number of rows')
                    end
                end
            end
            
            dat = [];
            for i = 1:nargin
                %Check if image_data object
                if ~isa(varargin{i}, 'image_data')
                    error('Input Data is not an image_data() object')
                end
                dat = [dat, varargin{i}.dat];
            end
            
            c = varargin{1};
            c.dat = dat;
        end
        
        function obj = threshold(obj, threshold, varargin)
            % sig = threshold(obj, pobj, varargin)
            % -------------------------------------------------------------------
            % Create a binary map thresholded on p-value.  Must input
            % object of p-values.
            % -------------------------------------------------------------------
            % Inputs
            % -------------------------------------------------------------------
            % threshold         : p - value to threshold
            % -------------------------------------------------------------------
            % Optional inputs
            % -------------------------------------------------------------------
            % image number      : select image to threshold
            % -------------------------------------------------------------------
            % Output:
            % -------------------------------------------------------------------
            % obj               : binary thresholded object
            % -------------------------------------------------------------------
            
            % Defaults
            doSigNum = 0;
            
            % Parse inputs
            if nargin > 2
                doSigNum = 1;
                signum = varargin{1};
                varargin{1} = {};
            end
            
            if doSigNum
                obj.dat = obj.dat(:,signum);
            end
            
            if size(obj.dat,2) > 1
                sprintf('Warning: more than one datafile, thresholding each image separately')
                for i = 1:size(obj,2)
                    obj.dat(obj.dat(:,i) > threshold,i) = 0;
                    obj.dat(:,i) = logical(obj.dat(:,i));
                end
            else
                obj.dat(obj.dat > threshold) = 0;
                obj.dat = logical(obj.dat);
            end
        end
        
        function obj = convolve_circle(obj, D)
            % sig = convolve_circle(obj, varargin)
            % -------------------------------------------------------------------
            % Convolve object with circle with diameter D
            % -------------------------------------------------------------------
            % Inputs
            % -------------------------------------------------------------------
            % D                 : Diameter in pixels (default = 5)
            % -------------------------------------------------------------------
            % Output:
            % -------------------------------------------------------------------
            % obj               : convolved object
            % -------------------------------------------------------------------
            
            % Defaults
            if nargin < 2
                D = 5;
            end
            
            % Create sphere for convolution
            [rr cc] = meshgrid(1:D+1);
            C = double(sqrt((rr-((D/2)+1)).^2+(cc-((D/2)+1)).^2)<=D/2);
 
            % Convert image_data to cell array and convolve each one
            matrix2d = oned2twod(obj);
            if iscell(matrix2d)
                for i = 1:length(matrix2d)
                    tmp = conv2(matrix2d{i},C,'same');
                    obj.dat(:,i) = tmp(:);
                end
            else
                tmp = conv2(matrix2d,C,'same');
                obj.dat = tmp(:);
            end
            
        end
            
        
    end
end


