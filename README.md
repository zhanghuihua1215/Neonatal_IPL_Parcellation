# Neonatal_IPL_Parcellation
Custom scripts and brain atlas for the neonatal IPL parcellation paper.
This project provides an advanced analysis pipeline for multi-modal brain imaging (structural/functional) in neonates (dHCP dataset) and adults (HCP dataset). It covers surface preprocessing, multi-modal parcellation fusion, independent component analysis (ICA), functional/structural fingerprint extraction, lateralization statistical modeling, and MSM-based cross-age surface registration.

# Core Modules and Workflows 

# 1. Preprocessing & Surface Smoothing
**surface_normalization_averaging.sh**: Performs Log transformation and normalization on cortical surface metric files, and computes multi-subject group-average surface maps. 
**volume_to_surface_s4mm.sh**: Projects voxel-space functional images to individual midthickness surfaces and applies a 4mm FWHM surface Gaussian smoothing kernel. 

# 2. Parcellation Fusion & Group-level Atlases 
**group_fusion.py**: Resolves multi-modal regional conflicts using a "consensus-first + neighborhood voting" algorithm based on structural (T2w) and functional (fMRI) parcellation results, generating high-quality fusion parcellation atlases.
**group_level_optimality.m**: Computes group-level Dice coefficients, hemisphere symmetry indices, and comprehensive optimality scores across different cluster numbers k to assist in determining the optimal partition scheme. 
**mpm_calculation.sh**: Computes the Maximum Probability Map (MPM) and extracts core partition boundaries. 

# 3. Independent Component Analysis (ICA) & Network Definition
**individual_nii_preparation.m**: Concatenates and converts left and right hemisphere surface data into 4D NIfTI pseudo-format files, compatible with the FSL platform. 
**melodic_ica_run.sh**: Calls FSL melodic to execute Group ICA (integrating MIGP dimensionality reduction and variance normalization). 
**split_ica_components.m**: Splits aggregate components into independent left and right hemisphere GIFTI (.func.gii) files. 
**winner_takes_all.m**: Applies the "Winner-Takes-All" (WTA) algorithm to selected functional networks, removes spatial overlaps, generates non-overlapping 11-network templates, and converts them into binary masks. 

# 4. Fingerprints & Lateralization Stats 
**extract_fc_fingerprint.m**: Extracts the average functional connectivity (FC) strength of 4 functional subregions (C1-C4) across 11 large-scale functional networks, generating a fingerprint matrix.
**extract_sc_fingerprint.m**: Extracts structural connection (SC) projection strength fingerprints.
**lateralization_ttest.py**: Performs paired-sample t-tests on left/right hemisphere fingerprints, applies Benjamini-Hochberg (FDR) correction for multiple comparisons, and calculates lateralization directions.
**generate_lateralization_tmap.m**: Maps significant lateralization T-values back to the surface space to generate bilateral lateralization T-maps. 

# 5. Visualization 
**plot_radar_fingerprint.py**: Generates 2×4 sub-plotted radar charts to visually compare left and right hemisphere network functional fingerprints across different subregions.
**plot_lateralization_heatmap.py**: Generates multi-subregion vs. multi-network lateralization heatmaps with dynamically overlaid significance asterisks. 
**plot_lateralization_barplot.py**: Generates grouped bar charts with error bars and significance markers to intuitively display left/right lateralization difference values (Diff). 

# 6. MSM Registration: Neonate to Adult 
**resample_adult_sulc.sh**: Resamples the adult reference template (164k) sulcal topography map to 32k. 
**run_msm_registration.sh**: Runs Multimodal Surface Matching (MSM) based on sulcal depth features and spherical meshes to achieve high-precision surface registration from neonatal space to adult space (fs_LR 32k).
**resample_to_adult_space.sh**: Utilizes MSM deformation spheres (.reg.surf.gii) to resample neonatal network masks and WTA atlases to adult space, followed by integer label correction.

# Prerequisites & Environment 
Operating System: Linux (recommended CentOS / Ubuntu, verified on server cluster environments) 
Core Neuroimaging Tools: 
  [Workbench (wb_command)](https://www.humanconnectome.org/software/connectome-workbench) (v1.4+)
  [FSL (melodic)](https://fsl.fmrib.ox.ac.uk/)
  [MSM (Multimodal Surface Matching)](https://github.com/ecr05/MSM_HOCR)
Python Dependencies:
 ```bash
 pip install numpy pandas nibabel scipy statsmodels matplotlib seaborn

MATLAB Dependencies:
MATLAB (R2018b or newer)
GIFTI Toolbox for MATLAB
