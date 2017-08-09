clear all; close all; delete(instrfind);

% --- Connect LED & Solenoid Arduino
BoardType = 'Uno'; 
SelectLEDCOM = GetSerialPort;
[LEDSelection, p] = listdlg('PromptString', 'Select LED & Solenoid communication port:', 'SelectionMode', 'single', 'ListString', SelectLEDCOM);
COM_LED = cell2mat(SelectLEDCOM(LEDSelection));
a = arduino(COM_LED, BoardType); % Establish hardware communication with LED & Solenoid Arduino
RLED = 'D5';
LLED = 'D6';
RSolenoid = 'D9';
LSolenoid = 'D10';

writePWMVoltage(a, RLED, 0); % Reset R LED to off mode
writePWMVoltage(a, LLED, 0); % Reset L LED to off mode
writePWMVoltage(a, RSolenoid, 0); % Reset R solenoid to off mode
writePWMVoltage(a, LSolenoid, 0); % Reset L solenoid to off mode

% FrontCamera = webcam(1);
% BackCamera = webcam(2);
% preview(FrontCamera); 
% preview(BackCamera);

% --- Dark run parameters
global TrialData % Structure in which all variables of interest will be saved

Today = datetime('today'); DateFormat = 'mm-dd-yyyy_'; % Format of Session ID: mm-dd-yyyy_MouseID

TrialData.UserID = questdlg('Whose cohort will be run today?', ...
    'User ID', ...
    'AYK', 'SZ', 'VC', 'AYK');

prompt = {'Mouse ID',...
    'Session ID',...
    'Session length (min)',...
    'LED intensity (V):',... % Brightness of LED, 0-5V
    'Solenoid pulse length (ms):',... % How long the solenoid will keep the valve open
    'ITI length (s):',... % How long between stimuli/reward onsets
    'Alternate stimuli sides? (y/n):' % Whether to alternate R/L LED + reward
    }; 

defaultans = {TrialData.UserID... % Mouse ID
    strcat('DarkRun', '_', datestr(Today, DateFormat), '_', TrialData.UserID),... % Session ID format: MMDDYY_[initial][cohort]_[number][sex]
    '60',... % Session Length (min) - typically 60 for 1x training
    '1',... % LED pulse intensity
    '300',... % Solenoid pulse length (ms)
    '30',... % ITI length (s)
    'y' % Alternate stimuli sides?
    }; 

dlg_title = 'Head-Fixed Dark Run: User Inputs';
answer = inputdlg(prompt, dlg_title, 1, defaultans); % Syntax for arguments: prompt, dialogue title, # lines, default answers

% Remember to str2double any quantitative inputs when calling them!
j = 1;
TrialData.MouseID = answer{j}; j = j + 1;
TrialData.SessionID = answer{j}; j = j + 1;
TrialData.SessionLength = (str2double(answer{j}) * 60); j = j + 1;
TrialData.LEDIntensity = str2double(answer{j}); j = j + 1;
TrialData.SolenoidPulseLength = (str2double(answer{j}) / 1000); j = j + 1;
TrialData.ITILength = str2double(answer{j}); j = j + 1;
TrialData.AlternatingStimuliIndicator = answer{j};

% --- Dark Run
Procedure = tic;

RCount = 0;
LCount = 0;
Count = 0;

RLEDTimer = timer('TimerFcn', 'writePWMVoltage(a, RLED, 0)', 'StartDelay', 0.500);
RSolenoidTimer = timer('TimerFcn', 'writePWMVoltage(a, RSolenoid, 0)', 'StartDelay', TrialData.SolenoidPulseLength);
LLEDTimer = timer('TimerFcn', 'writePWMVoltage(a, LLED, 0)', 'StartDelay', 0.500);
LSolenoidTimer = timer('TimerFcn', 'writePWMVoltage(a, LSolenoid, 0)', 'StartDelay', TrialData.SolenoidPulseLength);

SolenoidTimer = timer('TimerFcn', 'writePWMVoltage(a, RSolenoid, 0); writePWMVoltage(a, LSolenoid, 0)', 'StartDelay', TrialData.SolenoidPulseLength / 2);
LEDTimer = timer('TimerFcn', 'writePWMVoltage(a, RLED, 0); writePWMVoltage(a, LLED, 0)', 'StartDelay', 0.500);

while toc(Procedure) <= TrialData.SessionLength
    
    if TrialData.AlternatingStimuliIndicator == 'y'
        
        writePWMVoltage(a, RLED, TrialData.LEDIntensity); writePWMVoltage(a, RSolenoid, 5);
        fprintf('\n Stimuli side: RIGHT');
        start(RLEDTimer); start(RSolenoidTimer);
        RCount = RCount + 1;
        fprintf('\n R stimuli count: %d', RCount);
        fprintf('\n L stimuli count: %d\n', LCount);
        
        pause(TrialData.ITILength);
        
        writePWMVoltage(a, LLED, TrialData.LEDIntensity); writePWMVoltage(a, LSolenoid, 5);
        fprintf('\n Stimuli side: LEFT');
        start(LLEDTimer); start(LSolenoidTimer);
        LCount = LCount + 1;
        fprintf('\n R stimuli count: %d', RCount);
        fprintf('\n L stimuli count: %d\n', LCount);
        
        pause(TrialData.ITILength);

    elseif TrialData.AlternatingStimuliIndicator == 'n'
        
        writePWMVoltage(a, RLED, TrialData.LEDIntensity); writePWMVoltage(a, LLED, TrialData.LEDIntensity); start(LEDTimer);
        writePWMVoltage(a, RSolenoid, 5); writePWMVoltage(a, LSolenoid, 5); start(SolenoidTimer);
        Count = Count + 1;
        fprintf('\n Stimuli count: %d\n', Count);
        
        pause(TrialData.ITILength);
        
    end
    
end
