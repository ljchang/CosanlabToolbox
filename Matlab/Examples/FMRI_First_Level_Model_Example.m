% -------------------------------------------------------------------------
% Here is an example of running an fMRI first level model using cosanlab
% and canlab tools.  This is a very flexible procedure and can be scripted
% in a variety of ways.
%
% Required toolboxes:
% 1) cosanlab toolbox
% 2) spm
% 3) canlab toolbox
%
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Specify paths and data file with stimulus onsets for each subject
% -------------------------------------------------------------------------

fPath = '/Volumes/engram/Users/lukechang/Dropbox/Guilt';
dPath = '/Volumes/engram/labdata/collab/Guilt';

data = design_matrix(fullfile(fPath,'Data','NeuronReanalyze','Guilt_Neuron_Reanalyze_Onsets.csv'));

% Create a design matrix for each subject combine runs and add separate intercept for each run.
sub = unique(data.dat(:,1));
run = unique(data.dat(:,2));
con = {'Face','PredInvest','Offer','PredReturn','Summary','Expect','Match','Return1','Return2','Return3','Return4','More','Missing'};


% -------------------------------------------------------------------------
% Build design Matrix, run regression, and write out beta files.  Loop
% through all subjects
% -------------------------------------------------------------------------

for i = 1:length(sub)
    
    % -------------------------------------------------------------------------
    % load fmri_data and stack runs into one file
    % -------------------------------------------------------------------------
    
    for j = 1:length(run)
        dat = fmri_data(fullfile(dPath,'Imaging',num2str(sub(i)),'Functional','Preprocessed',['run' num2str(run(j))],['swrad' num2str(sub(i)) '_run' num2str(run(j)) '_flip.nii']));
        if j == 1
            sdat = dat;
        else
            sdat = [sdat, dat];
        end
    end
    
    % -------------------------------------------------------------------------
    %Create Full Design Matrix for subject
    % -------------------------------------------------------------------------
    
    tr = 207; %number of volumes
    s = data.dat(data.dat(:,1)==sub(i),:); %select subject data from main stimulus onset data file
    
    for j = 1:length(run) %Loop through runs and stack into one file per subject
        
        % -------------------------------------------------------------------------
        %Create Intercept
        % -------------------------------------------------------------------------
        
        int = zeros(tr,4);
        int(:,j) = ones(tr,1);
        
        % -------------------------------------------------------------------------
        % add task onsets to Design Matrix
        % -------------------------------------------------------------------------
        srdm = design_matrix(int,{'Intercept1','Intercept2','Intercept3','Intercept4'});
        for k = 1:13
            getdat = s(s(:,3)==k & s(:,2)==run(j),4:6); %Grab onset data for condition and run
            %check if regressor exists
            if ~isempty(getdat)
                srdm = srdm.onsettimes({getdat}, con(k), 2, 'sec2tr');
            else %fill in with empty regressor - will complain about being rank deficient
                srdm = srdm.addvariable(zeros(tr,1),'Name',con(k));
            end
        end
        if j == 1 %Stack Runs
            sdm = srdm;
        else
            sdm = [sdm; srdm];
        end
    end
    
    % -------------------------------------------------------------------------
    %Convolve task regressors with canonical hrf (requires spm_hrf()
    %function on path
    % -------------------------------------------------------------------------
    
    sdm = sdm.conv_hrf('tr', 2, 'select',[5:17]);
    
    % -------------------------------------------------------------------------
    %Add nuisance regressors - uses nuisance .mat file created with
    %canlab_preproc
    % -------------------------------------------------------------------------
    
    load(fullfile(dPath,'Imaging',num2str(sub(i)),'Functional','Preprocessed','Nuisance_covariates_R.mat'))
    sdm = sdm.addvariable([R{2}{5},R{1}{5}]);
    
    % -------------------------------------------------------------------------
    %Add highpass filter - Uses spm's discrete cosine transform, which is
    %added to design matrix
    % -------------------------------------------------------------------------
    
    sdm = sdm.hpfilter('tr', 2, 'duration', 180);
    
    % -------------------------------------------------------------------------
    %Run Regression - run OLS regress.  Don't need to correct for
    %autocorrelation if only interested in looking at 2nd level data
    % -------------------------------------------------------------------------
    
    sdat.Y = sdm.dat; %combine fmri_data() and design_matrix() objects
    [out, statimg] = regress(sdat, .005, 'unc', 'nodisplay', 'nointercept'); %Run regression
    dat.dat = out.b(11:15,:)'; %select betas to write out to nifti image
    dat.fullpath = fullfile(fPath,'Data','NeuronReanalyze',[num2str(sub(i)) '_Match_Expectation.nii']); %specify file path
    write(dat) %write data to .nii file
    
end