function y = OutRange(OutBarrier, Side, PosInitial, PosFinal)
    if Side == 1
        if (PosFinal - PosInitial) >= OutBarrier
            y = true;
        else
            y = false;
        end
    elseif Side == -1
        if (PosFinal - PosInitial) <= -1*OutBarrier
            y = true;
        else
            y = false;
        end
    end
end