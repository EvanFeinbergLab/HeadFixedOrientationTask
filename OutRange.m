function y = OutRange(OutBarrier, Side, PosInitial, PosFinal)

PosDiff = PosFinal - PosInitial;
if PosDiff <= -180
    PosDiff = PosDiff + 360; 
elseif PosDiff > 180
    PosDiff = PosDiff - 360;
end

if Side == 1
    if PosDiff >= OutBarrier
        y = true;
    else
        y = false;
    end
    
elseif Side == -1
    if PosDiff <= -1*OutBarrier
        y = true;
    else
        y = false;
    end
    
end

end