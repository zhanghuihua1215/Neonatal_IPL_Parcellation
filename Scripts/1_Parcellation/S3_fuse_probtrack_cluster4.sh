#!/bin/bash
#
# This script performs the following steps:
# 1. Splits a 4-parcel ROI file into four individual ROI files (C1, C2, C3, C4).
# 2. For each individual ROI, it iterates through 40 subjects.
# 3. For each subject, it maps the standard-space ROI to the individual's surface.
# 4. It then runs probabilistic tractography using the individual's ROI as a seed.
#
# By qianwang, adapted by Gemini.

# --- [!!] USER-CONFIGURABLE HEMISPHERE SETTINGS [!!] ---
# --- [!!] 只需修改下面这一行来切换左右脑 ('L' 或 'R') [!!] ---
HEMI_CHOICE='R'
# -------------------------------------------------------------

# --- Based on your choice, derive other necessary variables ---
if [ "$HEMI_CHOICE" = "L" ]; then
    Hemi="L"
    side="hemi-left"
elif [ "$HEMI_CHOICE" = "R" ]; then
    Hemi="R"
    side="hemi-right"
else
    echo "Error: Invalid HEMI_CHOICE. Please set to 'L' or 'R'."
    exit 1
fi

echo "*************************************************"
echo "*** Running Tractography for HEMISPHERE: ${Hemi} ***"
echo "*************************************************"


# --- 1. 基本参数和路径设置 ---
mesh=32k

# 源ROI文件（包含4个分区）- 已使用变量 ${Hemi}
SOURCE_ROI_FILE="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/IPL_group_Neighborhood_Consensus/Group_Fused_NC.${Hemi}.4.32k.func.gii"

# 总输出目录的基础路径
BASE_OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4"

# 被试列表文件
SUBJECT_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
SES_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"


# --- 2. 外层循环：遍历4个分区 (C1 to C4) ---
for CL_NUM in `seq 1 4`; do

    echo "================================================="
    echo "===      Processing Parcel C${CL_NUM}           ==="
    echo "================================================="

    # --- 为当前分区定义路径和文件名 ---
    PARCEL_NAME="C${CL_NUM}"
    PARCEL_DIR="${BASE_OUT_DIR}/IPL_probtrack_${PARCEL_NAME}"
    PARCEL_ROI_FILE="${PARCEL_DIR}/IPL_${PARCEL_NAME}.${Hemi}.func.gii" # 为避免左右脑ROI文件冲突，文件名中也加入Hemi

    # 创建当前分区的总目录
    mkdir -p ${PARCEL_DIR}

    # --- 拆分ROI：从源文件提取当前分区，只执行一次 ---
    if [ ! -f ${PARCEL_ROI_FILE} ]; then
        echo "Creating seed mask for parcel ${PARCEL_NAME}..."
        wb_command -metric-math "x == ${CL_NUM}" ${PARCEL_ROI_FILE} -var x ${SOURCE_ROI_FILE}
    else
        echo "Seed mask for parcel ${PARCEL_NAME} already exists."
    fi


    # --- 3. 内层循环：遍历所有被试 ---
    paste ${SUBJECT_LIST} ${SES_LIST} | while read Subject ses; do

        echo "--- Processing Subject: ${Subject} for Parcel: ${PARCEL_NAME} ---"

        # --- 为当前被试定义路径 ---
        PathData="/dat05/users/zhanghuihua/brain_development/rel3_dhcp_anat_pipeline/${Subject}/${ses}"
        bedpostx="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_dwi/${Subject}/${ses}"
        PathSurf="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${Subject}/${ses}"
        
        # 定义最终的纤维束示踪输出目录 - 已使用变量 ${Hemi}
        PathOut="${PARCEL_DIR}/${Subject}/IPL_fuse_${Hemi}_probtrackx"
        mkdir -p ${PathOut}

        # 定义个体化的种子文件路径 - 已使用变量 ${Hemi}
        INDIV_SEED_FILE="${PathOut}/seed_${PARCEL_NAME}.${Hemi}.white.${mesh}.gii"

        # --- 步骤A: 映射ROI到个体大脑表面 ---
        echo "Mapping ROI to individual surface for ${Subject}..."
        # 此处使用 ${side} 变量来选择正确的白质表面文件
        surf2surf -i ${PathSurf}/${Subject}_${ses}_${side}_wm.surf.gii \
                  -o ${INDIV_SEED_FILE} \
                  --values=${PARCEL_ROI_FILE}

        # --- 步骤B: 创建停止掩模 (Stopping Masks) ---
        # 注意：停止掩模通常同时包含左右两侧的皮层表面，以防止纤维束错误地穿过大脑，这是标准做法。
        # 因此，这部分代码不需要根据单侧半球进行修改。
        echo "Creating stop masks for ${Subject}..."
        surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_pial.surf.gii -o $PathOut/lh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
        surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_pial.surf.gii -o $PathOut/rh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
        
        echo "$PathOut/lh.pial.${mesh}.gii" > $PathOut/stop
        echo "$PathOut/rh.pial.${mesh}.gii" >> $PathOut/stop


        # --- 步骤C: 执行纤维束示踪 ---
        # 检查输出文件是否存在，避免重复运行
        if [ ! -f ${PathOut}/fdt_matrix2.dot ]; then 
            echo "Running probtrackx2 for ${Subject}, Parcel ${PARCEL_NAME}..."
            /mnt/soft/fsl-6.0.7.15/bin/probtrackx2_gpu10.2 \
                --samples=${bedpostx}/Diffusion.bedpostX/merged \
                --mask=${bedpostx}/Diffusion.bedpostX/nodif_brain_mask \
                --xfm=${bedpostx}/xfm/${Subject}_${ses}_from-T2w_to-dwi_mode-image.mat \
                --invxfm=${bedpostx}/xfm/${Subject}_${ses}_from-dwi_to-T2w_mode-image.mat \
                --seedref=${PathSurf}/${Subject}_${ses}_T2w.nii.gz \
                -P 5000 --loopcheck --forcedir -c 0.2 --sampvox=2 --randfib=1 \
                -x ${INDIV_SEED_FILE} \
                --omatrix2 --target2=${bedpostx}/Diffusion.bedpostX/nodif_brain_mask \
                --dir=${PathOut} \
                --opd \
                --stop=${PathOut}/stop --ompl
        else
            echo "Tractography for ${Subject}, Parcel ${PARCEL_NAME} already completed. Skipping."
        fi

    done # --- 内层循环 (被试) 结束 ---

done # --- 外层循环 (分区) 结束 ---

echo "================================================="
echo "All processing is complete for HEMISPHERE: ${Hemi}."
echo "================================================="