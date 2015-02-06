%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script will run the postpartum social feedback paradigm.
%
% Requires: Psychtoolbox 3, cosanlabtoolbox, and Gstreamer for video input
%           http://psychtoolbox.org/
%           https://github.com/ljchang/CosanlabToolbox
%           http://gstreamer.freedesktop.org/
%
% Developed by Luke Chang, Christina Metcalf, Leonie Koban, and Sona
% Dimidjian
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

%% Notes:
% Repeat practice trial not working yet.


%% GLOBAL PARAMETERS

% clear all; close all; fclose all;
fPath = '/Users/lukechang/Dropbox/Postpartum/Paradigm';
cosanlabToolsPath = '/Users/lukechang/Dropbox/Github/Cosanlabtoolbox/Matlab/Psychtoolbox';
% fPath = '/Users/10cam/Dropbox/Postpartum/Paradigm';
% cosanlabToolsPath = '/Users/10cam/Documents/Cosanlabtoolbox/Matlab/Psychtoolbox';
addpath(genpath(fullfile(cosanlabToolsPath,'SupportFunctions')));

% random number generator reset
rand('state',sum(100*clock));

% Settings
USE_VIDEO = 0;          % record video of Run
TRACKBALL_MULTIPLIER = 5;


%% PREPARE DISPLAY
% will break with error message if Screen() can't run
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL;

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');
screenNumber = max(screens);

% Prepare the screen
% [window rect] = Screen('OpenWindow', screenNumber, 0, [0 0 800 600]);
% [window rect] = Screen('OpenWindow', screenNumber, 0, [0 0 1200 900]);
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

%%% Rating scale screen uses GetRating.m function

% clean up
clear image texture

%% Questions

% Main Questions
q{1} = 'What percentage of the day do you feel overhwelmed?';
q{2} = 'What percentage of the time do you think that you are a good mother?';
q{3} = 'What percentage of the day do you understand what your baby wants or needs?';
q{4} = 'What percent of the day do you feel a sense of deep love and affection for your baby?';
q{5} = 'How many minutes does it take for you to soothe your baby when your baby is distressed or crying?';
q{6} = 'What percentage of the day do you feel joyful being with your baby?';
q{7} = 'What percentage of your baby?s future or success do you feel directly responsible for?';
q{8} = 'How many hours per week do you leave your baby in the care of another person?';
q{9} = 'How many times per week do you get into conflicts with your partner or close others? ';
q{10} = 'What percentage of the overall caretaking for your baby do you feel reliant or dependent on other people for?';

qind = 1:length(q);

% Expectations
exp = q;
% exp{1} = 'How much do you think most baby''s eat?'
% Emotions
emotions = {'anger', 'guilt', 'happiness', 'pride', 'sadness', 'shame', 'surprise'};

% Create random signs
select_sign = cellstr([repmat('positive',round(length(q)/2),1);repmat('negative',round(length(q)/2),1)]);
select_sign = select_sign(randperm(length(select_sign)));

%% Timings

STARTFIX = 1;
FIXDUR = geometric_progression(1, length(q) * (length(emotions) + 1), 3); % Create a Random Vector of ISI Times
FIXDUR = FIXDUR(randperm(length(FIXDUR)));
ENDSCREENDUR = 2;
feedbackDur = 4;
questionDur = 2;

%% Text for slides

% %Instructions
pract_instruct = 'We will now practice how to make ratings.\n\nYou will be asked questions about your baby\n\nAfter you have responded you will be able to see how other mother''s have answered.\n\nAfter each question you will rate the intensity of emotion that you are feelling.\n\nPlease respond as honestly as you can.\n\n\nPress "spacebar" to continue.';
instruct = 'Great!  We are now ready to begin the experiment.\n\nYou will be asked questions about your baby\n\nAfter you have responded you will be able to see how other mother''s have answered.\n\nAfter each question   you will rate the intensity of emotion that you are feelling.\n\nPlease respond as honestly as you can.\n\nAsk the experimenter if you have any questions.\n\n\nPress "spacebar" to continue.';

%% PREPARE FOR INPUT
% Enable unified mode of KbName, so KbName accepts identical key names on all operating systems:
KbName('UnifyKeyNames');

% % define keys
key.space = KbName('SPACE');
% key.ttl = KbName('5%');
key.s = KbName('s');
key.p = KbName('p');
key.q = KbName('q');
key.r = KbName('r');
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

RestrictKeysForKbCheck([key.space, key.s, key.p, key.q, key.r, key.esc, 30:39]);

%% Collect inputs

% Enter Subject Information
ListenChar(2); %Stop listening to keyboard
Screen('TextSize',window, 50);
SUBID = GetEchoString(window, 'Experimenter: Please enter subject ID: ', round(disp.screenWidth*.25), disp.ycenter, [255, 255, 255], [0, 0, 0],[]);
SUBID = str2num(SUBID);
Screen('FillRect',window,screenNumber); % paint black
ListenChar(1); %Start listening to keyboard again.

% Check if data file exists.  If so ask if we want to rerun, if not then quit and check subject ID.
file_exist = exist(fullfile(fPath,'Data',[num2str(SUBID) '_Postpartum.csv']),'file');
ListenChar(2); %Stop listening to keyboard
if file_exist == 2
    exist_text = ['WARNING!\n\nA data file exists for Subject - ' num2str(SUBID) '\nPress ''q'' to quit or ''p'' to proceed'];
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

if USE_VIDEO
    
    % Device info
    devs = Screen('VideoCaptureDevices');
    did = [];
    for i=1:length(devs)
        if devs(i).InputIndex==0
            did = [did,devs(i).DeviceIndex];
        end
    end
    
    % Select Codec
    c = ':CodecType=x264enc Keyframe=1: CodecSettings= Videoquality=1';
    
    % Settings for video recording
    recFlag = 0 + 4 + 16 + 64; % [0,2]=sound off or on; [4] = disables internal processing; [16]=offload to separate processing thread; [64] = request timestamps in movie recording time instead of GetSecs() time:
    
    % Initialize capture
    % Need to figure out how to change resolution and select webcam
    % videoPtr =Screen('OpenVideoCapture', windowPtr [, deviceIndex][, roirectangle][, pixeldepth][, numbuffers][, allowfallback][, targetmoviename][, recordingflags][, captureEngineType][, bitdepth=8]);
    grabber = Screen('OpenVideoCapture', window, did(2), [], [], [], 1, fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Postpartum.avi' c]), recFlag, 3, 8);
    WaitSecs('YieldSecs', 2); %insert delay to allow video to spool up
    
end

%% Run Script

%Initialize File with Header
hdr = 'Subject,Trial,QuestionIndex,ExperimentStart,FixationOnset,FixationOffset,FixationDur,QuestionOnset,QuestionOffset,QuestionDuration,QuestionRating,SocialNorm,FeedbackOnset,FeedbackOffset,FeedbackDur,AngerOnset,AngerOffset,AngerDur,AngerRating,GuiltOnset,GuiltOffset,GuiltDur,GuiltRating,HappinessOnset,HappinessOffset,HappinessDur,HappinessRating,PrideOnset,PrideOffset,PrideDur,PrideRating,SadnessOnset,SadnessOffset,SadnessDur,SadnessRating,ShameOnset,ShameOffset,ShameDur,ShameRating,SurpriseOnset,SurpriseOffset,SurpriseDur,SurpriseRating';
timings = nan(1,19);
dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Postpartum.csv']), hdr,'')

% put up instruction screen
Screen('TextSize',window, 36);
DrawFormattedText(window,pract_instruct,'center','center',255);
Screen('Flip',window);

% wait for experimenter to press spacebar
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

%%% Practice Trial
repeat = 1;
while repeat ~= 0
    %%% Fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('CopyWindow',disp.fixation.w,window);
    Screen('Flip',window);
    WaitSecs(2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Question
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [practice(1) practice(2) practice(3) practice(4)] = GetRating(window, rect, screenNumber, 'txt', 'How much does your baby weigh?', 'type','line','anchor', {'0 lbs','50 lbs'});
    WaitSecs(questionDur);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Feedback
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    practice(5) = .75; %hard code the norm
    if practice(4) > practice(5)
        fbck = 'You have reported more than most other mothers';
    elseif practice(4) < practice(5)
        fbck = 'You have reported less than most other mothers';
    else
        fbck = 'You have reported about the same as most other mothers';
    end
    [practice(6) practice(7) practice(8)] = ShowRating([practice(4), practice(5)], feedbackDur, window, rect, screenNumber, 'txt', ['How much does your baby weigh?\n\nRed line indicates your response\nGreen line indicates what most other mothers report\n\n' fbck], 'type','line', 'anchor', {'0 lbs','50 lbs'});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Short Fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('CopyWindow',disp.fixation.w,window);
    Screen('Flip',window);
    WaitSecs(1.5)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Emotion Ratings - Probably should randomize these per question
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lastt = 8;
    for e = 1:length(emotions)
        [practice(lastt + 1) practice(lastt + 2) practice(lastt + 3) practice(lastt + 4)] = GetRating(window, rect, screenNumber, 'txt',['How much ' emotions{e} ' do you feel?'],'type','line', 'anchor', {'None','A Lot'});
        lastt = lastt + 4;
        
        % Wait for 1 second in between each rating
        Screen('Flip',window);
        WaitSecs(1)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Repeat Practice trials?
    Screen('TextSize',window, 36);
    DrawFormattedText(window,'Would you like to repeat practice trial?\n\nPress ''r'' to repeat or ''p'' to proceed','center','center',255);
    Screen('Flip',window);
    keycode(key.r) = 0;
    keycode(key.p) = 0;
    ListenChar(2); %Stop listening to keyboard.
    while(keycode(key.p) == 0 && keycode(key.r) == 0)
        [presstime keycode delta] = KbWait;
    end
    % 'r' restarts practice trial, 'p' proceeds
    if keycode(key.p) == 1
        repeat = 0;
    end
    ListenChar(1); %Start listening to keyboard again.
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Experiment

% put up instruction screen
Screen('TextSize',window, 36);
DrawFormattedText(window,instruct,'center','center',255);
Screen('Flip',window);

% wait for experimenter to press spacebar
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

% wait for experimenter to press spacebar
WaitSecs(.2);
keycode(key.space) = 0;
while keycode(key.space) == 0
    [presstime keycode delta] = KbWait;
end

%Start Video Recording
if USE_VIDEO
    % Start capture -
    [fps t] = Screen('StartVideoCapture', grabber, 30, 0);
end

% put up fixation
Screen('CopyWindow',disp.fixation.w,window);
startfix = Screen('Flip',window);
WaitSecs(STARTFIX);

% trial loop
trial = 1;
endExperiment = false;
while trial <= length(q) || ~endExperiment
    
    %Record Data
    % 'Subject,Trial,QuestionIndex,ExperimentStart,FixationOnset,FixationOffset,FixationDur,QuestionOnset,QuestionOffset,QuestionDuration,QuestionRating,SocialNorm,FeedbackOnset,FeedbackOffset,FeedbackDur,GuiltOnset,GuiltOffset,GuiltDur,GuiltRating,AngerOnset,AngerOffset,AngerDur,AngerRating,FearOnset,FearOffset,FearDur,FearRating,HappinessOnset,HappinessOffset,HappinessDur,HappinessRating,PrideOnset,PrideOffset,PrideDur,PrideRating,SadnessOnset,SadnessOffset,SadnessDur,SadnessRating,ShameOnset,ShameOffset,ShameDur,ShameRating,SurpriseOnset,SurpriseOffset,SurpriseDur,SurpriseRating';
    timings(1) = SUBID;
    timings(2) = trial;
    timings(3) = qind(trial);
    timings(4) = startfix;
    
    %%% Fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('CopyWindow',disp.fixation.w,window);
    timings(5) = Screen('Flip',window);
    WaitSecs(FIXDUR(trial));
    timings(6) = GetSecs;
    timings(7) = timings(7) - timings(6);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Question
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [timings(8) timings(9) timings(10) timings(11)] = GetRating(window, rect, screenNumber, 'txt', q{trial}, 'type','line','anchor', {'None','A Lot'});
    WaitSecs(questionDur);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%% Feedback
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    timings(12) = randomSample(timings(11),20,'cutoff',[0,1],'sign',select_sign(trial)); %Social Norm
    if timings(11) > timings(12)
        fbck = 'You have reported more than most other mothers';
    elseif timings(11) < timings(12)
        fbck = 'You have reported less than most other mothers';
    else
        fbck = 'You have reported about the same as most other mothers';
    end
    [timings(13) timings(14) timings(15)] = ShowRating([timings(11), timings(12)], feedbackDur, window, rect, screenNumber, 'txt', [q{trial} '\n\nRed line indicates your response\nGreen line indicates what most other mothers report\n\n' fbck], 'type','line', 'anchor', {'None','A Lot'});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%% Short Fixation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('CopyWindow',disp.fixation.w,window);
    Screen('Flip',window);
    WaitSecs(1.5)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Emotion Ratings - Probably should randomize these per question
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lastt = 15;
    for e = 1:length(emotions)
        [timings(lastt + 1) timings(lastt + 2) timings(lastt + 3) timings(lastt + 4)] = GetRating(window, rect, screenNumber, 'txt',['How much ' emotions{e} ' do you feel?'],'type','line', 'anchor', {'None','A Lot'});
        lastt = lastt + 4;
        
        % Wait for 1 second in between each rating
        Screen('Flip',window);
        WaitSecs(1)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Append data to file after every trial
    dlmwrite(fullfile(fPath,'Data',[num2str(SUBID) '_Postpartum.csv']), timings, 'delimiter',',','-append','precision',10)
    
end


% END SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('TextSize',window,72);
DrawFormattedText(window,'END','center','center',255);
WaitSecs('UntilTime',ENDSCREENDUR);
timing.endscreen = Screen('Flip',window);
WaitSecs(ENDSCREENDUR);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FINISH UP

if USE_VIDEO
    % Stop capture engine and recording:
    Screen('StopVideoCapture', grabber);
    telapsed = GetSecs - t;
    
    % Close engine and recorded movie file:S
    Screen('CloseVideoCapture', grabber);
    
    %Write out timing information
    dlmwrite(fullfile(fPath,'Data',['Video_' num2str(SUBID) '_Postpartum_Timing.txt']),[telapsed,fps])
end

Screen('CloseAll');
ShowCursor;
Priority(0);
sca;


