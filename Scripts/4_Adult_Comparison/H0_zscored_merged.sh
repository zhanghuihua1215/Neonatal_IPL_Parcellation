#!/bin/bash

SUBJ_LIST="/dat05/users/zhanghuihua/brain_development/demo/ica_finger_demo/Human_HCP_ica/list1.txt"
DATA_DIR="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface"
OUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface/rfMRI_REST1_Zscored_merged/"

mkdir -p "$OUT_ROOT"

for hemi in L R; do
    cat "${SUBJ_LIST}" | while read -r sub junk; do
        sub_id=$(echo "$sub" | xargs)
        [[ -z "$sub_id" ]] && continue
        
        dir_LR="${DATA_DIR}/rfMRI_REST1_LR/${hemi}/${sub_id}"
        dir_RL="${DATA_DIR}/rfMRI_REST1_RL/${hemi}/${sub_id}"
        
        file_LR="${dir_LR}/${sub_id}_${hemi}_LR_bold_projected_masked.func.gii"
        file_RL="${dir_RL}/${sub_id}_${hemi}_RL_bold_projected_masked.func.gii"

        sub_out_dir="${OUT_ROOT}/${hemi}/${sub_id}"
        mkdir -p "$sub_out_dir"
        final_merged="${sub_out_dir}/${sub_id}_${hemi}_REST1_combined_zscored.func.gii"

        if [ ! -f "$file_LR" ] || [ ! -f "$file_RL" ]; then
            continue
        fi

        wb_command -metric-reduce "$file_LR" MEAN "${sub_out_dir}/tmp_LR_mean.func.gii"
        wb_command -metric-reduce "$file_LR" STDEV "${sub_out_dir}/tmp_LR_std.func.gii"
        wb_command -metric-math "(x - mean) / std" "${sub_out_dir}/tmp_LR_z.func.gii" \
            -var x "$file_LR" \
            -var mean "${sub_out_dir}/tmp_LR_mean.func.gii" -column 1 -repeat \
            -var std "${sub_out_dir}/tmp_LR_std.func.gii" -column 1 -repeat \
            -fixnan 0

        wb_command -metric-reduce "$file_RL" MEAN "${sub_out_dir}/tmp_RL_mean.func.gii"
        wb_command -metric-reduce "$file_RL" STDEV "${sub_out_dir}/tmp_RL_std.func.gii"
        wb_command -metric-math "(x - mean) / std" "${sub_out_dir}/tmp_RL_z.func.gii" \
            -var x "$file_RL" \
            -var mean "${sub_out_dir}/tmp_RL_mean.func.gii" -column 1 -repeat \
            -var std "${sub_out_dir}/tmp_RL_std.func.gii" -column 1 -repeat \
            -fixnan 0

        wb_command -metric-merge "$final_merged" \
            -metric "${sub_out_dir}/tmp_LR_z.func.gii" \
            -metric "${sub_out_dir}/tmp_RL_z.func.gii"

        rm ${sub_out_dir}/tmp_*
    done
done
