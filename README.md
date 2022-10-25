# `spm_auto_reorient`
A few routines to perform "auto reorient" in SPM.

Setting up the AC-PC and reorienting images is a recurrent issue as the "unified segmentation" process is (can be) sensitive to the starting orientation of the image... So we came up with some automatic solution.
The main function, `spm_auto_reorient.m`, automatically (but approximately) rigib-body reorients a T1 image (or any other usual image modality) in the MNI space, i.e. mainly set the AC location and correct for head rotation, in order to further proceed with the segmentation/normalisation of the image. Note that this relies on a "template matching" principle (as in the old normalize function), you therefore ought to specify the appropriate template/reference image.


The tool can be included in the batching system of SPM12 by 
- adding the `spm_cfg_autoreorient.m` function in to the spm\config sub-directory. Then this module can be included in any processing pipeline;
- overwriting the `spm_cfg.m` with this one, so that the module appears in the SPM\spatial pull-down menu.
See the 'help', for all the details and various options.

Obviously NO guarantee whatsoever that this will work 100% of the times! 
And I have NOT checked when it breaks down in term of rotation angle or displacement. All I can claim is that it does a good job with our data (young and old healthy subjects + AD/PD patients)...

The code was originally written by Carlton Chu (FIL, UCL, London, UK) then modified and extended by Christophe Phillips (Cyclotron Research Centre, University of Liege, Belgium).

For questions or suggestions, contact Christophe Phillips (c.phillips_at_ulg.ac.be).

[![DOI](https://zenodo.org/badge/46079046.svg)](https://zenodo.org/badge/latestdoi/46079046)
