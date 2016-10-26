function LL = LogLikelihoodNormal(y,x,beta,sigma)

    n = length(y);
    ssr = sum((y - (x * beta')).^2);
    LL = n * log(sigma) - n * log(sqrt(2 * pi)) - (ssr)/(2 * sigma^2);
end

