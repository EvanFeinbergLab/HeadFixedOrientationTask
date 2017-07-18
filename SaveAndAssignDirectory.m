function SaveAndAssignDirectory(variable, UserID)
VariableString = variable; % name of variable to be saved
FileNameString = variable; % name of file to be saved
FileExtension = '.mat';

% --- Folder Format = '[Grandparent]\[Parent]\[Child]'
% --- Example: 'C:\HeadFixedTrials\071217_130030\AYK'
    % Grandparent Folder = 'C:\HeadFixedTrials'
    % Parent Folder = '071217_130030'
    % Child Folder: 'AYK'
    
% --- Grandparent Folder
GrandparentFolder = 'C:\HeadFixedTrials';

% --- Parent Folder
ParentFolder = datestr(now, 'mmddyy');

% --- Child Folder
ChildFolder = UserID;

% --- File header
FileHeader = datestr(now, 'mmddyy_HHMMSS');

% --- Grandparent-Parent Name
FolderName_GP = strcat(GrandparentFolder, '\', ParentFolder);
FolderName_GPC = strcat(GrandparentFolder, '\', ParentFolder, '\', ChildFolder);

% --- exist() (0 - no, 7 - yes)
GP_AlreadyExist = exist(FolderName_GP, 'dir');
GPC_AlreadyExist = exist(FolderName_GPC, 'dir');

% --- Make Parent and/or Child Folder

if GPC_AlreadyExist == 0
    mkdir(FolderName_GPC);
    save(fullfile(FolderName_GPC, strcat(FileHeader, '_', variable.MouseID, FileExtension)), 'VariableString');

elseif GPC_AlreadyExist == 7
    save(fullfile(FolderName_GPC, strcat(FileHeader, '_', variable.MouseID, FileExtension)), 'VariableString');
    
end

% Parent Folders
% Humza's computer - C:\Users\Evan\Documents\HeadFixedSetup\scripts and data\fake_data\
% Alison's computer - /Users/alisonkim/Dropbox/_ucsf/code/HeadFixedSetup/
% Behaviour computer - C:\HeadFixedTrials\