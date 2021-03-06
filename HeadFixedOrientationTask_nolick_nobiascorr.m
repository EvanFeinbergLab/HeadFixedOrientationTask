%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               USER-DEFINED FUNCTIONS & NOTATIONS              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% = regular comment
%%% = future update
%%%%% = troubleshooting comment/code

% Coinflip.m: output = val
% CorrectDirection.m: output = boolean
% DeleteNaN.m: output = array
% InRange.m: output = boolean
% SaveAndAssignDirectory.m: output = .mat file
% OutRange.m: output = boolean


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 ESTABLISH HARDWARE COMMUNICATION              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all; delete(instrfind); % Terminates any existing objective and/or serial communications

% --- Connect Encoder Arduino
SelectEncoderCOM = GetSerialPort;
[EncoderSelection, n] = listdlg('PromptString', 'Select Encoder communication port:', 'SelectionMode', 'single', 'ListString', SelectEncoderCOM);
COM_Encoder = cell2mat(SelectEncoderCOM(EncoderSelection));
ArduinoEncoder = serial(COM_Encoder);
ArduinoEncoder.BaudRate = 115200;
fopen(ArduinoEncoder); % Open serial communication with Encoder Arduino

% --- Connect Stimulus (LED) & Solenoid Arduino
BoardType = 'Uno'; 
SelectLEDCOM = GetSerialPort;
[LEDSelection, p] = listdlg('PromptString', 'Select LED & Solenoid communication port:', 'SelectionMode', 'single', 'ListString', SelectLEDCOM);
COM_LED = cell2mat(SelectLEDCOM(LEDSelection));
ArduinoLEDSolenoid = arduino(COM_LED, BoardType); % Establish hardware communication with LED & Solenoid Arduino
RLED = 'D5';
LLED = 'D6';
RSolenoid = 'D9';
LSolenoid = 'D10';
writePWMVoltage(ArduinoLEDSolenoid, RLED, 0); % Reset R Solenoid to off mode
writePWMVoltage(ArduinoLEDSolenoid, LLED, 0); % Reset L Solenoid to off mode
writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 0); % Reset R LED to off mode
writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 0); % Reset L LED to off mode

% --- Connect USB cameras
FrontCamera = webcam(1);
% BackCamera = webcam(2);
preview(FrontCamera);
% preview(BackCamera);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	USER INPUT PROMPT: TRIAL INFORMATION & HARDWARE CONFIGURATION	%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global TrialData % Structure in which all variables of interest will be saved

Today = datetime('today'); DateFormat = 'mm-dd-yyyy_'; % Format of Session ID: mm-dd-yyyy_MouseID

TrialData.UserID = questdlg('Whose cohort will be run today?', ...
    'User ID', ...
    'AYK', 'SZ', 'AYK');

prompt = {'Mouse ID:',...
    'Session ID (MMDDYY_[initial][cohort]_[number][sex]):',...
    'Session length (min):',... % How long user wants the session to run
    'Mininum ITI length (s):',... % Minimum inter-trial interval (ITI) length, want to decrease once mouse is accustomed
    'Maximum ITI length (s):',... % Maximum ITI length
    'Timeout threshold (s):',... % Length of time after which trial will be marked incorrect
    'Outrange threshold (deg):'... % The absolute value of the degree (in the wrong direction) past which a trial is marked wrong
    'L minimum angle (deg):',... % Left side angle range (> 0)
    'L maximum angle (deg):',...
    'R minimum angle (deg):',... % Right side angle range (< 0)
    'R maximum angle (deg):',...
    'LED pulse intensity (1-5V):',... % How brightly the LED will flash
    'Solenoid pulse length (ms):',... % How long the solenoid will keep the valve open
    'Force Standstill to start trials? (1 for yes):' % Whether to require standing still to start new trial
    }; 

defaultans = {TrialData.UserID... % Mouse ID
    strcat(datestr(Today, DateFormat), '_', TrialData.UserID),... % Session ID format: MMDDYY_[initial][cohort]_[number][sex]
    '60',... % Session Length (min) - typically 30 for 2x training, 60 for 1x training
    '3',... % Mininum ITI length (s)
    '5',... % Maximum ITI length (s)
    '2',... % Timeout threshold (s)
    '20',... % OutRange degree threshold
    '12',... % Left side angle minimum
    '45',... % Left side angle maximum
    '-45',... % Right side angle minimum
    '-12',... % Right side angle maximum
    '0.100',... % LED pulse intensity
    '100',... % Solenoid pulse length (ms)
    ''}; % Whether to require standing still to start new trial

dlg_title = 'Head-Fixed Orientation Task: User Inputs';
answer = inputdlg(prompt, dlg_title, 1, defaultans); % Syntax for arguments: prompt, dialogue title, # lines, default answers

% Remember to str2double any quantitative inputs when calling them!
j = 1;
TrialData.MouseID = answer{j}; j = j + 1;
TrialData.SessionID = answer{j}; j = j + 1;
TrialData.SessionLength = (str2double(answer{j}) * 60); j = j + 1;
TrialData.MinITI = str2double(answer{j}); j = j + 1;
TrialData.MaxITI = str2double(answer{j}); j = j + 1;
TrialData.TimeoutThreshold = str2double(answer{j}); j = j + 1;
TrialData.OutRangeThreshold = str2double(answer{j}); j = j + 1;
% TrialData.SideBiasThreshold = str2double(answer{j}); j = j + 1;
TrialData.LMinAngle = str2double(answer{j}); j = j + 1;
TrialData.LMaxAngle = str2double(answer{j}); j = j + 1;
TrialData.RMinAngle = str2double(answer{j}); j = j + 1;
TrialData.RMaxAngle = str2double(answer{j}); j = j + 1;
TrialData.LEDIntensity = str2double(answer{j}); j = j + 1;
TrialData.SolenoidPulseLength = (str2double(answer{j}) / 1000); j = j + 1;
TrialData.StandStillIndicator = str2double(answer{j});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     INITIALISE DATA STRUCTURES                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Initialise program storage arrays (for Matlab program)
i = 1; % Received bit number counter
Side = 0; % Which LED was triggered: -1 = L, +1 = R
TrialNumber = 1; % Trial index
CurrentTrialLength = 0; % Length of time (sec) taken to achieve angle

% --- Initialise file storage arrays (for post-trial analysis)
% Trial information & statistics
    TrialData.StimulusLocationNum = []; % -1 = L, +1 = R
    TrialData.StimulusLocationAlpha = []; % 'R' or 'L'
    TrialData.StimulusTypeNum = []; % 1 = random, 2 = biased
    TrialData.RandomProportion = []; % Proportion of randomly-triggered LED trials to total trials
    TrialData.BiasedProportion = []; % Proportion of biased-side LED trigger trials to total trials
    TrialData.TrialIndex = []; % Array of trial indices (to aid plotting)
    TrialData.RTrial = 0; % Number of trials in which R LED was triggered
    TrialData.LTrial = 0; % Number of trials in which L LED was triggered
    TrialData.RSideProportion = []; % Proportion of trials in which R LED was triggered
    TrialData.LSideProportion = []; % Proportion of trials in which L LED was triggered

% Performance information & statistics
    % Accuracy
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
    
    % Temporal
    TrialData.TrialLengths = []; % Array of trial lengths (time taken to achieve correct angle)
    TrialData.ITILengths = []; % Array of ITIs
    
    % Displacement
    TrialData.XDataRCorrect = []; % Time Stamp - R correct
    TrialData.XDataLCorrect = []; % Time Stamp - L correct
    TrialData.XDataRIncorrect = []; % Time Stamp - R incorrect
    TrialData.XDataLIncorrect = []; % Time Stamp - L incorrect
    TrialData.YDataRCorrect = []; % Overall displacement - R correct
    TrialData.YDataLCorrect = []; % Overall displacement - L correct
    TrialData.YDataRIncorrect = []; % Overall displacement - R incorrect
    TrialData.YDataLIncorrect = []; % Overall displacement - L incorrect


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               EXECUTE HEAD-FIXED ORIENTATION TASK                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Self-initiation code will go here

% --- Initiation (for now, freebie)
Freebie = timer;
    Freebie.StartFcn = 'writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 5); writePWMVoltage(ArduinoLEDSolenoid, RLED, TrialData.LEDIntensity); writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 5); writePWMVoltage(ArduinoLEDSolenoid, LLED, TrialData.LEDIntensity)';
    Freebie.TimerFcn = 'writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 0); writePWMVoltage(ArduinoLEDSolenoid, RLED, 0); writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 0); writePWMVoltage(ArduinoLEDSolenoid, LLED, 0)';
    Freebie.StartDelay = TrialData.SolenoidPulseLength;

start(Freebie);
pause(2);

AllTimeStart = tic;
TrialData.AllTime = 0;
TrialData.AllScan = 0;
NewTime = 0;

% --- Display session information
% Hardware configuration, sampling rate
    fprintf('Baud rate of Encoder (bits/s): %d\n', ArduinoEncoder.BaudRate);
    fprintf('LED intensity (0 - 5V): % d\n', TrialData.LEDIntensity);
    fprintf('Solenoid pulse length: % d sec\n', TrialData.SolenoidPulseLength);

% Behavioural configuration
    if TrialData.StandStillIndicator == 1 
        fprintf('\nStandstill required to initiate next round.\n'); 
    else
        fprintf('\nStandstill not required.\n');
    end
    
% Session information
    fprintf('Mouse ID: %s\n', TrialData.MouseID);
    fprintf('Session length: %d min\n', (TrialData.SessionLength / 60));
    fprintf('ITI range: %d - %d sec\n', TrialData.MinITI, TrialData.MaxITI);
    fprintf('Timeout threshold: %d sec\n', TrialData.TimeoutThreshold);
    fprintf('Outrange threshold: %d deg\n', TrialData.OutRangeThreshold);
    fprintf('Minimum displacement for correct trial: %d deg\n', TrialData.LMinAngle);
%     fprintf('Maximum side bias disparity: %.4f\n', TrialData.SideBiasThreshold);
    

while NewTime <= TrialData.SessionLength
    
    StimulusValue = Coinflip();
    fprintf('\nCurrent Trial: %d \n', TrialNumber); % Print current trial index to display
    
    % --- Trigger LED, assign variables
    if StimulusValue < 0.5000 % left
        writePWMVoltage(ArduinoLEDSolenoid, LLED, TrialData.LEDIntensity);
        
        Side = -1; % Assign value to Side
        DisplaySide = 'LEFT';
        
        AngleMin = TrialData.LMinAngle; % Define angle range
        AngleMax = TrialData.LMaxAngle;
        
    else % right
        writePWMVoltage(ArduinoLEDSolenoid, RLED, TrialData.LEDIntensity);
        
        Side = 1; % Assign value to Side
        DisplaySide = 'RIGHT';
        
        AngleMin = TrialData.RMinAngle; % Define angle range
        AngleMax = TrialData.RMaxAngle;
        
    end
    
    % --- Print stimulus side & type to display
    StimulusTypeAlpha = 'random';
    TrialData.StimulusTypeNum = [TrialData.StimulusTypeNum, 1];
    TrialData.RandomProportion = (length(find(TrialData.StimulusTypeNum == 1)) / length(TrialData.StimulusTypeNum));
    
    fprintf('\nStimulus Side & Type: %s, %s \n', DisplaySide, StimulusTypeAlpha);
    
    % --- Initialise timer
    TimerExist = exist('MaxDurCheck', 'var');
    if TimerExist == 1
        stop(MaxDurCheck);
    end
    clear chktime;
    
    StartRoundCheck = TrialNumber;
    MaxDurCheck = timer('TimerFcn', 'chktime = TrialData.TimeoutThreshold;', 'StartDelay', TrialData.TimeoutThreshold); % Starts timer to ensure that trial ends after TrialData.TimeoutThreshold seconds
    start(MaxDurCheck);
    
    FailIndicator = 0;
    SuccessIndicator = 0;
    PosInitial = 0; % Reset PosInitial to 0
    Time = NaN([1 5001]); Time(1) = TrialNumber; % Resets these arrays and assigns first bin to trial number
    StoreTime = Time;
    StoreAngle = Time;
    AngularDisplacement = Time;
    PosFinal = Time;
    EncoderPlot = Time; 
    CapValues = Time; 
    
    TrialStart = tic; % Start/reset timer for trial length

    while NewTime <= (TrialData.SessionLength + 100)
        
        % --- Suppress unsuccessful read notes because it messes up the serial reading...
        warning('off', 'MATLAB:serial:fscanf:unsuccessfulRead');
        ScanAngle = fscanf(ArduinoEncoder); % Serially read encoder output from ArduinoEncoder
        warning('on', 'MATLAB:serial:fscanf:unsuccessfulRead');

        NewTime = toc(AllTimeStart); TrialData.AllTime = [TrialData.AllTime NewTime];
        if ~isa(ScanAngle, 'double') 
            ScanAngle = str2double(ScanAngle);
        end
        TrialData.AllScan = [TrialData.AllScan ScanAngle];
        
        if PosInitial == 0
            PosInitial = ScanAngle;
        end

        % --- Convert data from Arduino to double precision integer, if necessary.
        EncoderPlot(i + 1) = ScanAngle;

        % --- Draw real-time plot
        Time(i + 1) = toc(TrialStart);
        StoreTime(i + 1) = Time(i + 1);
        StoreAngle(i + 1) = EncoderPlot(i + 1); % Update angle value with ScanAngle value
        AngularDisplacement(i + 1) = StoreAngle(i + 1) - PosInitial; % Angular displacement
        PosFinal = StoreAngle(i + 1); % PosFinal is the latest angle value received at or before the moment of AngleAchieved = true
        i = i + 1; % Update bit number
        %set(DisplacementLine, 'XData', Time, 'YData', AngularDisplacement); % Draw angular displacement
        %drawnow % Force MATLAB to flush any queued displays
        
        if ((SuccessIndicator == 1) || (FailIndicator == 1)) && (abs(TrialData.AllScan(end) - PosChangeCheck) > 5) && (TrialData.StandStillIndicator == 1)
            stop(ITITimer);
            start(ITITimer);
            PosChangeCheck = ScanAngle;
        end
        
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
                if Side == -1
                    LSolenoidTimer = timer;
                        LSolenoidTimer.StartFcn = 'writePWMVoltage(ArduinoLEDSolenoid, LLED, 0); writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 5)';
                        LSolenoidTimer.TimerFcn = 'writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 0); SuccessIndicator = 2;';
                        LSolenoidTimer.StartDelay = TrialData.SolenoidPulseLength; % Turns off solenoid after specific pulse length
                    start(LSolenoidTimer);
                    
                elseif Side == 1
                    RSolenoidTimer = timer;
                        RSolenoidTimer.StartFcn = 'writePWMVoltage(ArduinoLEDSolenoid, RLED, 0); writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 5)';
                        RSolenoidTimer.TimerFcn = 'writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 0); SuccessIndicator = 2;';
                        RSolenoidTimer.StartDelay = TrialData.SolenoidPulseLength; % Turns off solenoid after specific pulse length
                    start(RSolenoidTimer);
                    
                end
            
            elseif SuccessIndicator == 2 % Solenoid/ITI transition (i.e., after solenoid triggers, before ITI starts)
            
                % --- Set ITI length
                ITI = datasample(TrialData.MinITI:TrialData.MaxITI, 1); % Randomly choose from user-specified range
                TrialData.ITILengths = [TrialData.ITILengths, ITI]; % Append ITI to ITI array
                ITITimer = timer('TimerFcn', 'SuccessIndicator = 3;', 'StartDelay', ITI); 
                start(ITITimer); %Pause for mouse to collect reward
                SuccessIndicator = 1; % In ITI
                PosChangeCheck = ScanAngle;
            
            elseif SuccessIndicator == 3 % ITI complete, about to move onto next trial
            
                % --- Save current trial real-time plot & stimulus location
                if Side == 1 % right

                    TrialData.YDataRCorrect = [TrialData.YDataRCorrect; EncoderPlot(1:5001)];
                    TrialData.XDataRCorrect = [TrialData.XDataRCorrect; StoreTime(1:5001)]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'R'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, 1];
                    TrialData.RTrial = TrialData.RTrial + 1;
                    TrialData.RCorrectIndex = [TrialData.RCorrectIndex, 1];

                elseif Side == -1 % left

                    TrialData.YDataLCorrect = [TrialData.YDataLCorrect; EncoderPlot(1:5001)];
                    TrialData.XDataLCorrect = [TrialData.XDataLCorrect; StoreTime(1:5001)]; % Update elapsed time array corresponding to angle
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
            
        if (exist('chktime', 'var') == 1 && StartRoundCheck == TrialNumber && SuccessIndicator == 0) || ((SuccessIndicator == 0) && OutRange(TrialData.OutRangeThreshold, Side, PosInitial, PosFinal)) || (FailIndicator == 2)
            
            if FailIndicator == 0
                
                TrialStop = toc(TrialStart);
                writePWMVoltage(ArduinoLEDSolenoid, RLED, 0);
                writePWMVoltage(ArduinoLEDSolenoid, LLED, 0);
                TrialData.CorrectIndex = [TrialData.CorrectIndex, 0];
                TrialData.TrialLengths = [TrialData.TrialLengths, TrialStop]; % Update trial length array
                
                if OutRange(TrialData.OutRangeThreshold, Side, PosInitial, PosFinal)
                    fprintf('\nOutrange threshold of %d degrees in wrong direction exceeded. Moving onto next trial.\n', TrialData.OutRangeThreshold);
                    TrialData.IncorrectType = [TrialData.IncorrectType, 'O']; % Update incorrect type array
                    TrialData.OutRangeProportion = [TrialData.OutRangeProportion, (length(find(TrialData.IncorrectType == 'O')) / length(TrialData.IncorrectType))];
                
                else
                    fprintf('\nTimeout threshold of %d sec exceeded. Moving onto next trial.\n', TrialData.TimeoutThreshold);
                    TrialData.IncorrectType = [TrialData.IncorrectType, 'T']; % Update incorrect type array
                    TrialData.TimeoutProportion = [TrialData.TimeoutProportion, (length(find(TrialData.IncorrectType == 'T')) / length(TrialData.IncorrectType))];
                
                end
                
                ITI = datasample(TrialData.MinITI:TrialData.MaxITI, 1); % Randomly choose from user-specified range
                TrialData.ITILengths = [TrialData.ITILengths, ITI]; % Append ITI to ITI array
                ITITimer = timer('TimerFcn', 'FailIndicator = 2;', 'StartDelay', ITI); % Pause for mouse to collect reward
                start(ITITimer);
                FailIndicator = 1; % It has already passed through this step, should not pass through this loop again for this round
                PosChangeCheck = ScanAngle;
            
            elseif FailIndicator == 2
                
                if Side == 1

                    TrialData.YDataRIncorrect = [TrialData.YDataRIncorrect; EncoderPlot(1:5001)];
                    TrialData.XDataRIncorrect = [TrialData.XDataRIncorrect; StoreTime(1:5001)]; % Update elapsed time array corresponding to angle
                    TrialData.StimulusLocationAlpha = [TrialData.StimulusLocationAlpha, 'R'];
                    TrialData.StimulusLocationNum = [TrialData.StimulusLocationNum, 1];
                    TrialData.RTrial = TrialData.RTrial + 1;
                    TrialData.RCorrectIndex = [TrialData.RCorrectIndex, 0];
                    TrialData.RIncorrect = length(TrialData.RCorrectIndex) - sum(TrialData.RCorrectIndex);

                elseif Side == -1

                    TrialData.YDataLIncorrect = [TrialData.YDataLIncorrect; EncoderPlot(1:5001)];
                    TrialData.XDataLIncorrect = [TrialData.XDataLIncorrect; StoreTime(1:5001)]; % Update elapsed time array corresponding to angle
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
    
    % --- Shut off any stray power to LEDs & solenoid
    writePWMVoltage(ArduinoLEDSolenoid, RSolenoid, 0); % R Solenoid
    writePWMVoltage(ArduinoLEDSolenoid, LSolenoid, 0); % L Solenoid
    writePWMVoltage(ArduinoLEDSolenoid, RLED, 0); % R LED
    writePWMVoltage(ArduinoLEDSolenoid, LLED, 0); % L LED
    
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
    EncoderPlot = NaN(1, 5001); % Reset EncoderPlot
    StoreAngle = 0; % Reset angular displacement
    %delete(DisplacementLine); % Delete trial displacement to refresh plot
    TrialNumber = TrialNumber + 1; % Increment trial number
    
end

% --- Update non-trivially initialised arrays
TrialData.RCorrectProb = TrialData.RCorrectProb(2:end); % Remove first element (pseudo-initialiser)
TrialData.LCorrectProb = TrialData.LCorrectProb(2:end);
TrialData.AllTime = TrialData.AllTime(2:end);
TrialData.AllScan = TrialData.AllScan(2:end);
clear Procedure


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   SUMMARY OF RESULTS                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TrialStats1(TrialData);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            	SAVE DATA               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



SaveAndAssignDirectory(TrialData, TrialData.UserID);

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
