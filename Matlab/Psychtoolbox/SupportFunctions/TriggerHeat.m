function [t] = TriggerHeat(temp,dur)
global THERMODE_PORT

code = 80 + (3*(dur-1)) + temp;

% calculate byte code
bytecode=fliplr(sprintf('%08.0f',str2double(dec2bin(code))))-'0';

% send trigger
putvalue(THERMODE_PORT.Line, bytecode);
t=GetSecs;

% flush buffer
WaitSecs(0.5);
putvalue (THERMODE_PORT.Line, [0 0 0 0 0 0 0 0]);
end