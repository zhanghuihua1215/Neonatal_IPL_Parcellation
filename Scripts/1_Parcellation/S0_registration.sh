#!/bin/bash

# --- A. 全局设置 ---

# 设置你想同时运行的最大任务数。
# 一个好的经验法则是设置为服务器CPU核心数的一半或3/4。
# 例如，如果你的服务器有32核，可以设置为16或24。
MAX_JOBS=8

# BET (脑提取) 参数
BET_OPTS="-f 0.2 -m"

# 静态路径和文件列表
SUBJECT_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_1_list.txt"
SESSION_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_ses_1_list.txt"
TEMPLATE_IMG="/dat05/users/zhanghuihua/brain_development/template/templates/week40_T2w.nii.gz"
# !! 强烈建议恢复使用配置文件，并解决refmask问题 !!
FNIRT_CONFIG="/dat05/users/zhanghuihua/brain_development/my_fnirt.cnf"


# --- B. 定义处理单个被试的函数 ---

process_subject() {
    # 函数接收被试ID和session作为参数
    local Subject=$1
    local ses=$2
    local bet_opts_str=$3 # 接收BET参数字符串

    echo "================================================================="
    echo "STARTING -- Subject: ${Subject}, Session: ${ses} (PID: $$)"
    echo "================================================================="

    # 为当前被试定义输入和输出路径
    # !! 再次确认T2图像的路径和文件名是正确的 !!
    local SUBJECT_T2="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${Subject}/${ses}/${Subject}_${ses}_T2w.nii.gz"
    local OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/template/registration/${Subject}/${ses}/transform_T2std2subj"
    
    # 定义将要生成的脑部提取后图像和掩模的路径
    local SUBJECT_BRAIN="${OUTPUT_DIR}/${Subject}_${ses}_T2w_brain"
    local SUBJECT_MASK="${OUTPUT_DIR}/${Subject}_${ses}_T2w_brain_mask.nii.gz"

    mkdir -p "${OUTPUT_DIR}"

    # 检查输入T2图像是否存在
    if [ ! -f "${SUBJECT_T2}" ]; then
        echo "!!! WARNING: Input T2 not found for ${Subject}/${ses}. Skipping."
        return 1 # 退出函数
    fi

    # --- 执行处理流程 ---

    # 步骤 0: 使用bet生成脑掩模 (如果掩模文件尚不存在)
    if [ ! -f "${SUBJECT_MASK}" ]; then
        echo "[${Subject}] Step 0: Running BET to create brain mask..."
        bet "${SUBJECT_T2}" "${SUBJECT_BRAIN}" ${bet_opts_str}
        
        # 检查bet是否成功生成了掩模文件
        if [ ! -f "${SUBJECT_MASK}" ]; then
            echo "!!! ERROR: BET failed to create brain mask for ${Subject}/${ses}. Skipping registration."
            return 1
        fi
    else
        echo "[${Subject}] Step 0: Brain mask already exists. Skipping BET."
    fi

    # 步骤 A: FLIRT
    echo "[${Subject}] Step A: Running FLIRT..."
    flirt -in "${TEMPLATE_IMG}" \
          -ref "${SUBJECT_T2}" \
          -omat "${OUTPUT_DIR}/template_to_subject_affine.mat" \
          -out "${OUTPUT_DIR}/template_to_subject_linear.nii.gz"

    # 步骤 B: FNIRT
    echo "[${Subject}] Step B: Running FNIRT..."
    fnirt --in="${TEMPLATE_IMG}" \
          --ref="${SUBJECT_T2}" \
          --refmask="${SUBJECT_MASK}" \
          --aff="${OUTPUT_DIR}/template_to_subject_affine.mat" \
          --cout="${OUTPUT_DIR}/template_to_subject_warp.nii.gz" \
          --iout="${OUTPUT_DIR}/template_to_subject_nonlinear.nii.gz" \
          --config="${FNIRT_CONFIG}"

    # 步骤 C: invwarp (仅在fnirt成功后执行)
    if [ -f "${OUTPUT_DIR}/template_to_subject_warp.nii.gz" ]; then
        echo "[${Subject}] Step C: Calculating inverse warp..."
        invwarp --warp="${OUTPUT_DIR}/template_to_subject_warp.nii.gz" \
                --ref="${TEMPLATE_IMG}" \
                --out="${OUTPUT_DIR}/subject_to_template_warp.nii.gz"
        echo "--- FINISHED -- Subject: ${Subject}, Session: ${ses} ---"
    else
        echo "!!! ERROR: FNIRT failed for ${Subject}/${ses}. Skipping inverse warp."
    fi
}

# --- C. 主循环：启动并管理并行任务 ---

# 导出函数和只读变量
export -f process_subject
export TEMPLATE_IMG FNIRT_CONFIG

# 使用paste和xargs实现并行
# 注意：我们现在需要传递3个参数给函数
# 为了将BET_OPTS传递进去，我们用一个小的循环
paste "${SUBJECT_LIST}" "${SESSION_LIST}" | while read -r Subject ses; do
    # 检查正在运行的作业数量
    while [[ $(jobs -r -p | wc -l) -ge ${MAX_JOBS} ]]; do
        sleep 1 # 如果达到上限，则等待1秒
    done
    # 在后台启动任务，并将BET参数作为第三个参数传递
    process_subject "${Subject}" "${ses}" "${BET_OPTS}" &
done

# 等待所有后台作业完成
wait

echo "================================================================="
echo "All subjects have been processed."
echo "================================================================="