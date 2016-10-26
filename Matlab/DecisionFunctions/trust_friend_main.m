function [params] = trust_friend_main(model);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   This script fits various reinforcement learning models to the Trust datasets from Rutgers.
%   Written by Luke Chang, University of Arizona, ljchang@email.arizona.edu
%
%   Models:
%   NLH         1 Parameter Expected Value Model (beta)%
%
%   STH         2 Parameter RW / decision hybrid model (alpha, beta)
%
%   LGH         3 Parameter RW / decision hybrid  model ( alphaG, alphaL, beta)
%
%   ValBonusH   3 Parameter RW  / decision hybrid model with bonus to value
%               term based on initial beliefs for each condition (e.g.,
%               friend, confederate, computer).  3 Parameters (alpha,
%               theta, beta)
%
%   ValBonus2H  4 Parameter RW  / decision hybrid model with bonus to value
%               term based on initial beliefs for each condition (e.g.,
%               friend, confederate, computer).  4 Parameters (alphaG,
%               alpha L, theta, beta)
%
%   Options:
%   rmsrch      adding '_rmsrch' at the end of each model will run the
%               model 100 times with a randomly selected initial starting
%               value. The best fitting model will be used.  Use this as a
%               final version
%
%   Example:
%   lgh = trust_friend_main('LGH')
%   lghrmsrch = trust_friend_main('LGH_rmsrch')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%NOTES:
%   Last updated by lc on 5/10/12
%   edited by Dominic Fareri 9/2012 for social network manipulations
%   updated again by DF, 4/2013
%
%   5/10/13: Luke: Bug fixes and new models
%       1) fixed bug in rmsrch that was using last iteration instead of
%       best iteration for writing out trial data
%
%       2) Added ValBonusH Model - which gives a bonus based on subjects
%       trustworthiness scaled by theta parameter. Uses only 1 learning
%       rate (3 params total).  This works even if Better if alpha gains is
%       2 X alpha loss
%
%       3) Added ValBonus2H Model - which gives a bonus based on subjects
%       trustworthiness scaled by theta parameter (4 params total).  This
%       model uses two learning rates for gains and losses.


global SubNum Condition sub VPEout

%% Set optimization parameters

options = optimset(@fmincon);
options = optimset(options, 'TolX', 0.00001, 'TolFun', 0.00001, 'MaxFunEvals', 900000000, 'LargeScale','off');

%% Data processing
%subject, include, TrialOrder, Run, Trial, Partner, Decision, Outcome, RT,
%PreRating, PostRating, ConTrial
%partner:   3=friend, 2=confederate, 1=computer,
%decision: 1=share, 0=keep
%outcome: 1=gain, 0=loss, 3=keep

%data=dlmread('/Users/lukechang/Research/Trust_Friend/Modeling/TrustSN_formodeling_allsubs_SANCNS_nohdr.txt');
data=dlmread('/Users/lukechang/Research/Trust_Friend/Modeling/TrustSN_formodeling_allsubs_SANCNS_nohdr2.txt');
%[header,data]=hdrload('/Users/lukechang/Research/Trust_CB/Analyses/20ss_less20FBincluded_4_2012bios.txt'); %Bios

%remove exclusions

%remove missing trials (999999)
data(find(data(:,7)==999999), 7:9)=nan; %set missing to NAN
%data1 = data;
%data2 = data;

%data(find(data(:,1)==12), :)=[];    %wrong images used for run 5, subject 12
%data(find(data(:,1)==13), :)=[];    %never experienced condition
%data(find(data(:,1)==14), :)=[];    %artifact
%data(find(data(:,1)==23), :)=[];    %never experienced condition, sleepy

data(find(data(:,2)==0), :)=[]; %remove all subjects and runs coded to be excluded (ss12r5, ss14, ss23)

%data1(find(data1(:,1)~=13), :)=[]; %this and the next 2 lines of code were implemented to re-run the models just on subjects for which the trial estimates seemed to be calculated incorrectly (e.g., lots of NaNs everywhere).
%data2(find(data2(:,1)~=31), :)=[];

%data = [data1;data2];

SubNum = unique(data(:,1));
Partner = unique(data(:,6));
alldata=[data(:,1) data(:,6:8) data(:,5) data(:,12) data(:,10:11) data(:,13)]; %subject, partner, decision, outcome, Trial, ConTrial, PreRating, PostRating

%% Estimate parameters using fmincon for each subject

switch model
    
    case 'NLH' % fixed probability no learning model as per reviewer.
        ipar=[0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_NLH, ipar, [], [], [], [], [0.01], [1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_NLH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_NLH.txt VPESubOut -ascii
        
    case 'NLInitH' % fixed probability no learning model as per reviewer with separate value for each condition.
        ipar=[0.01 0.01 0.01 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_NLInitH, ipar, [], [], [], [], [0.01 0.01 0.01 0.01], [1 1 1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_NLInitH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_NLInitH.txt VPESubOut -ascii
        
    case 'STH' % 2 parameter Hybrid model.
        ipar=rand(1,2);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_STH, ipar, [], [], [], [], [0.01 0.01], [1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_STH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_STH.txt VPESubOut -ascii
        
    case 'LGInitH' % 3 parameter Hybrid model with free parameters for initial values of 4 conditions.
        ipar=[0.01 0.01 0.01 0.01 0.01 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_LGInitH, ipar, [], [], [], [], [0.01 0.01 0.01 0.01 0.01 0.01], [1 1 1 1 1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LGInitH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LGInitH.txt VPESubOut -ascii
        
    case 'LGH' % 3 parameter Hybrid model.
        ipar=rand(1,3);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_LGH, ipar, [], [], [], [], [0.01 0.01 0.01], [1 1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LGH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LGH.txt VPESubOut -ascii
        
    case 'LG2H' % 3 parameter Hybrid model.
        ipar=rand(1,2);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_LG2H, ipar, [], [], [], [], [0.01 0.01], [1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LG2H.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LG2H.txt VPESubOut -ascii
        
    case 'CBiasH' % 3 parameter Hybrid model.
        ipar=[0.01 0.01 0.01 1.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_CBiasH, ipar, [], [], [], [], [0.01 0.01 0.01 1.01], [1 1 1 10], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_CBiasH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_CBiasH.txt VPESubOut -ascii
        
    case 'ValBonusH' % 3 parameter Hybrid model.
        ipar=rand(1,3);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_ValBonusH, ipar, [], [], [], [], [0.01 0.01 0.01 ], [1 3 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            %Calculate bonus (normalized rating * theta)
            Partner = unique(alldata(:,2));
            for j = 1:length(Partner)
                trust(sub,j) = mean(subdata(subdata(:,2) == Partner(j),7))/7;
                params(sub,length(xpar)+5+j) = params(sub,3) * trust(sub,j);
            end
            
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_ValBonusH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_ValBonusH.txt VPESubOut -ascii
        
    case 'IOSValBonusH' % 3 parameter Hybrid model.
        ipar=rand(1,3);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_IOSValBonusH, ipar, [], [], [], [], [0.01 0.01 0.01 ], [1 5 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            %Calculate bonus (normalized rating * theta)
            Partner = unique(alldata(:,2));
            for j = 1:length(Partner)
                trust(sub,j) = mean(subdata(subdata(:,2) == Partner(j),9))/7;
                params(sub,length(xpar)+5+j) = params(sub,3) * trust(sub,j);
            end
            
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_IOSValBonusH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_IOSValBonusH.txt VPESubOut -ascii
        
    case 'ValBonus2H' % 3 parameter Hybrid model.
        ipar=rand(1,4);
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_ValBonus2H, ipar, [], [], [], [], [0.01 0.01 0.01 0.01], [1 1 3 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_ValBonus2H.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_ValBonus2H.txt VPESubOut -ascii
        
    case 'LGConH' %Gain Loss 3 parameter Q model separately for each condition.
        ipar=[0.01 0.01 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            Condition=unique(subdata(:,2));
            params=[];
            for con=1:length(Condition)
                condata=subdata(find(subdata(:,2)==Condition(con)),:);
                
                [xpar fval exitflag output]=fmincon(@Trust_minimization_LGConH, ipar, [], [], [], [], [0.01 0.01 0.01], [1 1 1], [], [], condata);
                
                params(con,1)=SubNum(sub);
                params(con,2)=Condition(con);
                params(con,3:length(xpar)+2)=xpar;
                params(con,length(xpar)+3)=fval;
                params(con,length(xpar)+4)=output.iterations;
                params(con,length(xpar)+5)=2*length(ipar)+fval; %AIC-smaller is better
                params(con,length(xpar)+6)=2*fval+length(ipar)*log(length(condata)); %BIC-Smaller is better
            end
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        subdataout
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        %tcbOutput(params,VPESubOut)
        %nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LGConH.txt subdataout -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LGConH.txt VPESubOut -ascii
        
    case 'NLInitConH' %No Learning 50% expected probability with initial value modeled separately for each condition.
        ipar=[0.01 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            Condition=unique(subdata(:,2));
            params=[];
            for con=1:length(Condition)
                condata=subdata(find(subdata(:,2)==Condition(con)),:);
                
                [xpar fval exitflag output]=fmincon(@Trust_minimization_NLInitConH, ipar, [], [], [], [], [0.01 0.01], [1 1], [], [], condata);
                
                params(con,1)=SubNum(sub);
                params(con,2)=Condition(con);
                params(con,3:length(xpar)+2)=xpar;
                params(con,length(xpar)+3)=fval;
                params(con,length(xpar)+4)=output.iterations;
                params(con,length(xpar)+5)=2*length(ipar)+fval; %AIC-smaller is better
                params(con,length(xpar)+6)=2*fval+length(ipar)*log(length(condata)); %BIC-Smaller is better
            end
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        subdataout
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        %tcbOutput(params,VPESubOut)
        %nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_NLInitConH.txt subdataout -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_NLInitConH.txt VPESubOut -ascii
        
    case 'BayesH' % 1 parameter Bayesian Hybrid model.
        ipar=[0.01 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_BayesH, ipar, [], [], [], [], [0.01 0.01], [1 10], [], options, subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be negative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be negative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_BayesH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_BayesH.txt VPESubOut -ascii
        
    case 'BayesWtH' % 1 parameter Bayesian Hybrid model.
        ipar=[1 0.01];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_BayesWtH, ipar, [], [], [], [], [1 0.01], [100 10], [], options, subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be negative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be negative see Doll et al Brain Research
            
            %Display the subject being processed
            disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_BayesWtH.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_BayesWtH.txt VPESubOut -ascii
        
    case 'NLH_rmsrch' % 1 parameter Expected Value model.
        ipar=[0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01];
        upper_limits =[1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            %for   sub=11
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_NLH(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_NLH, xstartmin, [], [], [], [], lower_limits, upper_limits, [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_NLH_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_NLH_rmsrch.txt VPESubOut -ascii
        
    case 'STH_rmsrch' % 2 parameter Hybrid model.
        ipar=[0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01];
        upper_limits =[1 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            %for   sub=11
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_STH(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            [xpar fval exitflag output]=fmincon(@Trust_minimization_STH, xstartmin, [], [], [], [], [0.01 0.01], [1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_STH_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_STH_rmsrch.txt VPESubOut -ascii
        
    case 'LGH_rmsrch' % 2 parameter Hybrid model.
        ipar=[0.01 0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01 0.01];
        upper_limits =[1 1 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            %for   sub=11
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_LGH(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_LGH, xstartmin, [], [], [], [], [0.01 0.01 0.01], [1 1 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LGH_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LGH_rmsrch.txt VPESubOut -ascii
        
    case 'ValBonusH_rmsrch' % 2 parameter Hybrid model.
        ipar=[0.01 0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01 0.01];
        upper_limits =[1 3 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_ValBonusH(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_ValBonusH, xstartmin, [], [], [], [], [0.01 0.01 0.01 ], [1 3 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Calculate bonus (normalized rating * theta)
            Partner = unique(alldata(:,2));
            for j = 1:length(Partner)
                trust(sub,j) = mean(subdata(subdata(:,2) == Partner(j),7))/7;
                params(sub,length(xpar)+5+j) = params(sub,3) * trust(sub,j);
            end
            
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_ValBonusH_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_ValBonusH_rmsrch.txt VPESubOut -ascii
        
    case 'ValBonus2H_rmsrch' % 2 parameter Hybrid model.
        ipar=[0.01 0.01 0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01 0.01 0.01];
        upper_limits =[1 1 3 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_ValBonus2H(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_ValBonus2H, xstartmin, [], [], [], [], [0.01 0.01 0.01 0.01 ], [1 1 3 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Calculate bonus (normalized rating * theta)
            Partner = unique(alldata(:,2));
            for j = 1:length(Partner)
                trust(sub,j) = mean(subdata(subdata(:,2) == Partner(j),7))/7;
                params(sub,length(xpar)+5+j) = params(sub,3) * trust(sub,j);
            end
            
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_ValBonus2H_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_ValBonus2H_rmsrch.txt VPESubOut -ascii
        
    case 'IOSValBonusH_rmsrch' % 3 parameter Hybrid model.
        ipar=[0.01 0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01 0.01];
        upper_limits =[1 3 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            
            [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_IOSValBonusH(xpar,subdata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
            
            %Find best fitting initial parameter
            xparmin=xpar(find(fval==min(fval)),:);
            fvalmin=min(fval);
            sizeXpar=size(xparmin);
            xstartmin=xstart(find(fval==min(fval)),:);
            if sizeXpar(1)>1
                xpar=xpar(1,:);
                xstartmin=xstartmin(1,:);
            end
            
            %Rerun model based on best fitting initial parameter (this will
            %ensure that the Trial output is correct.
            
            [xpar fval exitflag output]=fmincon(@Trust_minimization_IOSValBonusH, xstartmin, [], [], [], [], [0.01 0.01 0.01 ], [1 5 1], [], [], subdata);
            
            params(sub,1)=SubNum(sub);
            params(sub,2:length(xpar)+1)=xpar;
            params(sub,length(xpar)+2)=fval;
            params(sub,length(xpar)+3)=output.iterations;
            params(sub,length(xpar)+4)=2*length(ipar)+fval; %AIC-smaller is better - LLE should be Comative see Doll et al Brain Research
            params(sub,length(xpar)+5)=2*fval+length(ipar)*log(length(subdata)); %BIC-Smaller is better - LLE should be Comative see Doll et al Brain Research
            
            %Calculate bonus (normalized rating * theta)
            Partner = unique(alldata(:,2));
            for j = 1:length(Partner)
                trust(sub,j) = mean(subdata(subdata(:,2) == Partner(j),9))/7;
                params(sub,length(xpar)+5+j) = params(sub,3) * trust(sub,j);
            end
            
            VPESubOut=[VPESubOut; VPEout];
        end
        
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        tcbOutput(params,VPESubOut)
        nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_IOSValBonusH_rmsrch.txt params -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_IOSValBonusH_rmsrch.txt VPESubOut -ascii
        
    case 'LGConH_rmsrch' %Gain Loss 3 parameter Q model separately for each condition.
        ipar=[0.01 0.01 0.01];
        num_start_pts =100; % number of different starting points
        lower_limits =  [0.01 0.01 0.01];
        upper_limits =[1 1 1];
        subdataout=[];
        VPESubOut=[];
        for sub=1:length(SubNum)
            subdata=alldata(find(alldata(:,1)==SubNum(sub)),:);
            Condition=unique(subdata(:,2));
            params=[];
            cVPEout=[];
            for con=1:length(Condition)
                condata=subdata(find(subdata(:,2)==Condition(con)),:);
                [xpar, fval, exitflag, xstart]=rmsearch(@(xpar) Trust_minimization_LGConH(xpar,condata) , 'fmincon', ipar, lower_limits, upper_limits, 'initialsample',num_start_pts, 'options',options);
                
                %Find best fitting initial parameter
                xparmin=xpar(find(fval==min(fval)),:);
                fvalmin=min(fval);
                sizeXpar=size(xparmin);
                xstartmin=xstart(find(fval==min(fval)),:);
                if sizeXpar(1)>1
                    xpar=xpar(1,:);
                    xstartmin=xstartmin(1,:);
                end
                
                %Rerun model based on best fitting initial parameter (this will
                %ensure that the Trial output is correct.
                
                [xpar fval exitflag output]=fmincon(@Trust_minimization_LGConH, xstartmin, [], [], [], [], [0.01 0.01 0.01], [1 1 1], [], [], condata);
                
                params(con,1)=SubNum(sub);
                params(con,2)=Condition(con);
                params(con,3:length(xpar)+2)=xpar;
                params(con,length(xpar)+3)=fval;
                params(con,length(xpar)+4)=output.iterations;
                params(con,length(xpar)+5)=2*length(ipar)+fval; %AIC-smaller is better
                params(con,length(xpar)+6)=2*fval+length(ipar)*log(length(condata)); %BIC-Smaller is better
                
                cVPEout=[cVPEout; VPEout];
            end
            
            %Display the subject being processed
            %disp([ 'Subject ' num2str(SubNum(sub)) ':' num2str(exitflag) ])
            
            subdataout=[subdataout; params];
            VPESubOut=[VPESubOut; cVPEout];
        end
        
        subdataout
        %%Display interesting parameters
        %Average Squared Error and Plot of learning
        %tcbOutput(params,VPESubOut)
        %nanmean(params(:,size(params,2)-1))
        
        %%Write out parameters to file
        %sub, alpha, beta, fval, iterations, AIC
        save Trust_Friend_Params_LGConH_rmsrch.txt subdataout -ascii
        
        %sub, condition, decision, outcome, trial, pe
        save Trust_Friend_Trial_LGConH_rmsrch.txt VPESubOut -ascii
end

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subfunctions  - Actual Models
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function LogLike=Trust_minimization_NLH(xpar,data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        beta=xpar(1);
        %p=xpar(2);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        
        %         epFri=p;
        %         epCon=p;
        %         epCom=p;
        %         epCom=p;
        
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_NLInitH(xpar,data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        beta=xpar(1);
        epFri=xpar(2);
        epCon=xpar(3);
        epCom=xpar(4);
        
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    evFri=epFri*1.5;
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    evCon=epCon*1.5;
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    evCom=epCom*1.5;
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_STH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alpha=xpar(1);
        beta=xpar(2);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        epFri = epFri + alpha * pe;
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        epCon = epCon + alpha * pe;
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        epCom = epCom + alpha * pe;
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_LGH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alphaG=xpar(1);
        alphaL=xpar(2);
        beta=xpar(3);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri=epFri+alphaG*pe;
                        elseif wtrial(4)==0
                            epFri=epFri+alphaL*pe;
                        end
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon=epCon+alphaG*pe;
                        elseif wtrial(4)==0
                            epCon=epCon+alphaL*pe;
                        end
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom=epCom+alphaG*pe;
                        elseif wtrial(4)==0
                            epCom=epCom+alphaL*pe;
                        end
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_LG2H(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alpha=xpar(1);
        beta=xpar(2);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri = epFri + alpha * pe;
                        elseif wtrial(4)==0
                            epFri = epFri + (alpha/2) * pe;
                        end
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon = epCon + alpha * pe;
                        elseif wtrial(4)==0
                            epCon = epCon + (alpha/2) * pe;
                        end
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom = epCom + alpha * pe;
                        elseif wtrial(4)==0
                            epCom = epCom + (alpha/2) * pe;
                        end
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_LGInitH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alphaG=xpar(1);
        alphaL=xpar(2);
        beta=xpar(3);
        epFri=xpar(4);
        epCon=xpar(5);
        epCom=xpar(6);
        
        %Set initial values
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri=epFri+alphaG*pe;
                        elseif wtrial(4)==0
                            epFri=epFri+alphaL*pe;
                        end
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon=epCon+alphaG*pe;
                        elseif wtrial(4)==0
                            epCon=epCon+alphaL*pe;
                        end
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom=epCom+alphaG*pe;
                        elseif wtrial(4)==0
                            epCom=epCom+alphaL*pe;
                        end
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_LGConH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alphaG=xpar(1);
        alphaL=xpar(2);
        beta=xpar(3);
        
        %Set initial values
        ep=.5;
        ev=.75;
        pSh=.5;
        pKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            if wtrial(3)==1
                pe=(wtrial(4)-ep);
                if wtrial(4)==1
                    ep=ep+alphaG*pe;
                elseif wtrial(4)==0
                    ep=ep+alphaL*pe;
                end
                ev=ep*1.5;
            else
                pe=0;
            end
            pSh=exp(ev/beta)/(exp(ev/beta)+exp(1/beta));
            pKp=exp(1/beta)/(exp(ev/beta)+exp(1/beta));
            if wtrial(3)==1
                LogLike=LogLike-log(pSh);
            elseif wtrial(3)==0
                LogLike=LogLike-log(pKp);
            end
            
            VPE=[data(trialnum,:) trialnum ep pSh pKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_NLInitConH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        init=xpar(1);
        beta=xpar(2);
        
        %Set initial values
        ep=init;
        ev=.75;
        pSh=.5;
        pKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            if wtrial(3)==1
                ev=ep*1.5;
            else
                pe=0;
            end
            pSh=exp(ev/beta)/(exp(ev/beta)+exp(1/beta));
            pKp=exp(1/beta)/(exp(ev/beta)+exp(1/beta));
            if wtrial(3)==1
                LogLike=LogLike-log(pSh);
            elseif wtrial(3)==0
                LogLike=LogLike-log(pKp);
            end
            
            VPE=[data(trialnum,:) trialnum ep pSh pKp];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_CBiasH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alphaG=xpar(1);
        alphaL=xpar(2);
        beta=xpar(3);
        theta=xpar(4);
        
        %Keep within reasonable bounds
        if theta>(1/alphaG)
            theta = 1/alphaG;
        elseif theta>(1/alphaL)
            theta = 1/alphaL;
        end
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri=epFri+alphaG*pe;
                        elseif wtrial(4)==0
                            epFri=epFri+(1/theta)*alphaL*pe;
                        end
                        evFri=epFri*1.5;
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon=epCon+alphaG*pe;
                        elseif wtrial(4)==0
                            epCon=epCon+alphaL*pe;
                        end
                        evCon=epCon*1.5;
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom = epCom + alphaG*pe;
                        elseif wtrial(4)==0
                            epCom = epCom + alphaL*pe;
                        end
                        evCom=epCom*1.5;
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end


    function LogLike=Trust_minimization_ValBonusH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating PostRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alpha = xpar(1);
        theta = xpar(2);
        beta = xpar(3);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri = epFri + alpha * pe;
                        elseif wtrial(4)==0
                            epFri = epFri + alpha * pe;
                        end
                        evFri = epFri * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon = epCon + alpha * pe;
                        elseif wtrial(4)==0
                            epCon = epCon + alpha * pe;
                        end
                        evCon = epCon * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom = epCom + alpha * pe;
                        elseif wtrial(4)==0
                            epCom = epCom + alpha * pe;
                        end
                        evCom = epCom * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_ValBonus2H(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating PostRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alphaG = xpar(1);
        alphaL = xpar(2);
        theta = xpar(3);
        beta = xpar(4);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri = epFri + alphaG * pe;
                        elseif wtrial(4)==0
                            epFri = epFri + alphaL * pe;
                        end
                        evFri = epFri * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon = epCon + alphaG * pe;
                        elseif wtrial(4)==0
                            epCon = epCon + alphaL * pe;
                        end
                        evCon = epCon * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom = epCom + alphaG * pe;
                        elseif wtrial(4)==0
                            epCom = epCom + alphaL * pe;
                        end
                        evCom = epCom * (1.5 + theta * wtrial(7)/7);
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_IOSValBonusH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating PostRating closenessRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %global VPEout
        
        %Free parameters
        alpha = xpar(1);
        theta = xpar(2);
        beta = xpar(3);
        
        %Set initial values
        epFri=.5;
        epCon=.5;
        epCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        pe=0;
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        pe=(wtrial(4)-epFri);
                        if wtrial(4)==1
                            epFri = epFri + alpha * pe;
                        elseif wtrial(4)==0
                            epFri = epFri + alpha * pe;
                        end
                        evFri = epFri * (1.5 + theta * wtrial(9)/7);
                    else
                        pe=0;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCon);
                        if wtrial(4)==1
                            epCon = epCon + alpha * pe;
                        elseif wtrial(4)==0
                            epCon = epCon + alpha * pe;
                        end
                        evCon = epCon * (1.5 + theta * wtrial(9)/7);
                    else
                        pe=0;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=1-pConSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        pe=(wtrial(4)-epCom);
                        if wtrial(4)==1
                            epCom = epCom + alpha * pe;
                        elseif wtrial(4)==0
                            epCom = epCom + alpha * pe;
                        end
                        evCom = epCom * (1.5 + theta * wtrial(9)/7);
                    else
                        pe=0;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=1-pComSh;
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) epFri epCon epCom pFriSh pFriKp pConSh pConKp pComSh pComKp pe];
            VPEout=[VPEout; VPE];
        end
    end

    function LogLike=Trust_minimization_BayesH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %need to account for the fact that there is no feedback if choose to keep.
        
        %global VPEout
        
        %Free parameters
        beta=xpar(1);
        phi=xpar(2);
        %Set initial values
        meanBetaFri=.5;
        meanBetaCon=.5;
        meanBetaCom=.5;
        varBetaFri=.5;
        varBetaCon=.5;
        varBetaCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        
        %hyperparameters
        aFri=1;bFri=1;
        aCon=1;bCon=1;
        aCom=1;bCom=1;
        
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aFri=aFri+1;
                        elseif wtrial(4)==0
                            bFri=bFri+1;
                        end
                        meanBetaFri=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaFri=aFri*bFri/((aFri+bFri)^2*(aFri+bFri+1));  %consider using this for beta parameter
                        evFri=meanBetaFri*1.5*phi;
                    end
                    pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aCon=aCon+1;
                        elseif wtrial(4)==0
                            bCon=bCon+1;
                        end
                        meanBetaCon=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaCon=aCon*bCon/((aCon+bCon)^2*(aCon+bCon+1));  %consider using this for beta parameter
                        evCon=meanBetaCon*1.5*phi;
                    end
                    pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConKp=exp(1/beta)/(exp(evCon/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aCom=aCom+1;
                        elseif wtrial(4)==0
                            bCom=bCom+1;
                        end
                        meanBetaCom=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaCom=aCom*bCom/((aCom+bCom)^2*(aCom+bCom+1));  %consider using this for beta parameter
                        evCom=meanBetaCom*1.5*phi;
                    end
                    pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComKp=exp(1/beta)/(exp(evCom/beta)+exp(1/beta));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) meanBetaFri meanBetaCon meanBetaCom varBetaFri varBetaCon varBetaCom pFriSh pFriKp pConSh pConKp pComSh pComKp];
            VPEout=[VPEout; VPE];
        end
    end


    function LogLike=Trust_minimization_BayesWtH(xpar, data)
        %data: subno partner decision outcome trial ConTrial preRating FritRating
        %partner:   3=good, 2=Contral, 1=bad, 0=lottery
        %decision: 1=share, 0=keep
        %outcome: 1=gain, 0=loss, 3=keep
        
        %need to account for the fact that there is no feedback if choose to keep.
        
        %global VPEout
        
        %Free parameters
        beta=xpar(1);
        phi=xpar(2);
        %Set initial values
        meanBetaFri=.5;
        meanBetaCon=.5;
        meanBetaCom=.5;
        varBetaFri=.5;
        varBetaCon=.5;
        varBetaCom=.5;
        evFri=.75;
        evCon=.75;
        evCom=.75;
        pFriSh=.5;
        pConSh=.5;
        pComSh=.5;
        pFriKp=.5;
        pConKp=.5;
        pComKp=.5;
        LogLike=0;
        
        %hyperparameters
        aFri=1;bFri=1;
        aCon=1;bCon=1;
        aCom=1;bCom=1;
        
        
        VPEout=[];
        for trialnum=1:length(data)
            wtrial=data(trialnum,:);
            %Update expected probability values
            switch wtrial(2)
                case 3
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aFri=aFri+1;
                        elseif wtrial(4)==0
                            bFri=bFri+1;
                        end
                        meanBetaFri=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaFri=aFri*bFri/((aFri+bFri)^2*(aFri+bFri+1));  %consider using this for beta parameter
                        evFri=meanBetaFri*1.5*phi;
                    end
                    %                     pFriSh=exp(evFri/beta)/(exp(evFri/beta)+exp(1/beta));
                    %                     pFriKp=exp(1/beta)/(exp(evFri/beta)+exp(1/beta));
                    pFriSh=exp(evFri/(beta*varBetaFri))/(exp(evFri/(beta*varBetaFri))+exp(1/(beta*varBetaFri)));
                    pFriKp=exp(1/(beta*varBetaFri))/(exp(evFri/(beta*varBetaFri))+exp(1/(beta*varBetaFri)));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pFriSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pFriKp);
                    end
                case 2
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aCon=aCon+1;
                        elseif wtrial(4)==0
                            bCon=bCon+1;
                        end
                        meanBetaCon=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaCon=aCon*bCon/((aCon+bCon)^2*(aCon+bCon+1));  %consider using this for beta parameter
                        evCon=meanBetaCon*1.5*phi;
                    end
                    %                     pConSh=exp(evCon/beta)/(exp(evCon/beta)+exp(1/beta));
                    %                     pConKp=exp(1/beta)/(exp(evCon/beta)+exp(1/beta));
                    pConSh=exp(evCon/(beta*varBetaCon))/(exp(evCon/(beta*varBetaCon))+exp(1/(beta*varBetaCon)));
                    pConKp=exp(1/(beta*varBetaCon))/(exp(evCon/(beta*varBetaCon))+exp(1/(beta*varBetaCon)));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pConSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pConKp);
                    end
                case 1
                    if wtrial(3)==1
                        if wtrial(4)==1
                            aCom=aCom+1;
                        elseif wtrial(4)==0
                            bCom=bCom+1;
                        end
                        meanBetaCom=aFri/(aFri+bFri); %EV of beta distribution - represents probability
                        varBetaCom=aCom*bCom/((aCom+bCom)^2*(aCom+bCom+1));  %consider using this for beta parameter
                        evCom=meanBetaCom*1.5*phi;
                    end
                    %                     pComSh=exp(evCom/beta)/(exp(evCom/beta)+exp(1/beta));
                    %                     pComKp=exp(1/beta)/(exp(evCom/beta)+exp(1/beta));
                    pComSh=exp(evCom/(beta*varBetaCom))/(exp(evCom/(beta*varBetaCom))+exp(1/(beta*varBetaCom)));
                    pComKp=exp(1/(beta*varBetaCom))/(exp(evCom/(beta*varBetaCom))+exp(1/(beta*varBetaCom)));
                    if wtrial(3)==1
                        LogLike=LogLike-log(pComSh);
                    elseif wtrial(3)==0
                        LogLike=LogLike-log(pComKp);
                    end
            end
            
            VPE=[data(trialnum,:) meanBetaFri meanBetaCon meanBetaCom varBetaFri varBetaCon varBetaCom pFriSh pFriKp pConSh pConKp pComSh pComKp];
            VPEout=[VPEout; VPE];
        end
    end
end %end of main function

