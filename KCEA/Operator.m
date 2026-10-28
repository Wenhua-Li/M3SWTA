function Offspring = Operator(Population,Prob)

%% 数据提取
target = Prob.target;
N = length(Population);
nTarget = length(target);
Offspring = Population;
for i=1:N
    P1 = Population(i).decs;
    P2 = Population(randperm(N,1)).decs;
    kdg = Population(i).kdg; % 提取知识
    %% 交叉
    % 统计冲突次数并计算选择概率
    tmp_count = histcounts(kdg(:, 2), 1:nTarget+1)'; % 统计每个数出现的次数
    c = (tmp_count+1)./(sum(1+tmp_count));

    if rand<0.5
        ind = find(rand(nTarget,1)<0.5);
    else
        ind = randsample(nTarget, 4, true, c);
    end
    for j=1:numel(ind)
        cur_pos = ind(j);
        for nM = 1:Prob.Target.MaxMissiles % 全部导弹的位置同时更换
            if rand<1/Prob.Target.MaxMissiles
                P1{nM}(cur_pos,:) = P2{nM}(cur_pos,:);
            end
        end
    end

    %% 变异：单点变异，融合知识的变异
    ind = find(rand(nTarget,1)<0.1);
    for j=1:numel(ind)
        cur_pos = ind(j);
        if any(Prob.abandon==cur_pos)
            continue
        end
        candidates = target(cur_pos).combination;

        if size(kdg,2) > 0 && rand < 0.5
            turn = randperm(size(kdg,2),1);
            pick = kdg(turn,1);
            pick2 = TournamentSelection(ceil(length(candidates)/4),1,candidates(:,3));
            P1{pick}(cur_pos,:) = candidates(pick2,1:2);
        else
            % 随机变异
            pick = randperm(size(candidates,1),1); % 随机挑选一个组合。
            P1{randperm(Prob.Target.MaxMissiles,1)}(cur_pos,:) = candidates(pick,1:2);
        end
    end

    Offspring(i).decs = P1;
end
Offspring = CalObj(Offspring,Prob);