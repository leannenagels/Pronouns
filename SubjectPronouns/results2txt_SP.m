% results folder path
cd('./SubPro Pilot/');

% open file 
fileID = fopen('SP_results.txt','wt');
% column names
fprintf(fileID,'subID\ttrial\tphase\tbias\tsndFile\tNP1\tNP1Idx\tNP2\tNP2Idx\tsndOnset\tkeyStroke\tsubRT\tkey\tbiasKey \n');
%fprintf(fileID,'subID\tphase\tverb\trefexIma\trefexSnd\tcondition\tkey\tanswer\tRT\tsubRT\tacc \n');


% get all mat files in results folder
files = dir('*.mat');
nFiles = length(files);
for ifiles = 1:nFiles
    load(files(ifiles).name);
    [~, startIndex] = regexp(files(ifiles).name,'SubjPro_');
    [endIndex, ~] = regexp(files(ifiles).name,'.mat');
    subID = files(ifiles).name(startIndex+1 : endIndex-1);
    
    nTrials = length(dataStr);
    
    for iTrial = 1 : nTrials
    fprintf(fileID,'%s\t', subID); % subID
    fprintf(fileID,'%i\t', iTrial); % trial
    fprintf(fileID,'%s\t', dataStr(iTrial).phase); % phase
    fprintf(fileID,'%s\t', dataStr(iTrial).bias); % verb bias
    fprintf(fileID,'%s\t', dataStr(iTrial).soundFile); % sndFile
    fprintf(fileID,'%s\t', dataStr(iTrial).NP1); % NP1 
    fprintf(fileID,'%s\t', dataStr(iTrial).np1Idx); % NP1 index
    fprintf(fileID,'%s\t', dataStr(iTrial).NP2);  % NP2
    fprintf(fileID,'%s\t', dataStr(iTrial).np2Idx); % NP2 index
    % fprintf(fileID,'%d\t', dataStr(iTrial).destinationRect); %
    % destinationRect probably only necessary for EDF file
    fprintf(fileID,'%1.3f\t', dataStr(iTrial).soundOnset); % soundOnset
    fprintf(fileID,'%1.3f\t', dataStr(iTrial).keyStroke); % time of keyStroke
    fprintf(fileID,'%1.3f\t', dataStr(iTrial).subRT); % subtracted reactionTime
    fprintf(fileID,'%s\t', dataStr(iTrial).key); % Pressed key ID
    if strcmp(dataStr(iTrial).bias, 'np1')
        fprintf(fileID,'%s\t', dataStr(iTrial).np1Idx); % Position of bias predicted picture
    elseif strcmp(dataStr(iTrial).bias, 'np2')
        fprintf(fileID,'%s\t', dataStr(iTrial).np2Idx); % Position of bias predicted picture
    end
    fprintf(fileID,'\n');
    end
    
end
fclose(fileID);