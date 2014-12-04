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

%% Testing Settings

ShowCursor;
screens = Screen('Screens');
% screenNumber = min(screens);
% [window rect] = Screen('OpenWindow', screenNumber, 0, [800 0 1600 600]);

%% GLOBAL PARAMETERS

clear all; close all; fclose all;
% fPath = '/Users/lukechang/Dropbox/RomanticCouples/CouplesParadigm';
% cosanlabToolsPath = '/Users/lukechang/Dropbox/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
fPath = '/Users/ljchang/Dropbox/RomanticCouples/CouplesParadigm';
cosanlabToolsPath = '/Users/ljchang/Dropbox/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

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
FEEDBACKDUR = 3;

% Condition - will be function input
% CONDITION = 1;
% SUBID = 201;
EXPERIMENTER = 1;

%% PREPARE DISPLAY
% % will break with error message if Screen() can't run
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

% % determine cursor parameters
% cursor.xmin = disp.scale.rect(1) + 123;
% cursor.width = 709;
% cursor.xmax = cursor.xmin + cursor.width;
% cursor.size = 8;
% cursor.center = cursor.xmin + ceil(cursor.width/2);
% cursor.y = disp.scale.rect(4) - 41;
% cursor.labels = cursor.xmin + [10 42 120 249 379];


% Add text
% [newX,newY]=Screen('DrawText', disp.share, text [,x] [,y] [,color] [,backgroundColor] [,yPositionIsBaseline] [,swapTextDirection]);
% [newX,newY]=Screen('DrawText', disp.share, );
% Screen('TextSize',disp.fixation.w,60);
% DrawFormattedText(disp.share.w,'This is how your partner wanted you to know how they are feeling.  Press space to acknowledge message and proceed.','top','center',255);

% 
% % determine cursor parameters
% cursor.xmin = disp.showfeeling.rect(1) + 123;
% cursor.width = 709;
% cursor.xmax = cursor.xmin + cursor.width;
% cursor.size = 8;
% cursor.center = cursor.xmin + ceil(cursor.width/2);
% cursor.y = disp.showfeeling.rect(4) - 41;
% cursor.labels = cursor.xmin + [10 42 120 249 379];

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
    dat_in = WaitForInput(connection, 5);
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
    fwrite(connection,1)
    
%     % Set up Rating screen
%     % determine cursor parameters
%     cursor.xmin = disp.scale.rect(1) + 123;
%     cursor.width = 709;
%     cursor.xmax = cursor.xmin + cursor.width;
%     cursor.size = 8;
%     cursor.center = cursor.xmin + ceil(cursor.width/2);
%     cursor.y = disp.scale.rect(4) - 41;
%     cursor.labels = cursor.xmin + [10 42 120 249 379];
%     
%     % create array of random starting cursor positions
%     for s = 1:nTrials
%         ok = false;
%         while ~ok
%             if mod(s,2)
%                 cursor.start(s) = round(rand(1)*0.4*cursor.width);
%             else
%                 cursor.start(s) = round(rand(1)*-0.4*cursor.width);
%             end
%             ok = true;
%             for i = 1:numel(cursor.labels)
%                 if abs((cursor.center+cursor.start(s))-(cursor.xmin+cursor.labels(i))) <= 5
%                     ok = false;
%                 end
%             end
%         end
%     end
%     cursor.start = Shuffle(cursor.start);
    
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
    % The good ones...
    %codec = ':CodecType=avenc_mpeg4' % % MPEG-4 video + audio: Ok @ 640 x 480.
    %codec = ':CodecType=x264enc Keyframe=1 Videobitrate=8192 AudioCodec=alawenc ::: AudioSource=pulsesrc ::: Muxer=qtmux'  % H264 video + MPEG-4 audio: Tut seshr gut @ 640 x 480
    %codec = ':CodecType=VideoCodec=x264enc speed-preset=1 noise-reduction=100000 ::: AudioCodec=faac ::: Muxer=avimux'
    % c = ':CodecType=DEFAULTencoder';
    % c = ':CodecType=avenc_mpeg4';
    c = ':CodecType=x264enc Keyframe=1: CodecSettings= Videoquality=1';
    
    % Settings for video recording
    recFlag = 0 + 4 + 16 + 64; % [0,2]=sound off or on; [4] = disables internal processing; [16]=offload to separate processing thread; [64] = request timestamps in movie recording time instead of GetSecs() time:
    
    % Initialize capture
    % Need to figure out how to change resolution and select webcam
    % videoPtr =Screen('OpenVideoCapture', windowPtr [, deviceIndex][, roirectangle][, pixeldepth][, numbuffers][, allowfallback][, targetmoviename][, recordingflags][, captureEngineType][, bitdepth=8]);
    grabber = Screen('OpenVideoCapture', window, did(2), [], [], [], 1, fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Condition' num2str(CONDITION) '.avi' c]), recFlag, 3, 8);
    WaitSecs('YieldSecs', 2); %insert delay to allow video to spool up
    
end

%% Collect Inputs

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


%% Text for slides

% %Instructions
switch CONDITION
    case 0 %practice trials
        instruct = 'We will now practice how to make ratings.\n\nYour partner will not be receiving any pain during practice.\n\nAfter each trial you will how bad you feel.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 1,2,3 %Standard conditions
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial you will rate how bad you feel.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 4 %Experience sharing
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial your partner will be able to share how they are feeling with you.\n\nAfter you have viewed the message, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\nPress "spacebar" to continue.';
    case 5,6
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nYou can directly communicate with your partner during the pain stimulation.\n\nAfter each trial, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 7%Hand holding
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nYou will be holding your partner''s hand during the stimulation.\n\nAfter each trial you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 8 %Button press control
        instruct = 'In this condition your partner will receive several trials of heat stimulation.\n\nAfter each trial you will be be instructed to rate a specific number.\n\nAfter you have selected the rating, you will then rate how bad you feel.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
end

%% Run Script

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
Screen('TextSize',window, 36);
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
    start = WaitForInput(connection, 10);
end
timings = nan(1,8);

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
                    txt = 'Please rate how bad you feel.\n\n Your partner will not see this rating.';
                    [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');

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
                        partner_rating = incoming_data(4);
                        txt = 'This is how your partner wanted you to know that they are feeling.';
                        [timings(13) timings(14) timings(15)] = ShowRating(partner_rating, FEEDBACKDUR, window, rect, screenNumber, 'txt', txt, 'type','linear');

%                     Screen('CopyWindow',disp.stimulation.w,window);
%                     Screen('DrawTextures',window,disp.showfeeling.texture,[],disp.scale.rect);
%                     Screen('DrawTextures',window,disp.showfeeling.texture,[],disp.showfeeling.rect);
%                     Screen('DrawLine',window,[255 0 0],incoming_data(4),cursor.y-(ceil(.107*(cursor.x-cursor.xmin)))-5,cursor.x,cursor.y+10,5);
% %                     Screen('DrawLine',window,[255 0 0],cursor.x,cursor.y-(ceil(.107*(cursor.x-cursor.xmin)))-5,cursor.x,cursor.y+10,3);
%                     Screen('Flip',window);
                    
                    % Get Rating Onset Time
                    timings(5) = GetSecs;
          
                    
                    % Send trial data to Computer 1
                    % timings = [startfixation stimulation onset, stimulation offset, stimulation duration, rating onset, rating offset, rating duration, rating]
                    fwrite(connection, 222,'double')

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


