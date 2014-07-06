    function varargout = SoftMax(vChoice,beta)
        
        % pChoice = SoftMax(vChoice,beta)
        %
        % Calculate probability of selecting each choice given beta
        %
        % INPUTS:
        % vChoice       Vector of Values of each possible Choice
        % beta          Temperature parameter of softmax (close to 0 means
        %               exploit closer to 1 means explore
        %
        % OUTPUTS:
        % varargout     Separate output for probability of selecting each choice
        %
        % EXAMPLES:
        % [p1,p2,p3] = SoftMax([2,1,.1], .9);
        %
        % Written by Luke Chang 7/2014
        
        nChoice = length(vChoice);
        
        % Calculate Regularization
        for i = 1:nChoice
            reg(i) = exp(vChoice(i)/beta);
        end
        reg = sum(reg);
        
        % Calculate probability of selecting each choice given beta
        for i = 1:nChoice
            varargout{i} = exp(vChoice(i)/beta)/reg;
        end
    end