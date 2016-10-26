function [t] = TriggerHeat(temp)
global THERMODE_PORT

% calculate byte code
if(mod(temp,1))
    % note: this will treat any decimal value as .5
    temp=temp+128-mod(temp,1);
end
bytecode=fliplr(sprintf('%08.0f',str2double(dec2bin(temp))))-'0';

% send trigger
putvalue(THERMODE_PORT.Line, bytecode);
t=GetSecs;

% flush buffer
WaitSecs(0.5);
putvalue (THERMODE_PORT.Line, [0 0 0 0 0 0 0 0]);
end