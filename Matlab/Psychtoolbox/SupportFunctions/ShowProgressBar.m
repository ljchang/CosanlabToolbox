function secRemain = ShowProgressBar(time, window, rect, screenNumber, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% [secRemain] = ShowProgressBar(time, window, rect, screenNumber, varargin)
%
% This function will display a graphical countdown in seconds
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
%
% time                      Amount of time to count down in seconds.
% window                    Window ID of initial screen
% rect                      1 x 4 matrix conatining the coordinates of
%                           box of all pixels
% screenNumber              Psychtoolbox screen display number
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional Input:
%
% 'txt'                     followed by string of text to display above
%                           rating
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output:
%
% RatingOnset               Onset of Rating Screen
% RatingOffset              Offset of Rating Screen
% RatingDuration            Duration of Rating Screen
% Rating                    Continuous Rating between 0 and 100
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

% Defaults
show_text = false;
wait_increment = 1;

% Parse Inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('time', @isnumeric);
ip.addRequired('window', @isnumeric);
ip.addRequired('rect', @isnumeric);
ip.addRequired('screenNumber',@isnumeric);
ip.addParameter('txt','');
ip.parse(time, window, rect, screenNumber, varargin{:})
time = ip.Results.time;
window  = ip.Results.window;
rect  = ip.Results.rect;
screenNumber  = ip.Results.screenNumber;
if ~isempty(ip.Results.txt)
    show_text = 1;
    txt = ip.Results.txt;
end

% Configure screen
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
disp.xcenter = disp.screenWidth/2;
disp.ycenter = disp.screenHeight/2;

%%% create Rating screen
disp.scale.width = 964;
disp.scale.height = 252;
disp.scale.w = Screen('OpenOffscreenWindow',screenNumber);

% placement
disp.scale.rect = [[disp.xcenter disp.ycenter]-[0.5*disp.scale.width 0.5*disp.scale.height] [disp.xcenter disp.ycenter]+[0.5*disp.scale.width 0.5*disp.scale.height]];
% Screen('DrawTexture',disp.scale.w,disp.scale.texture,[],disp.scale.rect);

% determine cursor parameters
cursor.xmin = disp.scale.rect(1) + 123;
cursor.width = 709;
cursor.xmax = cursor.xmin + cursor.width;
cursor.size = 8;
cursor.center = cursor.xmin + ceil(cursor.width/2);
cursor.y = disp.scale.rect(4) - 41;
cursor.labels = cursor.xmin + [10 42 120 249 379];

% Get Rating Onset Time
RatingOnset = GetSecs;

% Show Ratings
line_array = [];
color_array = [];

tic
for t = 1:time
    % Calculate percentage completed
    tmpTime = toc;
    pctComplete = tmpTime/time;
    
    % Starting position (x,y)
    l(1,1) = cursor.xmin;
    l(2,1) = cursor.y;
    
    % Ending position (x,y)
    l(1,2) = cursor.xmin + pctComplete * cursor.width;
    l(2,2) = cursor.y;
    
    % Colors (need to specify separate column for start and stop
    col(:,1) = [255 0 0]; %color
    col(:,2) = [255 0 0 ]; %color
    
    % Plot ratings cursor
    %     Screen('DrawTextures',window,disp.scale.texture,[],disp.scale.rect);
    Screen('DrawLines',window, l, 10,col);
    Screen('Flip',window);
    
    if show_text
        Screen('TextSize',window,36);
        DrawFormattedText(window, txt,'center',disp.scale.height,255);
    end
    
    % Wait
    WaitSecs(wait_increment)
end


