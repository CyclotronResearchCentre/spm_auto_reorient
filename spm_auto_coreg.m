function spm_auto_coreg(struct,func,others,mode,modality)

% FORMAT spm_auto_coreg(struct,func,others,mode,modality)
%
% Function to coregister functional (or other modalities) to structural images
% using rigid-body transform via a Mutual Information calculation on Joint Histograms.
% Works on SPM12.
%
% It is advised to check (and fix if necessary) manually the result (using CheckReg).
%
% IN:
% - struct      : filename of the reference structural image
% - func        : filename of the source functional image (that will be coregistered to structural image). In general, this should be the first BOLD volume (to register to the first volume)
% - others      : list of filenames of other functional (or other modality) images to coregister with the same transform as the source image (format similar to what `ls` returns)
% - mode        : coregister using the old 'affine' method, or the new 'mi' Mutual Information method (default) or 'both' (first affine then mi)
% - modality    : modality of the 'func' image, can be any type supported by SPM: 't1', 't2', 'epi', 'pd', 'pet', 'spect'. Default: 'epi'.
%
% OUT:
% - the voxel-to-world part of the headers of the selected source (func) and others images is modified.
%__________________________________________________________________________
% v1.0.3
% License: GPL (General Public License) v2
% Copyright (C) 2019 Stephen Karl Larroque - Coma Science Group - GIGA-Consciousness - University & Hospital of Liege

%% Check inputs
if nargin<1 || isempty(struct)
    struct = spm_select(1,'image','Select structural image');
end
if nargin<2 || isempty(func)
    func = spm_select(1,'image','Select first functional image');
end
if iscell(struct), struct = char(struct); end
if iscell(func), func = char(func); end

if nargin<3
    others = spm_select(Inf,'image','Select other functional images');  % to ease usage by non programmers, most will want to apply the transform on other EPI images too
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
% COREGISTRATION ONTO STRUCTURAL
fprintf('Coregistration to structural, please wait...\n');
% if selected by gui (spm_select), then there will be a frame number, then we need to extract it from the path
[pth,nam,ext,n] = spm_fileparts(struct);
structpath = fullfile(pth,[nam ext]);
% coregister to structural
spm_auto_reorient(func, structpath, others, mode);

fprintf('Automatic coregistration done.\n');

end %endfunction
