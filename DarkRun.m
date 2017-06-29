%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	ESTABLISH HARDWARE COMMUNICATION	%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all; clc; delete(instrfind);

% --- Connect Encoder Arduino
SelectEncoderCOM = GetSerialPort;
[EncoderSelection, n] = listdlg('PromptString', 'Select Encoder communication port:', 'SelectionMode', 'single', 'ListString', SelectEncoderCOM);
COM_Encoder = cell2mat(SelectEncoderCOM(EncoderSelection));
s = serial(COM_Encoder);
s.BaudRate = 115200;
fopen(s); % Open serial communication with Encoder Arduino

% --- Connect LED & Solenoid Arduino
BoardType = 'Uno'; 
SelectLEDCOM = GetSerialPort;
[LEDSelection, p] = listdlg('PromptString', 'Select LED & Solenoid communication port:', 'SelectionMode', 'single', 'ListString', SelectLEDCOM);
COM_LED = cell2mat(SelectLEDCOM(LEDSelection));
a = arduino(COM_LED, BoardType); % Establish hardware communication with LED & Solenoid Arduino
writeDigitalPin(a, 'D5', 0); % Reset LED to off mode
writeDigitalPin(a, 'D6', 0); % Reset LED to off mode

% --- Connect USB cameras
%FrontCamera = webcam('USB2.0 PC CAMERA');
%BackCamera = webcam('USB2.0 Camera');
%preview(FrontCamera); preview(BackCamera);
%%% save recording as .avi


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	USER INPUT PROMPT: TRIAL INFORMATION & HARDWARE CONFIGURATION	%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global TrialData % Structure in which all variables of interest will be saved

Today = datetime('today'); DateFormat = 'mm-dd-yyyy_'; % Format of Session ID: mm-dd-yyyy_MouseID

prompt = {'Mouse ID:',...
    'Session ID (MMDDYY_[initial][cohort]_[number][sex]):',...
    'Session length (s):',... % How long user wants the session to run
    'Reward interval (s):',... % How long user wants between reward deliveries
    'Solenoid pulse length (s):'}; % How long the solenoid will keep the valve open

defaultans = {'',... % Mouse ID
    datestr(Today, DateFormat),... % Session ID format: MMDDYY_[initial][cohort]_[number][sex]
    '3600',... % Session Length
    '20',... % Inter-reward delay (s)
    '0.5'}; % Solenoid pulse length

dlg_title = 'Head-Fixed Orientation Task: User Inputs';
answer = inputdlg(prompt, dlg_title, 1, defaultans); % Syntax for arguments: prompt, dialogue title, # lines, default answers

% Remember to str2double any quantitative inputs when calling them!
j = 1;
TrialData.MouseID = answer{j}; j = j + 1;
TrialData.SessionID = answer{j}; j = j + 1;
TrialData.SessionLength = str2double(answer{j}); j = j + 1;
TrialData.RewardInterval = str2double(answer{j}); j = j + 1;
TrialData.SolenoidPulseLength = str2double(answer{j});

fprintf('BaudRate of Encoder (bits/s): %d \n', s.BaudRate);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	INITIALISE DATA STRUCTURES	 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Set figure properties
CurrentTrialData = figure;
    CurrentTrialData.Name = strcat(TrialData.SessionID, ' Current Session Data');
    CurrentTrialData.NumberTitle = 'off';
    CurrentTrialData.Position = [500 500 500 500];

% --- Initialise real-time plot
Displacement = subplot(1, 1, 1); % m = row, n = column, p = position
InitialiseX = 0:8; InitialiseY = NaN(1, 9);
DisplacementLine = line('XData', InitialiseX, 'YData', InitialiseY, 'Color', 'b');
    xlabel('Time (seconds)'); ylabel('Displacement (\circ)');
    Displacement.Box = 'off';
    Displacement.XGrid = 'on'; Displacement.YGrid = 'on';
	Displacement.XLim = [0 8];
    Displacement.YLim = [-360 360];
    Displacement.XTick = [0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0];
    Displacement.XMinorTick = 'on';
    Displacement.XTickLabel = {'0', '1.0', '2.0', '3.0', '4.0', '5.0', '6.0', '7.0', '8.0'};
    Displacement.YTick = [-360 -270 -180 -90 0 90 180 270 360];
    Displacement.YTickLabel = {'-360\circ', '-270\circ', '-180\circ', '-90\circ', '0\circ', '90\circ', '180\circ', '270\circ', '360\circ'};

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               EXECUTE DARK RUN                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Procedure = tic; % Start session timer
    
while toc(Procedure) <= TrialData.SessionLength
    
    PosInitial = 0; % Reset PosInitial to 0
    clf
    Displacement = subplot(1, 1, 1); % (m, n, p) - m = row, n = column, p = position
    InitialiseX = 0:8; InitialiseY = zeros(1, 9);
    DisplacementLine = line('XData', InitialiseX, 'YData', InitialiseY, 'Color', 'b'); % Re-initialise plot
    xlabel('Time (seconds)'); ylabel('Displacement (\circ)');
        Displacement.Box = 'off';
        Displacement.XGrid = 'on'; Displacement.YGrid = 'on';
        Displacement.XLim = [0 20];
        Displacement.YLim = [-360 360];
        Displacement.XTick = [0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0];
        Displacement.XMinorTick = 'on';
        Displacement.XTickLabel = {'0', '1.0', '2.0', '3.0', '4.0', '5.0', '6.0', '7.0', '8.0'};
        Displacement.YTick = [-360 -270 -180 -90 0 90 180 270 360];
        Displacement.YTickLabel = {'-360\circ', '-270\circ', '-180\circ', '-90\circ', '0\circ', '90\circ', '180\circ', '270\circ', '360\circ'};
    
    flushinput(s); % Remove data from input buffer
    Time = NaN([1 2001]); Time(1) = TrialNumber; % Resets these arrays and assigns first bin to trial number
    StoreTime = Time;
    StoreAngle = Time;
    AngularDisplacement = Time;
    PosFinal = Time;
    EncoderPlot = Time; 
    
    TrialStart = tic; % Start/reset timer for trial length

    while i <= 2000
        
        % --- Suppress unsuccessful read notes because it messes up the serial reading...
        warning('off', 'MATLAB:serial:fscanf:unsuccessfulRead');
        ScanAngle = fscanf(s); % Serially read encoder output from Arduino
        warning('on', 'MATLAB:serial:fscanf:unsuccessfulRead');

        if PosInitial == 0
            PosInitial = str2double(ScanAngle);
        end

        % --- Convert data from Arduino to double precision integer, if necessary.
        if ~isa(ScanAngle, 'double')
            EncoderPlot(i + 1) = str2double(ScanAngle);

        else
            EncoderPlot(i + 1) = ScanAngle;

        end        

        % --- Draw real-time plot
        Time(i + 1) = toc(TrialStart);
        StoreTime(i + 1) = Time(i + 1);
        StoreAngle(i + 1) = EncoderPlot(i + 1); % Update angle value with ScanAngle value
        AngularDisplacement(i + 1) = StoreAngle(i + 1) - PosInitial; % Angular displacement
        PosFinal = StoreAngle(i + 1); % PosFinal is the latest angle value received at or before the moment of AngleAchieved = true
        i = i + 1; % Update bit number
        set(DisplacementLine, 'XData', Time, 'YData', AngularDisplacement); % Draw angular displacement
        drawnow % Force MATLAB to flush any queued displays
    
    % --- Reset real-time plot
    i = 1; % Reset bit counter
    EncoderPlot = NaN(1, 2001); % Reset EncoderPlot
    StoreAngle = 0; % Reset angular displacement
    delete(DisplacementLine); % Delete trial displacement to refresh plot
    TrialNumber = TrialNumber + 1; % Increment trial number
    
end

% --- Update non-trivially initialised arrays
TrialData.RCorrectProb = TrialData.RCorrectProb(2:end); % Remove first element (pseudo-initialiser)
TrialData.LCorrectProb = TrialData.LCorrectProb(2:end);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   SUMMARY OF RESULTS                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Overall result statistics (irrespective of correct/incorrect)
fprintf('\nSUMMARY OF SESSION %s\n', TrialData.SessionID);
fprintf('\nOVERALL (number, proportion)');
fprintf('\n---ALL trials: %d', TrialData.TrialIndex(end));
fprintf('\n---R-SIDE trials: %d, %.4f', TrialData.RTrial(end), TrialData.RSideProportion(end));
fprintf('\n---L-SIDE trials: %d, %.4f', TrialData.LTrial(end), TrialData.LSideProportion(end));
fprintf('\n---RANDOM trials: %d, %.4f', length(find(TrialData.StimulusTypeNum == 1)), TrialData.RandomProportion(end));
fprintf('\n---FORCED trials: %d, %.4f', length(find(TrialData.StimulusTypeNum == 2)), TrialData.ForcedProportion(end));

% --- Correct result statistics
fprintf('\n\nCORRECT (number, proportion)');
fprintf('\n---ALL trials: %d, %.4f', length(find(TrialData.CorrectIndex == 1)), TrialData.CorrectProb(end));
fprintf('\n---R-SIDE trials: %d, %.4f', length(find(TrialData.RCorrectIndex == 1)), TrialData.RCorrectProb(end));
fprintf('\n---L-SIDE trials: %d, %.4f', length(find(TrialData.LCorrectIndex == 1)), TrialData.LCorrectProb(end));

% --- Incorrect result statistics
fprintf('\n\nINCORRECT (number, proportion)');
fprintf('\n---ALL trials: %d', (1 - TrialData.CorrectProb(end)));
fprintf('\n---R-SIDE trials: %d, %.4f', length(find(TrialData.RCorrectIndex == 0)), (1 - TrialData.RCorrectProb(end)));
fprintf('\n---L-SIDE trials: %d, %.4f', length(find(TrialData.LCorrectIndex == 0)), (1 - TrialData.LCorrectProb(end)));
fprintf('\n---TIMEOUT errors: %d, %.4f', length(find(TrialData.IncorrectType == 'T')), TrialData.TimeoutProportion);
fprintf('\n---OUTRANGE errors: %d, %.4f', length(find(TrialData.IncorrectType == 'O')), TrialData.OutRangeProportion);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            	SAVE DATA               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SaveAndAssignDirectory(TrialData);

h = msgbox('Session Complete');