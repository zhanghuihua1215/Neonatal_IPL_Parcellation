#!/bin/bash

SUBJ_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
IN_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface"
OUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface_zscore"

cat "$SUBJ_LIST" | while read -r sub_id; do
    sub_id=$(echo "$sub_id" | tr -d '\r' | xargs)
    [[ -z "$sub_id" ]] && continue

    for hemi in left right; do
        in_file="${IN_ROOT}/${hemi}/${sub_id}/${sub_id}_hemi-${hemi}_bold_projected_masked.func.gii"
        
        out_dir="${OUT_ROOT}/${hemi}/${sub_id}"
        mkdir -p "$out_dir"
        out_file="${out_dir}/${sub_id}_hemi-${hemi}_bold_projected_masked_zscored.func.gii"

        tmp_mean="${out_dir}/tmp_mean.func.gii"
        tmp_std="${out_dir}/tmp_std.func.gii"

        wb_command -metric-reduce "$in_file" MEAN "$tmp_mean"
        wb_command -metric-reduce "$in_file" STDEV "$tmp_std"

        wb_command -metric-math "(x - mean) / std" "$out_file" \
            -var x "$in_file" \
            -var mean "$tmp_mean" -column 1 -repeat \
            -var std "$tmp_std" -column 1 -repeat \
            -fixnan 0

        rm "$tmp_mean" "$tmp_std"
    done
done
