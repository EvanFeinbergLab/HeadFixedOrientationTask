function [y] = Coinflip()
%Difference = Rcorrect - Lcorrect;
%FailThreshold = 0.4500;
%ChanceThreshold = 0.5700;
% x values: 1 = random
%           2 = forced

%if TrialNumber <= 20 % Trials 1-20 can be treated as "adjustment trials"
rand1 = rand;
rand2 = rand;
%x = 1; % random
y = (rand1 + rand2) / 2;
    
% else % After adjustment period, now doing "real" trials
% 
%     if (Rcorrect < FailThreshold) && (Lcorrect < FailThreshold) % Essentially hasn't learned the task yet
%         rand1 = rand;
%         rand2 = rand;
%         x = 1; % random
%         y = (rand1 + rand2) / 2;
%         
%     elseif (Rcorrect >= ChanceThreshold) && (Lcorrect >= ChanceThreshold) % Essentially learned, w/ or w/o bias
% 
%         if abs(Difference) >= BiasThreshold % Bias present
% 
%             if sign(Difference) > 0 % indicates R bias
%                 x = 2; % forced
%                 y = 0; % value in [0, 0.5000) will produce left stimulus
%                 
%             elseif sign(Difference) < 0 % indicates L bias
%                 x = 2; % forced
%                 y = 1; % value in [0.5000, 1] will produce right stimulus
%                 
%             end
%             
%         else % Bias absent
%             rand1 = rand;
%             rand2 = rand;
%             x = 1; % random
%             y = (rand1 + rand2) / 2;
%             
%         end
%         
%      else %if (Rcorrect >= FailThreshold && Rcorrect < ChanceThreshold) || (Lcorrect >= FailThreshold && Lcorrect < ChanceThreshold) % Possibility of chance
%         
%         if abs(Difference) >= BiasThreshold % Bias present
%             
%             if sign(Difference) > 0 % indicates R bias
%                 x = 2; % forced
%                 y = 0; % value in [0, 0.5000) will produce left stimulus
%                 
%             elseif sign(Difference) < 0 % indicates L bias
%                 x = 2; % forced
%                 y = 1; % value in [0.5000, 1] will produce right stimulus
%                 
%             end
%             
%         else % Bias absent but still exists an element of chance, so keep training with random selection
%             rand1 = rand;
%             rand2 = rand;
%             x = 1; % random
%             y = (rand1 + rand2) / 2;
%             
%         end
%         
%     end
%     
end