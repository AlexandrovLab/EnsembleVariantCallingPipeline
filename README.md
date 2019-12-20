# EnsembleVaraintCallingPipeline
Built in December 2019, updated version of the previous Consensus Variant Calling pipeline


Run run_env anywhere to create the scripts.

In the output directory, a jobs/ directory should be created.

Please submit jobs step by step, do not move to the next step until the previous step is finished and verified. 

1. Both the *Nalign_1.pbs* and *Talign_1.pbs* under jobs/align/
2. The *targetInterval.pbs* under jobs/refine/ (when this is finished, the corresponding *Nrefine_2.pbs* and *Trefine_2.pbs* will be submitted automatically)
3. Scripts under jobs/pon/, jobs/strelka/ and jobs/varscan/ can all be submitted simutaniously at this point.
