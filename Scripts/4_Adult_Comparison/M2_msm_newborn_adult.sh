#!/bin/bash

OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/2_msm_registration"
mkdir -p ${OUT_DIR}

NEO_L_SPHERE="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_sphere.surf.gii"
NEO_L_SULC="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_sulc.shape.gii"

NEO_R_SPHERE="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_sphere.surf.gii"
NEO_R_SULC="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_sulc.shape.gii"

ADULT_L_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/L.sphere.32k_fs_LR.surf.gii"
ADULT_L_SULC="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/1_32k_adult_sulc/L.refsulc.32k_fs_LR.shape.gii"

ADULT_R_SPHERE="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/R.sphere.32k_fs_LR.surf.gii"
ADULT_R_SULC="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/1_32k_adult_sulc/R.refsulc.32k_fs_LR.shape.gii"

msm \
    --inmesh=${NEO_L_SPHERE} \
    --refmesh=${ADULT_L_SPHERE} \
    --indata=${NEO_L_SULC} \
    --refdata=${ADULT_L_SULC} \
    --out=${OUT_DIR}/L_neonate_to_adult_ \
    --verbose

msm \
    --inmesh=${NEO_R_SPHERE} \
    --refmesh=${ADULT_R_SPHERE} \
    --indata=${NEO_R_SULC} \
    --refdata=${ADULT_R_SULC} \
    --out=${OUT_DIR}/R_neonate_to_adult_ \
    --verbose
