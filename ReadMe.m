%%%%%%%%%%%%%%%%%%%%%%%
%	VERSION UPDATES   %
%%%%%%%%%%%%%%%%%%%%%%%

%---v1.11 (released 06/18)
% 1. Print summary of session to display at end of session
% 2. Dialogue box after saving to let user know that the sesssion is complete

%---v1.10 (released 06/13)
% 1. Front camera!
% 2. LED brightness is now a user-settable variable

%---v1.9 (released 06/12)
% 1. Correct side-biases during training
    % 1. Update Coinflip.m to review R/L CorrectProb discrepancy at the beginning of each trial
    % 2. Introduced TrialData.SideBiasThreshold variable
    % 3. Introduced TrialData.StimulusTypeNum storage array for stimulus types 
% 2. Introduced TrialData.StimulusLength variable to be able to reduce LED pulse length (to increase trial difficulty)
% 3. Storage of all encoder across all time within session

%---v1.8 (releaesd 06/09)
% 1. OutRange function to handle cheated trials (i.e., mouse goes too far in other direction - disincentivises guessing)
% 2. Storage array for error types (T/O)

%---v1.7.2 (released 06/07)
% 1. Display to read out stimulus side
% 2. Rectified time-out issue
    % 1. Introduced SuccessIndicator variable
    % 2. timer Function instead of tic/toc for timed out trials 

%---v1.7.1 (released 06/06)
% 1. Storage array for total/R/L correct probabilities (to be plotted against trial number, etc.)
% 2. Save feature that correctly assigns/creates directory

%---v1.6.2 (released 05/25)
% 1. Fixed XData array issue where XData(1) = NaN (initialising code)

%---v1.6.1 (released 05/24)
% 1. x-axis to reflect elapsed time rather than bit read
% 2. Storage array for elapsed time corresponding to read angle

%---v1.5 (released 05/23/17)
% 1. Display to read out correct probabilities
% 2. Save angular displacement plots for post-session analysis
% 3. Freebie reward at very beginning of session

%---v1.4 (released 05/19/17)
% 1. Bug fix: make sure they turn the right direction to achieve angle

%---v1.3 (released 05/18/17)
% 1. Connection to USB camera
% 2. Bug fix: serial timeout
% 3. Timeout: if unresponsive for user-specified amount of time, then move onto next trial

%---v1.2 (released 05/15/17)
% 1. UI input: added a timeout threshold parameter
% 2. TrialData structure: added trial probability metrics (total/R/L correct proportion)

%---v1.1 (released 05/07/17)
% 1. Most basic features needed to run the head-fixed protocol, including:
%   a. Random LED selection, subsequent lighting of LED
%   b. Rotary encoder to measure angular displacement of ball
%   c. Solenoid trigger when correct angular range has been reached
% 2. Real-time plot of angular displacement for tracking
% 3. UI input dialogue to control parameters (mouse/session info, trial length, solenoid pulse length)