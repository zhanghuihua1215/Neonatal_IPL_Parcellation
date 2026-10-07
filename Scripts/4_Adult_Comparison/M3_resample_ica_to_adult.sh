#!/bin/bash

# ==========================================
# 1. 设置文件路径变量
# ==========================================
ICA_DIR="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/5_split_components_thre_4_sym_20_wta/wall_masked/"
MSM_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/2_msm_registration"
OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/3_resampled_to_adult"
mkdir -p ${OUT_DIR}

ADULT_SPHERE_L="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/L.sphere.32k_fs_LR.surf.gii"
ADULT_SPHERE_R="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/R.sphere.32k_fs_LR.surf.gii"

COMPS=("01" "06" "07" "08" "09" "11" "12" "14" "15" "16" "19")
HEMIS=("L" "R")

# ==========================================
# 2. 开始循环重采样
# ==========================================

for hemi in "${HEMIS[@]}"; do
    echo "========================================"
    echo "正在处理 ${hemi} 半球..."
    
    REG_SPHERE="${MSM_DIR}/${hemi}_neonate_to_adult_sphere.reg.surf.gii"
    if [ "$hemi" == "L" ]; then
        ADULT_SPHERE=${ADULT_SPHERE_L}
    else
        ADULT_SPHERE=${ADULT_SPHERE_R}
    fi

    # ------------------------------------------
    # 任务 A: 处理 Z-score 连续数值 (绝对保留原值，不取整)
    # ------------------------------------------
    for comp in "${COMPS[@]}"; do
        INPUT_METRIC="${ICA_DIR}/WTA_component_${comp}_${hemi}_masked.func.gii"
        OUTPUT_METRIC="${OUT_DIR}/AdultSpace_WTA_component_${comp}_${hemi}.func.gii"
        
        echo "  - [任务A] 正在重采样 Z-score 连续数值网络: WTA_component_${comp}"
        
        # 仅执行重采样，完美保留完整的浮点数数据信息
        wb_command -metric-resample \
            ${INPUT_METRIC} \
            ${REG_SPHERE} \
            ${ADULT_SPHERE} \
            BARYCENTRIC \
            ${OUTPUT_METRIC}
    done

    # ------------------------------------------
    # 任务 B: 处理 分类标签 1, 2, 4, 5... (必须进行四舍五入取整)
    # ------------------------------------------
    INPUT_COMB="${ICA_DIR}/Combined_Parcellation_11Net_${hemi}_masked.func.gii"
    OUTPUT_COMB="${OUT_DIR}/AdultSpace_Combined_Parcellation_11Net_${hemi}.func.gii"
    
    echo "  - [任务B] 正在重采样 分类标签图: Combined_Parcellation_11Net"
    
    # 第 1 步：执行重采样（这一步会产生边界小数伪影，如 1.5）
    wb_command -metric-resample \
        ${INPUT_COMB} \
        ${REG_SPHERE} \
        ${ADULT_SPHERE} \
        BARYCENTRIC \
        ${OUTPUT_COMB}

    # 第 2 步：核心修复！使用数学公式强制把小数四舍五入，恢复为干净的整数标签 (1.0, 2.0, 4.0...)
    wb_command -metric-math "round(x)" ${OUTPUT_COMB} -var x ${OUTPUT_COMB}

done

echo "========================================"
echo "恭喜！所有重采样任务均已完美完成！"