%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	USER-DEFINED FUNCTIONS & NOTATIONS	%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% = regular comment
%%% = future update
%%%%% = troubleshooting comment/code

% Coinflip.m: output = val
% CorrectDirection.m: output = boolean
% DeleteNaN.m: output = array
% InRange.m: output = boolean
% SaveAndAssignDirectory.m: output = .mat file
% OutRange.m: output = boolean


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
    'Mininum ITI length (s):',... % Minimum inter-trial interval (ITI) length, want to decrease once mouse is accustomed
    'Maximum ITI length (s):',... % Maximum ITI length
    'Timeout threshold (s):',... % Length of time after which trial will be marked incorrect
    'OutRange threshold (deg):'... % The absolute value of the degree (in the wrong direction) past which a trial is marked wrong
    'R/L bias threshold:'... % The maximum allowable difference between RCorrectProb and LCorrectProb before triggering consecutive opposite-side stimuli
    'L minimum angle (deg):',... % Left side angle range (> 0)
    'L maximum angle (deg):',...
    'R minimum angle (deg):',... % Right side angle range (< 0)
    'R maximum angle (deg):',...
    'LED pulse intensity (1-5V):',... % How brightly the LED will flash
    'LED pulse length (s):',... % How long the LED will flash
    'Solenoid pulse length (s):'}; % How long the solenoid will keep the valve open

defaultans = {'AYK',... % Mouse ID
    datestr(Today, DateFormat),... % Session ID format: MMDDYY_[initial][cohort]_[number][sex]
    '3600',... % Session Length
    '3',... % Mininum ITI length (s)
    '5',... % Maximum ITI length (s)
    '8',... % Timeout threshold (s)
    '30',... % OutRange degree threshold
    '0.1500',... % R/L bias threshold
    '12',... % Left side angle minimum
    '45',... % Left side angle maximum
    '-45',... % Right side angle minimum
    '-12',... % Right side angle maximum
    '3',... % LED pulse intensity
    '0.4',... % LED pulse length
    '0.35'}; % Solenoid pulse length

dlg_title = 'Head-Fixed Orientation Task: User Inputs';
answer = inputdlg(prompt, dlg_title, 1, defaultans); % Syntax for arguments: prompt, dialogue title, # lines, default answers

% Remember to str2double any quantitative inputs when calling them!
j = 1;
TrialData.MouseID = answer{j}; j = j + 1;
TrialData.SessionID = answer{j}; j = j + 1;
TrialData.SessionLength = str2double(answer{j}); j = j + 1;
TrialData.MinITI = str2double(answer{j}); j = j + 1;
TrialData.MaxITI = str2double(answer{j}); j = j + 1;
TrialData.TimeoutThreshold = str2double(answer{j}); j = j + 1;
TrialData.OutRangeThreshold = str2double(answer{j}); j = j + 1;
TrialData.SideBiasThreshold = str2double(answer{j}); j = j + 1;
TrialData.LMinAngle = str2double(answer{j}); j = j + 1;
TrialData.LMaxAngle = str2double(answer{j}); j = j + 1;
TrialData.RMinAngle = str2double(answer{j}); j = j + 1;
TrialData.RMaxAngle = str2double(answer{j}); j = j + 1;
TrialData.LEDIntensity = str2double(answer{j}); j = j + 1;
TrialData.LEDPulseLength = str2double(answer{j}); j = j + 1;
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

% --- Initialise program storage arrays (for Matlab program)
i = 1; % Received bit number counter

Side = 0; % Which LED was triggered
          % -1 = L
          % +1 = R
          
TrialNumber = 1; % Trial index
CurrentTrialLength = 0; % Length of time taken to achieve angle

% --- Initialise file storage arrays (for post-trial analysis)
TrialData.StimulusLocationNum = []; % -1 = L
                                    % +1 = R
TrialData.StimulusLocationAlpha = []; % 'R' or 'L'
TrialData.StimulusTypeNum = []; % 1 = random, 2 = forced
TrialData.RandomProportion = []; % Proportion of randomly-triggered LED trials to total trials
TrialData.ForcedProportion = []; % Proportion of forced-side LED trigger trials to total trials
TrialData.TrialIndex = []; % Array of trial indices (to aid plotting)
TrialData.RTrial = 0; % Trials in which R LED was triggered
TrialData.LTrial = 0; % Number of trials in which L LED was triggered
TrialData.RSideProportion = []; % Proportion of trials in which R LED was triggered
TrialData.LSideProportion = []; % Proportion of trials in which L LED was triggered

TrialData.CorrectIndex = []; % Which trials were correctly performed
TrialData.CorrectProb = []; % Proportion of trials correctly performed to total trials
TrialData.RCorrectIndex = []; % R trials correctly performed
TrialData.LCorrectIndex = []; % L trials correctly performed
TrialData.RCorrectProb = 1; % Proportion of R trials correctly performed to total R trials
TrialData.LCorrectProb = 1; % Proportion of L trials correctly performed to total L trials
TrialData.LIncorrect = 0; % Number of L trials incorrectly performed
TrialData.RIncorrect = 0; % Number of R trials incorrectly performed
TrialData.IncorrectType = []; % Incorrect trial labeled by timeout 'T' or OutRange 'O'
TrialData.TimeoutProportion = []; % Proportion of timeout error trials to total incorrect trials
TrialData.OutRangeProportion = []; % Proportion of outrange error trials to total incorrect trials

TrialData.TrialLengths = []; % Array of trial lengths (time taken to achieve correct angle)
TrialData.ITILengths = []; % Array of ITIs

TrialData.XDataRCorrect = []; % Time Stamp - R correct
TrialData.XDataLCorrect = []; % Time Stamp - L correct
TrialData.XDataRIncorrect = []; % Time Stamp - R incorrect
TrialData.XDataLIncorrect = []; % Time Stamp - L incorrect
TrialData.YDataRCorrect = []; % Overall displacement - R correct
TrialData.YDataLCorrect = []; % Overall displacement - L correct
TrialData.YDataRIncorrect = []; % Overall displacement - R incorrect
TrialData.YDataLIncorrect = []; % Overall displacement - L incorrect


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	EXECUTE HEAD-FIXED ORIENTATION TASK    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Start reading the encoder data. Store them in a format that is readable.
% Update the appropriate arrays and counters.

%%% Self-initiation code will go here

writePWMVoltage(a, 'D3', 5); pause(TrialData.SolenoidPulseLength); writePWMVoltage(a, 'D3', 0); % Freebie
pause(2);

Procedure = tic; % Start session timer
    
while toc(Procedure) <= TrialData.SessionLength
    
    % --- Select stimulus side (R/L, random/forced)
    [StimulusTypeNum, StimulusValue] = Coinflip(TrialData.RCorrectProb(end), TrialData.LCorrectProb(end), TrialNumber, TrialData.SideBiasThreshold);
    fprintf('\nCurrent Trial: %d \n', TrialNumber); % Print current trial index to display
    
    % --- Trigger LED, assign variables
    if StimulusValue < 0.5000 % left
        writePWMVoltage(a, 'D6', TrialData.LEDIntensity);
        pause(TrialData.LEDPulseLength); % 500 ms
        writePWMVoltage(a, 'D6', 0);
        
        Side = -1; % Assign value to Side
        DisplaySide = 'LEFT';
        
        AngleMin = TrialData.LMinAngle; % Define angle range
        AngleMax = TrialData.LMaxAngle;
        
    else % right
        writePWMVoltage(a, 'D5', TrialData.LEDIntensity);
        pause(TrialData.LEDPulseLength); % 500 ms
        writePWMVoltage(a, 'D5', 0);
        
        Side = 1; % Assign value to Side
        DisplaySide = 'RIGHT';
        
        AngleMin = TrialData.RMinAngle; % Define angle range
        AngleMax = TrialData.RMaxAngle;
        
    end
    
    % --- Print stimulus side & type to display
    if StimulusTypeNum == 1
        StimulusTypeAlpha = 'random';
        TrialData.StimulusTypeNum = [TrialData.StimulusTypeNum, 1];
        TrialData.RandomProportion = (length(find(TrialData.StimulusTypeNum == 1)) / length(TrialData.StimulusTypeNum));
    
    elseif StimulusTypeNum == 2
        StimulusTypeAlpha = 'forced';
        TrialData.StimulusTypeNum = [TrialData.StimulusTypeNum, 2];
        TrialData.ForcedProportion = (length(find(TrialData.StimulusTypeNum == 2)) / length(TrialData.StimulusTypeNum))
    
    end
    
    fprintf('\nStimulus Side & Type: %s, %s \n', DisplaySide, StimulusTypeAlpha);
    
    % --- Initialise timer
    TimerExist = exist('MaxDurCheck','var');
    if TimerExist == 1
        stop(MaxDurCheck);
    end
    clear chktime;
    
    StartRoundCheck = TrialNumber;
    MaxDurCheck = timer('TimerFcn', 'chktime = 8;', 'StartDelay', 8); % Starts timer to ensure that trial ends after 8 seconds
    start(MaxDurCheck);
    
    FailIndicator = 0;
    SuccessIndicator = 0;
    PosInitial = 0; % Reset PosInitial to 0
    clf
    Displacement = subplot(1, 1, 1); % (m, n, p) - m = row, n = column, p = position
    InitialiseX = 0:8; InitialiseY = zeros(1, 9);
    DisplacementLine = line('XData', InitialiseX, 'YData', InitialiseY, 'Color', 'b'); % Re-initialise plot
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
        
        % --- If the mouse correctly completes the trial
        if FailIndicator == 0 && ((InRange(AngleMin, AngleMax, PosInitial, PosFinal) && CorrectDirection(StoreAngle, Side)) || SuccessIndicator ~= 0) % Success indicator legend at bottom of code
            
            if SuccessIndicator == 0 % Task not yet complete
                TrialStop = toc(TrialStart); % Stop timer for trial length
                TrialData.TrialLengths = [TrialData.TrialLengths, TrialStop]; % Update trial length array
                TrialData.CorrectIndex = [TrialData.CorrectIndex, 1]; % 1 = correct, 0 = incorrect

                % --- Print results
                fprintf('\nCorrect angle achieved in %.4f sec: %d deg\n', TrialStop, PosFinal - PosInitial);
                SuccessIndicator = -1;
                
                % --- Trigger solenoid
                writePWMVoltage(a, 'D3', 5);
                SolenoidTimer = timer('TimerFcn', 'writePWMVoltage(a, ''D3'', 0); SuccessIndicator = 2;', 'StartDelay', TrialData.SolenoidPulseLength); % Turns off solenoid after specific pulse length
                start(SolenoidTimer);
            end
            
            if SuccessIndicator == 2 % Solenoid/ITI transition (i.e., after solenoid triggers, before ITI starts)
            
                % --- Set ITI length
                ITI = datasample(TrialData.MinITI:TrialData.MaxITI, 1); % Randomly choose from user-specified range
                TrialData.ITILengths = [TrialData.ITILengths, ITI]; % Append ITI to ITI array
                ITITimer = timer('TimerFcn', 'SuccessIndicator = 3;', 'StartDelay' , ITI); % Pause for mouse to collect reward
                start(ITITimer);
                SuccessIndicator = 1; % In ITI
            end
            
            if SuccessIndicator == 3 % ITI complete, about to move onto next trial
            
                % --- Save current trial real-time plot & stimulus location
                if Side == 1

                    TrialData.YDataRCorrect = [TrialData.YDataRCorrect; EncoderPlot];
                    TrialData.XDataRCorrect = [TrialData.XDataRCorrect; StoreTime]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'R'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, 1];
                    TrialData.RTrial = TrialData.RTrial + 1;
                    TrialData.RCorrectIndex = [TrialData.RCorrectIndex, 1];

                elseif Side == -1

                    TrialData.YDataLCorrect = [TrialData.YDataLCorrect; EncoderPlot];
                    TrialData.XDataLCorrect = [TrialData.XDataLCorrect; StoreTime]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'L'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, -1];
                    TrialData.LTrial = TrialData.LTrial + 1;
                    TrialData.LCorrectIndex = [TrialData.LCorrectIndex, 1];

                end

                % --- Update trial index array, then trial index (for next loop)
                TrialData.TrialIndex = [TrialData.TrialIndex, TrialNumber]; % Append trial number to trial index array
                break

            end
            
        end
            
        if (exist('chktime', 'var') == 1 && StartRoundCheck == TrialNumber && SuccessIndicator == 0) || ((SuccessIndicator == 0) && OutRange(TrialData.OutRangeThreshold, Side, PosInitial, PosFinal))
            
            if FailIndicator == 0
                
                TrialStop = toc(TrialStart);
                TrialData.CorrectIndex = [TrialData.CorrectIndex, 0];
                TrialData.TrialLengths = [TrialData.TrialLengths, TrialStop]; % Update trial length array
                
                if OutRange(TrialData.OutRangeThreshold, Side, PosInitial, PosFinal)
                    fprintf('\nOutrange threshold of %d degrees in wrong direction exceeded. Moving onto next trial.\n', TrialData.OutRangeThreshold);
                    TrialData.IncorrectType = [TrialData.IncorrectType, 'O']; % Update incorrect type array
                    TrialData.OutRangeProportion = [TrialData.OutRangeProportion, (length(find(TrialData.IncorrectType == 'O')) / length(TrialData.IncorrectType));
                
                else
                    fprintf('\nTimeout threshold of %d sec exceeded. Moving onto next trial.\n', TrialData.TimeoutThreshold);
                    TrialData.IncorrectType = [TrialData.IncorrectType, 'T']; % Update incorrect type array
                    TrialData.TimeoutProportion = [TrialData.TimeoutProportion, (length(find(TrialData.IncorrectType == 'T')) / length(TrialData.IncorrectType));
                
                end
                
                ITI = datasample(TrialData.MinITI:TrialData.MaxITI, 1); % Randomly choose from user-specified range
                TrialData.ITILengths = [TrialData.ITILengths, ITI]; % Append ITI to ITI array
                ITITimer = timer('TimerFcn', 'FailIndicator = 2;', 'StartDelay' , ITI); % Pause for mouse to collect reward
                start(ITITimer);
                FailIndicator = 1; % It has already passed through this step, should not pass through this loop again for this round
            
            
            elseif FailIndicator == 2
                
                if Side == 1

                    TrialData.YDataRIncorrect = [TrialData.YDataRIncorrect; EncoderPlot];
                    TrialData.XDataRIncorrect = [TrialData.XDataRIncorrect; StoreTime]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'R'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, 1];
                    TrialData.RTrial = TrialData.RTrial + 1;
                    TrialData.RCorrectIndex = [TrialData.RCorrectIndex, 0];
                    TrialData.RIncorrect = length(TrialData.RCorrectIndex) - sum(TrialData.RCorrectIndex);

                elseif Side == -1

                    TrialData.YDataLIncorrect = [TrialData.YDataLIncorrect; EncoderPlot];
                    TrialData.XDataLIncorrect = [TrialData.XDataLIncorrect; StoreTime]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'L'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, -1];
                    TrialData.LTrial = TrialData.LTrial + 1;
                    TrialData.LCorrectIndex = [TrialData.LCorrectIndex, 0];
                    TrialData.LIncorrect = length(TrialData.LCorrectIndex) - sum(TrialData.LCorrectIndex);
                
                end
                              
                % --- Update trial index array, then trial index (for next loop)
                TrialData.TrialIndex = [TrialData.TrialIndex, TrialNumber]; % Append trial number to trial index array
                
                break
            
            end

        end
            
    end
    
    % --- Update correct proportions
    TrialData.LSideProportion = [TrialData.LSideProportion, TrialData.LTrial / (TrialData.LTrial + TrialData.RTrial)];
    TrialData.RSideProportion = [TrialData.RSideProportion, TrialData.RTrial / (TrialData.LTrial + TrialData.RTrial)];
    
    % --- Update correct probabilities
    TrialData.RCorrectProb = [TrialData.RCorrectProb, (TrialData.RTrial - TrialData.RIncorrect) / TrialData.RTrial];
    TrialData.LCorrectProb = [TrialData.LCorrectProb, (TrialData.LTrial - TrialData.LIncorrect) / TrialData.LTrial];
    TrialData.CorrectProb = [TrialData.CorrectProb, sum(TrialData.CorrectIndex) / TrialNumber];
    
    % --- Print correct probability results
    fprintf('\nCorrect TOTAL probability: %.4f\n', TrialData.CorrectProb(end));
    fprintf('\nCorrect R-SIDE probability: %.4f\n', TrialData.RCorrectProb(end));
    fprintf('\nCorrect L-SIDE probability: %.4f\n\n----------------------------\n', TrialData.LCorrectProb(end));
    
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  LEGEND: SuccessIndicator                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: Stages of SuccessIndicator
% SuccessIndicator = -1: Solenoid is giving food
% SuccessIndicator = 0: Task not yet complete
% SuccessIndicator = 1: In ITI
% SuccessIndicator = 2: Transition of Solenoid and ITI
% SuccessIndicator = 3: ITI complete, about to move on to next round


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     AUTHOR INFORMATION                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Author: Alison Y. Kim
% Contributing Editors: Humza N. Zubair
% Principal Investigator: Evan H. Feinberg, Ph.D.
% University of California, San Francisco
    % Dept. of Anatomy
    % Kavli Institute for Fundamental Neuroscience
% [e]: alison.kim@ucsf.edu
% [a]: 1500 4th St Box 2822, San Francisco, CA 94158