function [Prob,target] = CalMissileSeeTarget(Prob,target,skip,curT)

Missile = Prob.Missile;
Radar = Prob.Radar;
Target = Prob.Target;
%% 首先对轨迹进行离散化，然后计算每个点是否可见
for i=skip+1:Target.N
    %% 轨迹离散化
    nP = floor(target(i).T/Prob.dT);
    track = inf*ones(nP,2);
    
    for t=curT:nP
        cur_l = (t-curT+1)*Prob.dT*target(i).v;
        cur_pos = target(i).startPOS+cur_l.*[-cos(target(i).angle),-sin(target(i).angle)];
        track(t,:) = cur_pos;
    end
    target(i).track = track;
    
    %% 轨迹与雷达扫描区域的位置关系
    flagRseeT = zeros(nP,Radar.N); % 该位置是否能够被雷达看到
    dist = pdist2(track,Radar.location);
    for j=1:Radar.N
        cur_dist = dist(:,j);
        
        % 计算点到雷达法线方向的夹角
        vec = track-Radar.location(j,:);
        angle = atan2d(vec(:,2),vec(:,1));
        flag = abs(angle-Radar.angle(j)*180/pi)<Radar.Theta(j);
        flag = flag & cur_dist<Radar.R(j,target(i).type);
        flagRseeT(:,j) = flag;
    end
    target(i).flagRseeT = flagRseeT;
    
    %% 轨迹与导弹防空区域的位置关系
    flagMseeT = zeros(nP,Missile.N); % 该位置是否能够被导弹看到
    dist = pdist2(track,Missile.location);
    for j=1:Missile.N
        cur_dist = dist(:,j); % 判断每个位置与导弹半径的位置关系
        flag=zeros(nP,1);
        for c=1:5
            flag=flag+double(cur_dist<Missile.rKill{Missile.type(j),1}(target(i).type,c));
        end
        
        %导弹发射的方向与目标飞行方向的夹角必须小于70°，后续根据实际情况修改
        vec = track-Missile.location(j,:);
        vec1 = [cos(target(i).angle),sin(target(i).angle)];
        for k = 1:size(vec,1)
            angle(k) = acos(dot(vec(k,:),vec1)/(norm(vec(k,:))*norm(vec1)))*180/pi;
            if angle(k) > Missile.Theta
                flag(k)=0;
            end
        end
        
        flagMseeT(:,j) = flag;
    end
    flagMseeT(flagMseeT==5) = 0; % 在最里面也是不可见的状态
    target(i).flagMseeT = flagMseeT;
    
    %% 计算目标被导弹+雷达组合命中的概率
    flagAttack=cell(Missile.N,Radar.N); % 该位置是否能够被导弹+雷达的组合看到
    flagAtkS = zeros(Missile.N,Radar.N);% 该路线是否能够被导弹+雷达的组合看到，简化
    pKill = cell(Missile.N,Radar.N); % 该位置导弹+雷达的组合毁伤的概率和导弹的发射时间
    
    for j=1:Missile.N
        for k=1:Radar.N
            tmp_flag = target(i).flagMseeT(:,j).*target(i).flagRseeT(:,k);
            tmp_p = tmp_flag; %计算命中的概率
            for l=1:4
                tmp_p(tmp_p==l) = Missile.pKill{Missile.type(j),1}(target(i).type,l+1);
            end
            % 按照文档给定的公式计算命中概率
            cur_dist = dist(:,j);
            radar_accuracy = Radar.accuracy(Radar.type(k)) .* ones(nP,1);
            computing_accuracy = radar_accuracy;
            ind = cur_dist<=10;
            computing_accuracy(ind) = radar_accuracy(ind) - 2;
            ind = cur_dist>10 & cur_dist<=20;
            computing_accuracy(ind) = radar_accuracy(ind) - 1;
            ind = cur_dist>20 & cur_dist<=30;
            computing_accuracy(ind) = radar_accuracy(ind);
            ind = cur_dist>30;
            computing_accuracy(ind) = radar_accuracy(ind) + abs(cur_dist(ind)-100)/30;
            P = min(tmp_p .* radar_accuracy./computing_accuracy, 0.8);
            P(tmp_p==0) = 0;
            
            % 计算导弹发射时间
            ind = find(tmp_p~=0);
            cur_dist = dist(ind,j);
            cur_t = 1:nP; cur_t=cur_t' * Prob.dT;% 当前位置目标的飞行时间
            fly_t = zeros(nP,1); % 导弹需要的飞行时间
            fly_t(ind) = cur_dist ./ Missile.v(Missile.type(j));
            launch_t = cur_t - fly_t;
            
            ind = false(size(P)); % 判断当前目标的前preT时间段内，雷达是否能跟踪。
            for tp = Prob.preNT+1:length(P)
                if any(P(tp-Prob.preNT:tp) == 0)
                    ind(tp) = true;
                end
            end
            ind(1:Prob.preNT) = true;
            
            ind = ind | launch_t<0;
            P(ind) = 0;
            launch_t(ind) = 0;
            tmp_flag(ind) = 0;
            % 按照毁伤概率和预计发射时间排序
            tmp_data = [P launch_t cur_t fly_t];
            pKill{j,k} = sortrows(tmp_data,[1 2],{'descend','ascend'}); % 按照命中概率和导弹的发射时间进行排序
            flagAttack{j,k} = tmp_flag;
            flagAtkS(j,k) = max(P);
        end
    end
    target(i).flagAttack = flagAttack;
    target(i).pKill = pKill;
    target(i).flagAtkS = flagAtkS;
    
    %% 计算可选组合和概率集合
    [missiles,radars] = find(target(i).flagAtkS>0);
    n = length(missiles);
    p = zeros(n,1);
    for j=1:n
        p(j) = target(i).flagAtkS(missiles(j),radars(j));
    end
    target(i).combination = [missiles,radars,p];
end

%% 按照目标的飞行时间进行排序
flyT = [target.T];
[~,Prob.targetInd] = sort(flyT,'ascend');

Prob.target = target;
Prob.abandon = []; % 表示该目标无法被击毁
for i=1:length(target)
    if all(all(target(i).flagAtkS==0))
        Prob.abandon = [Prob.abandon i];
    end
end
