
function [t] = TriggerBiopac_io32(dur)
% USAGE: [time] = TriggerBiopac_io32(duration)
% this function made to work with io32
% See http://apps.usd.edu/coglab/psyc770/IO32.html

global BIOPAC_PORT

ioObj = io32;
status = io32(ioObj);
if status
    error('Make sure io32 is installed correctly and added to path')
end
io32(ioObj,BIOPAC_PORT,2); %send TTL to biopac
t = GetSecs;
WaitSecs(dur);
io32(ioObj, BIOPAC_PORT, 0); %flush TTL signal

end