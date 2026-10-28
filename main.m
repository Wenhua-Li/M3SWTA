clc;clear;
close all
warning off
addpath(genpath(pwd));
%% 总体参数设置
Prob = [];
Prob.scenarioFile = '.\Scenario\Info_enemy_1.mat';
Prob.dT = 0.8; % 离散化时间粒度，单位：秒
Prob.sT = 0; % 当前时刻为0，滚动插入时需要考虑
Prob.flagAllowMultiMissile = 1; % 是否允许多发导弹
Prob.modeFire = 2; % 1表示集火攻击模式；2表示分火攻击模式。只在flagAllowMultiMissile = 1生效

%% 问题参数载入
ParameterSetting();

%% 目标航行轨迹状态计算
timer = tic;
[Prob,target] = CalMissileSeeTarget(Prob,target,0,Prob.sT+1);
fprintf('初始化计算用时：%.2f秒\n',toc(timer))

% return
%% 优化开始
% 算法参数设置
PopSize = 2*Target.N;
MaxFEs = 100*Target.N;
timer = tic;

%% 调用求解器
Population = Init(PopSize,Prob);
KCEA(); % 改进型遗传算法
timer = toc(timer);

%% 优化结束
fprintf('用时：%3.2f秒 最优值：%.2f\n',timer,BestObj)
plot(trace,'r-','linewidth',2)
xlabel('迭代次数');ylabel('总命中概率')
grid on;box on;

%% 接力制导填充
BestSol = CalRelayGuidance(Prob,BestSol);

%% 展示最优结果
PlotSol(Prob,BestSol);