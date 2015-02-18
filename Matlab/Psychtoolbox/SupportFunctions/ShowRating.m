function [RatingOnset RatingOffset RatingDuration] = ShowRating(rating, screenduration, window, rect, screenNumber, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% [RatingOnset RatingOffset RatingDuration ] = ShowRating()
%
% This function uses the bartoshuk logarithmic or linear rating scale to depict a
% continuous rating.  See GetRating.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
%
% rating                    a vector of ratings to plot (e.g., [.2,.5]).
% duration                  number of seconds to show rating.  If
%                           screenduration = 0, then will require button press to continue
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
% 'type'                    followed by 'linear' or 'log' or 'line' to
%                           indicate type of rating scale.  Default is
%                           line.
% 'anchor'                  followed by cell array of low and high rating
%                           anchors (e.g., {'None','A lot'}
% 'txtSize'                 followed by size to display text
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
show_text = 0;
show_anchor = 0;

% Parse Inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('rating', @isnumeric);
ip.addRequired('screenduration', @isnumeric);
ip.addRequired('window', @isnumeric);
ip.addRequired('rect', @isnumeric);
ip.addRequired('screenNumber',@isnumeric);
ip.addParameter('txt','');
checkType = @(t) any(strcmpi(t,{'line','linear','log'}));
ip.addParameter('type','line',checkType);
ip.addParameter('anchor',{''},@iscell);
ip.addParameter('txtSize',@isnumeric)
ip.parse(rating,screenduration,window, rect, screenNumber, varargin{:})
rating = ip.Results.rating;
screenduration = ip.Results.screenduration;
window  = ip.Results.window;
rect  = ip.Results.rect;
screenNumber  = ip.Results.screenNumber;
img_type = ip.Results.type;
anchor = ip.Results.anchor;
txtSize = ip.Results.txtSize;
if ~isempty(ip.Results.txt)
    show_text = 1;
    txt = ip.Results.txt;
end
if length(ip.Results.anchor) > 1
    show_anchor = 1;
    anchor = ip.Results.anchor;
end
if ~isempty(ip.Results.txtSize)
    txtSize = ip.Results.txtSize;
else
    txtSize = 32;
end


% Check that image is on path
switch img_type
    case 'log'
        try
            img_file = which('bartoshuk_scale.jpg');
        catch
            error('Make sure bartoshuk_scale.jpg is on your path')
        end
    case 'linear'
        try
            img_file = which('linear_scale.jpg');
        catch
            error('Make sure linear_scale.jpg is on your path')
        end
    case 'line'
        try
            img_file = which('line_scale.jpg');
        catch
            error('Make sure line_scale.jpg is on your path')
        end
end

% Colors
rgb = [255 0 0; 0 255 0; 0 0 255; 0 128 128; 128 128 0; 128 0 128;  0 64 192; 192 64 0; 64 192 0; 64 0 192; 192 0 64];

% Configure screen
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
disp.xcenter = disp.screenWidth/2;
disp.ycenter = disp.screenHeight/2;

%%% create Rating screen
disp.scale.width = 964;
disp.scale.height = 252;
disp.scale.w = Screen('OpenOffscreenWindow',screenNumber);

% add scale image
disp.scale.imagefile = which(img_file);
image = imread(disp.scale.imagefile);
disp.scale.texture = Screen('MakeTexture',window,image);

% placement
disp.scale.rect = [[disp.xcenter disp.ycenter]-[0.5*disp.scale.width 0.5*disp.scale.height] [disp.xcenter disp.ycenter]+[0.5*disp.scale.width 0.5*disp.scale.height]];
Screen('DrawTexture',disp.scale.w,disp.scale.texture,[],disp.scale.rect);

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
for i = 1:length(rating)
    
    % Generate random color if more than 11 variables to plot
    if i > size(rgb,1)
        rgb(i,:) = round(rand(1,3)*255);
    end
    
    %     % check bounds
    %     if cursor.x > cursor.xmax
    %         cursor.x = cursor.xmax;
    %     elseif cursor.x < cursor.xmin
    %         cursor.x = cursor.xmin;
    %     end
    
    % Starting position (x,y)
    l(1,1) = cursor.xmin + (rating(i)*cursor.width);
    l(2,1) = cursor.y - 42;
    
    % Ending position (x,y)
    l(1,2) = cursor.xmin + (rating(i)*cursor.width);
    l(2,2) = cursor.y + 17;
    line_array = [line_array l];
    
    % Colors (need to specify separate column for start and stop
    col(:,1) = rgb(i,:); %color
    col(:,2) = rgb(i,:); %color
    color_array = [color_array col];
end

% Plot ratings cursor
Screen('DrawTextures',window,disp.scale.texture,[],disp.scale.rect);
if img_type == 'line'
    Screen('DrawLines',window, line_array, 5,color_array);
else %change size
    Screen('DrawLines',window, line_array, 4,color_array);
    %     Screen('DrawLine',window,rgb(i,:),cursor.x,cursor.y-(ceil(.107*(cursor.x-cursor.xmin)))-5,cursor.x,cursor.y+10,3);
end

if show_text
    Screen('TextSize',window,txtSize);
    DrawFormattedText(window, txt,'center',disp.scale.height,255);
end

if show_anchor     %Show Anchor
    %     Screen('TextFont', window, 'Helvetica Light');
    Screen('TextSize', window, 20);
    DrawFormattedText(window, anchor{1}, cursor.xmin - length(anchor{1})*10 - 40,cursor.y - 25, [255 255 255]);
    DrawFormattedText(window, anchor{2}, cursor.xmax + 25,cursor.y - 25, [255 255 255]);
end

Screen('Flip',window);

if screenduration == 0
    [presstime keycode delta] = KbWait;
else
    WaitSecs(screenduration);
end

RatingOffset = GetSecs;
RatingDuration = RatingOffset - RatingOnset;

