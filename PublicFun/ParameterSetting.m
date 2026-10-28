Prob.nRadarType = 6; %雷达类型数量
Prob.nTargetType = 3; %目标类型数量：1，2，3
Prob.nMissileType = 6; %导弹型号数量

%% 用于设置雷达、发射车、导弹和目标的参数
shift_Radar = zeros(Prob.nRadarType,2);
shift_Radar_angle = zeros(Prob.nRadarType,1);
shift_Launch = zeros(Prob.nMissileType,2); %-- 位置偏移参数 --

%% 雷达参数
% 基础参数
Radar = [];
Radar.R = [64,90,36;
    32,45,18;
    32,45,18;
    32,45,18;
    32,45,18;
    32,45,18];  % 雷达类型i针对目标类型j的探测威力
Radar.accuracy = [3,3,3,3,3,3]; %雷达初始的精度参数,本项目认为该参数与观测目标的距离有关
Radar.nChannel = 10.*[1,1,1,1,1,1]; %雷达的跟踪通道数（一个雷达同一时刻只能跟一个目标）
Radar.coefficient = ones(Prob.nRadarType,Prob.nTargetType); %对于不同雷达而言，不同目标所占通道数不同，此处设为1
Radar.Theta = [70,70,70,70,70,70]; %雷达的探测角度，只能探测一个扇形区域，70代表能探测法线±70°以内的区域
radarR_coef = ones(Prob.nRadarType,1); %雷达的远界缩放
for i=1:Prob.nRadarType
    Radar.R(i,:) = Radar.R(i,:)*radarR_coef(i);
end

% 部署参数
Radar.N = 6; % 雷达数量
Radar.type = [1,2,2,2,2,2]; 
Radar.location = [-5,0;5,0;-5,10;5,10;-5,20;5,20] + shift_Radar; 
Radar.angle = [3*pi/5;2*pi/5;pi/2;pi/2;2*pi/3;pi/3] + shift_Radar_angle; 

%% 导弹参数
Missile = [];
Missile.rKill = cell(Prob.nRadarType,Prob.nMissileType);
Missile.rKill{1,1} = [1,3,11,17,21;
    1,3,17,22,25;
    1,3,11,12,18]; %1型导弹在第1种雷达制导下，对3类目标的低概率拦截近界、高概率拦截近界、低概率拦截远界、高概率拦截远界
Missile.pKill{1,1} = [0,0.3,0.5,0.4,0.2,0;
    0,0.4,0.6,0.3,0.3,0;
    0,0.5,0.7,0.2,0.1,0]; %1型导弹在第1种雷达制导下，对3类目标的拦截概率
for i=1:Prob.nRadarType
    for j=1:Prob.nMissileType
        Missile.rKill{i,j} = Missile.rKill{1,1};
        Missile.pKill{i,j} = Missile.pKill{1,1};
    end
end
launch_coef = ones(Prob.nMissileType,1); %发射车的远界缩放
Missile.cost = zeros(Prob.nMissileType,1); %导弹的费用
Missile.v = [0.5,0.5,0.5,0.5,0.5,0.5]; %导弹的平均速度
Missile.launchProbability = [0.8,0.8,0.8,0.8,0.8,0.8]; %初始概率（真正计算不用）
Missile.R = 80; % 布控扇形区域的半径   仅用于画图描点用
Missile.Theta = 70;  % 导弹发射的方向与目标飞行方向的夹角必须小于70°，后续根据实际情况修改

% 部署参数
Missile.N = 6; % 发射车数量
Missile.type = [1,2,3,4,5,6];  % 导弹类型
Missile.location = [-5,0;5,0;-5,10;5,10;-5,20;5,20] + shift_Launch; % 发射车位置矩阵
Missile.accuracy = [1,2,3,2,3,1]; % 发射车对应的雷达精度
Missile.loadLimit = 15*[1,1,1,1,1,1];

%% 目标参数
Target = [];
Target.v = [0.2,0.1,0.05]; %三种目标的飞行速度
Target.cost = [20,10,1]; %三种目标的价值

% 部署参数
load(Prob.scenarioFile)
Target.startPOS = Info_enemy.enemy_start; % 目标初始位置
Target.type = Info_enemy.enemy_type; % 目标类型
Target.angle = Info_enemy.enemy_angle; % 目标角度
Target.N = length(Target.startPOS); % 目标数量


Target.x0 = zeros(1,Target.N); % 目标与x轴相交点的坐标
Target.length = zeros(1,Target.N); % 目标飞行到x轴的距离
for i=1:Target.N
    Target.length(i) = Target.startPOS(i,2)/sin(Target.angle(i));
    Target.x0(i) = Target.startPOS(i,1)-Target.length(i)*cos(Target.angle(i));
end

empty_target = [];
target = repmat(empty_target,Missile.N,1);
for i=1:Target.N
    target(i).type = Target.type(i);
    target(i).startPOS = Target.startPOS(i,:);
    target(i).angle = Target.angle(i);
    target(i).length = Target.length(i);
    target(i).v = Target.v(target(i).type);
    target(i).cost = Target.cost(target(i).type);
    target(i).T = ceil(target(i).length/target(i).v);
end

%% 总体参数设置
Target.MaxMissiles = 3; % 朝每个目标发射导弹数量的最大值
Prob.preT = 15; % 在目标被击中前，需要连续跟踪的时长，单位：秒
Prob.preNT = ceil(Prob.preT/Prob.dT); % 在目标被击中前，需要连续跟踪的时段

if Prob.modeFire == 1
    Prob.deltaT1Lower = 0; % 要求相邻两枚导弹的t_end相差不大于要求相邻两枚导弹的t_end相差[0,5]
    Prob.deltaT1Upper = 5;
else
    Prob.deltaT1Lower = 10; % 要求相邻两枚导弹的t_end相差不大于要求相邻两枚导弹的t_end相差[10,15]
    Prob.deltaT1Upper = 15;
end
Prob.deltaT2 = 10; 
Prob.deltaT3 = 15; % 要求相邻两枚导弹的t_end_(j-1)和t_start_j的间隔在[Δt2, Δt3]范围内；
if Prob.flagAllowMultiMissile == 0
    Target.MaxMissiles = 1;
end

maxT = max([target.T]); % 所有目标的最大飞行时间
Prob.nS = floor(maxT/Prob.dT); % 阶段数

%% 封装数据
Prob.nRadar = Radar.N;
Prob.nMissile = Missile.N;
Prob.nTarget = Target.N;
Prob.Missile = Missile;
Prob.Target = Target;
Prob.Radar = Radar;

clearvars -except Prob Missile Target Radar target