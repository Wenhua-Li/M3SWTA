function PlotSol(Prob,BestSol)
% close all
%% 数据提取
Missile = Prob.Missile; 
Radar = Prob.Radar;
Target = Prob.Target;
target = Prob.target;
targetInfo = BestSol.targetInfo;
cRadar = colormap('lines');
cTarget={'r','g','m'};
mMissile = {'o','s','^','v','>','<'};

% %% 输出最优方案
% for i=1:length(BestSol.targetInfo)
%     ctarget = targetInfo(i).target;
%     missile = targetInfo(i).missile;
%     radar = targetInfo(i).radar;
%     times = targetInfo(i).round;
% 
%     tStartTrack0 = targetInfo(i).tLaunch;
%     tStartTrack = targetInfo(i).tStartTrack;
%     tKill = targetInfo(i).tKill;
%     tLaunch = targetInfo(i).tLaunch;
%     radar0 = targetInfo(i).radar0;
%     if isempty(radar0)
%         fprintf('目标%2d第%d次拦截：发射车%d-雷达%d 发射时间：%4.2f 跟踪时间：%4.2f-%4.2f\n',...
%             ctarget,times,missile,radar,tLaunch,tStartTrack,tKill)
%     else
%         fprintf('目标%2d第%d次拦截：发射车%d-雷达%d-雷达%d 发射时间：%4.2f 跟踪时间：%4.2f-%4.2f-%4.2f\n',...
%             ctarget,times,missile,radar0,radar,tLaunch,tStartTrack0,tStartTrack,tKill)
%     end
% end
%% 雷达跟踪甘特图
% set(gcf,'position',[200,40,800,800]);
figure
cc=1;
radar_count = ones(Radar.N,Prob.nS);
for i=1:length(targetInfo)
    cur_target = targetInfo(i).target;
    cur_radar = targetInfo(i).radar;
    cur_missile = targetInfo(i).missile;
    subplot(Radar.N,1,cur_radar)
    hold on
    st = targetInfo(i).tStartTrack;
    et = targetInfo(i).tKill;
        y = max(radar_count(cur_radar,st/Prob.dT:et/Prob.dT));    
    rectangle('Position',[st,y-0.1,et-st,0.2],...
    'EdgeColor','none','FaceColor',cRadar(mod(cc,11)+1,:),'Curvature',[1 0.1])
text(st+(et-st)/2-2,y+0.2,['$T_{' num2str(cur_target),'}$'],'color','k','Fontsize',10,'Fontname','Helvetica','interpreter','latex');
%     line([st,et],[radar_count(cur_radar),radar_count(cur_radar)],'linewidth',2,'color',cRadar(cur_radar,:))
%     plot(et,radar_count(cur_radar),mMissile{cur_missile},'color',cRadar(cur_radar,:))
%     if targetInfo(i).round==1
%         text(st+(et-st)/2-2,radar_count(cur_radar)+0.5,['T' num2str(cur_target)],'color','k','Fontsize',10,'Fontname','Helvetica');
%         text(et+2,radar_count(cur_radar),['T' num2str(cur_target)],'color','k','Fontsize',10,'Fontname','Helvetica');
%     end
    if radar_count(cur_radar)==1
        ylabel(['雷达' num2str(cur_radar)],'fontsize',14)
        grid on
        box on
    end
    ylim([0,max(radar_count(cur_radar,:))+1])
    radar_count(cur_radar,st/Prob.dT:et/Prob.dT) = radar_count(cur_radar,st/Prob.dT:et/Prob.dT)+1;
    cc=cc+1;
%     radar_count(cur_radar) = radar_count(cur_radar)+1;
end

% return
% for i = 1:Radar.N
%     subplot(Radar.N,1,i)
%     targets = rTask(i).target;
%     missiles = rTask(i).missile;
%     for j=1:numel(targets)
%         if ismember(targets(j),BestSol.failTarget)
%             continue
%         end
%         st = rTask(i).tStartTrack(j);
%         et = rTask(i).tEndTrack(j);
%         line([st,et],[j,j],'linewidth',1,'color',cRadar(i,:),'marker',mMissile{missiles(j)})
%         text(st+(et-st)/2-2,j+0.5,['T' num2str(targets(j))],'color','k','Fontsize',10,'Fontname','Helvetica');
%     end
%     ylabel(['雷达' num2str(i)],'fontsize',14)
%     ylim([0,numel(targets)+1])
%     grid on
%     box on
%     hold on
%     if i==Radar.N
%         % 添加图例
%         legends=cell(1,Missile.N);
%         h=[];
%         for j=1:Missile.N
%             h(j) = scatter(-10,0,50,cRadar(j,:),mMissile{j});
%             legends{j} = ['发射车' num2str(j)];
%         end
%         legend(h,legends,'Location','southoutside','NumColumns',Missile.N,'fontsize',12)
%     end
%     xlim([0,inf])
% end

%% 目标跟踪甘特图
figure
hold on
% set(gcf,'position',[200,40,800,400]);
cur_target = inf;
for i=1:length(targetInfo)
    ctarget = targetInfo(i).target;
    missile = targetInfo(i).missile;
    radar = targetInfo(i).radar;
    times = targetInfo(i).round;

    tStartTrack0 = targetInfo(i).tLaunch;
    tStartTrack = targetInfo(i).tStartTrack;
    tKill = targetInfo(i).tKill;
    tLaunch = targetInfo(i).tLaunch;
    radar0 = targetInfo(i).radar0;
    scatter(tKill,ctarget,50,cRadar(radar,:),mMissile{missile},'filled')
    if isempty(radar0)
        line([tStartTrack,tKill],[ctarget,ctarget],'linewidth',2,'color',cRadar(radar,:))
    else
        line([tStartTrack,tKill],[ctarget,ctarget],'linewidth',2,'color',cRadar(radar,:))
        line([tStartTrack0,tStartTrack],[ctarget,ctarget],'linewidth',6,'color',cRadar(radar0,:))
    end
end
grid on
yticks([1:1:Target.N])
box on
ylabel('雷达编号')
xlabel('时间/秒')

% 添加图例
legends=cell(1,Radar.N+Missile.N);
h=[];
for i=1:Radar.N
    h(i) = plot(-10,0,'-','color',cRadar(i,:),'linewidth',2);
    legends{i} = ['雷达' num2str(i)];
end
for i=1:Missile.N
    h(Radar.N+i) = scatter(-10,0,50,cRadar(i,:),mMissile{i},'filled');
    legends{Radar.N+i} = ['发射车' num2str(i)];
end
legend(h,legends,'Location','best','NumColumns',4)
xlim([0,inf])

%% 目标被击毁位置
for typetar = 1%:Prob.nTargetType
    figure
    h=[];
%     set(gcf,'position',[200,40,1600,800]);
    title(['目标类型:' num2str(typetar)])
    %% 雷达部署
    colormap_ = linspecer(Radar.N);
    hold on
    box on
    for i = 1 : Radar.N
        type = Radar.type(i);
        theta_start = Radar.angle(i) - Radar.Theta(type) * pi/180;
        theta_end = Radar.angle(i) + Radar.Theta(type) * pi/180;
        theta = linspace(theta_start,theta_end,20);
        x0 = Radar.location(i,1);
        y0 = Radar.location(i,2);
        text(x0+2,y0,['R' num2str(i)],'color','k','Fontsize',10,'Fontname','Helvetica');
        R = Radar.R(Radar.type(i),typetar); % 雷达hh行为的威力
        x = [x0 x0 + R*cos(theta) x0];
        y = [y0 y0 + R*sin(theta) y0];
        patch = fill(x, y,colormap_(i,:),'facealpha',0.05,'EdgeColor',colormap_(i,:));
    end
    grid on
    h(1) = scatter(Radar.location(1:Radar.N,1),Radar.location(1:Radar.N,2),150,'g','s','filled','MarkerEdgeColor','k');
    
        %% 发射车的情况
%     for i=1:Missile.N
%         x = Missile.location(i,1);
%         y = Missile.location(i,2);
%         %         r = Missile.rKill{1,1}(typetar,1);
%         %         rectangle('Position',[x-r,y-r,2*r,2*r],'Curvature',[1,1],'EdgeColor','m')
%         r = Missile.rKill{1,1}(typetar,5);
%         rectangle('Position',[x-r,y-r,2*r,2*r],'Curvature',[1,1],'EdgeColor','m')
%     end
    h(2) = scatter(Missile.location(1:Missile.N,1),Missile.location(1:Missile.N,2),60,'m','o','filled');
    
    %% 目标情况
    colormap_ = linspecer(Prob.nTargetType);
    ind = Target.type==typetar;
    h(3) = scatter(Target.startPOS(ind,1),Target.startPOS(ind,2),[],cTarget{typetar},'v');
    
    for i=1:length(targetInfo)
        missile = targetInfo(i).missile;
        radar = targetInfo(i).radar;
        cur_target = targetInfo(i).target;
        x0 = Target.startPOS(cur_target,1);
        y0 = Target.startPOS(cur_target,2);
        if Target.type(cur_target)==typetar
            text(x0+1,y0,['T' num2str(cur_target)],'color','k','Fontsize',10,'Fontname','Helvetica');
            
            tEnd = round(targetInfo(i).tKill/Prob.dT);
            pos = target(cur_target).track(tEnd,:);
            h(4) = scatter(pos(1),pos(2),60,'b*');
            h(5) = line([x0,pos(1)],[y0,pos(2)],'color',cTarget{typetar});
            mpos = Missile.location(missile,:);
            h(6) = line([mpos(1),pos(1)],[mpos(2),pos(2)],'color',cTarget{typetar},'LineStyle','-.');
        end
    end
    %% 添加图例
    legends={'雷达','发射车','目标起点','目标轨迹','打击位置','导弹轨迹'};
    legend(h,legends,'Location','north','NumColumns',6,'fontsize',12)    
end
