function vrc = CalinskiHarabasz(X, IDX, C, SUMD)
% Calculate Calinski-Harabasz Criterion for evaluating the optimal k for a
% given clusteing solution. Works best with kmean clustering and squared euclidean distance.
% 
% See Calinski, R. B., and Harabasz, J. (1974) A Dendrite Method for Cluster Analysis, Communications in Statistics, 3, 1-27.
%
% vrc = CalinskiHarabasz(X, IDX, C, SUMD)
%
% Inputs:
% ---------------------------------------------------------------------
% X                         : Matrix used for clustering 
%
% IDX                       : Cluster Labels from clustering output
%   
% C                         : Cluster Centroids
%
% SUMD                      : Sum of squared Euclidean distance from
%                             cluster center
%
% Outputs:
% ---------------------------------------------------------------------
% vrc                       : Validity criterion
%
% Examples:
% ---------------------------------------------------------------------
% vrc = CalinskiHarabasz(X, IDX, C, SUMD)
%
% Original version: Copyright Luke Chang 2/2014

%Number of Clusters
clusts = unique(IDX);
NC = length(clusts);
NOBS = size(X,1);
Ni= accumarray(IDX,ones(length(IDX),1));

%Calculate within sum of squares
%SUMD is the sum of squared Euclidean Distance
ssw = sum(SUMD,1);

%Calculate Between sum of squares
ssb = sum(Ni.*(pdist2(C,mean(X))).^2);

vrc = (ssb/ssw) * (NOBS-NC)/(NC-1);
