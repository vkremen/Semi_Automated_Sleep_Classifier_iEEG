%% Modified script for Analysis of University of Wisconsin Madison data
%
% Modify subject_id on row: 42 accordingly and run the script
%
% The script automates extraction of the data and semi-automated sleep
% scoring of data originally prepared in University of Wisconsin at Madison
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


clc;
clear all;

% example how to define subject_id in here
% subject_id = {'409_041_0001' '409_041_0002' '369_074_0000' '384_038_0000'...
% '399_083_0000' '403_017_0000' '384_038_0001' '384_038_0002' '403_017_0001' '403_017_0002'}; 
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
    
   