#!/bin/bash

# ==========================================
# 1. 设置输出目录和前缀
# ==========================================
# 请将这里的路径替换为你希望保存配准结果的文件夹
OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/2_msm_registration"
mkdir -p ${OUT_DIR}

# ==========================================
# 2. 定义文件路径变量 (新生儿 - 移动图像/in)
# ==========================================
NEO_L_SPHERE="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii"
NEO_L_SULC="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_sulc.shape.gii"

NEO_R_SPHERE="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii"
NEO_R_SULC="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_sulc.shape.gii"

# ==========================================
# 3. 定义文件路径变量 (成人 - 参考图像/ref)
# ==========================================
#ADULT_L_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii"
ADULT_L_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/L.sphere.32k_fs_LR.surf.gii"
ADULT_L_SULC="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/1_32k_adult_sulc/L.refsulc.32k_fs_LR.shape.gii"

#ADULT_R_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii"
ADULT_R_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/R.sphere.32k_fs_LR.surf.gii"
ADULT_R_SULC="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/1_32k_adult_sulc/R.refsulc.32k_fs_LR.shape.gii"


# ==========================================
# 4. 执行 MSM 配准
# ==========================================
echo "开始配准左半球 (Left Hemisphere)..."
msm \
    --inmesh=${NEO_L_SPHERE} \
    --refmesh=${ADULT_L_SPHERE} \
    --indata=${NEO_L_SULC} \
    --refdata=${ADULT_L_SULC} \
    --out=${OUT_DIR}/L_neonate_to_adult_ \
    --verbose
    # 如果你有 HCP 提供的专门用于 sulc 配准的配置文件，可以加上: --conf=/path/to/MSMSulcStrain.conf

echo "左半球配准完成！"

echo "开始配准右半球 (Right Hemisphere)..."
msm \
    --inmesh=${NEO_R_SPHERE} \
    --refmesh=${ADULT_R_SPHERE} \
    --indata=${NEO_R_SULC} \
    --refdata=${ADULT_R_SULC} \
    --out=${OUT_DIR}/R_neonate_to_adult_ \
    --verbose
    # 如果你有 HCP 提供的专门用于 sulc 配准的配置文件，可以加上: --conf=/path/to/MSMSulcStrain.conf

echo "右半球配准完成！所有任务结束。"