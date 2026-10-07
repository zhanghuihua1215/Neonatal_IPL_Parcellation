#!/bin/bash

set -e
export LC_NUMERIC="C"

HEMI_CHOICE='L'
WB_COMMAND_PATH="wb_command"
BASE_DIR="/dat05/users/zhanghuihua/brain_development"
BASE_OUTPUT_DIR="${BASE_DIR}/less_out/fused_out/out_4" 
SUBJECT_LIST="${BASE_DIR}/dHCP_40_list.txt"
REGIONS="C1 C2 C3 C4"

if [ "$HEMI_CHOICE" = "L" ]; then
    Hemi="L"
elif [ "$HEMI_CHOICE" = "R" ]; then
    Hemi="R"
else
    exit 1
fi

for region in $REGIONS; do
    OUTPUT_DIR="${BASE_OUTPUT_DIR}/IPL_connection_${region}"
    NORM_DIR="${OUTPUT_DIR}/tmp_normalized_files_${Hemi}"

    if [ ! -d "$OUTPUT_DIR" ]; then
        continue
    fi

    mkdir -p "$NORM_DIR"

    while read -r subject; do
        subject_file="${OUTPUT_DIR}/${subject}/${subject}_${Hemi}_probtrack_on_native_surf.func.gii"

        if [ -f "$subject_file" ]; then
            filename=$(basename "$subject_file" .func.gii)
            log_temp_file="${NORM_DIR}/${filename}_log_temp.func.gii"
            normalized_file="${NORM_DIR}/${filename}_normalized.func.gii"

            "$WB_COMMAND_PATH" -metric-math "log(x+1)" "$log_temp_file" -var x "$subject_file"
            log_max_val=$("$WB_COMMAND_PATH" -metric-stats "$log_temp_file" -reduce MAX)

            if awk -v val="$log_max_val" 'BEGIN { exit !(val > 0) }'; then
                "$WB_COMMAND_PATH" -metric-math "x / ${log_max_val}" "$normalized_file" -var x "$log_temp_file"
            else
                "$WB_COMMAND_PATH" -metric-math "x * 0" "$normalized_file" -var x "$log_temp_file"
            fi
        fi
    done < "$SUBJECT_LIST"
    
    shopt -s nullglob
    normalized_files_array=("${NORM_DIR}"/*_normalized.func.gii)
    shopt -u nullglob
    
    num_files=${#normalized_files_array[@]}
    if [ "$num_files" -eq 0 ]; then
        rm -r "$NORM_DIR"
        continue
    fi

    sum_file="${NORM_DIR}/temp_sum.func.gii"
    cp "${normalized_files_array[0]}" "$sum_file"

    for (( i=1; i<${num_files}; i++ )); do
        current_file="${normalized_files_array[$i]}"
        "$WB_COMMAND_PATH" -metric-math "s + n" "$sum_file" -var s "$sum_file" -var n "$current_file"
    done
    
    final_average_file="${OUTPUT_DIR}/average_${Hemi}_projection_${region}_native.func.gii"
    "$WB_COMMAND_PATH" -metric-math "s / ${num_files}" "$final_average_file" -var s "$sum_file"

    rm -r "$NORM_DIR"
done
