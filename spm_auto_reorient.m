function spm_auto_reorient(p,i_type,p_other,mode,smooth_factor,flags_affine,flags_mi)

% FORMAT spm_auto_reorient(p,i_type,p_other,mode,smooth_factor)
%
% Automatically (but approximately) rigid-body reorient
% a T1 image (or any other usual image modality) in the MNI space,
% i.e. mainly set the AC location and correct for head rotation,
% in order to further proceed with the segmentation/normalisation
% of the image. This uses a non-linear coregistration on a template,
% although the reorientation only applies a rigid-body transform.
% This supports both euclidian (spm_affreg) and joint histogram
% (spm_coreg) methods.
%
% This is useful as group analysis rely on between-subjects coregistration
% which is for most methods, such as in "unified segmentation", sensitive
% to initial conditions (the starting orientation of the image).
%
% If more than 1 image is selected, then they should all be of the
% *same* modality. Moreover each of them will be treated *seperately*.
% Thus you shouldn't probably apply auto-reorient on a whole fMRI time
% series! In the case of an fMRI time series, use the mean MRI (or
% 1st MRI depending on what you choose to be the volume of reference) as 1st
% argument and put all the other images in a cell in the 2rd argument (see
% here under).
%
% If mode 'mi' is selected, the origin will also be changed to match AC.
%
% It is advised to check (and fix if necessary) manually the result.
%
% IN:
% - p       : filename or list of filenames of images to reorient (as `ls` returns).
%             For 4D nifti files, please select only the first volume, and not the others (they will also be reoriented).
% - i_type  : template image type 'T1group' (default), 'T1canonical', 'T1', 'T2', 'PET', 'EPI',...
%             i.e. any of the templates provided by SPM. 'T1group' is an average computed from
%             normalized T1 images from 10 subjects with intensity normalization and without skull
%             stripping using CAT12 (rm* file), 'T1canonical' is the T1 brain image of a single subject
%             as provided with SPM. Note that you can adjust the respective template if you want to tweak
%             the target realignment to your liking. Special option: can also be the path to a nifti file
%             (this allows cross-modality coregistration, no smoothing is applied here then, in this case
%             it is advised to use mode 'mi' only).
% - p_other : cell array of filenames of other images to be reoriented as
%             the corresponding p image. Should be of same length as p, or
%             left empty (default).
% - mode    : coregister using the old 'affine' euclidian method, or the new 'mi' Mutual Information on Joint Histogram method or 'both' (first affine then mi) (default)
% - smooth_factor : smoothing kernel (isotropic) for the affine coregistration. Default: 20. Usually, a big kernel helps in coregistering
%             to template, particularly for brain damaged patients, but might also help with healthy volunteers.
%             However, a too big kernel will also result in suboptimal coregistration. 20 is good for T1.
% - flags_affine: provide your custom flags for the affine coregistration
% - flags_mi    : provide your custom flags for the mutual information coregistration
%
% OUT:
% - the header of the selected images is modified, so are the other images
%   if any were specified.
%__________________________________________________________________________
% v1.3.4
% Copyright (C) 2011 Cyclotron Research Centre
% Copyright (C) 2019-2020 Stephen Karl Larroque, Coma Science Group, GIGA-Consciousness, University & Hospital of Liege
%
% Code originally written by Carlton Chu, FIL, UCL, London, UK
% Modified and extended by Christophe Phillips, CRC, ULg, Liege, Belgium
% Updated and extended by Stephen Karl Larroque, Coma Science Group, GIGA-Consciousness, University & Hospital of Liege, Belgium
%
% Licensed under GPL (General Public License) v2

%% Check inputs
if nargin<1 || isempty(p)
    p = spm_select(inf,'image','Select nifti files to reorient');
end
if iscell(p), p = char(p); end
Np = size(p,1);

if nargin<2 || isempty(i_type)
    i_type = 'T1group';
end
if iscell(i_type), i_type = char(i_type); end
if size(i_type, 1) ~= Np
    error('Wrong number of template images, does not match the number of source images to reorient!');
end

if nargin<3 || isempty(p_other)
    p_other = [];
end
if ischar(p_other)
    % p_others should be a cellarray of chararrays, so with one such chararray per input p (so that we can provide a list of images to reorient)
    p_other = {p_other};
end
if ~isempty(p_other) & (numel(p_other)~= Np)
    error('Wrong number of other images to reorient, does not match the number of source images to reorient!');
end

if nargin<4 || isempty(mode)
    mode = 'both';
end

if nargin<5 || isempty(smooth_factor)
    smooth_factor = 20;
end

if nargin<6 || isempty(flags_affine)
    flags_affine = [];
end

if nargin<7 || isempty(flags_mi)
    flags_mi = [];
end

%% specify template
switch lower(i_type)
    case 't1',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','T1.nii');
    case 't2',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','T2.nii');
    case 'epi',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','EPI.nii');
    case 'pd',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','PD.nii');
    case 'pet',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','PET.nii');
    case 'spect',
        tmpl = fullfile(spm('dir'),'toolbox','OldNorm','SPECT.nii');
    case 't1canonical',
        tmpl = fullfile(spm('dir'),'canonical','single_subj_T1.nii');
    case 't1group',
        tmpl = fullfile(spm('dir'),'canonical','T1_template_CAT12_rm_withskull.nii');  % you need to add this file into spm/canonical
        if ~exist(tmpl, 'file') == 2  % if template cannot be found in spm folder, try to look locally, in same folder as current script
            % Build the path to current script (because pwd is unreliable)
            scriptpath = mfilename('fullpath');
            scriptdir = fileparts(scriptpath); % get the parent directory of the current script
            tmpl = fullfile(scriptdir, 'T1_template_CAT12_rm_withskull.nii');  % this file needs to be in the same folder as this script
            if ~exist(tmpl, 'file') == 2
                error('Cannot find template t1group, please make sure the nifti file is at the appropriate place (see readme)')
            end %endif
        end %endif
    otherwise,
        if exist(i_type(1,:), 'file') == 2
            % The template is directly a file, we use it as a template (can be used to coregister across modalities, eg EPI BOLD on T1)
            tmpl = 'file';
        else
            error('Unknown template image type')
        end
end

% AFFINE COREGISTRATION
M_aff_mem = {};
if strcmp(mode,'affine') | strcmp(mode,'both')
    fprintf('Affine reorientation, please wait...\n');
    % Configure coregistration to template (will be the basis of the reorientation)
    if ~isempty(flags_affine)
        flags = flags_affine
    else
        flags.sep = 5;  % sampling distance. Reducing this enhances a bit the reorientation but significantly increases processing time.
        flags.regtype = 'mni';  % can be 'none', 'rigid', 'subj' or 'mni'. On brain damaged patients, 'mni' seems to give the best results (non-affine transform), but we don't use the scaling factor anyway. See also a comparison in: Liu, Yuan, and Benoit M. Dawant. "Automatic detection of the anterior and posterior commissures on MRI scans using regression forests." 2014 36th Annual International Conference of the IEEE Engineering in Medicine and Biology Society. IEEE, 2014.
    end %endif

    %% Treat each image p at a time
    for ii = 1:Np
        % Load template image
        if strcmp(tmpl, 'file')
            Vtemplate = spm_vol(i_type(ii,:));
        else
            Vtemplate = spm_vol(tmpl);
        end %endif
        % Load source image to reorient to template
        source = strtrim(p(ii,:));
        Vsource = spm_vol(source);
        % smooth to ease coregistration to template
        Vsourcesmoothed = zeros(Vsource.dim(1:3));  % prevent spm_smooth() from saving the smoothing back to the file, by creating a temporary variable where to store the smoothed image
        spm_smooth(Vsource,Vsourcesmoothed,[smooth_factor smooth_factor smooth_factor]);  % TODO: should update to spm_smoothkern()? Check spm_realign()
        % put the smoothed data back to the original struct, from https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1808&L=spm&P=R27983&1=spm&9=A&I=-3&J=on&d=No+Match%3BMatch%3BMatches&z=4 and https://github.com/spm/spm12/blob/r7219/spm_spm.m#L522
        Vsource.dat = Vsourcesmoothed;
        Vsource.dt = [spm_type('float64') spm_platform('bigend')];  % necessary to make the data readable in-memory
        Vsource.pinfo = [1 0 0]';  % necessary to make the data readable in-memory
        % estimate reorientation
        [M, scal] = spm_affreg(Vtemplate,Vsource,flags);
        M3 = M(1:3,1:3);
        [u s v] = svd(M3);
        M3 = u*v';
        M(1:3,1:3) = M3;
        % Memorize to apply on other images later
        M_aff_mem{ii} = M;
        % Reload source image to apply the transform on it
        N = nifti(source);
        N.mat = M*N.mat;
        % Save the transform into nifti file headers
        create(N);
    end %endfor
end %endif

% MUTUAL INFORMATION COREGISTRATION
M_mi_mem = {};
if strcmp(mode,'mi') | strcmp(mode,'both')
    fprintf('Mutual information reorientation, please wait...\n');
    % Configure coregistration
    if ~isempty(flags_mi)
        flags2 = flags_mi;
    else
        flags2.cost_fun = 'ecc';  % ncc works remarkably well, when it works, else it fails very badly... Also ncc should only be used for within-modality coregistration (TODO: test if for reorientation it works well, even on very damaged/artefacted brains?)
        flags2.tol = [0.02, 0.02, 0.02, 0.001, 0.001, 0.001, 0.01, 0.01, 0.01, 0.001, 0.001, 0.001];  % VERY important to get good results, these are defaults from the GUI
    end
    %% Treat each image p at a time
    for ii = 1:Np
        % Load template image
        if strcmp(tmpl, 'file')
            Vtemplate = spm_vol(i_type(ii,:));
        else
            Vtemplate = spm_vol(tmpl);
        end %endif
        % Load source image to reorient to template
        % NB: no need for smoothing here since the joint histogram is smoothed
        source = strtrim(p(ii,:));
        Vsource = spm_vol(source);
        % Estimate reorientation from source image to reference (structural) image
        M_mi = spm_coreg(Vtemplate,Vsource,flags2);
        % Memorize to apply on other images later
        M_mi_mem{ii} = M_mi;
        % apply it on source image
        N = nifti(source);
        N.mat = spm_matrix(M_mi)\N.mat;
        % Save the transform into nifti file headers
        create(N);
    end %endfor
end %endif

% Apply the reorientation transform onto other images (if specified), without recalculating, so that we keep motion information if any
if ~isempty(p_other)
    fprintf('Applying transform to other images...\n');
    for ii = 1:Np
        % Load the appropriate transforms
        if strcmp(mode,'affine') | strcmp(mode,'both'), M = M_aff_mem{ii}; end
        if strcmp(mode,'mi') | strcmp(mode,'both'), M_mi = M_mi_mem{ii}; end
        % For each other image
        for jj = 1:size(p_other{ii},1);
            % Get file path
            if iscell(p_other{ii})
                source_other = strtrim(p_other{ii}{jj});
            elseif ischar(p_other{ii})
                source_other = strtrim(p_other{ii}(jj,:));
            else
                error('Malformatted p_other, please check the structure used');
            end %endif
            if ~isempty(source_other) && ~strcmp(source,source_other)  % If filepath is empty or same as source functional, just skip
                % Load volume
                N = nifti(source_other);
                if strcmp(mode,'affine') | strcmp(mode,'both')
                    % Apply affine transform
                    N.mat = M*N.mat;
                end %endif
                if strcmp(mode,'mi') | strcmp(mode,'both')
                    % Apply Mutual Information rigid-body transform
                    N.mat = spm_matrix(M_mi)\N.mat;
                end %endif
                % Save the transform into nifti file headers
                create(N);
            end %endif
        end %endfor
    end %endfor
end %endif

fprintf('Automatic reorientation done.\n');

end %endfunction


% == Main test ==
% p = spm_select(1,'image')
% pt = spm_select(Inf,'image'); p_other = {pt}
% i_type = []; % use default
% spm_auto_reorient(p,i_type,p_other)
