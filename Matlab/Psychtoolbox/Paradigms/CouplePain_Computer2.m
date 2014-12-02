%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run the Social Pain Paradigm for Participant 2
%
% Requires: Psychtoolbox 3, cosanlabtoolbox, and Gstreamer for video input
%           http://psychtoolbox.org/
%           https://github.com/ljchang/CosanlabToolbox
%           http://gstreamer.freedesktop.org/
%
% Developed by Luke Chang, Brianna Robustelli, Mark Whisman, Tor Wager
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

%% Notes

% This paradigm allows a partner to rate how much distress they are feeling
% in response to their partner experiencing pain.  They are asked to rate
% how much pain they feel after ever trial.
%
% Biopac triggering will happen on computer 1 via the parallel port

% Conditions
% 1) Deliver Pain Trials (7?)
% 2) Pain with parter in room but hidden
% 3) pain with partner in room - can see and not talk
% 4) pain with partner can share how feeling
% 5) pain with partner can provide support
% 6) pain with partner can talk only distraction
% 7) pain with partner holding hand
% 8) pain with no partner in room and press button after each pain (message sharing control)


%% GLOBAL PARAMETERS

clear all; close all; fclose all;
fPath = '~/Dropbox/RomanticCouples/CouplesParadigm';
addpath(genpath(fullfile(fPath,'SupportFunctions')));

% random number generator reset
rand('state',sum(100*clock));

% Devices
USE_VIDEO = 0;          % record video of Run
USE_NETWORK = 1;        % refers to Biopac make 0 if not running on computer with biopac

TRACKBALL_MULTIPLIER = 5;

% Timing
PAINDUR = 1;
RATINGDUR = 1;
CUEDUR = 1;
ENDSCREENDUR = 3;
STARTFIX = 1;

% Condition - will be function input
CONDITION = 1;
SUBID = 201;
EXPERIMENTER = 1;

%% PREPARE DISPLAY
% will break with error message if Screen() can't run
AssertOpenGL;

% Here we call some default settings for setting up Psychtoolbox
% PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');
screenNumber = max(screens);

% Prepare the screen
[window rect] = Screen('OpenWindow',screenNumber);
Screen('fillrect', window, screenNumber);
HideCursor;

% Configure screen
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
disp.xcenter = disp.screenWidth/2;
disp.ycenter = disp.screenHeight/2;

%%% create FIXATION screen
disp.fixation.w = Screen('OpenOffscreenWindow',screenNumber);

% paint black
Screen('FillRect',disp.fixation.w,screenNumber);

% add text
Screen('TextSize',disp.fixation.w,60);
DrawFormattedText(disp.fixation.w,'+','center','center',255);

%%% create INSTRUCTIONS screen
halfheight = ceil((0.75*disp.screenHeight)/2);
halfwidth = ceil(halfheight/.75);
disp.instruct.rect = [[disp.xcenter disp.ycenter]-[halfwidth halfheight] [disp.xcenter disp.ycenter]+[halfwidth halfheight]];
disp.instruct.w = Screen('OpenOffscreenWindow',screenNumber);

% paint black
Screen('FillRect',disp.instruct.w,screenNumber);

% add instructions image
image = imread(fullfile(fPath,'SupportFunctions','CameraBase_2_2.png'));
texture = Screen('MakeTexture',window,image);
Screen('DrawTexture',disp.instruct.w,texture,[],disp.instruct.rect)

%%% create Rating screen
disp.scale.width = 964;
disp.scale.height = 252;
disp.scale.w = Screen('OpenOffscreenWindow',screenNumber);

% add scale image
disp.scale.imagefile = fullfile(fPath,'SupportFunctions','bartoshuk_scale.jpg');
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

%%% create ShowFeeling screen
disp.showfeeling.width = 964;
disp.showfeeling.height = 252;
disp.showfeeling.w = Screen('OpenOffscreenWindow',screenNumber);

% add scale image
disp.showfeeling.imagefile = fullfile(fPath,'SupportFunctions','bartoshuk_scale.jpg');
image = imread(disp.showfeeling.imagefile);
disp.showfeeling.texture = Screen('MakeTexture',window,image);

% placement
disp.showfeeling.rect = [[disp.xcenter disp.ycenter]-[0.5*disp.showfeeling.width 0.5*disp.showfeeling.height] [disp.xcenter disp.ycenter]+[0.5*disp.showfeeling.width 0.5*disp.showfeeling.height]];
Screen('DrawTexture',disp.showfeeling.w,disp.showfeeling.texture,[],disp.showfeeling.rect);

% Add text
% [newX,newY]=Screen('DrawText', disp.share, text [,x] [,y] [,color] [,backgroundColor] [,yPositionIsBaseline] [,swapTextDirection]);
% [newX,newY]=Screen('DrawText', disp.share, );
% Screen('TextSize',disp.fixation.w,60);
DrawFormattedText(disp.share.w,'This is how your partner wanted you to know how they are feeling.  Press space to acknowledge message and proceed.','top','center',255);


% determine cursor parameters
cursor.xmin = disp.showfeeling.rect(1) + 123;
cursor.width = 709;
cursor.xmax = cursor.xmin + cursor.width;
cursor.size = 8;
cursor.center = cursor.xmin + ceil(cursor.width/2);
cursor.y = disp.showfeeling.rect(4) - 41;
cursor.labels = cursor.xmin + [10 42 120 249 379];

% Make a base Rect of 200 by 200 pixels
baseMark = [0 0 20 20];

%%% create a stimulation screen
disp.stimulation.w = Screen('OpenOffscreenWindow',screenNumber);
% paint black
Screen('FillRect',disp.stimulation.w,screenNumber);
Screen('TextSize',disp.stimulation.w,50);
DrawFormattedText(disp.stimulation.w,'Partner is receiving pain','center','center',255);

% clean up
clear image texture

%% Instructions

% instructions= sprintf('During this task you will see different images.\nYou will be asked questions about these images later.\nPlease remain still and alert, and get ready to begin.');
% waitScan='Wait for scanner...';
% % waitExper='Wait for experimenter...';
% endrun='Thank you. You have completed the experiment.';
% fixation='+';

%% PREPARE FOR INPUT
% Enable unified mode of KbName, so KbName accepts identical key names on
% all operating systems:
KbName('UnifyKeyNames');

% % define keys
key.space = KbName('SPACE');
key.ttl = KbName('5%');
key.s = KbName('s');
key.p = KbName('p');
key.esc = KbName('ESCAPE');

%% PREPARE DEVICES

if USE_VIDEO
    vid = videoinput('macvideo', 1);
    set(vid, 'FramesPerTrigger', Inf);
    set(vid, 'ReturnedColorspace', 'rgb');
    set(vid,'LoggingMode','disk');
    mp4 = VideoWriter(fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '.mp4']),'MPEG-4');
    mp4.FrameRate = 12;
    set(vid,'DiskLogger',mp4);
    vid.FrameGrabInterval = 1;  % distance between captured frames
end

if USE_NETWORK
    
    % Setup Screens
    disp.ipaddress.w = Screen('OpenOffscreenWindow',screenNumber);
    Screen('FillRect',disp.ipaddress.w,screenNumber);
    Screen('TextSize',disp.ipaddress.w,30);
    disp.ipaddresstest.w = Screen('OpenOffscreenWindow',screenNumber);
    Screen('FillRect',disp.ipaddresstest.w,screenNumber);
    Screen('TextSize',disp.ipaddresstest.w,30);
    
    % Get IP address of local computer to display on screen
    address = java.net.InetAddress.getLocalHost;
    IPaddress = char(address.getHostAddress);
    
    %%% create check IP Address Screen
    % paint black
    DrawFormattedText(disp.ipaddress.w,['IP Address of Computer 2 Server:\n\n' IPaddress '\n\nWaiting for Response from Computer 1 Client'],'center','center',255);
    Screen('CopyWindow',disp.ipaddress.w,window);
    Screen('Flip',window);
    connection = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');
    fopen(connection)
    
    %%% Test Connection
    nTrials = WaitForInput(connection, 5);
    if ~isnan(nTrials)
        DrawFormattedText(disp.ipaddresstest.w,['Test Sucessful!\n\nConnection to Client Computer Established.\n\nWill run paradigm with ' num2str(nTrials) ' trials.'],'center','center',255);
        Screen('CopyWindow',disp.ipaddresstest.w,window);
        Screen('Flip',window);
    else
        DrawFormattedText(disp.ipaddresstest.w,'Testing connection unsuccessful.\n\n Will now end experiment','center','center',255);
        Screen('CopyWindow',disp.ipaddresstest.w,window);
        Screen('Flip',window);
        WaitSecs(3);
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        sca;
        return;
    end
    
    % Send Signal to Computer 1 to proceed
    fwrite(connection,1)
    
    % Set up Rating screen
    % determine cursor parameters
    cursor.xmin = disp.scale.rect(1) + 123;
    cursor.width = 709;
    cursor.xmax = cursor.xmin + cursor.width;
    cursor.size = 8;
    cursor.center = cursor.xmin + ceil(cursor.width/2);
    cursor.y = disp.scale.rect(4) - 41;
    cursor.labels = cursor.xmin + [10 42 120 249 379];
    
    % create array of random starting cursor positions
    for s = 1:nTrials
        ok = false;
        while ~ok
            if mod(s,2)
                cursor.start(s) = round(rand(1)*0.4*cursor.width);
            else
                cursor.start(s) = round(rand(1)*-0.4*cursor.width);
            end
            ok = true;
            for i = 1:numel(cursor.labels)
                if abs((cursor.center+cursor.start(s))-(cursor.xmin+cursor.labels(i))) <= 5
                    ok = false;
                end
            end
        end
    end
    cursor.start = Shuffle(cursor.start);
    
end

%% Run Script

% Check if data file exists.  If so ask if we want to rerun, if not then quit and check subject ID.
file_exist = exist(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']),'file');
ListenChar(2); %Stop listening to keyboard
if file_exist == 2
    exist_text = ['WARNING!\n\nA data file exists for Subject - ' num2str(SUBID) ' Condition - ' num2str(CONDITION) '\nPress ''q'' to quit or ''p'' to proceed'];
    Screen('TextSize',window, 50);
    DrawFormattedText(window,exist_text,'center','center',255);
    Screen('Flip',window);
    keycode(key.q) = 0;
    keycode(key.p) = 0;
    while(keycode(key.p) == 0 && keycode(key.q) == 0)
        %     while any(keycode)
        [presstime keycode delta] = KbWait;
    end
    
    % ESC key quits the experiment, 'p' proceeds
    if keycode(key.q) == 1
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        sca;
        return;
    end
end
ListenChar(1); %Start listening to keyboard again.

%Initialize File with Header - need to get condition information from Computer 1
if ~USE_NETWORK
    switch CONDITION
        case 1,2,3,7
            hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings = nan(1,19);
        case 4
            hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings = nan(1,23);
        case 8
            hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,ShareOnset,ShareOffset,ShareDur,ShareRating,,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur,RandomNumber';
            timings = nan(1,24);
        case 5,6
    end
else
    hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur,P2StartFixation,P2StimulationOnset, P2StimulationOffset,P2StimulationDuration,P2RatingOnset,P2RatingOffset,P2RatingDuration,P2Rating';
    timings = nan(1,30);
end

% initialize
Screen('TextSize',window,72);
DrawFormattedText(window,'.','center','center',255);
Screen('Flip',window);

% put up instruction screen
Screen('CopyWindow',disp.instruct.w,window);
Screen('Flip',window);
% wait for experimenter to press spacebar
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

% ready screen
Screen('TextSize',window,72);
DrawFormattedText(window,'Ready','center','center',255);
Screen('Flip',window);

%%% Need to wait for signal from other computer to begin
% add screen to say waiting for partner to begin
% add button press to ready screen.

% Wait for start signal from Computer 1
start = nan;
while start ~= 111
    start = WaitForInput(connection, 10);
end
timings = nan(1,8);

%Start Video Recording
if USE_VIDEO
    StillRunning = isrunning(vid);
    if ~StillRunning
        start(vid);
        tic %Record times
    end
end

% put up fixation
Screen('CopyWindow',disp.fixation.w,window);
startfix = Screen('Flip',window);
timings(1) = startfix;
% WaitSecs(STARTFIX);

t = 1;
while t <= nTrials
    
    % Wait for incoming data from computer 1;
    incoming_data = WaitForInput(connection, 2);
    trial = incoming_data(1);
    condition = incoming_data(2);
    trial_part = incoming_data(3);
    
    switch condition
        case 1,2,3,4
            switch trial_part
                case 2 %Stimulation
                    
                    %%% STIM
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    Screen('CopyWindow',disp.stimulation.w,window);
                    %                     Screen('TextSize',window,72);
                    %                     DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                    timings(2) = Screen('Flip',window);
                    
                    % Wait for stop signal from Computer 1
                    stop = nan;
                    while stop ~= 222
                        stop = WaitForInput(connection, 2);
                    end
                    
                    timings(3) = GetSecs;
                    timings(4) = timings(3) - timings(2);
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                case 3 %Rating stage
                    
                    %%% RATING
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber);

                    % Send trial data to Computer 1
                    % timings = [startfixation stimulation onset, stimulation offset, stimulation duration, rating onset, rating offset, rating duration, rating]
                    fwrite(connection, timings,'double')
                    
                    % We need to write out data for computer 2 similar to
                    % computer 1 (look at other script for example)
                    
                    % only send rating information to computer 1, or figure
                    % out how to deal with max numbers greater than 255.
                    % Also it would be nice to have decimal information.
                  
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    %%% End of Trial
                    t = t+1; %Update trial count for main while loop
                    
                case 4 %Share how partner is feeling
                    
                    %%% Share Feeling
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    Screen('CopyWindow',disp.stimulation.w,window);
                    Screen('DrawTextures',window,disp.showfeeling.texture,[],disp.scale.rect);
                    Screen('DrawTextures',window,disp.showfeeling.texture,[],disp.showfeeling.rect);
                    Screen('DrawLine',window,[255 0 0],incoming_data(4),cursor.y-(ceil(.107*(cursor.x-cursor.xmin)))-5,cursor.x,cursor.y+10,5);
%                     Screen('DrawLine',window,[255 0 0],cursor.x,cursor.y-(ceil(.107*(cursor.x-cursor.xmin)))-5,cursor.x,cursor.y+10,3);
                    Screen('Flip',window);
                    
                    % Get Rating Onset Time
                    timings(5) = GetSecs;
                    
                    % wait for participant to acknowledge response
                    keycode(key.space) = 0;
                    while keycode(key.space) == 0
                        [timings(6) keycode delta] = KbWait;
                    end
                    timings(7) = timings(6) - timings(5);
                    timings(8) =(cursor.x-cursor.xmin)/7;
                    WaitSecs(.25);
                    
                    % Send trial data to Computer 1
                    % timings = [startfixation stimulation onset, stimulation offset, stimulation duration, rating onset, rating offset, rating duration, rating]
                    fwrite(connection, timings,'double')
                    
                    % We need to write out data for computer 2 similar to
                    % computer 1 (look at other script for example)
                    
                    % only send rating information to computer 1, or figure
                    % out how to deal with max numbers greater than 255.
                    % Also it would be nice to have decimal information.
                    
            end
    end
    %%% Fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('CopyWindow',disp.fixation.w,window);
    Screen('Flip',window);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% END SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('TextSize',window,72);
DrawFormattedText(window,'END','center','center',255);
WaitSecs('UntilTime',ENDSCREENDUR);
timing.endscreen = Screen('Flip',window);
WaitSecs(3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%

sca
