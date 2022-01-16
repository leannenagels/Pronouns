% results folder path
% cd('Results/');
% cd('../Pilot/');
cd('Pilot/');

% open file 
fileID = fopen('OP_results.txt','wt');
% column names
fprintf(fileID,'subID\ttrial\tphase\tverb\trefexIma\trefexSnd\tcondition\tkey\tRT \n');
%fprintf(fileID,'subID\tphase\tverb\trefexIma\trefexSnd\tcondition\tkey\tanswer\tRT\tsubRT\tacc \n');


% get all mat files in results folder
files = dir('*.mat');
nFiles = length(files);
for ifiles = 1:nFiles
    load(files(ifiles).name);
    [~, startIndex] = regexp(files(ifiles).name,'ObjPro_');
    [endIndex, ~] = regexp(files(ifiles).name,'.mat');
    subID = files(ifiles).name(startIndex+1 : endIndex-1);
    
    nTrials = length(dataStr);
    
    for iTrial = 1 : nTrials
    fprintf(fileID,'%s\t', subID);
    fprintf(fileID,'%i\t', iTrial);
    fprintf(fileID,'%s\t', dataStr(iTrial).phase);
    fprintf(fileID,'%s\t', dataStr(iTrial).verb);
    fprintf(fileID,'%s\t', dataStr(iTrial).refexIma);  
    fprintf(fileID,'%s\t', dataStr(iTrial).refexSnd); 
    fprintf(fileID,'%s\t', dataStr(iTrial).condition);  
    fprintf(fileID,'%s\t', dataStr(iTrial).key); 
    fprintf(fileID,'%1.3f\t', dataStr(iTrial).RT); 
    %fprintf(fileID,'%1.3f\t', dataStr(iTrial).subRT); 
    %fprintf(fileID,'%i\t', dataStr(iTrial).acc); 
    
    fprintf(fileID,'\n');
    end
    
end
fclose(fileID);