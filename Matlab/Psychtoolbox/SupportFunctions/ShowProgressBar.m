function [Onset, Offset, Duration] = ShowProgressBar(time, window, rect, screenNumber, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% [Onset, Offset, Duration] = ShowProgressBar(time, window, rect, screenNumber, varargin)
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
% 'anchor'                  followed by cell array of low and high rating
%                           anchors (e.g., {'0','30'})
% 'increment'               followed by seconds to increment progress bar
%                           (default: 1)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output:
%
% Onset                     Onset of Rating Screen
% Offset                    Offset of Rating Screen
% Duration                  Duration of Rating Screen
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
show_anchor = false;
wait_increment = 1;

% Parse Inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('time', @isnumeric);
ip.addRequired('window', @isnumeric);
ip.addRequired('rect', @isnumeric);
ip.addRequired('screenNumber',@isnumeric);
ip.addParameter('txt','');
ip.addParameter('anchor',{''},@iscell);
% ip.addParameter('increment',{''},@isnumeric);
ip.parse(time, window, rect, screenNumber, varargin{:})
time = ip.Results.time;
window  = ip.Results.window;
rect  = ip.Results.rect;
screenNumber  = ip.Results.screenNumber;
if ~isempty(ip.Results.txt)
    show_text = true;
    txt = ip.Results.txt;
end
if length(ip.Results.anchor) > 1
    show_anchor = true;
    anchor = ip.Results.anchor;
end
% if ~isempty(ip.Results.increment)
%     wait_increment = ip.Results.increment;
% end

% Configure screen
[disp.xcenter, disp.ycenter] = RectCenter(rect);
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
[disp.xcenter, disp.ycenter] = RectCenter(rect);

%%% create Rating screen
disp.scale.width = 964;
disp.scale.height = 252;
disp.scale.w = Screen('OpenOffscreenWindow',screenNumber);

% placement
disp.scale.rect = [[disp.xcenter disp.ycenter]-[0.5*disp.scale.width 0.5*disp.scale.height] [disp.xcenter disp.ycenter]+[0.5*disp.scale.width 0.5*disp.scale.height]];

% determine cursor parameters
cursor.xmin = disp.scale.rect(1) + 123;
cursor.width = 709;
cursor.xmax = cursor.xmin + cursor.width;
cursor.size = 8;
cursor.center = cursor.xmin + ceil(cursor.width/2);
cursor.y = disp.scale.rect(4) - 41;
cursor.labels = cursor.xmin + [10 42 120 249 379];

% Create Rectangle Frame
baseRect = [0 0 cursor.width 50];
RectFrame = CenterRectOnPointd(baseRect, disp.xcenter, disp.ycenter + 100);

% Get Rating Onset Time
Onset = GetSecs;

% Show Ratings
line_array = [];
color_array = [];

tic
for t = 1:time
    % Calculate percentage completed
    pctComplete = t/time;
    
    % Plot rectangle frame
    penWidthPixels = 6;
    Screen('FrameRect', window, [255 255 255], RectFrame, penWidthPixels);
    
    % Fill Rectangle
    baseFill = [0 0 cursor.width * pctComplete, 50];
    RectFill=AlignRect(baseFill,RectFrame,'left','top');
    Screen('FillRect', window, [255 255 255 ], RectFill);
    Screen('Flip',window);
    
    % Add text if requested
    if show_text
        Screen('TextSize',window,36);
        DrawFormattedText(window, txt,'center',disp.scale.height,255);
    end
    
    % Add Anchors if requested
    if show_anchor
        %     Screen('TextFont', window, 'Helvetica Light');
        Screen('TextSize', window, 20);
        DrawFormattedText(window, anchor{1}, cursor.xmin - length(anchor{1})*10 - 30,disp.ycenter + 90, [255 255 255]);
        DrawFormattedText(window, anchor{2}, cursor.xmax + 25,disp.ycenter + 90, [255 255 255]);
    end
    
    % Wait
    WaitSecs(wait_increment)
end

% Get Timing
Offset = GetSecs;
Duration = Offset - Onset;
