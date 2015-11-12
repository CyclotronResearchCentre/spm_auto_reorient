function autoreor = spm_cfg_autoreorient
% SPM Configuration file for spm_auto_reorient
%_______________________________________________________________________
% Copyright (C) 2011 Cyclotron Research Centre

% Written by C. Phillips, 2011.
% Cyclotron Research Centre, University of Liege, Belgium

% ---------------------------------------------------------------------
% image Image to reorient
% ---------------------------------------------------------------------
image         = cfg_files;
image.tag     = 'image';
image.name    = 'Image';
image.help    = {[...
    'Select here the image(s) that need to be approximately reoriented '...
    'into MNI space.'],[...
    'If more than 1 image is selected, then they should all be of the '...
    '*same* modality. Moreover each of them will be treated '...
    '*seperately*. Thus you shouldn''t probably apply auto-reorient on '...
    'a whole fMRI time series!']}';
image.filter = 'image';
image.ufilter = '.*';
image.num     = [1 Inf];

% ---------------------------------------------------------------------
% imgtype Objective Function
% ---------------------------------------------------------------------
imgtype         = cfg_menu;
imgtype.tag     = 'imgtype';
imgtype.name    = 'Image type';
imgtype.help    = {[...
    'Auto-reorient need to know which modality of image is selected. ',...
    'Select from the list, the template to use.']};
imgtype.labels = {'T1', 'T2', 'PD', 'EPI', 'PET', 'SPECT', 'T1canonical'}';
imgtype.values = {'t1', 't2', 'pd', 'epi', 'pet', 'spect', 't1canonical'}';
imgtype.def    = @(val)spm_get_defaults('autoreor.mod', val{:});

%--------------------------------------------------------------------------
% other Other Images
%--------------------------------------------------------------------------
other         = cfg_files;
other.tag     = 'other';
other.name    = 'Other Images';
other.val     = {{''}};
other.help    = {'These are any images that need to remain in alignment ', ...
    'with the image that is re-oriented. This works in the case of a *single* ',...
    'image selected to be reoriented'};
other.filter  = 'image';
other.ufilter = '.*';
other.num     = [0 Inf];

%---------------------------------------------------------------------
% autoreor Auto-reorient one (or more) image(s) approximately in MNI space
%---------------------------------------------------------------------
autoreor         = cfg_exbranch;
autoreor.tag     = 'autoreor';
autoreor.name    = 'Auto-Reorient';
autoreor.val     = {image imgtype other};
autoreor.help    = {[...
    'Function to automatically (but approximately) rigib-body reorient '...
    'a T1 image (or any other usual image modality) in the MNI '...
    'space, i.e. mainly set the AC location and correct for head '...
    'rotation, in order to further proceed with the segmentation/'...
    'normalisation of the image.'],...
    ['A set of other images can be reoriented along the 1st one. They '...
    'should be spacified as "Other".'],[...
    'This is useful as the "unified segmentation" process is rather '...
    'sensitive to the starting orientation of the image.']
    }';
autoreor.prog = @spm_run_autoreorient;
autoreor.vout = @vout_autoreor;

%------------------------------------------------------------------------
function dep = vout_autoreor(job) %#ok<*INUSD>
dep(1)            = cfg_dep;
dep(1).sname      = 'Auto-reoriented Image(s)';
dep(1).src_output = substruct('.','afiles');
dep(1).tgt_spec   = cfg_findspec({{'filter','image','strtype','e'}});
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function out = spm_run_autoreorient(varargin)
job = varargin{1};
spm_auto_reorient(job.image, job.imgtype, {job.other});
if numel(job.other(:))==1 && isempty(job.other{1})
    PO = job.image(:);
else
    PO = [job.image(:); job.other(:)];
end
out.afiles = spm_select('expand',PO);
return;
%------------------------------------------------------------------------
