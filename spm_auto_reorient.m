function spm_auto_reorient(p,i_type,p_other,smooth_factor)

% FORMAT spm_auto_reorient(p,i_type,p_other)
%
% Function to automatically (but approximately) rigib-body reorient
% a T1 image (or any other usual image modality) in the MNI space,
% i.e. mainly set the AC location and correct for head rotation,
% in order to further proceed with the segmentation/normalisation
% of the image. This uses a non-linear coregistration on a template,
% although the reorientation only applies a rigid-body transform.
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
% It is advised to check (and fix if necessary) manually the result.
%
% IN:
% - p       : filename or list of filenames of images to reorient (as `ls` returns)
% - i_type  : image type 'T1group' (default), 'T1canonical', 'T1', 'T2', 'PET', 'EPI',... i.e. any of
%             the templates provided by SPM. 'T1group' is an average computed from normalized T1 images
%             from 10 subjects with intensity normalization and without skull stripping using
%             CAT12 (rm* file), 'T1canonical' is the T1 brain image of a single subject as provided
%             with SPM. Note that you can adjust the respective template if you want to tweak the
%             target realignment to your liking.
% - p_other : cell array of filenames of other images to be reoriented as
%             the corresponding p image. Should be of same length as p, or
%             left empty (default).
% - smooth_factor : smoothing kernel (isotropic). Default: 20. Usually, a big kernel helps in coregistering
%             to template, particularly for brain damaged patients, but might also help with healthy volunteers.
%             However, a too big kernel will also result in suboptimal coregistration. 20 is good for T1.
%
% OUT:
% - the header of the selected images is modified, so are the other images
%   if any were specified.
%__________________________________________________________________________
% Copyright (C) 2011 Cyclotron Research Centre
% Copyright (C) 2019 Stephen Karl Larroque, Coma Science Group, GIGA-Consciousness, University & Hospital of Liege
%
% Code originally written by Carlton Chu, FIL, UCL, London, UK
% Modified and extended by Christophe Phillips, CRC, ULg, Liege, Belgium
% Updated by Stephen Karl Larroque, Coma Science Group, GIGA-Consciousness, University & Hospital of Liege, Belgium

%% Check inputs
if nargin<1 || isempty(p)
    p = spm_select(inf,'image');
end
if iscell(p), p = char(p); end
Np = size(p,1);

if nargin<2 || isempty(i_type)
    i_type = 'T1group';
end

if nargin<3 || isempty(p_other{1}{1})
    p_other = cell(Np,1);
end
if numel(p_other)~= Np
    error('Wrong number of other images to reorient!');
end

if nargin<4 || isempty(smooth_factor)
    smooth_factor = 20;
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
        end %endif
    otherwise, error('Unknown template image type')
end
vg = spm_vol(tmpl);  % get template image

% Configure coregistration to template (will be the basis of the reorientation)
flags.sep = 5;  % sampling distance. Reducing this enhances a bit the reorientation but significantly increases processing time.
flags.regtype = 'mni';  % can be 'none', 'rigid', 'subj' or 'mni'. On brain damaged patients, 'mni' seems to give the best results (non-affine transform), but we don't use the scaling factor anyway. See also a comparison in: Liu, Yuan, and Benoit M. Dawant. "Automatic detection of the anterior and posterior commissures on MRI scans using regression forests." 2014 36th Annual International Conference of the IEEE Engineering in Medicine and Biology Society. IEEE, 2014.

%% Treat each image p at a time
for ii = 1:Np
    % get image, create a temporary file (to avoid permission issues) and smooth to ease coregistration to template
    f = strtrim(p(ii,:));
    spm_smooth(f,'temp.nii',[smooth_factor smooth_factor smooth_factor]);
    vf = spm_vol('temp.nii');
    % estimate reorientation
    [M, scal] = spm_affreg(vg,vf,flags);
    M3 = M(1:3,1:3);
    [u s v] = svd(M3);
    M3 = u*v';
    M(1:3,1:3) = M3;
    % apply it on image p
    N = nifti(f);
    N.mat = M*N.mat;
    create(N);
    % apply it on other images
    No = size(p_other{ii},1);
    for jj = 1:No
        fo = strtrim(p_other{ii}{jj});
        if ~isempty(fo) && ~strcmp(f,fo)
            % allow case where :
            % - noname was passed
            % - name is same as the image used for the reorient
            % => skip
            N = nifti(fo);
            N.mat = M*N.mat;
            create(N);
        end
    end
    % clean up
    delete('temp.nii');
end

end


% % test
% p = spm_select(1,'image')
% pt = spm_select(Inf,'image'); p_other = {pt}
% i_type = []; % use default
% spm_auto_reorient(p,i_type,p_other)
