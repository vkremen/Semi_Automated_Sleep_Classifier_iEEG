% [fdata, fdesc] =  feature_extraction(x, fsamp, segm_size, fbands) 
%
% INPUT
% x:            input signal
% fsamp:        sample frequency
% segm_size:    segment size in seconds
% fbands:       frequency bands for PSD in Hz: [f1_start f1_end; f2_start f2_end; ... ; fn_start fn_end]
%
% OUTPUT
% fdata:        list of computed features; size: <number of features> x <number of segments>
% fdesc:        feature labels; size: <number of features> x <1>

% Original script made by Vaclav Gerla and modified by Vaclav Kremen, 
% CIIRC, CTU in Prague, Czech Republic, 2018
%
%
% Copyright (c) 2017-2018, Czech Technical University in Prague, Czech Republic & Mayo Foundation for Medical Education and Research (MFMER), 
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


function[fdata, fdesc] =  feature_extraction(x, fsamp, segm_size, fbands)

%% SEGMENTATION

xbuffered = buffer(x, round(fsamp * segm_size));

%% FINAL LIST OF FEATURES
nfeatures = 3 * size(fbands, 1) + 3;
fdata = zeros(nfeatures, size(xbuffered , 2));
fdesc = cell(nfeatures, 1);
forder = 1;

%% PSD
N = size(xbuffered,1);
xdft = fft(xbuffered);
xdft = xdft(2:round(N/2+1), :);
psdx = (1/(fsamp*N)) * abs(xdft).^2;
psdx(isinf(psdx)) = NaN;

%% FREQ. BANDS
fbands_scaled = round(fbands * segm_size);
fmin = min(fbands(:));
fmax = max(fbands(:));
fmin_scaled = min(fbands_scaled(:));
fmax_scaled = max(fbands_scaled(:));

%% SPECTRAL ENTROPY OF WHOLE SPECTRUM (from fmin to fmax)
for i = 1 : size(psdx, 2) 
    fdata(forder, i) = wentropy(psdx(fmin_scaled : fmax_scaled, i), 'shannon');
end
fdesc{forder} = sprintf('SPECTRAL ENTROPY %.1f - %.1f Hz', fmin, fmax);
forder = forder + 1;
    
%% MEAN DOMINANT FREQUNECY (MDF)
freq_axis = 1 : size(psdx, 1);
freq_axis = freq_axis / size(psdx, 1);
freq_axis = freq_axis * (fsamp/2);
[~, min_position] = min(abs(freq_axis - fmin));
[~, max_position] = min(abs(freq_axis - fmax));
freq_axis = freq_axis(min_position : max_position);
fdata(forder, :) = meanfreq(psdx(fmin_scaled : fmax_scaled, :), freq_axis);
fdesc{forder} = 'MEAN DOMINANT FREQUENCY (MDF)';
forder = forder + 1;

%% SPECTRAL MEDIAN FREQUENCY (SMF)
fdata(forder, :) = medfreq(psdx(fmin_scaled : fmax_scaled, :), freq_axis);
fdesc{forder} = 'SPECTRAL MEDIAN FREQUENCY (SMF)';
forder = forder + 1;

%% FEATURE EXTRACTION
fullpsdx = nansum(psdx(fmin_scaled : fmax_scaled, :)); % for computing of relative power
for i = 1 : size(fbands_scaled, 1)
    subpsdx = psdx(fbands_scaled(i, 1) : fbands_scaled(i, 2), :);
       
    
    %% MEAN PSD
    fdata(forder, :) = nanmean(subpsdx);
    fdesc{forder} = sprintf('MEAN PSD %.1f - %.1f Hz', fbands(i,1), fbands(i,2));
    forder = forder + 1;
    
    %% REL PSD
    fdata(forder, :) = nansum(subpsdx) ./ fullpsdx;
    fdesc{forder} = sprintf('REL PSD %.1f - %.1f Hz', fbands(i,1), fbands(i,2));
    forder = forder + 1;
    
    %% SPECTRAL ENTROPY
    for k = 1 : size(subpsdx, 2) 
        fdata(forder, k) = wentropy(subpsdx(:, k), 'shannon');
    end
    fdesc{forder} = sprintf('SPECTRAL ENTROPY %.1f - %.1f Hz', fbands(i,1), fbands(i,2));
    forder = forder + 1;
end