% --- Connect LED & Solenoid Arduino
clear all; close all; delete(instrfind);

BoardType = 'Uno';
COM1 = '/dev/cu.usbmodem1411';
% COM2 = '/dev/cu.usbmodem1421';

% a = arduino(COM2, BoardType)
s = serial(COM1);
s.BaudRate = 9600;
fopen(s);

CapValues = [];
i = 0;

CapTimer = tic;

% writePWMVoltage(a, 'D3', 5); pause(0.1); writePWMVoltage(a, 'D3', 0);

while toc(CapTimer) <= 20;
    
    warning('off', 'MATLAB:serial:fscanf:unsuccessfulRead');
    Capacitance = fscanf(s);
    warning('on', 'MATLAB:serial:fscanf:unsuccessfulRead');
    
    if ~isa(Capacitance, 'double')
        Capacitance = str2double(Capacitance);
    end
    
    fprintf('Capacitance detected: %d\n', Capacitance);
    CapValues = [CapValues, Capacitance];
    
%     if MovingSlope(CapValues, 2) > 10
%     	fprintf('Lick detected!');
%     end
   
end

x = 1:1:length(CapValues);
y = CapValues;
plot(x, y, 'b');
hold on
y_diff = MovingSlope(CapValues, 2);
plot(x, y_diff, 'r');