clear all, close all

% gain silent room is -26; harmonie building is -27
gain = -27;  

commandwindow
Gamepad('GetButton', 1, 5)
Gamepad('GetButton', 1, 6)

%% Read in soundfiles 
% Load the stimuli here so that if there is an error because the
% file is not found the PSYCHTOOLBOX functions have not been called yet.

[y, freq] = audioread('aap.kietelen.self.wav');
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 0, 1, 1, 44100, 2);
sndmatrix = repmat(y', [2, 1])*10^(gain/20);
sndmatrix = zeros(size(sndmatrix));  % make it all zeros so that you can't hear anything
PsychPortAudio('FillBuffer', pahandle, sndmatrix);
PsychPortAudio('Start', pahandle, 1); 
pause(2); % this is to make sure that all the mex files are loaded in matlab before anything starts


% Define resultfolder or make one
ResultsFolder ="Results/";
if ~exist(ResultsFolder, 'dir')
    fprintf('%s does not exists\n', ResultsFolder);
    return
end


% Enter participant number
fail1='Program aborted. Participant number not entered'; % error message which is printed to command window
prompt = {'Participant ID:','participant number:'};
dlg_title = 'New Participant';
num_lines = 1;
default = {'00', '00'};
Resultsfolder = dir('\results*');
ParticipantInfo = inputdlg(prompt,dlg_title,num_lines,default); % presents box to enter data into
ParticipantID=(ParticipantInfo{1});
ParticipantNum=(ParticipantInfo{2});

% load stimuliSetup
load stimuliSetup.mat


        % initialize eyetracker
        edfFile   = ['OP_s', ParticipantInfo{1}]; 
        initializedummy=0;
        if initializedummy~=1
            if Eyelink('initialize') ~= 0
                fprintf('error in connecting to the eye tracker');
                return;
            end
        else
            Eyelink('initializedummy');
        end
        
        
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
        
        el.cal_target_beep=[600 0 0.05];
        el.drift_correction_target_beep=[600 0 0.05];
        el.calibration_failed_beep=[400 0 0.25];
    	el.calibration_success_beep=[800 0 0.25];
        el.drift_correction_failed_beep=[400 0 0.25];
        el.drift_correction_success_beep=[800 0 0.25];
        el.displayCalResults = 1;
%         el.eyeimgsize=50;
        
        
        % you must call this function to apply the changes from above
        EyelinkUpdateDefaults(el);
        EyelinkDoTrackerSetup(el, 'c');



% % randomize trial order, but keeping first 2 trials as practice trials
nTrials = length(dataStr);
tmp1 = dataStr(contains({dataStr.phase}, 'practice')); % two practice trials
    idx_tmp1 = ones(1,2);
    A1 = num2cell(idx_tmp1);
    [tmp1.targetIdx] = A1{:};
    [tmp1.sndFileIdx] = A1{:};
tmp2 = dataStr(contains({dataStr.phase}, 'test')); % test items
tmp3 = dataStr(contains({dataStr.phase}, 'filler')); % filler items
    idx_tmp3 = ones(1,8);
    B1 = num2cell(idx_tmp3);
    [tmp3.targetIdx] = B1{:};
    [tmp3.sndFileIdx] = B1{:};

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
[y, freq] = audioread('aap.kietelen.other.wav');
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
   
    % save subject id and number, and trial num
    dataStr(iTrial).subID = ParticipantID;
    dataStr(iTrial).subNUM = ParticipantNum;
    dataStr(iTrial).trial = iTrial;
    
    HideCursor; % while image is shown hide the mouse cursor
   
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

            
    %% load in figures, get sizes and specify locations of presentation
    width = zeros(1,2);
    height = zeros(1,2);
    
    % read in image from structs
    if dataStr(iTrial).targetIdx == 1 % reflexive item
        if dataStr(iTrial).revIdx == 1 % not mirrored
            target = imread(dataStr(iTrial).image_refl, 'JPG');
            dataStr(iTrial).targetima = dataStr(iTrial).image_refl;
        else % mirrored
            target = imread(dataStr(iTrial).image_refl_rev, 'JPG');
            dataStr(iTrial).targetima = dataStr(iTrial).image_refl_rev;
        end
    else % pronoun item
        if dataStr(iTrial).revIdx == 1 % not mirrored
            target = imread(dataStr(iTrial).image_pro, 'JPG');
            dataStr(iTrial).targetima = dataStr(iTrial).image_pro;
        else % mirrored
            target = imread(dataStr(iTrial).image_pro_rev, 'JPG');
            dataStr(iTrial).targetima = dataStr(iTrial).image_pro_rev;
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
    if dataStr(iTrial).sndFileIdx == 1
        [y, freq] = audioread([dataStr(iTrial).sndFile_refl]);
        dataStr(iTrial).targetsndFile = dataStr(iTrial).sndFile_refl;
    else
        [y, freq] = audioread([dataStr(iTrial).sndFile_pro]);
        dataStr(iTrial).targetsndFile = dataStr(iTrial).sndFile_pro;
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

    
    % Show image and buttons
    Screen('DrawTextures', wdw, imageTexture, [], [], 0);
    Screen('DrawTextures', wdw, button_rightTexture, [], RightRect);
    Screen('DrawTextures', wdw, button_wrongTexture, [], WrongRect);
    
    dataStr(iTrial).imageTexture = imageTexture;
    dataStr(iTrial).button_rightTexture = RightRect;
    dataStr(iTrial).button_rightonTexture = RightRecton;   
    dataStr(iTrial).button_wrongTexture = WrongRect;
    dataStr(iTrial).button_wrongonTexture = WrongRecton;
    
            % STEP 7.4.1 - EYETRACKES
            % mark zero-plot time in data file
            Eyelink('message', 'TRIAL=%i onsetVisualStim', iTrial);

            
    % Check timestamp for screenflip
    [pictureOnset, dataStr(iTrial).OnsetTime2] = Screen('Flip', wdw, timeBlank + .6);

    
    % THIS NEEDS TO BE CHECKED
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
            dataStr(iTrial).answer = 'correct';
            break;
        end
        if Gamepad('GetButton', gamepadIndex, 6)
            dataStr(iTrial).keyStroke = GetSecs;
            dataStr(iTrial).key = 'right';
            dataStr(iTrial).answer = 'wrong';
            break;
        end
    end
    dataStr(iTrial).RT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset; % - dataStr(iTrial).duration;
    
    if dataStr(iTrial).sndFileIdx == 1
        dataStr(iTrial).subRT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset - dataStr(iTrial).sndDuration_refl;
    else
        dataStr(iTrial).subRT = dataStr(iTrial).keyStroke - dataStr(iTrial).soundOnset - dataStr(iTrial).sndDuration_pro;
    end
    
    
    %    button response
    switch dataStr(iTrial).key
        case 'left'
            Screen('DrawTextures', wdw, button_rightonTexture, [], RightRecton);
        case 'right'
            Screen('DrawTextures', wdw, button_wrongonTexture, [], WrongRecton);
    end
    Screen('Flip', wdw);    
        
    % if targetIdx and sndFile match than condition = 'match', else
    % 'mismatch'
    dataStr(iTrial).condition = 'mismatch'; % NO
    if dataStr(iTrial).targetIdx == dataStr(iTrial).sndFileIdx
        dataStr(iTrial).condition = 'match'; % YES     
        
                % EYELINK
                Eyelink('message', 'match response'); % response type
    end
    
    % make accuracy variable
    dataStr(iTrial).acc = 0;
    if strcmp(dataStr(iTrial).condition, 'match') % for match condition 
        if strcmp(dataStr(iTrial).answer, 'correct') % if sub pressed correct...
            dataStr(iTrial).acc = 1; % acc is 1
        else 
           dataStr(iTrial).acc = 0; % else it is 0
        end
    end
    if strcmp(dataStr(iTrial).condition, 'mismatch') % for mismatch condition 
        if strcmp(dataStr(iTrial).answer, 'correct') % if sub pressed correct...
            dataStr(iTrial).acc = 0; % acc is 0
        else 
           dataStr(iTrial).acc = 1; % else it is 1
        end
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
    
    % wait for pupillometry
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
    if iTrial == 21
        pauze = imread('pauze.png', 'BackgroundColor', bg);
        Screen(wdw,'PutImage', pauze);
        Screen('Flip', wdw);
        KbWait
    end
    

end % end trials

% save struct with the results
save(sprintf('results/s%s_ObjPro_%s.mat', ParticipantID, ParticipantNum), 'dataStr');

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






