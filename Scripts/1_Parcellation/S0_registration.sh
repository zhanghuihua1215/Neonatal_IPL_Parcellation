#!/bin/bash

MAX_JOBS=8
BET_OPTS="-f 0.2 -m"

SUBJECT_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_1_list.txt"
SESSION_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_ses_1_list.txt"
TEMPLATE_IMG="/dat05/users/zhanghuihua/brain_development/template/templates/week40_T2w.nii.gz"
FNIRT_CONFIG="/dat05/users/zhanghuihua/brain_development/my_fnirt.cnf"

process_subject() {
    local Subject=$1
    local ses=$2
    local bet_opts=$3

    local SUBJECT_T2="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${Subject}/${ses}/${Subject}_${ses}_T2w.nii.gz"
    local OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/template/registration/${Subject}/${ses}/transform_T2std2subj"
    local SUBJECT_BRAIN="${OUTPUT_DIR}/${Subject}_${ses}_T2w_brain"
    local SUBJECT_MASK="${OUTPUT_DIR}/${Subject}_${ses}_T2w_brain_mask.nii.gz"

    mkdir -p "${OUTPUT_DIR}"

    bet "${SUBJECT_T2}" "${SUBJECT_BRAIN}" ${bet_opts}

    flirt -in "${TEMPLATE_IMG}" \
          -ref "${SUBJECT_T2}" \
          -omat "${OUTPUT_DIR}/template_to_subject_affine.mat" \
          -out "${OUTPUT_DIR}/template_to_subject_linear.nii.gz"

    fnirt --in="${TEMPLATE_IMG}" \
          --ref="${SUBJECT_T2}" \
          --refmask="${SUBJECT_MASK}" \
          --aff="${OUTPUT_DIR}/template_to_subject_affine.mat" \
          --cout="${OUTPUT_DIR}/template_to_subject_warp.nii.gz" \
          --iout="${OUTPUT_DIR}/template_to_subject_nonlinear.nii.gz" \
          --config="${FNIRT_CONFIG}"

    invwarp --warp="${OUTPUT_DIR}/template_to_subject_warp.nii.gz" \
            --ref="${TEMPLATE_IMG}" \
            --out="${OUTPUT_DIR}/subject_to_template_warp.nii.gz"
}

export -f process_subject
export TEMPLATE_IMG FNIRT_CONFIG

paste "${SUBJECT_LIST}" "${SESSION_LIST}" | while read -r Subject ses; do
    while [[ $(jobs -r -p | wc -l) -ge ${MAX_JOBS} ]]; do
        sleep 1
    done
    process_subject "${Subject}" "${ses}" "${BET_OPTS}" &
done

wait
