%% Load data
clear all
close all

load('pre-processed_data\PropErrorClamp_trials.mat');

% Pilot and real data
% K_subj_names = {'PropEC_622C__J10','PropEC_622C__J9', 'PropEC_622A__J8_a', 'PropEC_622C__J7_b',...
%         'PropEC_622C__ j6', 'PropEC_622A__ j5_a', 'PropEC_622C__ j4', 'PropEC_622C__J3', 'PropEC_622A__J2',... % Pilot data
%         'PropEC_905C_1_J1', 'PropEC_905A_1_J2_a', 'PropEC_905C__J3_a', 'PropEC_905A__J4_a',...
%         'PropEC_905C__J5_a', 'PropEC_905A__J6_a', 'PropEC_905C__J7_a', 'PropEC_905A__J8_a',...
%         'PropEC_905C__J9_a','PropEC_905A__J10_a', 'PropEC_905C__J11_a','PropEC_905A__J12_b',...
%         'PropEC_905C__J13_a', 'PropEC_905A__J14', 'PropEC_905C__J15_a', 'PropEC_905A__J16_a',...
%         'PropEC_905C__J17_a', 'PropEC_905A__J18_a', 'PropEC_905A__J20', 'PropEC_905C__J21_a'};

% % Real data only
K_subj_names = {'PropEC_905C_1_J1', 'PropEC_905A_1_J2_a', 'PropEC_905C__J3_a', 'PropEC_905A__J4_a',...
        'PropEC_905C__J5_a', 'PropEC_905A__J6_a', 'PropEC_905C__J7_a', 'PropEC_905A__J8_a',...
        'PropEC_905C__J9_a','PropEC_905A__J10_a', 'PropEC_905C__J11_a','PropEC_905A__J12_b',...
        'PropEC_905C__J13_a', 'PropEC_905A__J14', 'PropEC_905C__J15_a', 'PropEC_905A__J16_a',...
        'PropEC_905C__J17_a', 'PropEC_905A__J18_a', 'PropEC_905A__J20', 'PropEC_905C__J21_a'};
    

% Check that # of subject names == # of subjects in datafile
if length(K_subj_names) ~= length(unique(T.SN))
    error_please_copy_in_subject_names_T1
end


hand_vars = {'hand_theta','hand_theta_maxv','hand_theta_maxradv','handMaxRadExt','hand_theta_50'};
prop_vars = {'FC_bias_X', 'FC_bias_Y', 'prop_theta'};



% T1 REMOVE OUTLIERS
T1 = T;
outlier_idx = abs(T1.hand_theta) > 90 ; % Remove trials greater than x degrees
fprintf('Outlier trials removed: %d \n' , [sum(outlier_idx)])
for vi = 1:length(hand_vars) % loop over hand angle columns
    T1.(hand_vars{vi})(outlier_idx, 1) = nan; % Flip trials .*(-1)
end
    
    
% T2 FLIP CCW SUBJECTS TO CW
T2 = T1;
flip_idx = T2.rot_cond > 0; % CW condition index   % Change to 'rot_cond' eventually
for vi = 1:length(hand_vars) % loop over hand angle columns
    T2.(hand_vars{vi})(flip_idx, 1) = T1.(hand_vars{vi})(flip_idx, 1).*(-1); % Flip trials .*(-1)
end

% flip proprioceptive related variables
T2.prop_theta(flip_idx) = T2.prop_theta(flip_idx).*(-1);
T2.FC_X(flip_idx) = T2.FC_X(flip_idx).*(-1);
T2.HL_X(flip_idx) = T2.HL_X(flip_idx).*(-1);
T2.FC_bias_X(flip_idx) = T2.FC_bias_X(flip_idx).*(-1);
T2.PropLocX(flip_idx) = T2.PropLocX(flip_idx).*(-1);
T2.ti(flip_idx) = T2.ti(flip_idx).*(-1) + 180;
T2.PropTestAng(flip_idx) = T2.PropTestAng(flip_idx).*(-1) + 180;


% T3 BASELINE SUBTRACTION
T3 = T2;
baseCN = 9:12; %%%% Reaching Baseline cycles to subtract 
base_idx = T3.CN >= min(baseCN) & T3.CN <= max(baseCN); % index of baseline cycles
base_mean = varfun(@nanmean,T2(base_idx ,:),'GroupingVariables',{'SN','ti'},'OutputFormat','table');

for SN = unique(T3.SN)';
    for ti = unique(T3.ti(~isnan(T3.ti)))'; % subtract baseline for each target
        for vi = 1:length(hand_vars) % loop over hand angle columns
            trial_idx = (T3.SN==SN & T3.ti==ti);
            base_idx = (base_mean.SN==SN & base_mean.ti==ti);
            T3.(hand_vars{vi})(trial_idx) = T2.(hand_vars{vi})(trial_idx) - base_mean.(strcat('nanmean_',hand_vars{vi}))(base_idx);
        end
    end
end

prop_baseCN = 13:20; %%%% Proprioceptive Baseline cycles to subtract 
% prop_baseCN = 17:20; %%%% Proprioceptive Baseline cycles to subtract 
prop_base_idx = T3.CN >= min(prop_baseCN) & T3.CN <= max(prop_baseCN); % index of baseline cycles
prop_base_mean = varfun(@nanmean,T2(prop_base_idx ,:),'GroupingVariables',{'SN','PropTestAng'},'OutputFormat','table');

for SN = unique(T3.SN)';
    for prop_ti = unique(T3.PropTestAng(~isnan(T3.PropTestAng)))'; % subtract baseline for each target
        for vi = 1:length(prop_vars) % loop over hand angle columns
            trial_idx = (T3.SN==SN & T3.PropTestAng==prop_ti);
            prop_base_idx = (prop_base_mean.SN==SN & prop_base_mean.PropTestAng==prop_ti);
            T3.(prop_vars{vi})(trial_idx) = T2.(prop_vars{vi})(trial_idx) - prop_base_mean.(strcat('nanmean_',prop_vars{vi}))(prop_base_idx);
        end
    end
end

K_lines_all_trials = [9.5 36.5 72.5 108.5 144.5 180.5 270.5 360.5 396.5 486.5 522.5 612.5 648.5 738.5];

% FOR REFERENCE
% % % In cycles
% % % Proprioceptive = 1
% % % No fb baseline = 2:4
% % % fb baseline = 5:12

% Figure lines for block divisions
%% Every subject every trial
clearvars -except T* K*
close all;
E = T3;
E.PB(isnan(E.PB)) = 0; % Cheap hack so that the split function works

subjs = unique(E.SN);

% for i = 1:length(subjs)
for i = 1
    
    figure('units','centimeters','pos',[1 5 20 20]);hold on;
    subplot(2,2,1:2); hold on;
    str = sprintf('Hand angle and Proprioceptive estimates for subj %d', subjs(i));
    title(str);
    % Hand theta
    x1 = E.TN(E.SN == subjs(i));
    y1 = E.hand_theta( E.SN == subjs(i));
    scatter(x1,y1,10,'filled');
    % Proprioceptive estimate (as an angle relative to tgt)
    x2 = E.TN(E.SN == subjs(i));
    y2 = E.prop_theta( E.SN == subjs(i));
    scatter(x2,y2,10,'filled');
    % Reference lines
    drawline(0, 'dir', 'horz', 'linestyle', '-'); % Draws line at target
    drawline(K_lines_all_trials, 'dir', 'vert', 'linestyle', ':');  % Draws line for blocks
    % Shade the no feedback trials
    no_fb_base =patch([9.5 36.5 36.5 9.5],[min(ylim) min(ylim) max(ylim) max(ylim)],zeros(1,4));
    set(no_fb_base,'facecolor',[0 0 0]); set(no_fb_base,'edgealpha',0);
    alpha(no_fb_base,0.1)
    % Fig labels
    xlabel('Trial'); ylabel('Hand Angle/Proprioceptive estimate (�)')
    
    subplot(2,2,3); title('Proprioceptive estimates'); hold on;
    % All proprioceptive estimates in absolute space
    x3 = E.FC_bias_X(E.SN == subjs(i));
    y3 = E.FC_bias_Y(E.SN == subjs(i));
    %     x3 = E.FC_X(E.SN == subjs(i));
    %     y3 = E.FC_Y(E.SN == subjs(i));
    Prop_block = E.PB(E.SN == subjs(i));
    scatterplot(x3,y3,'split',Prop_block,'leg','auto' );
    % Fig labels
    axis('square');
    xlabel('mm'); ylabel('mm')
    
    
    subplot(2,2,4); title('Mean Proprioceptive Bias'); hold on;
    % Mean Proprioceptive estimate per block
    x3=[]; y3=[];
    PBs = [1:6]; % Proprioceptive block number
    for bi = 1:length(PBs)
        x3(bi,1) = nanmean( E.FC_bias_X(E.SN == subjs(i) & E.PB == PBs(bi)) );
        y3(bi,1) = nanmean( E.FC_bias_Y(E.SN == subjs(i) & E.PB == PBs(bi)) );
    end
    cmap = jet(length(x3)); % Color map
    scatter(x3,y3,40,cmap,'filled');
    text(x3,y3,{'   bnf','   bf','   c1','   c2','   c3','   c4'}) % Label points
    
    % Fig labels
    scatter(0,0,80,'k.') % Target reference (0,0)
    %     axis([-30 30 -30 30]);
    axis('square');
    xlabel('mm'); ylabel('mm')
end
%% Group mean hand angle
clearvars -except T* K*
E = T3;
E.hand = E.hand_theta;
% E = E(E.rot_cond<0, :);
% F = E(E.rot_cond>0, :);

figure; hold on;

% Plot hand angle for reaching blocks
for rbi = 1:max(E.RB)
    block_trials=[]; hy=[]; sem_hy=[];
    RB_idx = (E.RB == rbi); % reaching block index
    block_trials = unique(E.TN(RB_idx)); % reaching block trials
    
    for i = 1:length(block_trials); % loop through blocks
        trial_idx = E.TN==block_trials(i);
        hy(i) = nanmean(E.hand(trial_idx ));
        sem_hy(i) = sem(E.hand(trial_idx ));
    end
    
    % Plot hand angles
    shadedErrorBar(block_trials,hy,sem_hy,'b')
end

% Plot proprioceptive estimates for each proprioceptive block
for pbi = 1:max(E.PB)
    block_trials=[]; py=[]; sem_py=[];
    PB_idx = (E.PB == pbi); % proprioceptive block index
    block_trials = unique(E.TN(PB_idx)); % proprioceptive block trials
    
    for i = 1:length(block_trials);
        trial_idx = E.TN==block_trials(i);
        py(i) = nanmean(E.prop_theta(trial_idx ));
        sem_py(i) = sem(E.prop_theta(trial_idx ));
        
    end
    
    shadedErrorBar(block_trials,py,sem_py,'r')
    
end
% Reference lines
drawline(0, 'dir', 'horz', 'linestyle', '-'); % Draws line at target
drawline(K_lines_all_trials, 'dir', 'vert', 'linestyle', ':');  % Draws line for blocks
% Shade the no feedback trials
no_fb_base =patch([9.5 36.5 36.5 9.5],[min(ylim) min(ylim) max(ylim) max(ylim)],zeros(1,4));
set(no_fb_base,'facecolor',[0 0 0]); set(no_fb_base,'edgealpha',0);
alpha(no_fb_base,0.1)
% Fig labels
xlabel('Trial'); ylabel('Hand Angle/Proprioceptive estimate (�)')
axis([0 max(E.TN) -15 35]);


% str3 = sprintf('Janet group trace');
% cd('C:\BoxSync\Dropbox\!!temp_figs\')
% print(str3,'-painters','-djpeg')
% savefig(str3)
%% Subject summary table
clearvars -except T* K*
E = T3;
% E = E(E.rot_cond>0, :);
E.hand = E.hand_theta;
subj = unique(E.SN);

for si = 1:length(subj)
    
    SN(si,1) = subj(si);
    rotCond(si,1) = mean(E.rot_cond(E.SN==subj(si),1));
    
    % Adaptation dependent variables
    earlyLearning(si,1) = nanmean( E.hand( E.SN==subj(si) & E.CN >= (21 + 1)  & E.CN <= (21 + 4) ) ); % clamp cycles 2 - 4 (smaller clamp cycles than usual because of generalization)
    asymptote(si,1) = nanmean( E.hand( E.SN==subj(si) & E.CN >= 73  & E.CN <= 82 ) ); % last 10 clamp cycles

    % Proprioceptive shift
    shift_idx = E.SN==subj(si) & E.PB > 2 ;
    base_idx = E.SN==subj(si) & E.PB == 2 ; 
    propShiftX(si,1) = nanmean(E.FC_bias_X(shift_idx)) - nanmean(E.FC_bias_X(base_idx));
    
    propShiftTheta(si,1) = nanmean(E.prop_theta(shift_idx)) - nanmean(E.prop_theta(base_idx));
    
    % Proprioceptive dispersion
    disp_idx = E.SN==subj(si) & E.PB==2;
    dispBlock1(si,1) = dispersion( E.FC_bias_X(disp_idx), E.FC_bias_Y(disp_idx));
    
    disp_idx=[];
    disp_idx = E.SN==subj(si) & ~isnan(E.PB);
    dispAll(si,1) = dispersion( E.FC_bias_X(disp_idx), E.FC_bias_Y(disp_idx));
end
% Summary table
summaryMatrix = table(earlyLearning, asymptote, propShiftX, propShiftTheta, dispBlock1, dispAll);

subjCond = table(SN, rotCond);
summaryBar = [summaryMatrix subjCond];


%% CORRELATION MATRIX
figure
[S,AX,BigAx,H,HAx] = plotmatrix(summaryMatrix{:,:});
[rho,pval] = corrcoef(summaryMatrix{:,:})

almostSigPlots = find(pval<0.1);
sigPlots = find(pval<0.05);

varnames = summaryMatrix.Properties.VariableNames;
for vi = 1:length(varnames) % loop over hand angle columns
    AX(vi,1).YLabel.String = varnames{vi};
    AX(length(varnames),vi).XLabel.String = varnames{vi};
end

for sigi = 1:length(almostSigPlots);
S(almostSigPlots(sigi)).Color = [1 0.5 0];
end

for sigi = 1:length(sigPlots);
S(sigPlots(sigi)).Color = 'r';
end

% str3 = sprintf('Janet matrix', si);
% cd('C:\BoxSync\Dropbox\!!temp_figs\')
% print(str3,'-painters','-djpeg')
% savefig(str3)
%%
figure; hold on

x = summaryMatrix.dispAll(summaryBar.rotCond == 15);
y = summaryMatrix.asymptote(summaryBar.rotCond == 15);
plot(x,y,'.r','markersize',20)

x = summaryMatrix.dispAll(summaryBar.rotCond == -15);
y = summaryMatrix.asymptote(summaryBar.rotCond == -15);
plot(x,y,'.b','markersize',20)

[rho,pval] = corrcoef(summaryMatrix.dispAll,summaryMatrix.asymptote)
r = rho(1,2)
p = pval(1,2)

xlabel('Dispersion (mm)')
ylabel('Asymptote (deg)')

str = sprintf('r = %.2f, p = %.2f', r, p)
title(str)

% str3 = sprintf('Janet with pilot disp vs asym');
% cd('C:\BoxSync\Dropbox\!!temp_figs\')
% print(str3,'-painters','-djpeg')
% savefig(str3)
%%
figure; hold on

x = summaryMatrix.dispAll(1:9);
y = summaryMatrix.asymptote(1:9);
plot(x,y,'.r','markersize',20)

x = summaryMatrix.dispAll(10:29);
y = summaryMatrix.asymptote(10:29);
plot(x,y,'.b','markersize',20)

[rho,pval] = corrcoef(summaryMatrix.dispAll,summaryMatrix.asymptote)
r = rho(1,2)
p = pval(1,2)

xlabel('Dispersion (mm)')
ylabel('Asymptote (deg)')

str = sprintf('r = %.2f, p = %.2f', r, p)
title(str)

str3 = sprintf('Janet with pilot disp vs asym');
cd('C:\BoxSync\Dropbox\!!temp_figs\')
print(str3,'-painters','-djpeg')
savefig(str3)
%%
y = summaryMatrix.propShiftX;
x = summaryMatrix.dispAll;
figure
plot(x,y,'.','markersize',20)
[rho,pval] = corrcoef(x,y);
r = rho(1,2)
p = pval(1,2)
%% BAR GRAPHS Split CCW and CW
figure
% Plot bars

barVarNames = summaryBar.Properties.VariableNames;
xpos = [1 2 4 5 7 8 10 11 13 14 16 17];
for vi = 1:6
    dataPoints = summaryBar.(barVarNames{vi})(summaryBar.rotCond < 0);    
    dpPlotBar(xpos(vi*2), dataPoints );

    dataPoints = summaryBar.(barVarNames{vi})(summaryBar.rotCond > 0);    
    dpPlotBar(xpos(vi*2 - 1), dataPoints );    
end 

% Aesthetics
% xticks = [1.5 4.5]; yticks = [-10:5:25];
% axis([0 20 -30 60]);
xticks = [1.5 4.5 7.5 10.5 13.5 16.5];
% set(gca,'xTick',xticks,'YTick',yticks,'xticklabel',{'Early','Late'},'ylim',[-6 26],'xticklabelrotation',45)
set(gca,'xTick',xticks,'xticklabel',barVarNames,'ylim',[-30 60],'xticklabelrotation',45)


% str3 = sprintf('Janet bar split', si);
% cd('C:\BoxSync\Dropbox\!!temp_figs\')
% print(str3,'-painters','-djpeg')
% savefig(str3)
%% BAR GRAPHS avg both directions
figure

% Plot bars
barVarNames = summaryBar.Properties.VariableNames;
for vi = 1:6
    dataPoints = summaryBar.(barVarNames{vi});    
    dpPlotBar(vi, dataPoints ); 
end 

xticks = [1:6];
set(gca,'xTick',xticks,'xticklabel',barVarNames,'ylim',[-30 60],'xticklabelrotation',45)

% str3 = sprintf('Janet bar together', si);
% cd('C:\BoxSync\Dropbox\!!temp_figs\')
% print(str3,'-painters','-djpeg')
% savefig(str3)



%% Plot Group Hand angle and Proprioceptive Estimate
clearvars -except T* K*

E = T3;
E.hand = E.hand_theta;

figure; hold on;
dpPropErrorClamp_plotGroup(E, 'hand', 'RB', [0 774 -15 35], 'b')
dpPropErrorClamp_plotGroup(E, 'prop_theta', 'PB', [0 774 -15 35], 'r')

% Fig labels
title('Hand and proprioceptive angle');
xlabel('Trial'); 
ylabel('Hand Angle/Proprioceptive estimate (�)')

%% Plot Group Hand angle and Proprioceptive Estimate
clearvars -except T* K*

E = T3;
E.hand = E.hand_theta;

figure; hold on;
dpPropErrorClamp_plotGroup(E, 'ST', 'RB', [0 774 0.3 6], 'b')
dpPropErrorClamp_plotGroup(E, 'ST', 'PB', [0 774 0 7], 'r')

% Fig labels
title('ST');
xlabel('Trial'); 
ylabel('RT (sec)')






