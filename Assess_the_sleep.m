%% ASSESS_THE_SLEEP Semi-automated assesment of sleep based on feature analysis of EEG. Runs and displays attributes of the time-domain data and launches UI for expert to classify 30-second epochs of the data into AASM2012 sleep classes.
%
% SYNOPSIS: Assess_the_sleep
%
% INPUT It loads data from structure, looks for /subject_id/subject_id_data.mat
%       It needs subject_id and its indexing 'z' variable defined as global in Matlab Workspace and
%       set properly as a string name with existing folder name:
%       global subject_id; e.g. subject_id = '403_017_0002';
%       Input data saved to subject_id_data.mat consists of:
%           Data: double [M:L], L number of raw EEG data samples for each
%           of M electrodes.
%           El_name: cell {1:M}, names in strings of each electrode (max
%           M).
%           El_number: double [1:M], numbering of each electrodes (max M).
%           fs: double [1], sampling rate of data
%           stage: double 1:L, score of sample in data that has been
%           manually sleep scored if it was done (if it
%           wasn't done, the variable is missing)
%           stage_key: cell array 1:N, description (N - names in strings) of
%           N sleep stages used for staging of the data and how they
%           link to numbers and score in STAGE (if it
%           wasn't done, the variable is missing)
%
%       If feature_struct variable file is present in directory it skips feature
%       extraction, otherwise goes next, it extracts features from all
%       electrodes and plot figures to subject_id directory to be ready
%       for electrode selection if needed
%
% OUTPUT If feature_struct was not available, it loads the data from
%       /subject_id/subject_id_data.m and run a feature extraction (feature_extraction.m) and
%       Then it aggregates all the features to a structure and saves extracted
%       features to /subject_it/subject_id_features.mat
%       file to be used in the future if needed.
%       feature_struct content looks like this:
%           WT: double [65:E], wavelet scalogram matrix with 65 frequency
%           lines and E number of epochs
%           wavelet_maximas: double [1:E], maximas of power in each epoch (taken from WT)
%           f_cwt: double [65], frequency of each frequency line in WT
%           features: double [21,E,M], 21 features calculated for E number
%           of epoch and M number of channels
%           features_key: cell array of strings {1:21} contains name of
%           features
%           El_name: cell {1:M}, names in strings of each electrode (max
%           M).
%           El_number: double [1:M], numbering of each electrodes (max M).
%           fs: double [1], sampling rate of data
%           stage: double 1:L, score of sample in data that has been
%           manually sleep scored if it was done (if it
%           wasn't done, the variable is missing)
%           stage_key: cell array 1:N, description (N - names in strings) of
%           N sleep stages used for staging of the data and how they
%           link to numbers and score in STAGE (if it
%           wasn't done, the variable is missing)
%           fs: double [1], sampling rate of time-domain data
%
%
%       Then it extracts the median features and plots the resulting image to
%       assess the sleep architecture. It saves the plotted images as png and fig
%       with name: Median_Spectra_features_and_Sleep_Stage.
%       It also plots: wavelet scalogram, all extracted features, Delta/Beta ratio,
%       and hypnogram if available from Scalp Scoring to enable manual
%       stagining of the sleep based on features and wavelet scalogram.
%
% CONTROLS of Figure and sleep scoring:
%       KEY STROKES and mouse click works on any part of windows when
%       Figure is activated
%       q - quit the figure
%       s - saves the scored values to subject_id/subject_id_Sleep_Scoring.mat
%
%       MOUSE CLICKS One left mouse button click - select beginning of region to score
%       Second left mouse button click - selects ends of region to score
%       Third left mouse button click - erases selection done by previous two
%       clicks
%
%       SLEEP SCORING When some time interval is selected to score:
%       0 - sets awake score
%       1 - N1 score
%       2 - N2 score
%       3 - N3 score
%       5 - REM score
%       7 - Unknown score
%
% Copyright 2019. Mayo Foundation for Medical Education and Research (MFMER). All rights reserved. Academic, non-commercial use of this software is allowed with expressed permission of the developers. MFMER and the developers disclaim all implied warranties of merchantability and fitness for a particular purpose with respect to this software, its application, and any verbal or written statements regarding its use. The software may not be distributed to third parties without consent of MFMER. Use of this software constitutes acceptance of these terms and acceptance of all risk and liability arising from the software?s use.
%
% Contributors: Vaclav Kremen, Vaclav Gerla.
%
% Version 1.0, 2019, Vaclav Kremen, Mayo Clinic.
%
% Acknowledgement: When use, acknlowledge please and refer to these journal papers:
% Kremen, V., Duque, J. J., Brinkmann, B. H., Berry, B. M., Kucewicz, M. T.,
% Khadjevand, F., Worrell, G. A. (2017). Behavioral state classification in
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

%%
function [] = Assess_the_sleep()
global SelectedEpochs time_axes Gold_Standard_Score hPlot ...
what_feat_plot median_feat feature_struct z i subject_id hFig

SelectedEpochs = []; % vector for selected epoch to score manually
Gold_Standard_Score = []; % vector to hold gold standard scoring
hPlot = []; % handler of plot

%% if no features were calculated (no .mat file), load the data file with data, extract features, save features
if ~isfile(sprintf('%s%s%s%s%s_feature_struct.mat', cd, filesep, subject_id{z}, filesep, subject_id{z}))
    % load the data from folder subject_id/subject_id
    fprintf('\nLoading the data... ')
    load(sprintf('%s%s%s%s%s_data.mat', cd, filesep, subject_id{z}, filesep, subject_id{z}));
    fprintf('Done.\n');

    fsamp_new = 64; % downsample to 64 Hz
    window_epochs_in_one_run = 86400;  % do one day of epochs - length of epoch needs to be define beforehand
    window_cwt_size_samples = window_epochs_in_one_run*30*fs;
    CWT_default_NumOctaves = 8;
    CWT_default_VoicesPerOctave = 8;
    CWT_default_TimeBandwidth = 90;

    i = 1; % what DAY to start from
    from_el = 1; % what ELECTRODE to start from
    skip_el = 1; % which STEP to skip to other electrodes
    n_electrodes = length(El_number); % get number of channels available

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

        %% plot the figure for each electrode and save it
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
        dest = [cd filesep subject_id{z} filesep];
        saveas(hFig,sprintf('%s%s%s_ToSelectElectrode_%s.png', dest, filesep, num2str(subject_id{z}), num2str(El_number(j))));
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
    dest = [cd filesep subject_id{z} filesep];
    save(strcat(dest, subject_id{z}, '_feature_struct.mat'), 'feature_struct', '-v7.3');
else
    % load the data from folder subject_id/subject_id
    load(sprintf('%s%s%s%s%s_feature_struct.mat', cd, filesep, subject_id{z}, filesep, subject_id{z}));
end


%% Plot from original or reloaded features and enable manual sleep scoring based on features
% to reconstruct/reload features for plotting from feature_struct_data
WT = feature_struct.WT;
Maximas = feature_struct.wavelet_maximas;
f_cwt = feature_struct.f_cwt;
features = feature_struct.features;
features_key = feature_struct.features_key;
stage = feature_struct.stage;
stage_key = feature_struct.stage_key;
El_name = feature_struct.El_name;
El_number = feature_struct.El_number;
if isfield(feature_struct,'fs')
    fs = feature_struct.fs;
else
    fs = 250; % set default sampling rate to 250 Hz.
end

% calculate median scalogram
median_WT = nanmedian(feature_struct.WT,3); % calculate median spectra
median_feat = nanmedian(feature_struct.features,3); % calculate median features
what_feat_plot = [1, 2, 3, 5, 8, 11, 14, 17]; % what features to plot
[from_f,~] = find(f_cwt>=1.5); % find all frequencies above X Hz
from_f = from_f(3:end,1); % get rid of three high freq samples
[~,ind] = max(median_WT(from_f, :)); % get maximal spectral power in each epoch
max_plot = f_cwt(from_f(ind,:),1)'; % save maximal freqency in each epoch
time_axes = [1:length(max_plot)];

% plot score, if available and plot median accross electrodes

hFig = figure('Position', [700, 1000, 1200, 800]);
set(hFig, 'KeyPressFcn', @MainWindowManualClick_callback); % create call back for mouse clicks
set(hFig, 'CloseRequestFcn', @hFig_CloseRequestFcn_callback); % create call back for pressing the close button

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
hPlot = subplot(3+length(what_feat_plot)+1,1,i+1);
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
set(gcf, 'WindowButtonDownFcn', @getMousePositionOnImage); % define mouse click callback

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

% wait till user closes the figure
waitfor(hFig);
disp(sprintf('\nFinished scoring for patient number: %s\n', subject_id{z}));

end


%% --- For manual corrections ---

function MainWindowManualClick_callback(src, evt)
global   SelectedEpochs  time_axes Gold_Standard_Score subject_id z i hFig;
if strcmp(evt.Character, 's')
    % saving data if confirmed by user
    answer = questdlg('Would you like to save your scoring now?');
    switch answer
        case 'Yes'
            % save variables
            h_msgbox = msgbox('Saving Scores');
            dest = [cd filesep subject_id{z} filesep];
            save(strcat(dest, subject_id{z}, '_Sleep_Scoring.mat'), 'Gold_Standard_Score', '-v7.3');
            close(h_msgbox);
            return;
        case 'No'
            return;
        case 'Cancel'
            return;
    end
elseif strcmp(evt.Character, 'q')
    % pop-up confirmation dialog
    answer = questdlg('Would you save your scoring before closing the figure?');
    switch answer
        case 'Yes'
            % save variables
            h_msgbox = msgbox('Saving Scores');
            dest = [cd filesep subject_id{z} filesep];
            save(strcat(dest, subject_id{z}, '_Sleep_Scoring.mat'), 'Gold_Standard_Score', '-v7.3');
            close(h_msgbox);

            % print images
            dest = [cd filesep subject_id{z} filesep];
            saveas(hFig,sprintf('%s%s%s_Median_Spectra_features_and_Sleep_Stages.png', dest, filesep, num2str(subject_id{z})));
            savefig(hFig,sprintf('%s%s%s_Median_Spectra_features_and_Sleep_Stages.fig', dest, filesep, num2str(subject_id{z})));

            delete(hFig); %
            return;
        case 'No'
            delete(hFig); %
            return;
        case 'Cancel'
            return;
    end
end

if size(SelectedEpochs,2) == 2
    WhatScore = str2num(evt.Character);
    if strcmp(evt.Character, 'b') & ~isempty(Score_backup_temp)
        %                    % place back saved score
        %                    OnsetRow = find(time_axes >=    SelectedEpochs(1,1),1);
        %                    OffsetRow = find(time_axes <=    SelectedEpochs(1,2),1,'last');
        %                    Gold_Standard_Score(OnsetRow:OffsetRow, 1) = Score_backup_temp;
        %                    Score_backup_temp;
        %                    RefreshHypnoPlotManual(); % refresh plot
    else
        if ~isempty(find([0 1 2 3 5 7] == WhatScore))   % if some reasonable number was hit
                % reassing all epochs selected to selected class
                OnsetRow = find(time_axes >=    SelectedEpochs(1,1),1);
                OffsetRow = find(time_axes <=    SelectedEpochs(1,2),1,'last');

                %Score_backup_temp = Gold_Standard_Score(OnsetRow:OffsetRow, 1);

                switch WhatScore
                    case 0
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 6*ones(1, OffsetRow-OnsetRow+1);  % for plotting Awake is top
                        %case 1 aggregated_Final_Scores(OnsetRow, OffsetRow, 1) = 3; % for plotting one is 4
                    case 1
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 4*ones(1, OffsetRow-OnsetRow+1); % N1 is 4
                    case 2
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 3*ones(1, OffsetRow-OnsetRow+1); % N2 is 3
                    case 3
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 2*ones(1, OffsetRow-OnsetRow+1); % N3 is 2
                    case 5
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 5*ones(1, OffsetRow-OnsetRow+1); % REM is 5
                    case 7
                        Gold_Standard_Score(OnsetRow:OffsetRow) = 7*ones(1, OffsetRow-OnsetRow+1); % Unknown is 7
                    case 9
                        pause('off'); % break paused of execution of the script till scoring is done
                end
            end
            RefreshHypnoPlotManual(); % refresh plot

        end
    end
end


    function getMousePositionOnImage(src, event)
        global SelectedEpochs;

        handles = get(src);
        cursorPoint = get(handles.CurrentAxes, 'CurrentPoint');
        curX = cursorPoint(1,1);
        curY = cursorPoint(1,2);

        %check if mouse clicked outside of axes component
        xLimits = get(handles.CurrentAxes, 'xlim');
        yLimits = get(handles.CurrentAxes, 'ylim');

        %if (curX<min(xLimits)) (curX==min(xLimits))
        %end
        %if (curX>max(xLimits)) (curX==max(xLimits))
        %end

        WhatToChange = size(SelectedEpochs,2)+1; % get index of selected segments (to define if start, end or delete).
        if WhatToChange >= 3
            SelectedEpochs = []; % Erase Selected Epochs
        else
            SelectedEpochs(1, WhatToChange) = curX (1); % Put in x coordinate of click
        end
        SelectedEpochs = sort(SelectedEpochs);

        RefreshHypnoPlotManual();

    end


    function RefreshHypnoPlotManual()
        global SelectedEpochs time_axes Gold_Standard_Score hPlot  what_feat_plot median_feat feature_struct i;
        y_limites = [];

        delete(hPlot);

        % do Delta Beta plot and show candidates of clear wake and clear deep sleep
        hPlot = subplot(3+length(what_feat_plot)+1,1,i+1);
        Db = median_feat(what_feat_plot(4),:)./median_feat(what_feat_plot(end),:);
        DbcritAW = 5;
        DbcritSWS = 90;
        plot(Db);
        hold on;
        plot(find(Db<prctile(Db,DbcritAW)),Db(find(Db<prctile(Db,DbcritAW))),...
            'yo', 'MarkerSize', 5, 'MarkerFaceColor', 'y');
        plot(find(Db>prctile(Db,DbcritSWS)),Db(find(Db>prctile(Db,DbcritSWS))),...
            'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');

        xlim([0 length(median_feat)]);
        title(sprintf('%s over %s', ...
            feature_struct.features_key{what_feat_plot(4)}, feature_struct.features_key{what_feat_plot(end)}));
        set(gca,'Xticklabel',[])
        set(gcf, 'WindowButtonDownFcn', @getMousePositionOnImage); % define mouse click callback

        hold on;

        % plot vertical selection if found
        y_limites = ylim;
        if size(SelectedEpochs,2) == 1
            plot([SelectedEpochs(1,1) SelectedEpochs(1,1)],  [y_limites(1) y_limites(2)], 'g', 'LineWidth', 2); % mark start of selected segment
        elseif size(SelectedEpochs,2) == 2
            plot([SelectedEpochs(1,1) SelectedEpochs(1,1)],  [y_limites(1) y_limites(2)], 'g', 'LineWidth', 2); % mark start of selected segment
            plot([SelectedEpochs(1,2) SelectedEpochs(1,2)],  [y_limites(1) y_limites(2)], 'r', 'LineWidth', 2); % mark start of selected segment
        end

        % plot score horizontal bar for each possible score
        % plot sleep score horizontal bar for each possible behavioral
        % stage
        y_limites = ylim;
        plot(time_axes(Gold_Standard_Score==7), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==7),2)), ...
            'o', 'color',[0,0,0]+0.7, 'LineWidth', 5); % UNKNOWN
        plot(time_axes(Gold_Standard_Score==6), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==6),2)), ...
            'o','color',[1,1,0], 'LineWidth', 5);  % AWAKE
        plot(time_axes(Gold_Standard_Score==5), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==5),2)), ...
            'o','color',[1,0,1], 'LineWidth', 5);  % REM
        plot(time_axes(Gold_Standard_Score==4), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==4),2)), ...
            'o','color',[91, 207, 244] / 255, 'LineWidth', 5);  % N1
        plot(time_axes(Gold_Standard_Score==3), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==3),2)), ...
            'o','color',[0,0,1], 'LineWidth', 5);  % N2
        plot(time_axes(Gold_Standard_Score==2), ...
            y_limites(2)*ones(1, size(Gold_Standard_Score(Gold_Standard_Score==2),2)), ...
            'o','color',[0,0,0], 'LineWidth', 5);  % N1
    end


function hFig_CloseRequestFcn_callback(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
%delete(hObject);
end
