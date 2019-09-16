%% Assess_the_sleep(subject_id)
%
% Modified script fo Analysis of University of Wisconsin Madison data.
%
% It loads data from structure, looks for /subject_id/subject_id_data.mat
%
% Next, it extracts features from all electrodes and plot figures to
% subject_id directory to be ready for electrode selection if needed
% 
% Then it aggregates all the features to structure and saves extracted
% features to /subject_it/subject_id_features.mat
% file to be used in the future if needed.
%
% Then it extracts the median features and plots the resulting image to
% assess the sleep architecture. It saves the plotted images as png and fig
% with name: Median_Spectra_features_and_Sleep_Stage. 
% It plots: wavelet scalogram, all extracted features, Delta/Beta ratio,
% and hypnogram if available from Scalp Scoring (from original Madison
% structure)
%
%
% Copyright (c) 2017-2018, Mayo Foundation for Medical Education and Research (MFMER), 
% All rights reserved. Academic, non-commercial use of this software is allowed with 
% expressed permission of the developers. MFMER and the developers disclaim all implied 
% warranties of merchantability and fitness for a particular purpose with respect to this software, 
% its application, and any verbal or written statements regarding its use. 
% The software may not be distributed to third parties without consent of MFMER. 
% Use of this software constitutes acceptance of these terms and acceptance of all risk 
% and liability arising from the software?s use.
% Contributors: Vaclav Kremen.
%
%
% Acknowledgement: When use, acknlowledge please and refer to these journal papers:
%?Kremen, V., Duque, J. J., Brinkmann, B. H., Berry, B. M., Kucewicz, M. T., 
% Khadjevand, F., ? Worrell, G. A. (2017). Behavioral state classification in 
% epileptic brain using intracranial electrophysiology. Journal of Neural 
% Engineering, 14(2), 026001. https://doi.org/10.1088/1741-2552/aa5688
%
% Kremen, V., Brinkmann, B. H., Van Gompel, J. J., Stead, S. (Matt) M.,
% St Louis, E. K., & Worrell, G. A. (2018). Automated Unsupervised Behavioral
% State Classification using Intracranial Electrophysiology. 
% Journal of Neural Engineering. https://doi.org/10.1088/1741-2552/aae5ab
%
% Gerla, V., Kremen, V., Macas, M., Dudysova, D., Mladek, A., Sos, P., & Lhotska, L. (2019). 
% Iterative expert-in-the-loop classification of sleep PSG recordings using a 
% hierarchical clustering. Journal of Neuroscience Methods, 317(February), 
% 61?70. https://doi.org/10.1016/j.jneumeth.2019.01.013

function [] = Assess_the_sleep(subject_id)

% load the data from folder subject_id/subject_id
load(sprintf('%s%s%s%s%s_data.mat', cd, filesep, subject_id, filesep, subject_id));

fsamp_new = 64;
window_epochs_in_one_run = 86400;  % do one day of epochs - length of epoch needs to be define beforehand
window_cwt_size_samples = window_epochs_in_one_run*30*fs;
CWT_default_NumOctaves = 8;
CWT_default_VoicesPerOctave = 8;
CWT_default_TimeBandwidth = 90;


%channel_features = zeros(window_epochs_in_one_run, length(channels), 8);

%%

i = 1; % what DAY to start from
from_el = 1; % what ELECTRODE to start from
skip_el = 1; % which STEP to skip to other electrodes
n_electrodes = length(El_number); % get number of channels available

%curr_seg = zeros(n_electrodes, 34527199);
WT = [];
Maximas = [];
features = [];
features_key = {};

%%  read all day segments and perform Wavelet analysis on that
for j = from_el : skip_el : n_electrodes % print images for all electrodes
    x = []; sub_wt = []; max_plot =[]; fdata = []; fdesc = {};
    
    % Wavelet
    % resampling
    x = []; x = Data(j,:);
    x(isnan(x)) = 0; % to plot wavelet with discontinuities as mean
    x = resample(x, round(10*fsamp_new), round(10*fs));
    
    % extract features
    tic
    segm_size = 30; % define epoch length (30 sec)
    fbands = [1 3; 3 7; 7 12; 12 15; 15 20; 20 25]; % define frequency bands
    [fdata, fdesc] = feature_extraction(x, fsamp_new, segm_size, fbands);
    fdata = fdata(:,1:end-1); % crop the last segment off not to overlap to next day
    fprintf('\tSignal #%s/%s;\n\t\tfeatures calculated: %s sec\n',...
        num2str(j), num2str(n_electrodes), num2str(toc));
    
    % CWT
    tic
    [sub_wt, f_cwt] = cwt(x, fsamp_new, 'NumOctaves', ...
        CWT_default_NumOctaves, 'VoicesPerOctave', ...
        CWT_default_VoicesPerOctave, 'TimeBandwidth', ...
        CWT_default_TimeBandwidth);
    sub_wt = zscore(abs(sub_wt));
    fprintf('\t\twavelet calculated: %s sec\n', num2str(toc));

    
    % get rid of slow waves and high frequency artifact at the end
    % of nyquist
    [from_f,~] = find(f_cwt>=1.5); % find all frequencies above 1 Hz
    from_f = from_f(3:end,1); % get rid of three high freq samples
    
    % RESIZE result
    epoch_num = round(size(sub_wt, 2) ./ (30 * fsamp_new));
    sub_wt = imresize(sub_wt, [size(sub_wt, 1) epoch_num], 'bicubic');
    
    [~,ind] = max(sub_wt(from_f, :));
    max_plot = f_cwt(from_f(ind,:),1)';
    
    %% plot the figure for each electrode
    hFig = figure;
    subplot(2,1,1)
    title (sprintf('Electrode nubmer %s', num2str(j)));
    imagesc(sub_wt(from_f,:));
    yticklabels([f_cwt(from_f(3)) f_cwt(from_f(9)) f_cwt(from_f(14)) f_cwt(from_f(20))...
        f_cwt(from_f(26)) f_cwt(from_f(32)) f_cwt(from_f(end))]);
    ylabel('f(Hz)'); xlabel('epochs (30 sec)');
    title (sprintf('Spectra for electrode number %s (%s)', num2str(j), El_name{j}));
    subplot(2,1,2)
    plot(max_plot);
    ylabel('f(Hz)');
    title (sprintf('Maximum of spectra in plot above'));
    
    set(gca,'XMinorTick','on');
    xlim([0 length(max_plot)]);
    all_ha = findobj(hFig  , 'type', 'axes', 'tag', '' );
    all_ha(1).YGrid = 'on'; % turn on Y-Grids
    all_ha(2).YGrid = 'on';
    
    % print images
    dest = [cd filesep subject_id filesep];
    saveas(hFig,sprintf('%s%s%s_ToSelectElectrode_%s.png', dest, filesep, num2str(subject_id), num2str(El_number(j))));
    close(hFig);
    
    % save to variable matrix
    WT(:,:,end+1) = sub_wt;
    Maximas = [Maximas; max_plot];
    features(:,:,end+1) = fdata;
    features_key = fdesc;
end

% accumulate the features in a structure
WT = WT(:,:,2:end); % delete first zeros
feature_struct.WT = WT;
feature_struct.wavelet_maximas = Maximas;
feature_struct.f_cwt = f_cwt;
feature_struct.features = features;
feature_struct.features_key = features_key;
if exist('stage', 'var'); feature_struct.stage = stage; else feature_struct.stage = []; end;
if exist('stage_key', 'var'); feature_struct.stage_key = stage_key; else; feature_struct.stage_key = []; end;
feature_struct.fs = fs;
feature_struct.El_name = El_name;
feature_struct.El_number = El_number;


%% save the calculated features for future use
dest = [cd filesep subject_id filesep];
save(strcat(dest, subject_id, '_feature_struct.mat'), 'feature_struct', '-v7.3');

%% Plot from original or reloaded features
% to reconstruct/reload features for plotting from feature_struct_data
WT = feature_struct.WT;
Maximas = feature_struct.wavelet_maximas;
f_cwt = feature_struct.f_cwt;
features = feature_struct.features;
features_key = feature_struct.features_key;
stage = feature_struct.stage;
stage_key = feature_struct.stage_key;
fs = feature_struct.fs;
El_name = feature_struct.El_name;
El_number = feature_struct.El_number;
if exist('fs') == 0
    fs = 250; 
end

% calculate median scalogram
median_WT = nanmedian(feature_struct.WT,3); % calculate median spectra
median_feat = nanmedian(feature_struct.features,3); % calculate median features
what_feat_plot = [1, 2, 3, 5, 8, 11, 14, 17]; % what features to plot
[from_f,~] = find(f_cwt>=1.5); % find all frequencies above X Hz
from_f = from_f(3:end,1); % get rid of three high freq samples
[~,ind] = max(median_WT(from_f, :)); % get maximal spectral power in each epoch
max_plot = f_cwt(from_f(ind,:),1)'; % save maximal freqency in each epoch

% plot score, if available and plot median accross electrodes

hFig = figure('Position', [700, 1000, 1700, 1200]);
subplot(3+length(what_feat_plot)+1,1,1)
imagesc(median_WT(from_f,:));
yticklabels([f_cwt(from_f(3)) f_cwt(from_f(9)) f_cwt(from_f(14)) f_cwt(from_f(20))...
    f_cwt(from_f(26)) f_cwt(from_f(32)) f_cwt(from_f(end))]);
ylabel('f(Hz)'); xlabel('epochs (30 sec)');
title (sprintf('Median spectra accross all electrodes'));
set(gca,'Xticklabel',[]) 

subplot(3+length(what_feat_plot)+1,1,2)
plot(max_plot);
ylabel('f(Hz)');
title (sprintf('Maximum of spectra in plot above'));
set(gca,'XMinorTick','on');
xlim([0 length(max_plot)]);
set(gca,'Xticklabel',[]) 

for i = 3:2+length(what_feat_plot)
    subplot(3+length(what_feat_plot),1,i);
    plot(median_feat(what_feat_plot(i-2),:));
    xlim([0 length(max_plot)]);
    title(feature_struct.features_key(what_feat_plot(i-2)));
    set(gca,'Xticklabel',[]) 
end

% do Delta Beta plot and show candidates of clear wake and clear deep sleep
subplot(3+length(what_feat_plot)+1,1,i+1);
Db = median_feat(what_feat_plot(4),:)./median_feat(what_feat_plot(end),:);
DbcritAW = 5;
DbcritSWS = 90;
plot(Db);
hold on;
plot(find(Db<prctile(Db,DbcritAW)),Db(find(Db<prctile(Db,DbcritAW))),...
    'yo', 'MarkerSize', 5, 'MarkerFaceColor', 'y');
plot(find(Db>prctile(Db,DbcritSWS)),Db(find(Db>prctile(Db,DbcritSWS))),...
    'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');

xlim([0 length(max_plot)]);
title(sprintf('%s over %s', ...
    feature_struct.features_key{what_feat_plot(4)}, feature_struct.features_key{what_feat_plot(end)}));
set(gca,'Xticklabel',[]) 

% plot hypnogram if available
subplot(3+length(what_feat_plot)+1,1,i+2);
plot(feature_struct.stage(1:fs*30:end), 'LineWidth', 3);
xlim([0 length(feature_struct.stage(1:fs*30:end))]);
title('Gold Standard Sleep Stage (if available)');
yticks(find(~strcmp(feature_struct.stage_key,'N/A')));
yticklabels(feature_struct.stage_key(~strcmp(feature_struct.stage_key,'N/A')));

all_ha = findobj(hFig  , 'type', 'axes', 'tag', '' );
%linkaxes( all_ha, 'x' );
for j = 1:length(all_ha)
    all_ha(j).YGrid = 'on'; % turn on Y-Grids
end

%% print images
dest = [cd filesep subject_id filesep];
saveas(hFig,sprintf('%s%s%s_Median_Spectra_features_and_Sleep_Stages.png', dest, filesep, num2str(subject_id)));
savefig(hFig,sprintf('%s%s%s_Median_Spectra_features_and_Sleep_Stages.fig', dest, filesep, num2str(subject_id)));

%% ----- BreakPoint -----
% one can put braekpoint here to do manual scoring of sleep

%% Action Item: continue with coding to enable scoring of sleep right in the 
% figure when it is opened and presented to user

close(hFig);
disp('Done...');


end

