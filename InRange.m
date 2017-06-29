function y = InRange(AngleMin, AngleMax, PosInitial, PosFinal)
    if (PosFinal - PosInitial) <= AngleMax && (PosFinal - PosInitial) >= AngleMin
        y = true;
    else
        y = false;
    end
end