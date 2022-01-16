clear all, close all

% gain 
gain = -25; 

commandwindow

%% Read all soundFiles in
% Load the stimuli here so that if there is an error because the
% file is not found the PSYCHTOOLBOX functions have not been called yet.
[y, freq] = audioread(fullfile('equalized', 'aap.winnen.hert.np1.wav'));
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 8 , 1, 1, 44100, 2);
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
   

% PSYCHTOOLBOX settings        
oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'SkipSyncTests', 1);

% PSYCHTOOLBOX open window commands
screenNumber = max(Screen('Screens'));
[wdw, wdwSize] = Screen('OpenWindow', screenNumber, [255 255 255]); % color is grey

% assign maximum possible priority
Priority(MaxPriority(wdw));
    

% randomize trial order, but keeping last 3 trials as practice trials (first 2 trials)
nTrials = length(dataStr);
tmp1 = dataStr(contains({dataStr.phase}, 'practice')); % two practice trials
tmp2 = dataStr(contains({dataStr.phase}, 'test')); % test items
tmp3 = dataStr(contains({dataStr.phase}, 'filler')); % filler items

% randomize test items, but keep practice items and filler items the same
rng('shuffle','twister'); % this is to make sure that the randomization differ every time matlab is started
tmp2 = tmp2(randperm(length(tmp2))); % randomize test items

% filler items should appear in the same order
dataStr = [tmp1, tmp2(1), tmp3(1), tmp2(2:4), tmp3(2), tmp2(5:6), tmp3(3), tmp2(7:9),tmp3(4), tmp2(10:14), tmp3(5), tmp2(15:16), tmp3(6:7), tmp2(17:18), tmp3(8), tmp2(19:20)];
          %1:2  %3        %4       %5:7       %8       %9:10      %11
          %12:14    %15     %16:20  %21 %22:23  %6:7 %26:27 %28 %29:30
          % fillers in trial 4, 8, 11, 15, 21, 24, 25, 28

          
% if participants name is 'test' than only 3 trials will be run.
if strcmp(ParticipantID, 'test')
    nTrials = 5;
end

% make indices for target position (mirrored vs. not-mirrored)
idx = [zeros(1,15), ones(1,15)];
rng('shuffle','twister');
idx = idx(randperm(2*15));
C = num2cell(idx);
[dataStr.revIdx] = C{:};

% initialize psychtoolbox portaudio library
[y, freq] = audioread(fullfile('equalized', 'aap.winnen.hert.np1.wav'));
InitializePsychSound(1);
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

% experiment loop: Now starts running individual trials;
for iTrial = 1 : nTrials

    % save in result file
    save(sprintf('results/s%s_SubjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');

    % Hide the mouse cursor. It is distracting to have it. Reintroduce it 
    % only when the figures are displayed
    HideCursor;
        
  
    %% load in figures, get sizes and specify locations of presentations
    width = zeros(1,2);
    height = zeros(1,2);
    
    % read in NP1 and NP2 images
    if dataStr(iTrial).revIdx == 1 % NP1 is not mirrored and NP2 is mirrored
        NP1 = imread(dataStr(iTrial).NP1, 'PNG');
        dataStr(iTrial).NP1Idx = 2;
        NP2 = imread(dataStr(iTrial).NP2_rev, 'PNG');
        dataStr(iTrial).NP2Idx = 1;
    else % NP1 is mirrored and NP2 is not mirrored
        NP1 = imread(dataStr(iTrial).NP1_rev, 'PNG');
        dataStr(iTrial).NP1Idx = 1; 
        NP2 = imread(dataStr(iTrial).NP2, 'PNG');
        dataStr(iTrial).NP2Idx = 2;
    end
    
    % texture for NP1
    textureIndex(:, dataStr(iTrial).NP1Idx) = Screen('MakeTexture', wdw, NP1);
    heigth(dataStr(iTrial).NP1Idx) = size(NP1, 1);
    width(dataStr(iTrial).NP1Idx) = size(NP1, 2);
    
    % texture for NP2
    textureIndex(:, dataStr(iTrial).NP2Idx) = Screen('MakeTexture', wdw, NP2);
    heigth(dataStr(iTrial).NP2Idx) = size(NP2, 1);
    width(dataStr(iTrial).NP2Idx) = size(NP2, 2);

    
    
    %% compute dimensions presentations
    % divide width and height by half so that we can center the figures.
    % Approximate to next pixels so that the figure is a bit strecthced but not
    % smaller
    dataStr(iTrial).width = width;
    dataStr(iTrial).heigth = heigth;
    
    heigth = floor(heigth ./ 2);
    width = floor(width ./ 2);
    oneThirdScrW = round(wdwSize(3) * 1/3);
    twoThirdScrW = round(wdwSize(3) * 2/3);
    oneThirdScrH = round(wdwSize(4) * 1/3);
    HalfishScrH = round(wdwSize(4) * 7/12);
    twoThirdScrH = round(wdwSize(4) * 2/3);
    distFromCenter = 120;
    destinationRect = zeros(4,2);
    
    % left border
    destinationRect(1, 1) = oneThirdScrW - width(1) - distFromCenter; % left
    destinationRect(1, 2) = twoThirdScrW - width(2) + distFromCenter; % right
    % top border
    destinationRect(2, 1) = HalfishScrH  - heigth(1) - distFromCenter; % left
    destinationRect(2, 2) = HalfishScrH - heigth(2) - distFromCenter; % right
    % right border
    destinationRect(3, 1) = oneThirdScrW + width(1) - distFromCenter; % left
    destinationRect(3, 2) = twoThirdScrW + width(2) + distFromCenter; % right
    % bottom border
    destinationRect(4, 1) = HalfishScrH  + heigth(1) - distFromCenter;% left
    destinationRect(4, 2) = HalfishScrH  + heigth(2) - distFromCenter;% right

    % store for later checks with dataStr(iTrial).heigth and 
    % dataStr(iTrial).width
    dataStr(iTrial).destinationRect = destinationRect;

        
    %% stimulus display and sound
    % load sound before startingtime critical operations
    if exist(dataStr(iTrial).soundFile,'file')
        [y, ~] = audioread(fullfile('equalized', [dataStr(iTrial).soundFile]));
    else
        fprintf('%s is missing\n', dataStr(iTrial).soundFile);
        sca
        return
    end
    sndmatrix = repmat(y', [2, 1])*10^(gain/20);
    PsychPortAudio('FillBuffer', pahandle, sndmatrix);
    
    
    % blank for 600 ms
    Screen('FillRect', wdw);
    [timeBlank, dataStr(iTrial).OnsetTime1] = Screen('Flip', wdw);      
  
    % Show the mouse cursor;
    ShowCursor('Arrow'); % prevent from showing the SandClock during the while loop
    % Move the cursor to the center of the screen, this is so that people
    % will go from the center to the target, in case that the target is in
    % the exact same position
    SetMouse(wdwSize(3)/2, wdwSize(4)/2);
    
  
    % Show images
    Screen('DrawTextures', wdw, textureIndex, [], destinationRect);
    
    % Check timestamp for screenflip
    [pictureOnset, dataStr(iTrial).OnsetTime2] = Screen('Flip', wdw, timeBlank + .6);

    % THIS NEEDS TO BE CHECKED
    % Wait two seconds so that participants can scan the images before the
    % sentence is produced
    
    tic;
    dataStr(iTrial).soundOnset = PsychPortAudio('Start', pahandle, 1, (pictureOnset + 1.5), 1);
    dataStr(iTrial).commandDelay = toc;
    
    %% response collection
    [xM, yM, buttons] = GetMouse(wdw);
    while ~any(buttons) % wait for press
        [dataStr(iTrial).xM, dataStr(iTrial).yM, buttons] = GetMouse(wdw);
%         dataStr(iTrial).RT = GetSecs - dataStr(iTrial).onsetStim;
        dataStr(iTrial).mouseClick = GetSecs;
        dataStr(iTrial).RT = dataStr(iTrial).mouseClick - dataStr(iTrial).soundOnset; %- dataStr(iTrial).duration
    end
    while any(buttons) % wait for release
        [~, ~, buttons] = GetMouse(wdw);
    end

    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
    dataStr(iTrial).response = KbName(keyCode);
    
%         if dataStr(iTrial).response == 'q'
%         tic;
%         dataStr(iTrial).soundOnset2 = PsychPortAudio('Start', pahandle, 1, 0, 1);
%         dataStr(iTrial).commandDelay2 = toc;
% 
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
%         end
    
    
    % Accurate response?
    dataStr(iTrial).acc = 0; % NO
    if dataStr(iTrial).xM >= destinationRect(1, dataStr(iTrial).NP1Idx) && ...
            dataStr(iTrial).xM <= destinationRect(3, dataStr(iTrial).NP1Idx) && ...
            dataStr(iTrial).yM >= destinationRect(2, dataStr(iTrial).NP1Idx) && ...
            dataStr(iTrial).yM <= destinationRect(4, dataStr(iTrial).NP1Idx)
        dataStr(iTrial).acc = 1; % YES
                                
    end
    
   
    if iTrial == 2
        Screen('Flip', wdw);
        Screen('TextSize', wdw, 42);
%         Screen('DrawText', wdw, 'Dat waren de voorbeelden.', 550, 450,[255 0 0])%  , 1, 0, 1);
%         Screen('DrawText', wdw, 'Het experiment begint nu!', 550, 550,[255 0 0])%  , 1, 0, 1);
        DrawFormattedText(wdw, 'Dit waren de voorbeelden. \n\n Het experiment begint nu!', 'center', 'center', [255 0 0]);
        Screen('Flip', wdw);
        KbWait
    end
    
    % optional break
    if iTrial == 16
        pauze = imread('pauze.png', 'BackgroundColor', bg);
        Screen(wdw,'PutImage', pauze);
        Screen('Flip', wdw);
        KbWait
    end
    

end % end trials

save(sprintf('results/s%s_SubjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');

WaitSecs(0.5);


% pa('reset');
PsychPortAudio('Close');

% show final screen
einde = imread('einde.png', 'BackgroundColor', bg);
Screen(wdw,'PutImage', einde);
Screen('Flip', wdw);
pause(5);

sca






