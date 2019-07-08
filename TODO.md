TODO
====

* Multistart: save MI histogram global score (as calculated by SPM for optimization) and randomly rotate head and try again the reorientation/coregistration, and see if it's better. Should allow to fix issue when converging to a flipped orientation (eg, nose on the opposite side).
* Optimized multistart: the SPM coregistration algorithms can be fundamentally defined as local search algorithms. Currently, the step rate is fixed, but it could be dynamically optimized and restarted when necessary to optimize convergence to the global optimum.
See also:
Hickernell, F. J., & Yuan, Y. X. (1997). A simple multistart algorithm for global optimization.
György, A., & Kocsis, L. (2011). Efficient multi-start strategies for local search algorithms. Journal of Artificial Intelligence Research, 41, 407-444.
* Unsharp mask: use [nii_unsharpmask.m](https://github.com/rordenlab/spmScripts/blob/master/nii_unsharpmask.m) as a preprocessing step to better reorient/coregister (only for reorientation step, not the first translation step). See also details on [MRIcroGL website](https://www.mccauslandcenter.sc.edu/mricrogl/beta-features).
