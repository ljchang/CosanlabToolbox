function [t] = TriggerBiopac(dur)
% USAGE: [time] = TriggerBiopac(duration)
% this function made to work with DAQ

global BIOPAC_PORT

putvalue(BIOPAC_PORT.Line, 2);
t = GetSecs;
WaitSecs(dur);
putvalue(BIOPAC_PORT.Line, 0);

end