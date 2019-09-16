%% Modified script for Analysis of University of Wisconsin Madison data

clc;
clear all;

% subject_id = '372_031_0001'; % file name, done
% subject_id = '376_049_0000'; % file name, done
% subject_id = '409_041_0000'; % file name, done - not good sleep
% subject_id = {'409_041_0001' '409_041_0002' '369_074_0000' '384_038_0000'...
% '399_083_0000' '403_017_0000' '384_038_0001' '384_038_0002' '403_017_0001' '403_017_0002'}; % done
subject_id = {};

    %% run to extract data from UW structure to one matrix and save
%     % it needs to have electrodes data in Matlab Workspace in folder subject_id/subject_id
    for i = 1 : length(subject_id)
        ExtractUWdata(subject_id{i});
    end
    
    %% run to identify good electrode for scoring 
    % load data from saved file xxx_data.mat
    %
    % If running for more patients, you can put breakpoint into
    % Assess_the_sleep to line appx. 227:
    % "%% ----- BreakPoint -----
    % one can put braekpoint here to do manual scoring of sleep"
    % this allows you to be able to analyze figures before progressing to
    % next patient
    for i = 1 : length(subject_id)
        Assess_the_sleep(subject_id{i}); % extract wavelets to select electrodes using one day data
    end
    
   