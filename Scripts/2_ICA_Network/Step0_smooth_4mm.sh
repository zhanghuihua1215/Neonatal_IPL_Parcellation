#!/bin/bash

set -e

LIST_SUBJ="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
LIST_SES="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"

INPUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface"
ANAT_ROOT="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat"
OUTPUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F3_volume_to_surface_s4mm"

SIGMA=1.6985 

paste "$LIST_SUBJ" "$LIST_SES" | tr -d '\r' | grep -v "^$" | while read sub_id ses_id; do
    sub_id=$(echo $sub_id | xargs)
    ses_id=$(echo $ses_id | xargs)
    
    if [ -z "$sub_id" ] || [ -z "$ses_id" ]; then continue; fi

    out_dir_L="${OUTPUT_ROOT}/left/${sub_id}"
    out_dir_R="${OUTPUT_ROOT}/right/${sub_id}"
    mkdir -p "$out_dir_L" "$out_dir_R"

    func_L_in="${INPUT_ROOT}/left/${sub_id}/${sub_id}_hemi-left_bold_projected_masked.func.gii"
    func_R_in="${INPUT_ROOT}/right/${sub_id}/${sub_id}_hemi-right_bold_projected_masked.func.gii"

    func_L_out="${out_dir_L}/${sub_id}_hemi-left_bold_projected_masked_s4mm.func.gii"
    func_R_out="${out_dir_R}/${sub_id}_hemi-right_bold_projected_masked_s4mm.func.gii"

    anat_filename_base="${sub_id}_${ses_id}"
    
    surf_L="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-left_midthickness.surf.gii"
    surf_R="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-right_midthickness.surf.gii"

    if [ ! -f "$func_L_in" ]; then
        continue
    fi

    if [ ! -f "$surf_L" ]; then
        surf_L_alt="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-L_midthickness.surf.gii"
        if [ -f "$surf_L_alt" ]; then
            surf_L=$surf_L_alt
            surf_R="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-R_midthickness.surf.gii"
        else
            continue
        fi
    fi

    wb_command -metric-smoothing "$surf_L" "$func_L_in" "$SIGMA" "$func_L_out"
    wb_command -metric-smoothing "$surf_R" "$func_R_in" "$SIGMA" "$func_R_out"

done
