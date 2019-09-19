%% EXTRACTUWDATA Prepares the data from particular project with University
%       of Wisconsin into a format that can be then processed by Assess_the_sleep
%       function
%
% SYNOPSIS: ExtractUWdata(subject_id);
%
% FUNCTION Extracts signals from matrixes and prepare them 
%       to structure suitable for feature extraction
%
% INPUT It loads the data from file - data file needs 
%       to be in /subject_id/subject_id.mat. Where as subject_id is a
%       string with the folder name: e.g.: '403_017_0002'
%       Input data are in structure:
%           name of electrode - is name of the structure variable loaded
%           from subject_id.mat file
%           el_name.dat - time series of data of electrode el_name
%           el_name.fs - sampling rate of time series data of electrode el_name
%           el_name.chan - number of recording channel of electrode el_name
%           STAGE - score of manual sleep scoring if it was done (if it
%           wasn't done, the variable is missing)
%           STAGE_KEY - description (name) of sleep stages and how they
%           link to numbers and score in STAGE (if it
%           wasn't done, the variable is missing).
%
% OUTPUT It saves the data to /subject_id/subjec_id_data.mat
%       Output data form saved to subject_id_data.mat:
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
function ExtractUWdata(subject_id);

% load the data from file - needs to be in /subject_id/subjec_id.mat
load(sprintf('%s%s%s%s%s.mat', cd, filesep, subject_id, filesep, subject_id));

El_number = [];
El_name ={};
Data =[];
fs =[];
stage = [];
stage_key = {};
var_list =[];
% var_list = evalin('base','who'); % get list of variables from Matlab Workspace
var_list = eval('who'); % get list of variables from Matlab Workspace

% scan through whole list of electrodes and get data, fs and names and
% numbers of electrodes
tic
c=1; % electrode saved, start from 1
for jj = 1:size(var_list,1)
    % read each individual variable if it is LFT electrode get data
    if regexp(var_list{jj,1}, 'LFP')
        %eval(sprintf('%s = evalin(''base'',''%s'');', var_list{jj,1}, var_list{jj,1})); % link Matlab workspace data
        %eval(sprintf('%s = eval(''%s'');', var_list{jj,1}, var_list{jj,1})); % link Matlab workspace data
        eval(sprintf('Data(c,:) = %s.dat;', var_list{jj,1})); % get data for this electrode
        eval(sprintf('fs = %s.fs;', var_list{jj,1})); % get sampling rate
        eval(sprintf('El_number(c) = %s.chan;', var_list{jj,1})); % get channel number
        El_name{c} = var_list{jj,1}; % get channel name
        eval(sprintf('clear %s;', var_list{jj,1}));
        c = c + 1; % increment electrode
    elseif strcmp(var_list{jj,1}, 'STAGE')
        % eval(sprintf('stage = evalin(''base'',''%s'');', var_list{jj,1}));
        eval(sprintf('stage = eval(''%s'');', var_list{jj,1}));
    elseif strcmp(var_list{jj,1}, 'STAGE_KEY') 
        % eval(sprintf('stage_key = evalin(''base'',''%s'');', var_list{jj,1}));
        eval(sprintf('stage_key = eval(''%s'');', var_list{jj,1}));
    end
end

fprintf('Extracted data: %s sec\n', num2str(toc));
tic
dest = [cd filesep subject_id filesep];
save(strcat(dest, subject_id, '_data.mat'), 'El_name', 'El_number', 'Data', 'fs', 'stage', 'stage_key', '-v7.3');
fprintf('Saved data: %s sec\n', num2str(toc));

end