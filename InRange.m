function y = InRange(AngleMin, AngleMax, PosInitial, PosFinal)

PosDiff = PosFinal - PosInitial;
if PosDiff <= -180
    PosDiff = PosDiff + 360; 
elseif PosDiff > 180
    PosDiff = PosDiff - 360;
end

if PosDiff <= AngleMax && PosDiff >= AngleMin
    y = true;
else
    y = false;
end

end