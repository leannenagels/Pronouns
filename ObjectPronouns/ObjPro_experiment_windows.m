clear all, close all

% gain
gain = -26;

commandwindow


%% Read in soundfiles 
% Load the stimuli here so that if there is an error because the
% file is not found the PSYCHTOOLBOX functions have not been called yet.

[y, freq] = audioread(fullfile('equalized','aap.kietelen.self.wav'));
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 2, 1, 1, 44100, 2);
sndmatrix = repmat(y', [2, 1])*10^(gain/20);
sndmatrix = zeros(size(sndmatrix));  % make it all zeros so that you can't hear anything
PsychPortAudio('FillBuffer', pahandle, sndmatrix);
PsychPortAudio('Start', pahandle, 1); 
pause(2); % this is to make sure that all the mex files are loaded in matlab before anything starts


% Define resultfolder or make one
ResultsFolder ="results/";
if ~exist(ResultsFolder, 'dir')
    fprintf('%s does not exists\n', ResultsFolder);
    return
end


% collect participant information
fail1='Program aborted. Participant number not entered'; % error message which is printed to command window
prompt = {'Participant ID:','Participant Number:'};
dlg_title = 'New Participant';
num_lines = 1;
default = {'PKS00', '00'};
Resultsfolder = dir('results/');
ParticipantInfo = inputdlg(prompt,dlg_title,num_lines,default); % presents box to enter data into
ParticipantID=(ParticipantInfo{1});
ParticipantNum=(ParticipantInfo{2});

% load stimuliSetup
load stimuliSetup.mat

% Prevent psychtoolbox warnings
% PSYCHTOOLBOX settings        
oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'SkipSyncTests', 1);


% PSYCHTOOLBOX open window commands
screenNumber = max(Screen('Screens'));
[wdw, wdwSize] = Screen('OpenWindow', screenNumber, [255 255 255]); % window color is grey


% assign maximum possible priority
Priority(MaxPriority(wdw));

% % randomize trial order, but keeping first 2 trials as practice trials
nTrials = length(dataStr);
tmp1 = dataStr(contains({dataStr.phase}, 'practice')); % two practice trials
tmp2 = dataStr(contains({dataStr.phase}, 'test')); % test items
tmp3 = dataStr(contains({dataStr.phase}, 'filler')); % filler items

% for practice items
idxpractice = ones(1,2);
P = num2cell(idxpractice);
[tmp1.targetIdx] = P{:};
[tmp1.sndFileIdx] = P{:};

% for fillers
idxfiller = ones(1,8);
F = num2cell(idxfiller);
[tmp3.targetIdx] = F{:};
[tmp3.sndFileIdx] = F{:};

tmp2a = tmp2(contains({tmp2.verb}, 'grooming'));
    rng('shuffle','twister');
    tmp2a = tmp2a(randperm(length(tmp2a)));
    idx1 = [zeros(1,8), ones(1,8)];
    A = num2cell(idx1);
    [tmp2a.targetIdx] = A{:};
    idx2 = [zeros(1,4), ones(1,4), zeros(1,4), ones(1,4)];
    B = num2cell(idx2);
    [tmp2a.sndFileIdx] = B{:};
     
tmp2b = tmp2(contains({tmp2.verb}, 'transitive'));
   rng('shuffle','twister');
   tmp2b = tmp2b(randperm(length(tmp2b)));
   idx3 = [zeros(1,8), ones(1,8)];
   C = num2cell(idx3);
   [tmp2b.targetIdx] = C{:};
   idx4 = [zeros(1,4), ones(1,4), zeros(1,4), ones(1,4)];
   D = num2cell(idx4);
   [tmp2b.sndFileIdx] = D{:};
    
tmp2 = [tmp2a, tmp2b];

rng('shuffle','twister'); % this is to make sure that the randomization differ every time matlab is started
tmp2 = tmp2(randperm(length(tmp2))); % randomize test items

dataStr = [tmp1, tmp2(1:2), tmp3(1), tmp2(3:5), tmp3(2), tmp2(6:10), tmp3(3),...
    tmp2(11:13),tmp3(4), tmp2(14:20), tmp3(5), tmp2(21), tmp3(6), tmp2(22:25), ...
    tmp3(7), tmp2(26:30), tmp3(8), tmp2(31:32)];
          %1:2  %3:4        %5       %6:8       %9       %10:14      %15
          %16:18 %19  %20:26  %27   %28  %29  %30:33  %34 %35:39 %40 %41:42
% fillers in trial 5, 9, 15, 19, 27, 29, 34, 40



% make indices for target position mirrored or not mirrored
idx = [zeros(1,21), ones(1,21)];
rng('shuffle','twister');
idx = idx(randperm(2*21));
C = num2cell(idx);
[dataStr.revIdx] = C{:};


% if participants name is 'test' than only 5 trials will be run.
if strcmp(ParticipantID, 'test')
    nTrials = 5;
end

% read in soundfiles again
[y, freq] = audioread(fullfile('equalized','aap.kietelen.self.wav'));
InitializePsychSound(1);

% make sndmatrix 
sndmatrix = repmat(y', [2, 1])*10^(gain/20);
sndmatrix = zeros(2, length(y)); % initialize to play no sound

PsychPortAudio('FillBuffer', pahandle, sndmatrix);
tic;
t1 = PsychPortAudio('Start', pahandle, 1); 
x = toc;
pause(2); % this is to make sure that all the mex files are loaded in matlab before anything starts

% start button
bg = [0.999 0.999 0.999];
start = imread('start.png', 'BackgroundColor', bg);
Screen(wdw,'PutImage', start);
Screen('Flip', wdw);
KbWait



%% Experiment loop for each trial %% 

for iTrial = 1 : nTrials
    % Make and save participant file with struct
    save(sprintf('results/s%s_ObjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');
   
    HideCursor; % while image is shown hide the mouse cursor
   
    %% load in figures, get sizes and specify locations of presentation
    width = zeros(1,2);
    height = zeros(1,2);
    
    % read in image from structs
    if dataStr(iTrial).targetIdx == 1 % reflexive item
        if dataStr(iTrial).revIdx == 1 % not mirrored
            target = imread(dataStr(iTrial).image_refl, 'JPG');
        else % mirrored
            target = imread(dataStr(iTrial).image_refl_rev, 'JPG');
        end
    else % pronoun item
        if dataStr(iTrial).revIdx == 1 % not mirrored
            target = imread(dataStr(iTrial).image_pro, 'JPG');
        else % mirrored
            target = imread(dataStr(iTrial).image_pro_rev, 'JPG');
        end
    end
    imageTexture = Screen('MakeTexture', wdw, target);
    
    
    % Read in buttons and positions
    xbutton_right= round(wdwSize(3) * 1/8);
    ybutton_right = round(wdwSize(4) * 7/8);
    xbutton_wrong= round(wdwSize(3) * 7/8);
    ybutton_wrong = round(wdwSize(4) * 7/8);

    button_right = imread('button_right.png', 'BackgroundColor', bg);
    button_rightTexture = Screen('MakeTexture', wdw, button_right);
    button_rightWidth = size(button_right, 1);
    button_rightHeight = size(button_right, 2);
    RightRect = [xbutton_right-button_rightWidth/2, ybutton_right-button_rightHeight, xbutton_right+button_rightWidth/2, ybutton_right]; 
    
    button_righton = imread('button_right_pressed.png', 'BackgroundColor', bg);
    button_rightonTexture = Screen('MakeTexture', wdw, button_righton);
    button_rightonWidth = size(button_righton, 1);
    button_rightonHeight = size(button_righton, 2);
    RightRecton = [xbutton_right-button_rightonWidth/2, ybutton_right-button_rightonHeight, xbutton_right+button_rightonWidth/2, ybutton_right]; 

    button_wrong = imread('button_wrong.png', 'BackgroundColor', bg);
    button_wrongTexture= Screen('MakeTexture', wdw, button_wrong);
    button_wrongWidth = size(button_wrong, 1);
    button_wrongHeight = size(button_wrong, 2);
    WrongRect = [xbutton_wrong-button_wrongWidth/2, ybutton_wrong-button_wrongHeight, xbutton_wrong+button_wrongWidth/2, ybutton_wrong];

    button_wrongon = imread('button_wrong_pressed.png', 'BackgroundColor', bg);
    button_wrongonTexture = Screen('MakeTexture', wdw, button_wrongon);
    button_wrongonWidth = size(button_wrongon, 1);
    button_wrongonHeight = size(button_wrongon, 2);
    WrongRecton = [xbutton_wrong-button_wrongonWidth/2, ybutton_wrong-button_wrongonHeight, xbutton_wrong+button_wrongonWidth/2, ybutton_wrong];

    
    %% stimulus display and sound

    % load sound before startingtime critical operations
    if dataStr(iTrial).sndFileIdx == 1
        [y, freq] = audioread(fullfile('equalized', [dataStr(iTrial).sndFile_refl]));
    else
        [y, freq] = audioread(fullfile('equalized', [dataStr(iTrial).sndFile_pro]));
    end
    sndmatrix = repmat(y', [2, 1])*10^(gain/20);
    PsychPortAudio('FillBuffer', pahandle, sndmatrix);
    
    
%     if dataStr(iTrial).sndFileIdx == 1
%         dataStr(iTrial).sndDuration_refl = length(y)./freq;
%     else
%         dataStr(iTrial).sndDuration_pro = length(y)./freq;
%     end
    
    % blank for 600 ms
    Screen('FillRect', wdw);
    [timeBlank, dataStr(iTrial).OnsetTime1] = Screen('Flip', wdw);      
    

    % Show image and buttons
    Screen('DrawTextures', wdw, imageTexture, [], [], 0);
    Screen('DrawTextures', wdw, button_rightTexture, [], RightRect);
    Screen('DrawTextures', wdw, button_wrongTexture, [], WrongRect);
    
    % Check timestamp for screenflip
    [pictureOnset, dataStr(iTrial).OnsetTime2] = Screen('Flip', wdw, timeBlank + .6);

    
    % THIS NEEDS TO BE CHECKED
    tic;
    dataStr(iTrial).soundOnset = PsychPortAudio('Start', pahandle, 1, (pictureOnset + 1.5), 1);
    dataStr(iTrial).commandDelay = toc;

    
    %% response collection
    % Collect keyboard responses
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;% Wait for and check which key was pressed
    while ~any(keyIsDown) % wait for press
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        dataStr(iTrial).keyStroke = GetSecs;
        dataStr(iTrial).RT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset; % - dataStr(iTrial).duration;
    end
    
    while any(keyIsDown) % wait for release
        [~, ~, keyIsDown] = KbCheck;
    end

    dataStr(iTrial).response = KbName(keyCode);
    dataStr(iTrial).responsenumber = find(keyCode);
  
    %    button response
    if KbName(keyCode) == 'w'
        Screen('DrawTextures', wdw, button_rightonTexture, [], RightRecton);
        Screen('Flip', wdw);    
    else
        Screen('DrawTextures', wdw, button_wrongonTexture, [], WrongRecton);
        Screen('Flip', wdw);    
    end

    
%     if KbName(keyCode) == 'w'
%         Screen('DrawTextures', wdw, button_rightonTexture, [], RightRecton);
%         Screen('Flip', wdw);    
%     else
%         Screen('DrawTextures', wdw, button_wrongonTexture, [], WrongRecton);
%         Screen('Flip', wdw);    
%     end
        
    
%     %% if the 'q' key is pressed, the soundstimulus will be played again and
%     % a second RT and response will be registered. 
%     if dataStr(iTrial).response == 'q'
%         tic;
%         dataStr(iTrial).soundOnset2 = PsychPortAudio('Start', pahandle, 1, 0, 1);
%         dataStr(iTrial).commandDelay2 = toc;
% 
%         % check which key was pressed after q press
%         [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();% Wait for and check which key was pressed
%         while ~any(keyIsDown) % wait for press
%             [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
%             dataStr(iTrial).keyStroke2 = GetSecs;
%             dataStr(iTrial).RT2 = dataStr(iTrial).keyStroke2 - dataStr(iTrial).soundOnset2;
%         end
% 
%         while any(keyIsDown) % wait for release
%             [~, ~, keyIsDown] = KbCheck();
%         end
%    
%         dataStr(iTrial).response2 = KbName(keyCode);
%         dataStr(iTrial).responsenumber2 = find(keyCode);
%         
%     end

    % if targetIdx and sndFile match than condition = 'match', else
    % 'mismatch'
    dataStr(iTrial).condition = 'mismatch'; % NO
    if dataStr(iTrial).targetIdx == dataStr(iTrial).sndFileIdx
        dataStr(iTrial).condition = 'match'; % YES                          
    end

    % if targetIdx is 0 than refexIma = 'pronoun', else 'reflexive'
    dataStr(iTrial).refexIma = 'pro'; % 0 is pronoun, if 1 then reflexive
    if dataStr(iTrial).targetIdx == 1
        dataStr(iTrial).refexIma = 'refl';                          
    end
    
    % if sndFileIdx is 0 than refexSnd = 'pronoun', else 'reflexive'
    dataStr(iTrial).refexSnd = 'pro'; % 0 is pronoun, if 1 then reflexive
    if dataStr(iTrial).sndFileIdx == 1
        dataStr(iTrial).refexSnd = 'refl';                        
    end

%     WaitSecs(1.5);
    
    % after two trials show a screen saying that these were the examples
    if iTrial == 2
        Screen('TextSize', wdw, 25);
        DrawFormattedText(wdw, 'Dit waren de voorbeelden.\n\n Het experiment begint nu.', 'center', 'center', [0 0 0]);
        Screen('Flip', wdw);
        KbWait
    end
    
    % optional break
    if iTrial == 21
        pauze = imread('pauze.png', 'BackgroundColor', bg);
        Screen(wdw,'PutImage', pauze);
        Screen('Flip', wdw);
        KbWait
    end
    

end % end trials

% save struct with the results
save(sprintf('results/s%s_ObjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');

WaitSecs(0.5);

PsychPortAudio('Close');

% show final screen
einde = imread('einde.png', 'BackgroundColor', bg);
Screen(wdw,'PutImage', einde);
Screen('Flip', wdw);
pause(5);


sca






