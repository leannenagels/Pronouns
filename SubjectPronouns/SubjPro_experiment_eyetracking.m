clear all, close all

% gain
gain = -25; 

% todo list:
commandwindow
Gamepad('GetButton', 1, 5)
Gamepad('GetButton', 1, 6)


%% Read in soundfiles 
% Load the stimuli here so that if there is an error because the
% file is not found the PSYCHTOOLBOX functions have not been called yet.
[y, freq] = audioread('aap.winnen.hert.np1.wav');
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 0, 1, 1, 44100, 2);
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
default = {'00', '00'};
Resultsfolder = dir('results/');
ParticipantInfo = inputdlg(prompt,dlg_title,num_lines,default); % presents box to enter data into
ParticipantID=(ParticipantInfo{1});
ParticipantNum=(ParticipantInfo{2});

% load stimuliSetup
load stimuliSetup.mat
   


        % initialize eyetracker
        edfFile   = ['SP_s', ParticipantInfo{1}]; 
        initializedummy=0;
        if initializedummy~=1
            if Eyelink('initialize') ~= 0
                fprintf('error in connecting to the eye tracker');
                return;
            end
        else
            Eyelink('initializedummy');
        end


% PSYCHTOOLBOX settings        
oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'SkipSyncTests', 1);

% PSYCHTOOLBOX open window commands
screenNumber = max(Screen('Screens'));
[wdw, wdwSize] = Screen('OpenWindow', screenNumber, [255 255 255]); % color is grey

% assign maximum possible priority
Priority(MaxPriority(wdw));
    

        % EYELINK
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        
        el = EyelinkInitDefaults(wdw);
%         el.backgroundcolour = 255;
        
        if ~EyelinkInit(initializedummy, 1)
            fprintf('Eyelink Init aborted.\n');
            cleanup;  % cleanup function
            return;
        end
        
        [v, vs] = Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
        
        % open file to record data to
        i = Eyelink('Openfile', edfFile);
        if i~=0
            fprintf('Cannot create EDF file ''%s'' ', edfFile);
            fprintf('filename can be only 8 characters long/n');
            
            Eyelink( 'Shutdown');
            sca; % clear screen otherwise how to we know
            return;
        end
        
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox comparativeSearch_eyeTracker-experiment''');

        % SET UP TRACKER CONFIGURATION
        % Setting the proper recording resolution, proper calibration type,
        % as well as the data file content;
        Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, wdwSize(3)-1, wdwSize(4)-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, wdwSize(3)-1, wdwSize(4)-1);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');
        % set parser (conservative saccade thresholds)
        Eyelink('command', 'saccade_velocity_threshold = 35');
        Eyelink('command', 'saccade_acceleration_threshold = 9500');
        % set EDF file contents
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
        % allow to use the big button on the eyelink gamepad to accept the
        % calibration/drift correction target
        Eyelink('command', 'button_function 5 "accept_target_fixation"');
        
        % make sure we're still connected.
        if Eyelink('IsConnected')~=1
            fprintf('ending because not connected to eyetracker')
            return;
        end
        
        % STEP 6 - EYELINK
        % Calibrate the eye tracker
        % setup the proper calibration foreground and background colors
%         el.foregroundcolour = 0;
        % all our experiment is displayed in white, so we should change
        % this to white as well
%         el.backgroundcolour = 255;
        
        % STEP 4
        % Calibrate the eye tracker
        
        el=EyelinkInitDefaults(wdw);
    
        el.backgroundcolour = WhiteIndex(el.window);
%         el.msgfontcolour    = BlackIndex(el.window);
%         el.imgtitlecolour = BlackIndex(el.window);
%         el.targetbeep = 0;
%         el.calibrationtargetcolour= BlackIndex(el.window);
%         el.calibrationtargetsize= 1;
%         el.calibrationtargetwidth=0.5;
        el.displayCalResults = 1;
%         el.eyeimgsize=50;

        el.cal_target_beep=[600 0 0.05];
        el.drift_correction_target_beep=[600 0 0.05];
        el.calibration_failed_beep=[400 0 0.25];
    	el.calibration_success_beep=[800 0 0.25];
        el.drift_correction_failed_beep=[400 0 0.25];
        el.drift_correction_success_beep=[800 0 0.25];
        el.displayCalResults = 1;
%        el.eyeimgsize=50;
        EyelinkUpdateDefaults(el);

        
        EyelinkDoTrackerSetup(el, 'c');


% randomize trial order, but keeping last 3 trials as practice trials (first 2 trials)
nTrials = length(dataStr);
tmp1 = dataStr(contains({dataStr.phase}, 'practice')); % two practice trials
tmp2 = dataStr(contains({dataStr.phase}, 'test')); % test items
tmp3 = dataStr(contains({dataStr.phase}, 'filler')); % filler items

% randomize test items, but keep practice items and filler items the same
rng('shuffle','twister'); % this is to make sure that the randomization differ every time matlab is started
tmp2 = tmp2(randperm(length(tmp2))); % randomize test items

% filler items should appear in the same order
dataStr = [tmp1, tmp2(1), tmp3(1), tmp2(2:4), tmp3(2), tmp2(5:6), tmp3(3), tmp2(7:9),tmp3(4),...
    tmp2(10:14), tmp3(5), tmp2(15:16), tmp3(6:7), tmp2(17:18), tmp3(8), tmp2(19:20)];
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
[y, freq] = audioread('aap.winnen.hert.np1.wav');
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
    
               % Do a drift correction every 5 trials
            % Performing drift correction (checking) is optional for
            % Eyelink 1000 eye trackers.
            % Calibrate the eye tracker
            % do a final check of calibration using driftcorrection
            if mod(iTrial, 5) == 1
                EyelinkDoDriftCorrection(el);
                % return to white background
                Screen('FillRect', wdw, [255, 255, 255])
                Screen('Flip', wdw)
            end

  
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

    
        % commented out because boxes are useless and we do not use that info.    
%         % EYELINK
%         % draw a box at the center of the screen
%         %         Eyelink('command', 'draw_box %d %d %d %d 15', widthScrn/2-50, heightScrn/2-50, widthScrn/2+50, heightScrn/2+50);
%         % draw boxes for each figure
%         Eyelink('command', 'draw_box %d %d %d %d 15', destinationRect(1, 1), destinationRect(2, 1), destinationRect(3, 1), destinationRect(4, 1));
%         Eyelink('command', 'draw_box %d %d %d %d 15', destinationRect(1, 2), destinationRect(2, 2), destinationRect(3, 2), destinationRect(4, 2));
%         Eyelink('command', 'draw_box %d %d %d %d 15', destinationRect(1, 3), destinationRect(2, 3), destinationRect(3, 3), destinationRect(4, 3));
%         Eyelink('command', 'draw_box %d %d %d %d 15', destinationRect(1, 4), destinationRect(2, 4), destinationRect(3, 4), destinationRect(4, 4));
%         % says to allow 500 ms so that command can finish. I leave 2
%         % seconds and we'll see what happens
%         WaitSecs(1.5);

        
    %% stimulus display and sound
    % load sound before startingtime critical operations
    if exist(dataStr(iTrial).soundFile,'file')
        [y, ~] = audioread([dataStr(iTrial).soundFile]);
    else
        fprintf('%s is missing\n', dataStr(iTrial).soundFile);
        sca
        return
    end
    sndmatrix = repmat(y', [2, 1])*10^(gain/20);
    PsychPortAudio('FillBuffer', pahandle, sndmatrix);
    
    
              % EYELINK: initialize trial recording
            Eyelink('command', 'record_status_message "TRIAL %i"', iTrial);
            % start recording eye position (preceded by a short pause so that
            % the tracker can finish the mode transition)
            % The paramerters for the 'StartRecording' call controls the
            % file_samples, file_events, link_samples, link_events availability
            Eyelink('command', 'set_idle_mode');
            
            WaitSecs(0.05);% EYELINK, remove from previous EYELINK bit because it is
            % otherwise recording plenty of rubbish
            Eyelink('StartRecording', 1, 1, 1, 1);
            % record a few samples before we actually start displaying
            % otherwise you may lose a few msec of data
            WaitSecs(0.1);
            Eyelink('message', 'TRIAL STARTS');
 
            
    % blank for 600 ms
    Screen('FillRect', wdw);
    [timeBlank, dataStr(iTrial).OnsetTime1] = Screen('Flip', wdw);      
  
    
         % measure 1 second interval for baseline 2
            if iTrial == 1
                        % EYELINK
                        Eyelink('message', 'BASELINE 2 STARTS');
                        WaitSecs(1.2);
                        Eyelink('message', 'BASELINE 2 ENDS');
            end

    
    % Show images
    Screen('DrawTextures', wdw, textureIndex, [], destinationRect);
    
            % STEP 7.4.1 - EYETRACKES
            % mark zero-plot time in data file
            Eyelink('message', 'TRIAL=%i onsetVisualStim', iTrial);

    
    % Check timestamp for screenflip
    [pictureOnset, dataStr(iTrial).OnsetTime2] = Screen('Flip', wdw, timeBlank + .6);

    % THIS NEEDS TO BE CHECKED
    % Wait two seconds so that participants can scan the images before the
    % sentence is produced
    
    tic;
    dataStr(iTrial).soundOnset = PsychPortAudio('Start', pahandle, 1, (pictureOnset + 1.5), 1);
    dataStr(iTrial).commandDelay = toc;

    
        % STEP 7.4.2 - EYETRACKES
            % mark zero-sound time in data file
            Eyelink('message', 'TRIAL=%i onsetSoundStim', iTrial);

    
    
    %% response collection
    gamepadIndex = 1;
    while 1
        if Gamepad('GetButton', gamepadIndex, 5)
            dataStr(iTrial).keyStroke = GetSecs;
            dataStr(iTrial).key = 'left';
                % EYELINK
                Eyelink('message', 'left response'); % response type            
            break;
        end
        if Gamepad('GetButton', gamepadIndex, 6)
            dataStr(iTrial).keyStroke = GetSecs;
            dataStr(iTrial).key = 'right';
                % EYELINK
                Eyelink('message', 'right response'); % response type            
            break;
        end
    end
    dataStr(iTrial).RT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset; 
    dataStr(iTrial).subRT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset - dataStr(iTrial).soundDuration;
    
    % wait before next trial, only for pupillometry
    WaitSecs(1.5);
                  % EYELINK
                Eyelink('message', 'TRIAL ENDS');
                Eyelink('StopRecording');
                
                
    % after two trials show a screen saying that these were the examples
    if iTrial == 2
        Screen('TextSize', wdw, 46);
        DrawFormattedText(wdw, 'Dit waren de voorbeelden.\n\n Het experiment begint nu.', 'center', 'center', [0 0 0]);
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

% save struct with the results
save(sprintf('results/s%s_SubjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');
WaitSecs(0.5);

    % EYELINK: terminate datacollection, close file and transfer to stim pc
    % End of Experiment; close the file first
    % close graphics window, close data file and shut down tracker
        Eyelink('command', 'set_idle_mode');
    WaitSecs(0.5);
        Eyelink('CloseFile');
    % download data file
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status = Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2 == exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end
    %close the eye tracker.
        Eyelink('ShutDown');


PsychPortAudio('Close');

% show final screen
einde = imread('einde.png', 'BackgroundColor', bg);
Screen(wdw,'PutImage', einde);
Screen('Flip', wdw);
pause(5);

sca






