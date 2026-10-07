#!/bin/bash

ADULT_DIR="/dat05/lqcheng/Monkey/NHPPipelines/global/templates/standard_mesh_atlases"
OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/Test3_32k_adult_sulc"
mkdir -p ${OUT_DIR}

for hemi in L R; do
    if [ "$hemi" == "L" ]; then 
        input_metric="${ADULT_DIR}/L.refsulc.164k_fs_LR.shape.gii"
        current_sphere="${ADULT_DIR}/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.164k_fs_LR.surf.gii" 
        target_sphere="${ADULT_DIR}/resample_fsaverage/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii"
    else
        input_metric="${ADULT_DIR}/R.refsulc.164k_fs_LR.shape.gii"
        current_sphere="${ADULT_DIR}/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.164k_fs_LR.surf.gii" 
        target_sphere="${ADULT_DIR}/resample_fsaverage/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii"
    fi

    wb_command -metric-resample \
        "${input_metric}" \
        "${current_sphere}" \
        "${target_sphere}" \
        BARYCENTRIC \
        "${OUT_DIR}/${hemi}.refsulc.32k_fs_LR.shape.gii"
done
