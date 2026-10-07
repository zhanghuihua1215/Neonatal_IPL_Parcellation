#!/bin/bash

hemi="right"

SUBJECT_LIST_FILE="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
SESSION_LIST_FILE="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"

paste "${SUBJECT_LIST_FILE}" "${SESSION_LIST_FILE}" | while IFS=$'\t' read -r sub ses; do

    medial_mask="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii"
    main_output_dir="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/${hemi}"
    
    fmri_volume="/dat05/users/zhanghuihua/brain_development/template/rel3_dhcp_fmri_pipeline/${sub}/${ses}/func/${sub}_${ses}_task-rest_desc-preproc_bold.nii.gz"
    inner_surface="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${sub}/${ses}/${sub}_${ses}_hemi-${hemi}_wm.surf.gii"
    outer_surface="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${sub}/${ses}/${sub}_${ses}_hemi-${hemi}_pial.surf.gii"

    output_dir="${main_output_dir}/${sub}/"
    mkdir -p "${output_dir}"

    base_name="${sub}_hemi-${hemi}_bold" 
    output_projected="${output_dir}/${base_name}_projected.func.gii"
    output_final="${output_dir}/${base_name}_projected_masked.func.gii"

    wb_command -volume-to-surface-mapping \
      "${fmri_volume}" \
      "${inner_surface}" \
      "${output_projected}" \
      -ribbon-constrained \
      "${inner_surface}" \
      "${outer_surface}"

    wb_command -metric-mask \
      "${output_projected}" \
      "${medial_mask}" \
      "${output_final}"

done
