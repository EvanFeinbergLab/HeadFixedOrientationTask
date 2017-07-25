clear all; clc; close all; delete(instrfind);

% --- Connect LED & Solenoid Arduino
BoardType = 'Uno'; 
SelectLEDCOM = GetSerialPort;
[LEDSelection, p] = listdlg('PromptString', 'Select LED & Solenoid communication port:', 'SelectionMode', 'single', 'ListString', SelectLEDCOM);
COM_LED = cell2mat(SelectLEDCOM(LEDSelection));
a = arduino(COM_LED, BoardType); % Establish hardware communication with LED & Solenoid Arduino
writeDigitalPin(a, 'D5', 0); % Reset LED to off mode
writeDigitalPin(a, 'D6', 0); % Reset LED to off mode

FrontCamera = webcam(1);
BackCamera = webcam(2);
preview(FrontCamera); 
preview(BackCamera);

% --- Dark Run

Procedure = tic;

while toc(Procedure) <= 3600
    writePWMVoltage(a, 'D3', 5);
    pause(0.3);
    writePWMVoltage(a, 'D3', 0);
    pause(60);
end