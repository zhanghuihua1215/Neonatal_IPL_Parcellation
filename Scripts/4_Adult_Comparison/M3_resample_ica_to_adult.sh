#!/bin/bash

ICA_DIR="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/5_split_components_thre_4_sym_20_wta/wall_masked/"
MSM_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/2_msm_registration"
OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/3_resampled_to_adult"
mkdir -p ${OUT_DIR}

ADULT_SPHERE_L="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/L.sphere.32k_fs_LR.surf.gii"
ADULT_SPHERE_R="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases/R.sphere.32k_fs_LR.surf.gii"

COMPS=("01" "06" "07" "08" "09" "11" "12" "14" "15" "16" "19")
HEMIS=("L" "R")

for hemi in "${HEMIS[@]}"; do
    REG_SPHERE="${MSM_DIR}/${hemi}_neonate_to_adult_sphere.reg.surf.gii"
    if [ "$hemi" == "L" ]; then
        ADULT_SPHERE=${ADULT_SPHERE_L}
    else
        ADULT_SPHERE=${ADULT_SPHERE_R}
    fi

    for comp in "${COMPS[@]}"; do
        INPUT_METRIC="${ICA_DIR}/WTA_component_${comp}_${hemi}_masked.func.gii"
        OUTPUT_METRIC="${OUT_DIR}/AdultSpace_WTA_component_${comp}_${hemi}.func.gii"
        
        wb_command -metric-resample \
            ${INPUT_METRIC} \
            ${REG_SPHERE} \
            ${ADULT_SPHERE} \
            BARYCENTRIC \
            ${OUTPUT_METRIC}
    done

    INPUT_COMB="${ICA_DIR}/Combined_Parcellation_11Net_${hemi}_masked.func.gii"
    OUTPUT_COMB="${OUT_DIR}/AdultSpace_Combined_Parcellation_11Net_${hemi}.func.gii"
    
    wb_command -metric-resample \
        ${INPUT_COMB} \
        ${REG_SPHERE} \
        ${ADULT_SPHERE} \
        BARYCENTRIC \
        ${OUTPUT_COMB}

    wb_command -metric-math "round(x)" ${OUTPUT_COMB} -var x ${OUTPUT_COMB}

done
