function SaveAndAssignDirectory(variable)
VariableString = variable; % name of variable to be saved
FileNameString = variable; % name of file to be saved

FolderDateFormat = 'mmddyy';
FileDateFormat = 'mmddyy_HHMMSS';
FolderName = datestr(now, FolderDateFormat);
FileName = datestr(now, FileDateFormat);
ParentFolder = 'C:\HeadFixedTrials\';
FolderPath = strcat(ParentFolder, FolderName);
FolderAlreadyExist = exist(FolderPath, 'dir');

if FolderAlreadyExist == 0
    mkdir(ParentFolder, FolderName);
    save(fullfile(FolderPath, strcat(FileName, '_', variable.MouseID, '.mat')), 'VariableString');
    
elseif FolderAlreadyExist == 7
    save(fullfile(FolderPath, strcat(FileName, '_', variable.MouseID, '.mat')), 'VariableString');
    
end

% Parent Folders
% Humza's computer - C:\Users\Evan\Documents\HeadFixedSetup\scripts and data\fake_data\
% Alison's computer - /Users/alisonkim/Dropbox/_ucsf/code/HeadFixedSetup/
% Behaviour computer - C:\HeadFixedTrials\