TODO
====

* Multistart: save MI histogram global score (as calculated by SPM for optimization) and randomly rotate head and try again the reorientation/coregistration, and see if it's better. Should allow to fix issue when converging to a flipped orientation (eg, nose on the opposite side).
* Unsharp mask: use [nii_unsharpmask.m](https://github.com/rordenlab/spmScripts/blob/master/nii_unsharpmask.m) as a preprocessing step to better reorient/coregister (only for reorientation step, not the first translation step). See also details on [MRIcroGL website](https://www.mccauslandcenter.sc.edu/mricrogl/beta-features).
