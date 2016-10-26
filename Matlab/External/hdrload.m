function [header, data] = hdrload(file)


% HDRLOAD Load data from an ASCII file containing a text header.
%     [header, data] = HDRLOAD('filename.ext') reads a data file
%     called 'filename.ext', which contains a text header.  There
%     is no default extension; any extensions must be explicitly
%     supplied.
%
%     The first output, HEADER, is the header information, 
%     returned as a text array.
%     The second output, DATA, is the data matrix.  This data 
%     matrix has the same dimensions as the data in the file, one
%     row per line of ASCII data in the file.  If the data is not
%     regularly spaced (i.e., each line of ASCII data does not 
%     contain the same number of points), the data is returned as
%     a column vector.
%
%     Limitations:  No line of the text header can begin with
%     a number.  Only one header and data set will be read,
%     and the header must come before the data.
%
%     See also LOAD, SAVE, SPCONVERT, FSCANF, FPRINTF, STR2MAT.
%     See also the IOFUN directory.


% check number and type of arguments
if nargin < 1
  error('Function requires one input argument');
elseif ~isstr(file)
  error('Input must be a string representing a filename');
end


% Open the file.  If this returns a -1, we did not open the file 
% successfully.
fid = fopen(file);
if fid==-1
  error('File not found or permission denied');
  end


% Initialize loop variables
% We store the number of lines in the header, and the maximum 
% length of any one line in the header.  These are used later 
% in assigning the 'header' output variable.
no_lines = 0;
max_line = 0;


% We also store the number of columns in the data we read.  This 
% way we can compute the size of the output based on the number 
% of columns and the total number of data points.
ncols = 0;


% Finally, we initialize the data to [].
data = [];


% Start processing.
line = fgetl(fid);
if ~isstr(line)
  disp('Warning: file contains no header and no data')
  end;
[data, ncols, errmsg, nxtindex] = sscanf(line, '%f');


% One slight problem, pointed out by Peter vanderWal: If the 
% first character of the line is 'e', then this will scan as 
% 0.00e+00. We can trap this case specifically by using the 
% 'next index' output: in the case of a stripped 'e' the next 
% index is one, indicating zero characters read.  See the help 
% entry for 'sscanf' for more information on this output 
% parameter. We loop through the file one line at a time until 
% we find some data.  After that point we stop checking for 
% header information. This part of the program takes most of the 
% processing time, because fgetl is relatively slow (compared to 
% fscanf, which we will use later).
while isempty(data)|(nxtindex==1)
  no_lines = no_lines+1;
  max_line = max([max_line, length(line)]);
  % Create unique variable to hold this line of text information.
  % Store the last-read line in this variable.
  eval(['line', num2str(no_lines), '=line;']);
  line = fgetl(fid);
  if ~isstr(line)
    disp('Warning: file contains no data')
    break
    end;
  [data, ncols, errmsg, nxtindex] = sscanf(line, '%f');
  end % while


% Now that we have read in the first line of data, we can skip 
% the processing that stores header information, and just read 
% in the rest of the data. 
data = [data; fscanf(fid, '%f')];
fclose(fid);


% Create header output from line information. The number of lines
% and the maximum line length are stored explicitly, and each 
% line is stored in a unique variable using the 'eval' statement 
% within the loop. Note that, if we knew a priori that the 
% headers were 10 lines or less, we could use the STR2MAT 
% function and save some work. First, initialize the header to an
% array of spaces.
header = setstr(' '*ones(no_lines, max_line));
for i = 1:no_lines
  varname = ['line' num2str(i)];
  % Note that we only assign this line variable to a subset of 
  % this row of the header array.  We thus ensure that the matrix
  % sizes in the assignment are equal. We also consider blank 
  % header lines using the following IF statement.
  if eval(['length(' varname ')~=0'])
    eval(['header(i, 1:length(' varname ')) = ' varname ';']);
    end
  end % for


% Resize output data, based on the number of columns (as returned
% from the sscanf of the first line of data) and the total number
% of data elements. Since the data was read in row-wise, and 
% MATLAB stores data in columnwise format, we have to reverse the
% size arguments and then transpose the data.  If we read in 
% irregularly spaced data, then the division we are about to do 
% will not work. Therefore, we will trap the error with an EVAL 
% call; if the reshape fails, we will just return the data as is.
eval('data = reshape(data, ncols, length(data)/ncols)'';', '');