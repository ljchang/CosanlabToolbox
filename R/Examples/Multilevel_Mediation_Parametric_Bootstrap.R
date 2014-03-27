# Run multilevel mediation with parametric bootstrapping using both percentile and bias corrected accelerated methods
#
# .:Suggested by Jake Westfall:.
#
# Basically you loop through N iterations (N being number of bootstrap samples) and each time you 
# (1) sample dependent variable from model using simulate() 
# (2) regress X on Y with multilevel model, save X slope, 
# (3) fit same multilevel model controlling for M, save new X slope, 
# (4) return difference in slopes. 
# (5) return the product of path a and b in slopes. 
#
# Then you have a bootstrap distribution of the estimates of the change in X slopes (c - c' or ab, in traditional mediation terminology) 
# against which you can compare your actual estimated of the change in X slopes. 
# This is basically all the packages are doing, but with added bells and whistles.
# 
# Calculate percentile and bias corrected accelerated confidence intervals
#
# See:
# http://davidakenny.net/cm/mediate.htm
# See Efron (1987). Better Bootstrap Confidence Intervals. JASA, 82(397), 171-185.
#
# Written by Luke Chang 3/26/2014

library(lme4)

#Load Data
fPath<-'/Users/lukechang/Research/Trust_Friend/Modeling/FinalPaperModels/'
dat<-read.table(paste(fPath,'data_lme_TSN.csv',sep=""),sep = ',', header=T,na.strings=999999)

#Run Multilevel Models
model.a<-lmer(Closeness ~ Nacc + (1|Subject), data=dat)
model.b<-lmer(Bonus ~ Closeness + (1|Subject), data=dat)
model.y<-lmer(Bonus ~ Nacc + (1|Subject), data=dat)
model.m<-lmer(Bonus ~ Nacc + Closeness + (1|Subject), data=dat)

#Concatenate Path estimates
a<-fixef(model.a)[2]
b<-fixef(model.b)[2]
c<-fixef(model.y)[2]
cprime <-fixef(model.m)[2]
m<-fixef(model.m)[3]
c_cprime<-c-cprime
ab <-a*b
theta<-c(a,b,c,cprime,m,c_cprime,ab)


#Bootstrap estimates
nBoot<-5000
bout<-matrix(nrow = nBoot,ncol = 7)
for(i in 1:nBoot){
	bout[i,1]<-fixef(refit(model.a, simulate(model.a, nsim = 1 , seed = NULL)))[2]
	bout[i,2]<-fixef(refit(model.b, simulate(model.b, nsim = 1 , seed = NULL)))[2]
	bout[i,3]<-fixef(refit(model.y, simulate(model.y, nsim = 1 , seed = NULL)))[2]
	bout[i,4:5]<-fixef(refit(model.m, simulate(model.m, nsim = 1 , seed = NULL)))[2:3]
}
bout[,6]<-bout[,3]-bout[,4]
bout[,7]<-bout[,1]*bout[,2]
bout<-data.frame(bout)
colnames(bout)<-c('a','b','c','cprime','m','c_cprime','ab')
write.table(bout, file = paste(fPath,"Bootstrapped_Estimates.csv",sep=""), sep = ",", row.names = FALSE,col.names = TRUE)

#Calculate Percentile Intervals
probs <- c(0.025, 0.975)
bootci<-data.frame(rbind(quantile(bout$a, probs = probs),
	quantile(bout$b, probs = probs),
	quantile(bout$c, probs = probs),
	quantile(bout$cprime, probs = probs),
	quantile(bout$m, probs = probs),
	quantile(bout$c_cprime, probs = probs),
	quantile(bout$ab, probs = probs)))
bootci$Path<-c('a','b','c','cprime','m','c_cprime','ab')
colnames(bootci)<-c('LBound','UBound','Path')
write.table(bootci, file = paste(fPath,"Percentile_Intervals.csv",sep=""), sep = ",", row.names = FALSE,col.names = TRUE)

#Jacknife each estimate
SubNum<-unique(dat$Subject)
jkout<-matrix(nrow = length(SubNum),ncol = 7)
for(i in 1:length(SubNum)){
	jk.dat<-dat[dat$Subject!=SubNum[i],]
	jkout[i,1]<-fixef(lmer(Closeness ~ Nacc + (1|Subject), data=jk.dat))[2]
	jkout[i,2]<-fixef(lmer(Bonus ~ Closeness + (1|Subject), data=jk.dat))[2]
	jkout[i,3]<-fixef(lmer(Bonus ~ Nacc + (1|Subject), data=jk.dat))[2]
	jkout[i,4:5]<-fixef(lmer(Bonus ~ Nacc + Closeness + (1|Subject), data=jk.dat))[2:3]
	jkout[i,6]<-jkout[i,3]-jkout[i,4]
	jkout[i,7]<-jkout[i,1]*jkout[i,2]
}
jk.theta<-data.frame(jkout)
colnames(jk.theta)<-c('a','b','c','cprime','m','c_cprime','ab')

#calculate BCa Intervals
source(paste(fPath,"Scripts/BCaInterval.R",sep=""))
ci<-matrix(nrow=7,ncol=2)
for(i in 1:7){
	ci[i,1:2]<-BCaInterval(bout[,i],theta[i],jk.theta[,i])
}
ci<-data.frame(ci)
ci$Path<-c('a','b','c','cprime','m','c_cprime','ab')
colnames(ci)<-c('LBound','UBound','Path')
write.table(ci, file = paste(fPath,"BCa_Intervals.csv",sep=""), sep = ",", row.names = FALSE,col.names = TRUE)
