#!/bin/bash

hemi="R"
SUBJECT_LIST_FILE="/dat05/users/zhanghuihua/brain_development/demo/ica_finger_demo/Human_HCP_ica/list1.txt"

cat "${SUBJECT_LIST_FILE}" | while read -r sub junk; do
    [[ -z "$sub" ]] && continue

    hcp_dir="/dat05/data/HCP/HCPS1200/${sub}/MNINonLinear/fsaverage_LR32k"
    
    medial_mask="${hcp_dir}/${sub}.${hemi}.atlasroi.32k_fs_LR.shape.gii"
    inner_surface="${hcp_dir}/${sub}.${hemi}.white.32k_fs_LR.surf.gii"
    outer_surface="${hcp_dir}/${sub}.${hemi}.pial.32k_fs_LR.surf.gii"
    mid_surface="${hcp_dir}/${sub}.${hemi}.midthickness.32k_fs_LR.surf.gii"
    
    fmri_volume="/dat05/data/HCP/HCPS1200/${sub}/MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_hp2000_clean.nii.gz"
    
    main_output_dir="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface/rfMRI_REST1_LR/${hemi}"
    output_dir="${main_output_dir}/${sub}"
    mkdir -p "${output_dir}"

    base_name="${sub}_${hemi}_LR_bold" 
    output_projected="${output_dir}/${base_name}_projected.func.gii"
    output_final="${output_dir}/${base_name}_projected_masked.func.gii"
    
    if [ ! -f "$fmri_volume" ] || [ ! -f "$inner_surface" ] || [ ! -f "$outer_surface" ] || [ ! -f "$medial_mask" ]; then 
        continue 
    fi

    wb_command -volume-to-surface-mapping \
      "${fmri_volume}" \
      "${mid_surface}" \
      "${output_projected}" \
      -ribbon-constrained \
      "${inner_surface}" \
      "${outer_surface}"

    wb_command -metric-mask \
      "${output_projected}" \
      "${medial_mask}" \
      "${output_final}"

done
