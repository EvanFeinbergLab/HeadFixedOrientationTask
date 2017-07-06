function y = CorrectDirection(vector, Side)
 
    RecordedAngles = DeleteNaN(vector);
    %RecordedAngles = RecordedAngles(end - 5:end);
    Derivatives = diff(RecordedAngles);
    CriticalDerivative = Derivatives(end);
    
    if CriticalDerivative <= -180
        CriticalDerivative = CriticalDerivative + 360; 
    elseif CriticalDerivative > 180
        CriticalDerivative = CriticalDerivative - 360;
    end

    BallDirection = sign(CriticalDerivative) * -1; % f' < 0 => going to the right, Side = 1
                                                   % f' > 0 => going to the left, Side = -1
                                                   
    if BallDirection == Side
        y = true;
    elseif BallDirection ~= Side
        y = false;
    end