function T=tanimoto(A,B)

% Computes tanimoto's coefficient of similarity, which is basically a generalized version of jaccards index for continuous and binary data.  
% Requires two vectors A & B

T=dot(A,B)/(norm(A)^2+norm(B)^2-dot(A,B));
