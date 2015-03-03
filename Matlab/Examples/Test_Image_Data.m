%% Test image_data() Class
% This script tests the functionality of the image_data() class
% Written by Luke Chang 3/2015

% initialize data - matrix
data = rand(100,25); 
dat = image_data(data);

% Plot data
plot(dat);

% Write out Single Image
dat.write(fullfile(pwd,'Test.csv'));

% Load Single Image from file
dat = image_data(fullfile(pwd,'Test.csv'));

% Write out Multiple Images
dat.dat = [dat.dat(:,1), dat.dat(:,1) + rand(size(dat.dat,1),1), dat.dat(:,1) + rand(size(dat.dat,1),1)];
dat.write('Test.csv');

% Read Multiple Image from File
fname = {fullfile(pwd,'Test_1.csv'); fullfile(pwd,'Test_2.csv'); fullfile(pwd,'Test_3.csv')};
dat = image_data(fname);

% Regression
dat.X = [1, 1; 1, 0; 1, 0];
stats = regress(dat);

% Plot beta
plot(stats.b);

% write out beta
stats.b.write(fullfile(pwd,'Test_beta.csv'));

% Robust Regression
dat.X = [1, 1; 1, 0; 1, 0];
stats = regress(dat,'robust');

% Plot t image
stats.t.plot

% Mean of data
mn = mean(dat);

% Concatenate data
c = [mn dat];

% Size of data
size(dat)
size(dat,1)

% Convert to 2D matrix
matrix2d = oned2twod(dat,1);
matrix2d = oned2twod(dat);




