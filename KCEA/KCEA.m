%% 改进型GA
trace = [];
curPopSize = PopSize;
FE = PopSize;
gen = 1;
while FE < MaxFEs
    MatingPool = TournamentSelection(2,curPopSize,[Population.objs]);
    Offspring  = Operator(Population(MatingPool),Prob);
    FE = FE + curPopSize;
    Population = EnvironmentalSelection(Population,Offspring,curPopSize);
    
    [BestObj,ind] = max([Population.objs]);
    BestSol = Population(ind);
    trace = [trace BestObj];
    gen = gen + 1;
    if ~mod(FE,20) %显示优化过程信息
        fprintf('迭代次数:%3d 当前最优值:%.2f \n',gen,BestObj)
    end
end