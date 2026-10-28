function Population = CalObj(Population,Prob)

%% 数据提取
Missile = Prob.Missile;
Radar = Prob.Radar;
Target = Prob.Target;
target = Prob.target;
N = length(Population);

%% 结构体构建
targetInfoStruct = [];
targetInfoStruct.target = [];
targetInfoStruct.round = [];
targetInfoStruct.missile = [];
targetInfoStruct.radar = [];
targetInfoStruct.tLaunch = [];
targetInfoStruct.tKill = [];
targetInfoStruct.tStartTrack = [];
targetInfoStruct.pKill = [];

missileInfoStruct = [];
missileInfoStruct.target = zeros(Target.N,Target.MaxMissiles);
missileInfoStruct = repmat(missileInfoStruct,Prob.nMissile,1);

initChannelStruct = cell(Prob.nRadar,2);
for i = 1:Prob.nRadar
    initChannelStruct{i} = zeros(Target.N,Prob.nS);% 每个雷达每个阶段每个目标使用通道数
end

% flyTime = cat(2,target.T);
% targetCost = cat(2,target.cost);

%% 开始评估个体目标值
for iP=1:N
    %% 计算量定义
    objs = 0;
    cons = 0;
    details = '';
    targetPkill = zeros(Target.N,Target.MaxMissiles+1);
    usedChannelAll = initChannelStruct;
    failTarget = false(Target.N,Target.MaxMissiles); % 目标是否无法拦截价值
    
    %% 数据初始化
    targetInfo = targetInfoStruct;
    missileInfo = missileInfoStruct;
    kdg = []; % 知识提取初始化
    task_count = 0;
    whichtask = zeros(Target.N,Target.MaxMissiles);
    
    %% 外层基本思路：先对每个目标分配一个导弹，然后依次增加导弹数量，直到不能增加为止
    for nM = 1:Target.MaxMissiles
        missiles = Population(iP).decs{nM}(:,1);
        radars = Population(iP).decs{nM}(:,2);
        
        for iT = 1:Target.N
            cur_target = Prob.targetInd(iT);
            cur_missile = missiles(cur_target);
            cur_radar = radars(cur_target);
            
            if failTarget(cur_target,nM) % 如果当前不可发射，则直接取消
                %kdg = [nM,0,] 不用处理知识
                continue
            end
            
            %% 首先检查当前发射车是否还有剩余导弹
            if sum(sum(missileInfo(cur_missile).target)) >= Missile.loadLimit(Missile.type(cur_missile))
%                 fprintf('导弹%d数量不足，目标%2d第%d次发射取消\n',cur_missile,cur_target,nM)
                failTarget(cur_target,nM:end) = true;
                continue
            else
                ind_pick_time = 1;
                if nM > 1 % 当前的导弹发射为第2发或第3发，需要考虑前后两发的时间窗口
                    lastTask = whichtask(cur_target,nM-1);
                    lastTkill = targetInfo(lastTask).tKill;
                    tKill = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,3);
                    deltaT = tKill - lastTkill;
                    flagThisTargetSuccess = (deltaT >= Prob.deltaT1Lower && deltaT <= Prob.deltaT1Upper);
                    
                    if ~flagThisTargetSuccess
                        tmpT = target(cur_target).pKill{cur_missile,cur_radar}(:,3) - lastTkill;
                        tmpPKill = target(cur_target).pKill{cur_missile,cur_radar}...
                            ((tmpT >= Prob.deltaT1Lower & tmpT <= Prob.deltaT1Upper),:);
                        for tmpInd = 1:length(tmpPKill)
                            
                        end
                    end
                    
                    while ~flagThisTargetSuccess
                        % 不满足时间要求，尝试调整发射时间
                        % 优先调整后一发的发射时间：遍历可行的命中时刻，看是否有窗口
                        ind_pick_time = ind_pick_time + 1;
                        % 耗时较久，先搜索确定可行时间段，再进行挑选
                        if target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,1) == 0 ...
                                || ind_pick_time > target(cur_target).T
                            kdg = [kdg;[nM,iT]];
                            break
                        end
                        tKill = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,3);
                        deltaT = tKill - lastTkill;
                        flagThisTargetSuccess = (deltaT >= Prob.deltaT1Lower && deltaT <= Prob.deltaT1Upper);
                    end
                    
                    if deltaT < Prob.preT % 相邻两发导弹的命中时刻小于3timep，那么引导雷达应该为同一个
                        lastRadar = targetInfo(lastTask).radar;
                        if lastRadar~=cur_radar
                            kdg = [kdg;[nM,iT]];
                            flagThisTargetSuccess = 0;
                        end
                    end
                    
                    if ~flagThisTargetSuccess
%                         fprintf('目标%2d第%d次发射时间窗口不行，取消\n',cur_target,nM)
                        failTarget(cur_target,nM:end) = true;
                        kdg = [kdg;[nM,iT]];
                        continue
                    end
                end

                %% 检查雷达的通道约束是否满足
                tKill = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,3);
                tEndInd = round(tKill/Prob.dT); tStartInd = round((tKill - Prob.preT)/Prob.dT);
                tmpusedChannel = usedChannelAll{cur_radar,1};
                needChannel = Radar.coefficient(Radar.type(cur_radar),target(cur_target).type);
                tmpusedChannel(cur_target,tStartInd:tEndInd) = needChannel;
                flagThisTargetFail = any(sum(tmpusedChannel(:,tStartInd:tEndInd)) ...
                    > Radar.nChannel(Radar.type(cur_radar)));
                if flagThisTargetFail % 雷达通道有冲突
                    if nM == 1
                        % 首次发射，可以自由调整时间
                        while flagThisTargetFail
                            % 同一时间总通道数超出上限
                            % 基本思路：发生冲突后，将当前的跟踪往后面挪一下，如果确实没办法挪，那就显示该目标无法被击毁
                            ind_pick_time = ind_pick_time+1;
                            if target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,1) == 0
                                break
                            end
                            tmpusedChannel = usedChannelAll{cur_radar,1};
                            tmpusedChannel(cur_target,tStartInd:tEndInd) = needChannel;
                            flagThisTargetFail = any(sum(tmpusedChannel(:,tStartInd:tEndInd)) ...
                                > Radar.nChannel(Radar.type(cur_radar)));
                        end
                    end
                    if flagThisTargetFail
%                         fprintf('目标%2d第%d次发射雷达通道不足，取消\n',cur_target,nM)
                        failTarget(cur_target,nM:end) = true;
                        continue
                    end
                end
                
                pKill = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,1);
                tLaunch = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,2);
                tKill = target(cur_target).pKill{cur_missile,cur_radar}(ind_pick_time,3);
                
                % 记录数据
                task_count = task_count+1;
                whichtask(cur_target,nM) = task_count;
                targetInfo(task_count).target = cur_target;
                targetInfo(task_count).round = nM;
                targetInfo(task_count).missile = cur_missile;
                targetInfo(task_count).radar = cur_radar;
                targetInfo(task_count).tLaunch = tLaunch;
                targetInfo(task_count).tKill = tKill;
                targetInfo(task_count).tStartTrack = tKill - Prob.preT;
                targetInfo(task_count).pKill = pKill;
                targetPkill(cur_target,nM) = pKill;
                missileInfo(cur_missile).target(cur_target,nM) = 1;
                usedChannelAll{cur_radar,1} = tmpusedChannel;
                usedChannelAll{cur_radar,2} = sum(usedChannelAll{cur_radar,1});
            end
            
        end
    end
    
    %% 计算目标值
    tmp_p = 1;
    for nM = 1:Target.MaxMissiles
        tmp_p = tmp_p.*(1-targetPkill(:,nM));
    end
    objs = sum(1-tmp_p);
    targetPkill(:,end) = 1-tmp_p;
    
    %% 封装数据
    Population(iP).objs = objs;
    Population(iP).cons = cons;
    Population(iP).kdg = kdg;
    Population(iP).details = details;
    Population(iP).targetInfo = targetInfo;
    Population(iP).targetKill = targetPkill;
    Population(iP).failTarget = failTarget;
    Population(iP).usedChannel = usedChannelAll;
end