function port = getserialport
    serialInfo = instrhwinfo('serial');
    port = serialInfo.SerialPorts;
end