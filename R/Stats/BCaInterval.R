BCaInterval <- function(bs.samples, theta, jk.theta,conf = .95){
	# Calculate the bias-correction accelerated intervals
	# See Efron (1987). Better Bootstrap Confidence Intervals. JASA, 82(397), 171-185.
	# 
	# bootstraps 	= vector of bootstrapped estimates
	# theta			= estimate
	# jk.theta		= vector of jacknifed thetas
	# conf 			= confidence interval percentile
	#
	# Outputs 		= bias corrected accelerated intervals
	#
	# Written by Luke Chang 3/26/2014


	alpha <- (1 + c(-conf, conf))/2

	z0 <- qnorm(mean(bs.samples < theta))

	a <- sum((theta-jk.theta)^3)/(6*sum((theta-jk.theta)^2)^(3/2))
	q.lb <- pnorm(z0+(z0+qnorm(alpha[1]))/(1-a*(z0+qnorm(alpha[1]))))
	q.ub <- pnorm(z0+(z0+qnorm(alpha[2]))/(1-a*(z0+qnorm(alpha[2]))))
	 
	limits<-c(quantile(bs.samples,q.lb),quantile(bs.samples,q.ub))
	return(limits)
}
