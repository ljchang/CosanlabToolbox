%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run the Social Pain Paradigm for Participant 1
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
% [window rect] = Screen('OpenWindow', screenNumber, 0, [0 0 800 600]);
% screenNumber = min(screens);

%% GLOBAL PARAMETERS

clear all; close all; fclose all;
% fPath = '~/Dropbox/RomanticCouples/CouplesParadigm';
fPath = '/Users/lukechang/Dropbox/Doctor_Patient_Andrew/CouplesParadigm';
cosanlabToolsPath = '/Users/lukechang/Dropbox/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
% fPath = '/Users/andrewfrederickson/Dropbox/Doctor_Patient_Andrew/CouplesParadigm';
% cosanlabToolsPath = '/Users/andrewfrederickson/Documents/CosanlabToolbox/Matlab/PsychToolbox';
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

% random number generator reset
rand('state',sum(100*clock));

% Devices
USE_THERMODE = 0;       % refers to thermode make 0 if not running on computer with thermode
USE_BIOPAC = 0;         % refers to Biopac make 0 if not running on computer with biopac
USE_VIDEO = 0;          % record video of Run
USE_NETWORK = 1;        % refers to Biopac make 0 if not running on computer with biopac

TRACKBALL_MULTIPLIER = 5;

% Number of Skin Sites
nSites = 1;

% PAIN: set temps for thermode
TEMPERATURES = [48 49 50];

% Number of trials
nTrials = nSites * length(TEMPERATURES);

% Create Random Vector of PAIN Trials
STIMULI = repmat(TEMPERATURES,1,nSites)';
SITES = repmat(1:nSites,1,length(TEMPERATURES))';
index = randperm(length(STIMULI));
STIMULI = STIMULI(index);
SITES = SITES(index);

% Create a Random Vector of ISI Times
FIXDUR = geometric_progression(1, nTrials, 3);
FIXDUR = FIXDUR(randperm(length(FIXDUR)));

% Timing
PAINDUR = 1;
RATINGDUR = 1;
CUEDUR = 1;
ENDSCREENDUR = 3;
STARTFIX = 1;

% Condition - will be function input
% CONDITION = 4;
% SUBID = 101;
EXPERIMENTER = 1;

%% PREPARE DISPLAY
% will break with error message if Screen() can't run
AssertOpenGL;

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
% cursor.xmin = disp.share.rect(1) + 123;
% cursor.width = 709;
% cursor.xmax = cursor.xmin + cursor.width;
% cursor.size = 8;
% cursor.center = cursor.xmin + ceil(cursor.width/2);
% cursor.y = disp.share.rect(4) - 41;
% cursor.labels = cursor.xmin + [10 42 120 249 379];

% Make a base Rect of 200 by 200 pixels
baseMark = [0 0 20 20];

%%% create no device screen
disp.nodevice.w = Screen('OpenOffscreenWindow',screenNumber);
% paint black
Screen('FillRect',disp.nodevice.w,screenNumber);
Screen('TextSize',disp.nodevice.w,72);
DrawFormattedText(disp.nodevice.w,'DEVICE NOT SET UP','center','center',255);

%%% Rating scale screen uses GetRating.m function

% clean up
clear image texture

%% PREPARE FOR INPUT
% Enable unified mode of KbName, so KbName accepts identical key names on all operating systems:
KbName('UnifyKeyNames');

% % define keys
key.space = KbName('SPACE');
% key.ttl = KbName('5%');
key.s = KbName('s');
key.p = KbName('p');
key.q = KbName('q');
key.esc = KbName('ESCAPE');
key.zero = KbName('0)');
key.one = KbName('1!');
key.two = KbName('2@');
key.three = KbName('3#');
key.four = KbName('4$');
key.five = KbName('5%');
key.six = KbName('6^');
key.seven = KbName('7&');
key.eight = KbName('8*');
key.nine = KbName('9(');

RestrictKeysForKbCheck([key.space, key.s, key.p, key.q, key.esc, 30:39]);

%% Collect inputs

% Enter Subject Information
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 50);
SUBID = GetEchoString(window, 'Experimenter: Please enter subject ID: ', round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
SUBID = str2num(SUBID);
Screen('FillRect',window,screenNumber); % paint black
ListenChar(1); %Start listening to keyboard again.

% Select Condition to Run
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 50);
DrawFormattedText(window,'Experimenter: Which condition do you want to run?\n\n0: Practice\n1: Alone\n2: Partner Behind Curtain\n3: Partner In View\n4: Share\n5: Partner Talk\n6: Hand Holding\n7: Practice\n8: Button\nq: Quit','center','center',255);
Screen('Flip',window);
keycode(key.q) = 0;
keycode(30:39) = 0;
% while keycode(key.zero)==0 && keycode(key.one) == 0 && keycode(key.two) == 0 && keycode(key.three) == 0 && keycode(key.four) == 0 && keycode(key.five) == 0 && keycode(key.six) == 0 && keycode(key.seven) == 0 && keycode(key.eight) == 0 && keycode(key.q) == 0
while ~any(keycode(30:39)) && keycode(key.q) == 0
    [presstime keycode delta] = KbWait;
end
button = find(keycode==1);
switch button
    case key.zero
        CONDITION = 0;
    case key.one
        CONDITION = 1;
    case key.two
        CONDITION = 2;
    case key.three
        CONDITION = 3;
    case key.four
        CONDITION = 4;
    case key.five
        CONDITION = 5;
    case key.six
        CONDITION = 6;
    case key.seven
        CONDITION = 7;
    case key.eight
        CONDITION = 8;
    case key.q % ESC key quits the experiment
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        sca;
        return;
end
ListenChar(1); %Start listening to keyboard again.

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


%% PREPARE DEVICES

if USE_THERMODE
    % set up thermode
    % initialize parallel port
    global THERMODE_PORT;
    THERMODE_PORT = digitalio('parallel','LPT1');
    hwlines = addline(THERMODE_PORT,0:7,'out'); % does this need to be run every time? can it be without problems?
end

if USE_BIOPAC
    BIOPAC_PULSE_WIDTH = 1; %% this counts as TIME
else
    BIOPAC_PULSE_WIDTH = 0;
end

% if use_biopac
%     [ignore hn] = system('hostname'); hn=deblank(hn);
%     addpath(genpath('\Program Files\MATLAB\R2012b\Toolbox\io32'));
%     global BIOPAC_PORT; %#ok
%     if strcmp(hn,'INC-DELL-001')
%         BIOPAC_PORT = hex2dec('E050');
%         trigger_biopac = str2func('TriggerBiopac2');
%     else
%         BIOPAC_PORT = digitalio('parallel','LPT2');
%         addline(BIOPAC_PORT,0:7,'out');
%         trigger_biopac = str2func('TriggerBiopac');
%     end
% end

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

if USE_NETWORK
    ListenChar(2); %Stop listening to keyboard
    Screen('TextSize',window, 20);
    
    % Load previous IPADDRESS
    file_exist = exist(fullfile(fPath,'ipaddress.txt'),'file');
    if file_exist == 2
        fid = fopen(fullfile(fPath,'ipaddress.txt'),'rt');
        tmp = textscan(fid,'%c','Delimiter','\n');
        ipaddress = tmp{1}';
        fclose(fid);
        iptext = ['Set up network connection with laptop.\nIs this the correct IP Address from the laptop server? ' ipaddress '\n\n1 = "YES"\n\n2="NO"'];
        Screen('TextSize',window, 40);
        DrawFormattedText(window,iptext,'center','center',255);
        Screen('Flip',window);
        keycode(key.one) = 0;
        keycode(key.two) = 0;
        while keycode(key.one) == 0 && keycode(key.two) == 0
            [presstime keycode delta] = KbWait;
        end
        if keycode(key.one)
            %             return;
        else %IP address is incorrect
            iptext = ['Set up network connection with laptop.\nPlease input the IP address from the laptop server (e.g. ' ipaddress ').'];
            ipaddress = GetEchoString(window, iptext, round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
        end
    else %no ipaddress file exists.
        iptext = ['Set up network connection with laptop. Please input the IP address from the laptop server (e.g. ' ipaddress ').'];
        ipaddress = GetEchoString(window, iptext, round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
    end
    
    % Write IP Address to file
    fid = fopen(fullfile(fPath,'ipaddress.txt'),'w');
    fprintf(fid,'%s\r\n',ipaddress);
    fclose(fid);
    ListenChar(1); %Start listening to keyboard again.
    
    % Start Connection
    connection = tcpip(ipaddress, 30000, 'NetworkRole', 'client');
    fopen(connection);
    
    % Test Connection
    WaitSecs(.1)
    fwrite(connection, [nTrials, SUBID + 100, CONDITION]);
    
    % Wait for signal from Computer 2 before proceeding
    testcomplete = 0;
    while testcomplete ~= 1
        testcomplete = WaitForInput(connection,.5);
    end
end


%% Text for slides

% %Instructions
switch CONDITION
    case 0 %practice trials
        instruct = 'We will now practice how to make ratings.\n\nYou will not be receiving any pain during practice.\n\nAfter each trial you will rate the intensity of the pain.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 1,2,3 %Standard conditions
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will rate the intensity of the pain.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 4 %Experience sharing
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will be able to share how you are feeling with your partner.\n\nAfter you have sent your message, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\nPress "spacebar" to continue.';
    case 5,6
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nYour partner can directly communicate with you during the pain stimulation.\n\nAfter each trial, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 7%Hand holding
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nYour partner will be holding your hand during the stimulation.\n\nAfter each trial you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 8 %Button press control
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will be be instructed to rate a specific number.\n\nAfter you have selected the rating, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
end


%% Run Script

%Initialize File with Header
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
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), hdr,'')

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

% wait for experimenter to press spacebar
WaitSecs(.2);
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

% Send Start signal to Computer 2
if USE_NETWORK; fwrite(connection,111); end

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
WaitSecs(STARTFIX);

switch CONDITION
    
    case 0 % Practice trials
        % trial loop
        for trial = 1:2
            
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(7) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2]);  end
            
            Screen('CopyWindow',disp.nodevice.w,window);
            Screen('TextSize',window,72);
            DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
            timings(10) = Screen('Flip',window);
            WaitSecs(PAINDUR);
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222)
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3]);  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_timings = WaitForInput(connection, 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(17) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(18) = GetSecs;
            timings(19) = timings(18) - timings(17);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
        end
        
    case 1,2,3,5,6,7  %Normal pain trials
        % trial loop
        for trial = 1:nTrials
            
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(7) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2]);  end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(10) = TriggerHeat(STIMULI(trial),TEMPDUR);
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(10) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222)
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3]);  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_timings = WaitForInput(connection, 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(17) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(18) = GetSecs;
            timings(19) = timings(18) - timings(17);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            if USE_NETWORK
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), [timings,computer2_timings'] , 'delimiter',',','-append','precision',10)
            else
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
            end
        end
        
    case 4  %Share Feeling Condition
        % trial loop
        for trial = 1:nTrials
            
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(7) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2]);  end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(10) = TriggerHeat(STIMULI(trial),TEMPDUR);
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(10) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222)
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% Share how you are feeling
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,4]);  end
            
            txt = 'Let your partner know how you are feeling.\n\nThis is independent of your pain rating.';
            [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                %Send Rating to Partner
                fwrite(connection,[trial,CONDITION,4,timings(16)])
                
                %Wait to proceed until partner has acknowledged feeling
                computer2_timings = nan;
                while computer2_timings ~= 222
                    computer2_timings = WaitForInput(connection, 1);
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3]);  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(17) timings(18) timings(19) timings(20)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_timings = WaitForInput(connection, 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(21) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(22) = GetSecs;
            timings(23) = timings(22) - timings(21);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            if USE_NETWORK
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), [timings,computer2_timings'] , 'delimiter',',','-append','precision',10)
            else
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
            end
        end
        
    case 8  %Button Press Control Condition
        
        % trial loop
        for trial = 1:nTrials
            
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(7) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2]);  end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(10) = TriggerHeat(STIMULI(trial),TEMPDUR);
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(10) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222)
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%% Press Button
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,4]);  end
            
            randnum = num2str(round(rand*100));            % Generate random target value
            txt = ['Please set the rating to approximately ' num2str(randnum)];
            [timings(13) timings(14) timings(15) timings(16)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                %Send Rating to Partner
                fwrite(connection,[trial,CONDITION,4,timings(19)])
                
                %Wait to proceed until partner has acknowledged feeling
                computer2_timings = WaitForInput(connection, 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3]);  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(17) timings(18) timings(19) timings(20)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','linear');
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_timings = WaitForInput(connection, 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(21) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(22) = GetSecs;
            timings(23) = timings(22) - timings(21);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            if USE_NETWORK
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), [timings,computer2_timings'] , 'delimiter',',','-append','precision',10)
            else
                dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
            end
            
        end
end

% END SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('TextSize',window,72);
DrawFormattedText(window,'END','center','center',255);
WaitSecs('UntilTime',ENDSCREENDUR);
timing.endscreen = Screen('Flip',window);
WaitSecs(2);
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


