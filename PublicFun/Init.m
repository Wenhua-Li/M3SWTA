function Population = Init(PopSize,Prob)
empty_pop = [];
empty_pop.decs = []; %决策向量：对应的导弹发射车编号
empty_pop.objs = []; %目标函数值
empty_pop.cons = []; %违反约束程度
empty_pop.kdg = [];  %知识提取
Population = repmat(empty_pop,PopSize,1);
target = Prob.target;

for i=1:PopSize
    decs = cell(1,Prob.Target.MaxMissiles);
    for nM = 1:Prob.Target.MaxMissiles
        inner_decs = zeros(Prob.nTarget,2);
        for j=1:Prob.nTarget
            if ~ismember(j,Prob.abandon)
                pick = TournamentSelection(2,1,target(j).combination(:,3));
                inner_decs(j,:) = target(j).combination(pick,1:2);
            end
        end
        decs{nM} = inner_decs;
    end
    Population(i).decs = decs;
end

Population = CalObj(Population,Prob);