function SaveAndAssignDirectory(TrialData)

% --- File extension
FileExtension = '.mat';

% --- File path divider
OS = computer;
if contains(OS, 'PC')
    FilePathDivider = FilePathDivider;
elseif contains(OS, 'MAC')
    FilePathDivider = '/';
end

% --- Folder Format = '[Grandparent]\[Parent]\[Child]'
% --- Example: 'C:\HeadFixedTrials\AYK\1-1M'
    % Grandparent Folder = 'C:\HeadFixedTrials'
    % Parent Folder = 'AYK'
    % Child Folder = '1-1M'
    
% --- Grandparent Folder
GrandparentFolder = 'C:\HeadFixedTrials\';

% --- Parent Folder
ParentFolder = TrialData.UserID;

% --- Child Folder
ChildFolder = erase(TrialData.MouseID, TrialData.UserID);

% --- Grandparent-Parent Name
FolderName = strcat(GrandparentFolder, FilePathDivider, ParentFolder, FilePathDivider, ChildFolder);

% --- exist() (0 - no, 7 - yes)
GPC_AlreadyExist = exist(FolderName, 'dir');

% --- Determine day of training
if length(dir(strcat(FolderName, FilePathDivider, '*.mat'))) == 0
    DaysSoFar = '01';
elseif (1 <= length(dir(strcat(FolderName, FilePathDivider, '*.mat')))) && (length(dir(strcat(FolderName, FilePathDivider, '*.mat'))) <= 8)
    DaysSoFar = strcat('0', num2str((length(dir(strcat(FolderName, FilePathDivider, '*.mat')))) + 1));
else length(dir(strcat(FolderName, FilePathDivider, '*.mat'))) > 8
    DaysSoFar = num2str((length(dir(strcat(FolderName, FilePathDivider, '*.mat')))) + 1);
end

% --- Save!
if GPC_AlreadyExist == 0
    mkdir(FolderName);
    save(fullfile(FolderName, strcat(TrialData.MouseID, '_', DaysSoFar, FileExtension)), 'TrialData');

elseif GPC_AlreadyExist == 7
    save(fullfile(FolderName, strcat(TrialData.MouseID, '_', DaysSoFar, FileExtension)), 'TrialData');
    
end

% Parent Folders
% Alison's computer - /Users/alisonkim/Dropbox/_ucsf/code/HeadFixedSetup/
% Behaviour computer - C:\HeadFixedTrials\