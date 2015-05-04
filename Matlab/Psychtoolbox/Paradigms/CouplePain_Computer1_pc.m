%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run the Social Pain Paradigm for Participant 1
%
% Requires: Psychtoolbox 3, cosanlabtoolbox, and Gstreamer for video input
%           http://psychtoolbox.org/
%           https://github.com/ljchang/CosanlabToolbox
%           http://gstreamer.freedesktop.org/
%
% Developed by Luke Chang, Briana Robustelli, Mark Whisman, Tor Wager
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
% 1) sending triggers in this paradigm only works on a 32bit windows 7
% machine.  We use digitalio for the thermode and io32 for the biopac.  see
% TriggerBiopac_io32 for more details.
%
% 2) Make sure that windows firewall is opened for port 30000, otherwise
% will be unable to receive network communication.

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

%% GLOBAL PARAMETERS

clear all; close all; fclose all;
if ismac %laptop
    fPath = '/Users/lukechang/Dropbox/RomanticCouples/CouplesParadigm';
    cosanlabToolsPath = '/Users/lukechang/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
    Screen('Preference', 'SkipSyncTests', 1); % skip sync tests problems with yosemite
elseif ispc %CINC Computer
    fPath = 'C:\Users\canlab\Desktop\RomanticCouple';
    cosanlabToolsPath = 'C:\Users\canlab\Documents\GitHub\CosanlabToolbox\Matlab\PsychToolbox';
%     Screen('Preference', 'SkipSyncTests', 1); % skip sync tests problems with yosemite
end
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

% random number generator reset
rand('state',sum(100*clock));

% Devices
USE_THERMODE = 0;       % refers to thermode make 0 if not running on computer with thermode
USE_BIOPAC = 0;         % refers to Biopac make 0 if not running on computer with biopac
USE_VIDEO = 0;          % record video of Run - Doesn't work on windows
USE_NETWORK = 0;        % refers to Biopac make 0 if not running on computer with biopac
USE_SOUND = 1;          % use sound to indicate start of video - useful for syncing video on windows

TRACKBALL_MULTIPLIER = 5;

% Number of Skin Sites
nSites = 4;

% PAIN: set temps for thermode
TEMPERATURES = [48];
PRACTICE_TEMP = 47;

% Number of trials
nTrials = nSites * length(TEMPERATURES);

% Create Random Vector of PAIN Trials
STIMULI = repmat(TEMPERATURES,1,nSites)';
PRACTICE_STIMULI = repmat(PRACTICE_TEMP,1,nSites)';
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
STARTFIX = 4;
TEMPDUR = 12;
COMFORTDUR = 13;

% Settings
text_size = 28;
anchor_size = 20;

%% PREPARE DISPLAY
% will break with error message if Screen() can't run
AssertOpenGL;

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

RestrictKeysForKbCheck([key.space, key.s, key.p, key.q, key.esc, key.zero, key.one, key.two, key.three, key.four, key.five, key.six, key.seven, key.eight, key.nine]);

%% Collect inputs

% Enter Subject Information
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 28);
Screen(window,'TextFont','Helvetica');
Screen(window,'TextStyle',0);
SUBID = GetEchoString(window, 'Experimenter: Please enter subject ID: ', round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
SUBID = str2num(SUBID);
Screen('FillRect',window,screenNumber); % paint black
ListenChar(1); %Start listening to keyboard again.

% Select Condition to Run
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 28);
DrawFormattedText(window,'Experimenter: Which condition do you want to run?\n\n0: Practice\n1: Alone\n2: Partner Behind Curtain\n3: Partner In View\n4: Button\n5:Share\n6: Distraction\n7: Partner Talk\n8: Hand Holding\n9: Alone\nq: Quit','center','center',255);
Screen('Flip',window);

% Clear keys
key_name = fieldnames(key);
for k = 1:length(key_name)
    keycode(key.(key_name{k}))=0;
end

% Wait for keypress
while keycode(key.zero)==0 && keycode(key.one)==0 && keycode(key.two)==0  && keycode(key.three)==0 && keycode(key.four)==0 && keycode(key.five)==0 && keycode(key.six)==0 && keycode(key.seven)==0 && keycode(key.eight)==0 && keycode(key.nine)==0 && keycode(key.q) == 0
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
    case key.eight
        CONDITION = 9;
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
    Screen('TextSize',window, 28);
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

if USE_SOUND
    % Set up audio playback
    % See http://www.scottfraundorf.com/matlab_audio.html#pc
    InitializePsychSound(1); %inidializes sound driver...the 1 pushes for low latency
    if ismac %laptop
        pahandle = PsychPortAudio('Open', [], 1, [], 44100, 2, [], 0.015);
    elseif ispc %CINC Computer
        pahandle = PsychPortAudio('Open', [], 1, [], 44100, 2, [], 0.015);
    end
    [sounddata soundfreq] = audioread(fullfile(cosanlabToolsPath,'SupportFunctions','Sounds','Bell_E5_1000ms.wav')); % Load Sound
    PsychPortAudio('FillBuffer', pahandle, sounddata');
end

if USE_THERMODE
    % set up thermode
    % initialize parallel port
    global THERMODE_PORT;
    THERMODE_PORT = digitalio('parallel','LPT1');
    addline(THERMODE_PORT,0:7,'out');
end

if USE_BIOPAC
    % Test to make sure io32 is on path
    try
        config_io
    catch
        error('Make sure io32 Driver is installed and config_io.m is on path')
    end
    test_func  = exist('io32');
    if test_func ~= 3
        error('if using windows, make sure io32 drivers are installed')
    end
    global BIOPAC_PORT;
    
    % DIGITALIO doesn't work for CINC computer, using io32 instead for now.
    %    BIOPAC_PORT = digitalio('parallel','LPT2');
    %     addline(BIOPAC_PORT,0:7,'out');
    
    BIOPAC_PORT = hex2dec('E050');
    
    BIOPAC_PULSE_DUR = 1; %% this counts as TIME
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
        Screen('TextSize',window, 28);
        DrawFormattedText(window,iptext,'center','center',255);
        Screen('Flip',window);
        keycode(key.one) = 0; keycode(key.two) = 0;
        while keycode(key.one) == 0 && keycode(key.two) == 0
            [presstime keycode delta] = KbWait;
        end
        if keycode(key.one)
            %             return;
        else %IP address is incorrect
            iptext = ['Please input the IP address from the laptop server (e.g. ' ipaddress ').'];
            ipaddress = GetEchoString(window, iptext, round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
            WaitSecs(.2);
            Screen('Flip',window);
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
    fwrite(connection, [nTrials, SUBID + 100, CONDITION],'double');
    WaitSecs(.2)
    
    % Wait for signal from Computer 2 before proceeding
    testcomplete = 0;
    while testcomplete ~= 1
        testcomplete = WaitForInput(connection,[1,1],.5);
    end
end

%% Text for slides

% %Instructions
switch CONDITION
    case 0 %practice trials
        instruct = 'We will now calibrate the thermode and practice how to make ratings.\n\nIn this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will rate the intensity of the pain.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case {1,2,3,9} %Standard conditions
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will rate the intensity of the pain.\n\nPlease respond as honestly as you can.\n\nNobody else will be able to see your ratings.\n\n\nPress "spacebar" to continue.';
    case 4 %Button press control
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will be be instructed to rate a specific number.\n\nAfter you have selected the rating, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 5 %Experience sharing
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nAfter each trial you will be able to share how you are feeling with your partner.\n\nAfter you have sent your message, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\nPress "spacebar" to continue.';
    case {6,7}
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nYour partner can directly communicate with you during the pain stimulation.\n\nAfter each trial, you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
    case 8%Hand holding
        instruct = 'In this condition you will receive several trials of heat stimulation.\n\nYour partner will be holding your hand during the stimulation.\n\nAfter each trial you will then rate the intensity of the pain.\n\nNobody else will be able to see these ratings.\n\n\nPress "spacebar" to continue.';
end


%% Run Script

%Initialize File with Header
switch CONDITION
    case {0,1,2,3,8,9}
        hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
        timings = nan(1,19);
    case {4,5}
        hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,ShareFeelingOnset,ShareFeeling,Offset,ShareFeelingDur,ShareFeelingRating,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
        timings = nan(1,23);
    case {6,7}
        hdr = 'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,TalkOnset,TalkOffset,TalkDur,ComfortWaitOnset,ComfortWaitOffset,ComfortWaitDur,StimulationOnset,StimulationOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
        timings = nan(1,22);
end
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), hdr,'')

% put up instruction screen
Screen('TextSize',window, 28);
DrawFormattedText(window,instruct,'center','center',255);
Screen('Flip',window);

% wait for experimenter to press spacebar
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

% ready screen
Screen('TextSize',window,50);
DrawFormattedText(window,'Ready','center','center',255);
Screen('Flip',window);

% wait for experimenter to press spacebar
WaitSecs(.2);
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

% Play Sound to sync video
if USE_SOUND; PsychPortAudio('Start', pahandle); end  % 	PsychPortAudio('Stop', pahandle, 1); %will wait until sound stops otherwise will continue with experiment as soon as sound starts

% Send Start signal to Computer 2
if USE_NETWORK; fwrite(connection,111,'double'); end

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
    case {0,1,2,3,8,9}  %Normal pain trials
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
            
            %%% Instruct Thermode Placement
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            stim_text = ['Experimenter, please place thermode on site ' num2str(SITES(trial)) '\n\n\n\nPress ''Spacebar'' when ready to proceed'];
            Screen('TextSize',window,28);
            DrawFormattedText(window,stim_text,'center',disp.ycenter,255);
            timings(7) = Screen('Flip',window);
            keycode(key.space) = 0;
            while keycode(key.space) == 0
                [presstime keycode delta] = KbWait;
            end
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(10) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2,0],'double');  end
            
            if USE_BIOPAC; TriggerBiopac_io32(BIOPAC_PULSE_DUR); end
            
            if USE_THERMODE
                % deliver thermal pain
                if CONDITION  == 0 %practice
                    timings(13) = TriggerHeat(PRACTICE_STIMULI(trial));
                else
                    timings(13) = TriggerHeat(STIMULI(trial));
                end
                WaitSecs(TEMPDUR)
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                if CONDITION == 0 % practice
                    DrawFormattedText(window,num2str(PRACTICE_STIMULI(trial)),'center',disp.ycenter+200,255);
                else
                    DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                end
                timings(13) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(14) = GetSecs;
            timings(15) = timings(14) - timings(13);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222,'double')
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3,0],'double');  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(16) timings(17) timings(18) timings(19)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_startsignal = WaitForInput(connection, [1,1], 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(20) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(21) = GetSecs;
            timings(22) = timings(21) - timings(20);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
        end
        
    case 4  %Button Press Control Condition
        for trial = 1:nTrials
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            %%% Instruct Thermode Placement
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            stim_text = ['Experimenter, please place thermode on site ' num2str(SITES(trial)) '\n\n\n\nPress ''Spacebar'' when ready to proceed'];
            Screen('TextSize',window,28);
            DrawFormattedText(window,stim_text,'center',disp.ycenter,255);
            timings(7) = Screen('Flip',window);
            keycode(key.space) = 0;
            while keycode(key.space) == 0
                [presstime keycode delta] = KbWait;
            end
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(10) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2,0],'double');  end
            
            if USE_BIOPAC; TriggerBiopac_io32(BIOPAC_PULSE_DUR); end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(13) = TriggerHeat(STIMULI(trial));
                WaitSecs(TEMPDUR)
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(13) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(14) = GetSecs;
            timings(15) = timings(14) - timings(13);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222,'double')
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% Press Button
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            randnum = rand;            % Generate random target value
            txt = ['Please set the rating to approximately ' num2str(round(randnum*100))];
            [timings(16) timings(17) timings(18) timings(19)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,4,randnum],'double'); end  %Send Rating to Partner
            
            % Wait for response from Computer 2
            if USE_NETWORK; 
                computer2_startsignal = WaitForInput(connection, [1,1], 3);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3,0],'double');  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(20) timings(21) timings(22) timings(23)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_startsignal = WaitForInput(connection, [1], 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(24) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(25) = GetSecs;
            timings(26) = timings(25) - timings(24);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
        end
        
    case 5  %Share Feeling Condition
        for trial = 1:nTrials
            %Record Data
            %'Subject,Condition,Trial,Temperature,StimulationSite,ExperimentStart,CueOnset,CueOffset,CueDur,AnticipationOnset,AnticipationOffset,AnticipationDur,StimulationOnset,StimulusOffset,StimulationDur,RatingOnset,RatingOffset,RatingDur,Rating,FixationOnset,FixationOffset,FixationDur';
            timings(1) = SUBID;
            timings(2) = CONDITION;
            timings(3) = trial;
            timings(4) = STIMULI(trial);
            timings(5) = SITES(trial);
            timings(6) = startfix;
            
            %%% Instruct Thermode Placement
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            stim_text = ['Experimenter, please place thermode on site ' num2str(SITES(trial)) '\n\n\n\nPress ''Spacebar'' when ready to proceed'];
            Screen('TextSize',window,28);
            DrawFormattedText(window,stim_text,'center',disp.ycenter,255);
            timings(7) = Screen('Flip',window);
            keycode(key.space) = 0;
            while keycode(key.space) == 0
                [presstime keycode delta] = KbWait;
            end
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(10) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,2,0],'double');  end
            
            if USE_BIOPAC; TriggerBiopac_io32(BIOPAC_PULSE_DUR); end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(13) = TriggerHeat(STIMULI(trial));
                WaitSecs(TEMPDUR)
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(13) = Screen('Flip',window);
            end
            WaitSecs(PAINDUR);
            timings(14) = GetSecs;
            timings(15) = timings(14) - timings(13);
            
            if USE_NETWORK % Send signal to stop stimulation screen to computer 2
                fwrite(connection,222,'double')
            end
            WaitSecs(.2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% Share how you are feeling
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            txt = 'Let your partner know how much pain you are feeling.\n\nThis is independent of your actual pain rating.';
            [timings(16) timings(17) timings(18) timings(19)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,5, timings(19)],'double');  end
            
            % Wait for response from Computer 2
            if USE_NETWORK; 
                computer2_startsignal = WaitForInput(connection, [1,1], 3);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3,0],'double');  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(20) timings(21) timings(22) timings(23)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_startsignal = WaitForInput(connection, [1,1], 1);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(24) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(25) = GetSecs;
            timings(26) = timings(25) - timings(24);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
        end
        
    case {6,7}  %Support and distraction trials
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
            
            %%% Instruct Thermode Placement
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            stim_text = ['Experimenter, please place thermode on site ' num2str(SITES(trial)) '\n\n\n\nPress ''Spacebar'' when ready to proceed'];
            Screen('TextSize',window,28);
            DrawFormattedText(window,stim_text,'center',disp.ycenter,255);
            timings(7) = Screen('Flip',window);
            keycode(key.space) = 0;
            while keycode(key.space) == 0
                [presstime keycode delta] = KbWait;
            end
            timings(8) = GetSecs;
            timings(9) = timings(8) - timings(7);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% PRESTIMFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(10) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(11) = GetSecs;
            timings(12) = timings(11) - timings(10);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% Send start comfort signal on Computer 2 -  Continue Fixation
            wait_time = TEMPDUR + COMFORTDUR;
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,CONDITION,wait_time],'double');  end
            timings(13) = GetSecs;
            WaitSecs(COMFORTDUR - 3);
            timings(14) = GetSecs;
            timings(15) = timings(14) - timings(13);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% STIM
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if USE_BIOPAC; TriggerBiopac_io32(BIOPAC_PULSE_DUR); end
            
            if USE_THERMODE
                % deliver thermal pain
                timings(16) = TriggerHeat(STIMULI(trial));
                WaitSecs(TEMPDUR)
            else
                Screen('CopyWindow',disp.nodevice.w,window);
                Screen('TextSize',window,72);
                DrawFormattedText(window,num2str(STIMULI(trial)),'center',disp.ycenter+200,255);
                timings(16) = Screen('Flip',window);
                WaitSecs(TEMPDUR);
            end
            timings(17) = GetSecs;
            timings(18) = timings(17) - timings(16);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% RATING
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            WaitSecs(2)
            if USE_NETWORK; fwrite(connection,[trial,CONDITION,3,0],'double');  end
            
            txt = 'Please rate the intensity of your pain.\n\n Your partner will not see this rating.';
            [timings(19) timings(20) timings(21) timings(22)] = GetRating(window, rect, screenNumber, 'txt',txt, 'type','line','anchor',{'None','Worst Pain Imaginable'},'txtSize',text_size,'anchorSize',anchor_size);
            
            if USE_NETWORK % Wait for signal from Computer 2 before proceeding
                computer2_startsignal = WaitForInput(connection, [1,1], 2);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% ENDFIX
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('CopyWindow',disp.fixation.w,window);
            timings(23) = Screen('Flip',window);
            WaitSecs(FIXDUR(trial));
            timings(24) = GetSecs;
            timings(25) = timings(24) - timings(23);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Append data to file after every trial
            dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Condition' num2str(CONDITION) '.csv']), timings, 'delimiter',',','-append','precision',10)
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


