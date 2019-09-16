% Extract signals from matrixes and prepare them to structure suitable for feature extraction
%
% It loads the data from file - data file needs to be in /subject_id/subjec_id.mat.
%
% It saves the data to /subject_id/subjec_id_data.mat

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