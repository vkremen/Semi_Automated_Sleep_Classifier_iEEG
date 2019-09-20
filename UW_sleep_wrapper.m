%% UW_SLEEP_WRAPPER Wrapper script that jumps through the number of defined directories Extract University of Wisconsin data by ExtractUWdata script to format that can be taken by Assess_the_sleep function to semi-automatically score the sleep from EEG.
%
% SYNOPSIS: UW_sleep_wrapper()
%
% INPUT List of directory names in format: subject_id = {'409_041_0001'
%       '409_041_0002' '369_074_0000' '384_038_0000'}; needs to be in
%       Matlab Workspace as global variable. Variable z needs to be in
%       Matlab Workspace as global variable too and can be set either as
%       empty (z=[];).
%       It requires subfolders with the same names as defined above containing data file 
%       with subject_id.mat name with raw data.
% 
% The script automates extraction of the data and semi-automated sleep
%       scoring of data originally prepared for a particular projects with 
%       University of Wisconsin at Madison. It sequentially runs data extraction from 
%       UW format for each subject defined in subject_id and then runs Assess_the_sleep for each subject. 
%       The data extraction routines can be addopted for any data format and 
%       produce data structure that can be then taken by Assess_the_sleep.m function.
%
% Copyright 2019. Mayo Foundation for Medical Education and Research (MFMER). All rights reserved. Academic, non-commercial use of this software is allowed with expressed permission of the developers. MFMER and the developers disclaim all implied warranties of merchantability and fitness for a particular purpose with respect to this software, its application, and any verbal or written statements regarding its use. The software may not be distributed to third parties without consent of MFMER. Use of this software constitutes acceptance of these terms and acceptance of all risk and liability arising from the software?s use.
%
% Contributors: Vaclav Kremen.
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
function UW_sleep_wrapper()
global subject_id z;
%% run to extract data from UW structure to one matrix and save
% it needs to have electrodes data in Matlab Workspace in folder subject_id/subject_id.mat
    for z = 1 : length(subject_id)
        ExtractUWdata(subject_id{z}); % prepare data for sleep scoring
    end
    
    for z = 1 : length(subject_id)
        Assess_the_sleep(); % do a sleep scoring
    end
    
   