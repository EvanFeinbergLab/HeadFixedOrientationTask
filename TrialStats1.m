function TrialStats1(TrialData)

% --- Create new array which stores ALL actions (C - correct, O - incorrect/outrange, T - incorrect/timeout)
ActionTypes = TrialData.IncorrectType;

for i = 1:length(TrialData.CorrectIndex)
    if TrialData.CorrectIndex(i) == 1
        ActionTypes = [ActionTypes(1:(i - 1)), 'C', ActionTypes(i:end)];
    end
end

% --- ALL TRIALS

AllTotal = TrialData.TrialIndex(end);
RTotal = TrialData.RTrial(end);
RProportion = TrialData.RSideProportion(end);
LTotal = TrialData.LTrial(end);
LProportion = TrialData.LSideProportion(end);

% --- ACTIVE TRIALS
% ------ Total on each side
ActiveRTotal = length(intersect(union(find(ActionTypes == 'C'), find(ActionTypes == 'O')), find(TrialData.StimulusLocationAlpha == 'R')));
ActiveLTotal = length(intersect(union(find(ActionTypes == 'C'), find(ActionTypes == 'O')), find(TrialData.StimulusLocationAlpha == 'L')));
ActiveRProportion = ActiveRTotal / RTotal;
ActiveLProportion = ActiveLTotal / LTotal;

% ------ Correct on each side
ActiveRCorrect = length((find(TrialData.RCorrectIndex == 1)));
ActiveLCorrect = length((find(TrialData.LCorrectIndex == 1)));
ActiveRCorrectProportion = ActiveRCorrect / ActiveRTotal;
ActiveLCorrectProportion = ActiveLCorrect / ActiveLTotal;

% ------ Incorrect on each side
ActiveRIncorrect = length(intersect(find(ActionTypes == 'O'), find(TrialData.StimulusLocationAlpha == 'R')));
ActiveLIncorrect = length(intersect(find(ActionTypes == 'O'), find(TrialData.StimulusLocationAlpha == 'L')));
ActiveRIncorrectProportion = ActiveRIncorrect / ActiveRTotal;
ActiveLIncorrectProportion = ActiveLIncorrect / ActiveLTotal;

% --- INACTIVE TRIALS
% ------ Total on each side
InactiveRTotal = length(intersect(find(ActionTypes == 'T'), find(TrialData.StimulusLocationAlpha == 'R')));
InactiveLTotal = length(intersect(find(ActionTypes == 'T'), find(TrialData.StimulusLocationAlpha == 'L')));
InactiveRProportion = InactiveRTotal / RTotal;
InactiveLProportion = InactiveLTotal / LTotal;


% --- Overall result statistics (irrespective of correct/incorrect)
fprintf('\nSUMMARY OF SESSION %s\n', TrialData.SessionID);
fprintf('\nTOTAL trials: %d', AllTotal);
fprintf('\n---R-SIDE trials: %d, %.3f', RTotal, RProportion);
fprintf('\n-----ACTIVE: %d, %.3f', ActiveRTotal, ActiveRProportion);
fprintf('\n--------CORRECT: %d, %.3f', ActiveRCorrect, ActiveRCorrectProportion);
fprintf('\n--------INCORRECT (OUTRANGE): %d, %.3f', ActiveRIncorrect, ActiveRIncorrectProportion);
fprintf('\n-----INACTIVE (TIMEOUT): %d, %.3f', InactiveRTotal, InactiveRProportion);
fprintf('\n---L-SIDE trials: %d, %.3f', LTotal, LProportion);
fprintf('\n-----ACTIVE: %d, %.3f', ActiveLTotal, ActiveLProportion);
fprintf('\n--------CORRECT: %d, %.3f', ActiveLCorrect, ActiveLCorrectProportion);
fprintf('\n--------INCORRECT (OUTRANGE): %d, %.3f', ActiveLIncorrect, ActiveLIncorrectProportion);
fprintf('\n-----INACTIVE (TIMEOUT): %d, %.3f\n\n', InactiveLTotal, InactiveLProportion);
