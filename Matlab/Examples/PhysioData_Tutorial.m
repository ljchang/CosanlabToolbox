% Here is an example of processing Heart Rate data acquired from biopac plethysmograph.
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 1) Create a physio_data object instance. This class inherits methods from
% the design_matrix() class.  Must input data, a cell array of variable
% names, and the sampling frequency
pulse = physio_data(data(:,2), {'pulse'}, 5000);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 2) Downsample the data to speed up computation time.
dpulse = downsample(pulse,'factor', 5);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 3) Filter SCR Data using a zero-phase bandpass filter (1st order Butterworth filter, 0.0159 and 2 Hz cut-off frequencies, sequentially forward and backward),
fdpulse = filter(dpulse,'bandpass',[.0159, 2]);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 4) Smooth data with a moving average of 250 samples to get rid of small spikes
sfdpulse = fdpulse.smooth('span', 250);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 5) Find Peaks in the data using a minimum peak height of the mean of the
% data.  The plot option is helpful to manually inspect the data to ensure
% the peaks were correctly identified.
psfdpulse = peakdetect(sfdpulse,'plot','MinPeakHeight',mean(sfdpulse.dat));

% Can count the number of pverall peaks detected
sum(psfdpulse.dat(:,end))
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 6) Calculate beats per minute with a centered sliding window of 4 sec.
% This method currently runs a for loop over the data and is a bit slow.
% Could be sped up by writing this as a filter.
rpsfdpulse = psfdpulse.calc_rate('WindowLength', 4);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 7) We can now downsample to TR (e.g., 1.3 sec) averaging over samples.
% This is useful if you want to combine this with other data that has a 
% lower sampling resolution, such as fMRI
drpsfdpulse = rpsfdpulse.downsample('Average', 1.3);
drpsfdpulse = drpsfdpulse.removevariable([1,2]); % Select only Averaged HR
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% 8) Finally, it can be useful to (a) plot the data, (b) write the data out
% to a table in a text file, and (c) save the object for future use.
plot(drpsfdpulse)
drpsfdpulse.write(fullfile(fPath, 'HR_drpsfd.txt')); % Write out average HR for each TR
rpsfdpulse.save(fullfile(fPath, 'HR_rpsfd.mat')); % Save Object to .mat file
% -------------------------------------------------------------------------


