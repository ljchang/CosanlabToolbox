function [F, p] = nestedModelComparison(sseFull,nFeaturesFull, sseNested,nFeaturesNested, nObservations)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % F = nestedModelComparison(sseFull,nFeaturesFull, sseNested,nFeaturesNested, nObservations)
    % 
    % This Function performs an F-test on nested model comparisons.
    %
    % INPUTS:
    % sseFull:          Sum of Squared Error for Full Model
    % sseNested:        Sum of Squared Error for Nested Model
    % nFeaturesFull:    Number of features in Full Model
    % nFeaturesNested:  Number of features in Nested Model
    % nObservations:    Number of observations
    %
    % OUTPUTS:
    % F:                F statistic
    % p:                pValue
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    g = (nFeaturesFull - nFeaturesNested);
    d = nObservations - nFeaturesFull - 1;
    F = ((sseNested - sseFull)/g)/(sseFull/d);
    p = fpdf(F,g,d);

end