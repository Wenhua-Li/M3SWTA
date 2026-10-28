function [Population] = EnvironmentalSelection(Population,Offspring,N)
%%
pObjs = [Population.objs];
oObjs = [Offspring.objs];
replace1 = pObjs <= oObjs;
Population(replace1) = Offspring(replace1);

%% 基于种群多样性的环境选择，线性递减
diversity_result = calculate_diversity(Population);
pObjs = [Population.objs]';
% 采用竞争选择策略挑选后代
while length(Population)>N
    pick = randperm(length(Population),1);
    % 找到最相似个体
    [~,pick2] = min(diversity_result(pick,:));
    if pObjs(pick) > pObjs(pick2)
        Population(pick2) = [];
    else
        Population(pick) = [];
    end
end

% 常规选择策略
% [~,ind] = sortrows([pObjs diversity_result'],'descend');
% Population = Population(ind(1:N));
end