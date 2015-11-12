function spm_auto_reorient(p,i_type,p_other) 

% FORMAT spm_auto_reorient(p,i_type,p_other)
%
% Function to automatically (but approximately) rigib-body reorient
% a T1 image (or any other usual image modality) in the MNI space, 
% i.e. mainly set the AC location and correct for head rotation, 
% in order to further proceed with the segmentation/normalisation 
% of the image.
% This is useful as the "unified segmentation" process is rather 
% sensitive to the starting orientation of the image.
%
% If more than 1 image is selected, then they should all be of the 
% *same* modality. Moreover each of them will be treated *seperately*. 
% Thus you shouldn't probably apply auto-reorient on a whole fMRI time
% series! In the case of an fMRI time series, use the mean MRI as 1st 
% argument and put all th eother images in a cell in the 2rd argument (see
% here under).
%
% IN:
% - p       : filename or list of filenames of images to reorient
% - i_type  : image type 'T1' (default), 'T2', 'PET', 'EPI',... i.e. any of 
%             the templates provided by SPM
% - p_other : cell array of filenames of other images to be reoriented as
%             the corresponding p image. Should be of same length as p, or
%             left empty (default).
%
% OUT:
% - the header of the selected images is modified, so are the other images
%   if any were specified.
%__________________________________________________________________________
% Copyright (C) 2011 Cyclotron Research Centre

% Code originally written by Carlton Chu, FIL, UCL, London, UK
% Modified and extended by Christophe Phillips, CRC, ULg, Liege, Belgium

%% Check inputs
if nargin<1 || isempty(p)
    p = spm_select(inf,'image');
end
if iscell(p), p = char(p); end
Np = size(p,1);

if nargin<2 || isempty(i_type)
    i_type = 'T1canonical';
end

if nargin<3 || isempty(p_other{1}{1})
    p_other = cell(Np,1);
end
if numel(p_other)~=Np
    error('crc:autoreorient','Wrong number of other images to reorient!');
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
    otherwise, error('Unknown image type')
end        
vg = spm_vol(tmpl);
flags.regtype = 'rigid';

%% Treat each image p at a time
for ii = 1:Np
    % get image and smooth
    f = strtrim(p(ii,:));
    spm_smooth(f,'temp.nii',[12 12 12]);
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
