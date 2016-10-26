%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run the Social Pain Paradigm for Participant 2
%
% Requires: Psychtoolbox 3, cosanlabtoolbox, and Gstreamer for video input
%           http://psychtoolbox.org/
%           https://github.com/ljchang/CosanlabToolbox
%           http://gstreamer.freedesktop.org/
%
% Developed by Luke Chang, Briana Robustelli, Mark Whisman, Tor Wager
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2014 Luke Chang
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (theco
% "Software"),co
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
% 1) Pain with partner not in room
% 2) Pain with parter in room but hidden
% 3) pain with partner in room - can see and not talk
% 4) pain with partner in room and press button after each pain (message sharing control)
% 5) pain with partner can share how feeling
% 6) pain with partner can talk only distraction
% 7) pain with partner can provide support
% 8) pain with partner holding hand
% 9) Pain with partner not in room

%% Testing Settings

commandwindow;
ShowCursor;
screens = Screen('Screens');
% screenNumber = min(screens);
% [window rect] = Screen('OpenWindow', screenNumber, 0, [800 0 1600 600]);

%% GLOBAL PARAMETERS

clear all; close all; fclose all;
% fPath = '/Users/lukechang/Dropbox/RomanticCouples/CouplesParadigm';
% cosanlabToolsPath = '/Users/lukechang/Dropbox/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
fPath = '/Users/canlab/Documents/RomanticCouples';
cosanlabToolsPath = '/Users/canlab/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

% random number generator reset
rand('state',sum(100*clock));

% Devices
USE_VIDEO = 1;          % record video of Run
USE_NETWORK = 1;        % refers to Biopac make 0 if not running on computer with biopac

TRACKBALL_MULTIPLIER = 5;

% Timing
PAINDUR = 1;
RATINGDUR = 1;
CUEDUR = 1;
ENDSCREENDUR = 4;
STARTFIX = 1;
FEEDBACKDUR = 0;  % Will wait for button press

% Settings
text_size = 28;
anchor_size = 20;

%% PREPARE DISPLAY
% % will break with error message if Screen() can't run

Screen('Preference', 'SkipSyncTests', 0);
AssertOpenGL;

% Here we call some default settings for setting up Psychtoolbox
% PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');
screenNumber = max(screens);


% Prepare the screen
[window rect] = Screen('OpenWindow',screenNumber);
% [window rect] = Screen('OpenWindow', screenNumber, 0, [0 0 1200 700]);
Screen('fillrect', window, screenNumber);
% HideCursor;

% Configure screen
disp.screenWidth = rect(3);
disp.screenHeight = rect(4);
disp.xcenter = disp.screenWidth/2;
disp.ycenter = disp.screenHeight/2;

%%% create FIXATION screen
disp.fixation.w = Screen('OpenOffscreenWindow',screenNumber);
Screen('FillRect',disp.fixation.w,screenNumber); % paint black
Screen('TextSize',disp.fixation.w,60);
DrawFormattedText(disp.fixation.w,'+','center','center',255); % add text


%%% create INSTRUCTIONS screen
halfheight = ceil((0.75*disp.screenHeight)/2);
halfwidth = ceil(halfheight/.75);
disp.instruct.rect = [[disp.xcenter disp.ycenter]-[halfwidth halfheight] [disp.xcenter disp.ycenter]+[halfwidth halfheight]];
disp.instruct.w = Screen('OpenOffscreenWindow',screenNumber);
Screen('FillRect',disp.instruct.w,screenNumber); % paint black

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


%% PREPARE FOR INPUT
% Enable unified mode of KbName, so KbName accepts identical key names on
% all operating systems:
KbName('UnifyKeyNames');

% % define keys
key.space = KbName('SPACE');
key.ttl = KbName('5%');
key.s = KbName('s');
key.p = KbName('p');
key.q = KbName('q');
key.esc = KbName('ESCAPE');



%% PREPARE DEVICES

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
    dat_in = WaitForInput(connection, [1,3], 15);
    nTrials = dat_in(1);
    SUBID = dat_in(2);
    CONDITION = dat_in(3);
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
    WaitSecs(.2)
    fwrite(connection,1,'double')
end

if USE_VIDEO
    
    % Device info
    devs = Screen('VideoCaptureDevices');
    did = [];
    for i=1:length(devs)
        if devs(i).InputIndex==0
            did = [did,devs(i).DeviceIndex];
        end
    end
    % [builtinID, builtin_dev] = PsychGetCamIdForSpec('OSXAVFoundationVideoSource');
    % [logitechID, log_dev] = PsychGetCamIdForSpec('OSXAVFoundationVideoSource');
    
    % Select Codec
    c = ':CodecType=x264enc Keyframe=1: CodecSettings= Videoquality=1';
    
    % Settings for video recording
    recFlag = 2 + 4 + 16 + 64; % [0,2]=sound off or on; [4] = disables internal processing; [16]=offload to separate processing thread; [64] = request timestamps in movie recording time instead of GetSecs() time:
    
    % Initialize capture
    % Need to figure out how to change resolution and select webcam
    % videoPtr =Screen('OpenVideoCapture', windowPtr [, deviceIndex][, roirectangle][, pixeldepth][, numbuffers][, allowfallback][, targetmoviename][, recordingflags][, captureEngineType][, bitdepth=8]);
    grabber = Screen('OpenVideoCapture', window, [], [0 0 320 240], [], [], 1, fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '.avi' c]), recFlag, 3, 8);
%     grabber = Screen('OpenVideoCapture', window, [], [0 0 640 480], [], [], 1, fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '.avi' c]), recFlag, 3, 8);
    WaitSecs('YieldSecs', 2); %insert delay to allow video to spool up
    
end

%% Collect Inputs

% Check if data file exists.  If so ask if we want to rerun, if not then quit and check subject ID.
file_exist = exist(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']),'file');
ListenChar(2); %Stop listening to keyboard
if file_exist == 2
    exist_text = ['WARNING!\n\nA data file exists for Subject - ' num2str(SUBID) ' Condition - ' num2str(CONDITION) '\nPress ''q'' to quit or ''p'' to proceed'];
    Screen('TextSize',window, 36);
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


%% Text for slides

% %Instructions
switch CONDITION
    case 0 %practice trials
        instruct = 'We will now practice how to make ratings.\n\nYour partner will receive several trials of heat stimulation while we calibrate the thermode.\n\nAfter each trial you will how bad you feel.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case {1,2,3,9} %Standard conditions
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial you will rate how bad you feel.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 4 %Button press control
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial you will be be instructed to rate a specific number.\n\nAfter you have selected the rating, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 5 %Experience sharing
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial your partner will be able to share how they are feeling with you.\n\nAfter you have viewed the message, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\nPress "spacebar" to continue.';
    case {6,7}
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nYou can directly communicate with your partner during the pain stimulation.\n\nAfter each trial, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 8 %Hand holding
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nYou will be holding your partner''s hand during the stimulation.\n\nAfter each trial you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
end

%% Run Script

%Initialize File with Header - need to get condition information from Computer 1
switch CONDITION
    case {0,1,2,3,8,9}
        hdr = 'Subject,Condition,Trial,ExperimentStart,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating';
        timings = nan(1,11);
    case {4,5}
        hdr = 'Subject,Condition,Trial,ExperimentStart,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,PartnerRating,PartnerRatingOnset,PartnerRatingOffset,PartnerRatingDur';
        timings = nan(1,15);
    case {6,7}
        hdr = 'Subject,Condition,Trial,ExperimentStart,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,ComfortOnset,ComfortOffset,ComfortDur';
        timings = nan(1,15);
end
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), hdr,'')

% initialize
Screen('TextSize',window,72);
DrawFormattedText(window,'.','center','center',255);
Screen('Flip',window);

% put up instruction screen
Screen('TextSize',window, text_size);
DrawFormattedText(window,instruct,'center','center',255);
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
    start = WaitForInput(connection, [1,1], 10);
end

%Start Video Recording
if USE_VIDEO
    % Start capture -
    %need to figure out how to deal with the initial pause at the beginning.
    % [fps starttime] = Screen('StartVideoCapture', capturePtr [, captureRateFPS=25] [, dropframes=0] [, startAt]);
    [fps t] = Screen('StartVideoCapture', grabber, 30, 0);
end

% put up fixation
Screen('CopyWindow',disp.fixation.w,window);
startfix = Screen('Flip',window);
timings(1) = startfix;
% WaitSecs(STARTFIX);

t = 1;
while t <= nTrials
    
    % Wait for incoming data from computer 1;
    incoming_data = WaitForInput(connection, [1,4], 2);
    trial = incoming_data(1);
    condition = incoming_data(2);
    trial_part = incoming_data(3);
    
    % Write to file
    timings(1) = SUBID;
    timings(2) = condition;
    timings(3) = trial;
    timings(4) = startfix;
    
    switch trial_part
        case 2 %Stimulation
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.stimulation.w,window);
            timings(5) = Screen('Flip',window);
            
            % Wait for stop signal from Computer 1
            stop = nan;
            while stop ~= 222
                stop = WaitForInput(connection, [1,1], 2);
            end
            
            timings(6) = GetSecs;
            timings(7) = timings(6) - timings(5);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 3 %Rating stage
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            txt = 'Please rate how bad you feel.\n\n Your partner will not see this rating.';
            [timings(8) timings(9) timings(10) timings(11)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','A Lot'},'txtSize',text_size,'anchorSize',anchor_size);
            
            % Send trial data to Computer 1
            fwrite(connection, 222,'double')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% End of Trial
            t = t+1; %Update trial count for main while loop
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
            
        case 4 %Show Button Press :: Only for condition 4
            
            %%% Show Button press
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            timings(12) = incoming_data(4);
            txt = 'This is the rating your partner was instructed to press.\n\n\n\n\n\n\n\n\n\n\n\n\n\nPress ''Spacebar'' when ready to proceed';
            [timings(13) timings(14) timings(15)] = ShowRating(timings(12), FEEDBACKDUR, window, rect, screenNumber, 'txt', txt, 'type','line','anchor',{'None','A Lot'},'txtSize',text_size,'anchorSize',anchor_size);
            
            % Send trial data to Computer 1
            fwrite(connection, 200,'double')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 5 %Share how partner is feeling :: Only for condition 5
            
            %%% Share Feeling
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            timings(12) = incoming_data(4);
            txt = 'This is how your partner wanted you to know that they are feeling.\n\n\n\n\n\n\n\n\n\n\n\n\n\nPress ''Spacebar'' when ready to proceed';
            
            [timings(13) timings(14) timings(15)] = ShowRating(timings(12), FEEDBACKDUR, window, rect, screenNumber, 'txt', txt, 'type','line','anchor',{'None','A Lot'},'txtSize',text_size,'anchorSize',anchor_size);
            
            % Send trial data to Computer 1
            fwrite(connection, 200,'double')
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 6 %Distract Your Partner :: Only for condition 6
            
            %%% Share Feeling
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            comfort_time = incoming_data(4);
            txt = 'Distract your partner until the end of the timer.';
            [timings(12) timings(13) timings(14)] = ShowProgressBar(comfort_time,window, rect, screenNumber,'txt',txt,'anchor',{'0',num2str(comfort_time)});
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
        case 7 %Comfort Your Partner :: Only for condition 7
            
            %%% Share Feeling
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            comfort_time = incoming_data(4);
            txt = 'Comfort your partner until the end of the timer.';
            [timings(12) timings(13) timings(14)] = ShowProgressBar(comfort_time,window, rect, screenNumber,'txt',txt,'anchor',{'0',num2str(comfort_time)});
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
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
timing.endscreen = Screen('Flip',window);
WaitSecs(ENDSCREENDUR);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FINISH UP

if USE_VIDEO
    %Record times
    %     video_offset = toc;
    %         nFrame = vid.FramesAcquired;
    %         frameRate = nFrame/video_offset;
    
    % Stop capture engine and recording:
    Screen('StopVideoCapture', grabber);
    telapsed = GetSecs - t;
    
    % Close engine and recorded movie file:
    Screen('CloseVideoCapture', grabber);
    
    %Write out timing information
    dlmwrite(fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '_Timing.txt']),[telapsed,fps])
end

Screen('CloseAll');
ShowCursor;
Priority(0);
sca;



