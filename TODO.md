TODO
====

* Multistart: save MI histogram global score (as calculated by SPM for optimization) and randomly rotate head and try again the reorientation/coregistration, and see if it's better. Should allow to fix issue when converging to a flipped orientation (eg, nose on the opposite side).
* Optimized multistart: the SPM coregistration algorithms can be fundamentally defined as local search algorithms. Currently, the step rate is fixed, but it could be dynamically optimized and restarted when necessary to optimize convergence to the global optimum.
  See also:
  Hickernell, F. J., & Yuan, Y. X. (1997). A simple multistart algorithm for global optimization.
  György, A., & Kocsis, L. (2011). Efficient multi-start strategies for local search algorithms. Journal of Artificial Intelligence Research, 41, 407-444.
* Pre-reorientation and pre-coregistration by center of mass: instead of using OldNorm coreg function to do an euclidian coregistration, which mainly serves the purpose of translating enough to overlap the brain on the template, directly compute the center of mass of thresholded brain to remove background noise, this will be faster to translate and more robust (as sometimes the step is not enough to translate the brain if there is a very big distance, although this is very rare). Then it would continue onto the Mutual Information coregistration, which is great for rotation.
* Set origin explicitly, either at the beginning (before applying the pre-coregistration step), and/or at the end to increase the likelihood that the cursor is on the AC. For inspiration, can look at [Fumio Yamashita's script](https://web.archive.org/web/20170704031721/http://www.nemotos.net/scripts/setorigin_center.m), or its [reimplementation by K. Nemoto](https://web.archive.org/web/20180727093129/http://www.nemotos.net/scripts/acpc_coreg.m).
* Unsharp mask: use [nii_unsharpmask.m](https://github.com/rordenlab/spmScripts/blob/master/nii_unsharpmask.m) as a preprocessing step to better reorient/coregister (only for reorientation step, not the first translation step). See also details on [MRIcroGL website](https://www.mccauslandcenter.sc.edu/mricrogl/beta-features).
