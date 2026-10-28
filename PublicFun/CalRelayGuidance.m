function BestSol = CalRelayGuidance(Prob,BestSol)

%% 数据提取
Missile = Prob.Missile;
Radar = Prob.Radar;
Target = Prob.Target;
target = Prob.target;

% 基本思路：依据导弹的飞行时间排序，依次往前填充，如果实在不行，就记录下来
usedChannelAll = BestSol.usedChannel; % 每个雷达每个阶段已经使用的通道数
targetInfo = BestSol.targetInfo;

%% 接力制导计算
for i = 1:length(targetInfo)
    cur_target = targetInfo(i).target;
    cur_missile = targetInfo(i).missile;
    if targetInfo(i).round > 1 % 后续发射任务，不需要考虑接力制导
        continue
        
    else
        tLaunch = targetInfo(i).tLaunch;
        tStartTrack = targetInfo(i).tStartTrack;
        if tStartTrack > tLaunch % 跟踪时长不够，需要接力制导
            cur_radar = targetInfo(i).radar;
            tStartInd = max(1,floor(tLaunch / Prob.dT));
            
            tEndInd = floor(tStartTrack/Prob.dT);
            
            
            radarInd = [cur_radar randperm(Radar.N,Radar.N)]; %优先选当前雷达
            
            flag = 0;
            for iR2 = 1:length(radarInd)
                
                radar2 = radarInd(iR2);
                tmpusedC = usedChannelAll{radar2};
                needChannel = Radar.coefficient(Radar.type(radar2),target(cur_target).type);
                tmpusedC(cur_target,tStartInd:tEndInd) = needChannel;
                
                if any(sum(tmpusedC) > Radar.nChannel(Radar.type(cur_radar)))
                    continue
                else
                    flag = 1;
                    targetInfo(i).radar0 = radar2;
                    usedChannelAll{radar2} = tmpusedC;
                    break;
                end
            end
            if ~flag
                fprintf('目标%d无法接力制导；\n',cur_missile)
            end
        else
            fprintf('目标%d无需接力制导；\n',cur_target)
        end
    end
end
BestSol.targetInfo = targetInfo;
% PlotSol(Prob,BestSol);