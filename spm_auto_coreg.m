function spm_auto_coreg(struct,func,others,mode,modality)

% FORMAT spm_auto_coreg(struct,func,others,mode,modality)
%
% Function to coregister functional (or other modalities) to structural images
% using rigid-body transform via either an euclidian coregistration or a Mutual Information calculation on Joint Histograms.
% Works on SPM12.
%
% It is advised to check (and fix if necessary) manually the result (using CheckReg).
%
% IN:
% - struct      : filename of the reference structural image
% - func        : filename of the source functional image (that will be coregistered to structural image). In general, this should be the first BOLD volume (to register to the first volume). For 4D NIfTI, select the first volume such as 'bold.nii,1', and do NOT select other volumes in others, as SPM will anyway coregister all volumes.
% - others      : list of filenames of other functional (or other modality) images to coregister with the same transform as the source image (format similar to what `ls` returns). For 4D NIfTI, if you selected the first volume in func, do NOT specify the rest of the volumes here.
% - mode        : coregister using the old 'affine' method, or the new 'mi' Mutual Information method (default) or 'both' (first affine then mi)
% - modality    : modality of the 'func' image, can be any type supported by SPM: 't1', 't2', 'epi', 'pd', 'pet', 'spect'. Default: 'epi'.
%
% OUT:
% - the voxel-to-world part of the headers of the selected source (func) and others images is modified.
%__________________________________________________________________________
% v1.0.7
% License: GPL (General Public License) v2
% Copyright (C) 2019-2020 Stephen Karl Larroque - Coma Science Group - GIGA-Consciousness - University & Hospital of Liege

%% Check inputs
if nargin<1 || isempty(struct)
    struct = spm_select(1,'image','Select structural image');
end
if nargin<2 || isempty(func)
    func = spm_select(1,'image','Select 1st functional image (for 4D NIfTI select 1st volume only)');
end
if iscell(struct), struct = char(struct); end
if iscell(func), func = char(func); end

% If functional image is a 4D nifti, we autoselect only the first volume and skip "others", as this is a source of error
skipothers = false;
if is4D(func)
    allfunc = expandhelper(func);
    func = allfunc{1};
    others = [];
    skipothers = true;
end

if nargin<3 & ~skipothers
    others = spm_select(Inf,'image','Select other functional images (can be empty, do not select other volumes in 4D NIfTI)');  % to ease usage by non programmers, most will want to apply the transform on other EPI images too
elseif isempty(others)
    others = [];
end
if ~isempty(others) & iscell(others), others = char(others); end

if nargin<4 || isempty(mode)
    mode = 'mi';
end

if nargin<5 || isempty(modality)
    modality = 'epi';
end

% PRE-COREGISTRATION ON TEMPLATE
% First, coregister on template brain
% This greatly enhance the results, particularly if the structural was auto-reoriented on MNI (using github.com/lrq3000/spm_auto_reorient) so that the template EPI is in the same space as the structural, hence why this enhances the results
% If this is not done, most often the coregistration will get the rotation right but not the translation
fprintf('Pre-coregistration on %s template, please wait...\n', modality);
spm_auto_reorient(func, modality, others, mode);
if strcmp(mode, 'precoreg')
    % Useful for debugging, we can only do the precoregistration and then leave
    return
end
% COREGISTRATION ONTO STRUCTURAL
fprintf('Coregistration to structural, please wait...\n');
% if selected by gui (spm_select), then there will be a frame number, then we need to extract it from the path
[pth,nam,ext,n] = spm_fileparts(struct);
structpath = fullfile(pth,[nam ext]);
% configure flags to optimize coregistration
flags_mi.cost_fun = 'ecc';  % ncc works remarkably well, when it works, else it fails very badly, particularly for between-modalities coregistration... ecc works better on some edge cases than mi and nmi for coregistration
flags_mi.tol = [0.1, 0.1, 0.02, 0.02, 0.02, 0.001, 0.001, 0.001, 0.01, 0.01, 0.01, 0.001, 0.001, 0.001, 0.0002, 0.0001, 0.00002];  % VERY important to get good results. This defines the amount of displacement tolerated. We start with one single big step allowed, to correct after the pre-coregistration if it somehow failed, and then we use the defaults from SPM GUI with progressively finer steps, repeated 2 times (multistart approach).
flags_mi.fwhm = [1, 1];  % reduce smoothing for more efficient coregistering, since the pre-coregistration normally should have placed the brain quite in the correct spot overall. This greatly enhances results, particularly on brain damaged subjects.
flags_mi.sep = [4 2 1];  % use [4 2 1] if you want to use a finer grained step at the end at 1mm, this can help to get more precise coregistration in some cases but at the cost of a quite longer computing time, this greatly help for a few hard cases
% coregister to structural
spm_auto_reorient(func, structpath, others, mode, [], [], flags_mi);

fprintf('Automatic coregistration done.\n');

end %endfunction


% == AUXILIARY FUNCTIONS ==
function outfiles = expandhelper(niftifiles)
% expandhelper(files)
% Given a list of files, automatically detect 4D nifti files and return an expanded list (where each entry = one volume)
% This script needs SPM in the path (to open nifti files)
% by Stephen Karl Larroque, 2019, Coma Science Group, GIGA-Consciousness, University & Hospital of Liege
% v1.0.0
%

if numel(niftifiles) > 0
    outfiles = cellstr(expand_4d_vols(char(niftifiles)));
else
    outfiles = [];
end %endif

end % endfunction

function res = is4D(file)
    nbframes = spm_select_get_nbframes(file);
    if nbframes > 1
        res = true;
    else
        res = false;
    end
end

function n = spm_select_get_nbframes(file)
% spm_select_get_nbframes(file) from SPM12 spm_select.m (copied here to be compatible with SPM8)
    N   = nifti(file);
    dim = [N.dat.dim 1 1 1 1 1];
    n   = dim(4);
    fclose('all'); % don't forget to close, else it might get stuck! Else you will get the infamous "Cant map view of file.  It may be locked by another program."
end

function out = expand_4d_vols(files)
% expand_4d_vols(nifti)  Given a path to a 4D nifti file, count the number of volumes and generate a list of all volumes
% updated by Stephen Larroque (LRQ3000) to expand multiple files
% this is an alternative to adding to the batch after named file selector the module: SPM -> Util -> Expand image frames or matlabbatch{2}.spm.util.exp_frames. This is necessary for VBM apply deformations (but not SPM steps), else you will get error Failed 'Apply Deformations (Many images)' Error using ==> inv Too many input arguments.
    out = {}; % use a cell because we will get strings of variable lengths (so can't use char)
    for i=1:size(files,1)
        s = files(i,:);
        nb_vols = spm_select_get_nbframes(s);
        out = [ out , cellstr(strcat(repmat(s, nb_vols, 1), ',', num2str([1:nb_vols]')))' ];
    end
    % Convert the cell to a char array
    out = char(out);
end
