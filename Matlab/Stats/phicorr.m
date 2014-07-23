function phi=phicorr(x,y)
%%phicorr = calculate phi correlation coefficient for two dichotomous variables
%%Seems to produce identicial results to using 'corr'function
%%if results are perfectly correlated output '0' rather than nan.  This
%%assumes that there won't be a perfect correlation unless there only
%%zeros
%%can also be derived from chi2; function=chi2tophi; phi=sqrt(chi2/N);
%%written by Luke Chang University of Arizona 1/22/11

n11=length(find(x==1&y==1));
n10=length(find(x==1&y==0));
n01=length(find(x==0&y==1));
n00=length(find(x==0&y==0));
r1=n11+n10;
r2=n01+n00;
r3=n11+n01;
r4=n10+n00;
phi=((n11*n00)-(n10*n01))/sqrt(r1*r2*r3*r4);
if isnan(phi)==1
    phi=0;
end

% %Simulate data
% n = 50;
% Z = mvnrnd([0 0], [1 .8; .8 1], n);
% U = normcdf(Z,0,1);
% d=U>.5; %dichotomize