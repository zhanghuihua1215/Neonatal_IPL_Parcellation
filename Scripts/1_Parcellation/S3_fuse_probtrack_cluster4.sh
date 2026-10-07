#!/bin/bash

HEMI_CHOICE='R'

if [ "$HEMI_CHOICE" = "L" ]; then
    Hemi="L"
    side="hemi-left"
elif [ "$HEMI_CHOICE" = "R" ]; then
    Hemi="R"
    side="hemi-right"
else
    exit 1
fi

mesh=32k
SOURCE_ROI_FILE="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/IPL_group_Neighborhood_Consensus/Group_Fused_NC.${Hemi}.4.32k.func.gii"
BASE_OUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4"
SUBJECT_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
SES_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"

for CL_NUM in `seq 1 4`; do

    PARCEL_NAME="C${CL_NUM}"
    PARCEL_DIR="${BASE_OUT_DIR}/IPL_probtrack_${PARCEL_NAME}"
    PARCEL_ROI_FILE="${PARCEL_DIR}/IPL_${PARCEL_NAME}.${Hemi}.func.gii"

    mkdir -p ${PARCEL_DIR}

    if [ ! -f ${PARCEL_ROI_FILE} ]; then
        wb_command -metric-math "x == ${CL_NUM}" ${PARCEL_ROI_FILE} -var x${SOURCE_ROI_FILE}
    fi

    paste ${SUBJECT_LIST}${SES_LIST} | while read Subject ses; do

        PathData="/dat05/users/zhanghuihua/brain_development/rel3_dhcp_anat_pipeline/${Subject}/${ses}"
        bedpostx="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_dwi/${Subject}/${ses}"
        PathSurf="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${Subject}/${ses}"
        
        PathOut="${PARCEL_DIR}/${Subject}/IPL_fuse_${Hemi}_probtrackx"
        mkdir -p ${PathOut}

        INDIV_SEED_FILE="${PathOut}/seed_${PARCEL_NAME}.${Hemi}.white.${mesh}.gii"

        surf2surf -i ${PathSurf}/${Subject}_${ses}_${side}_wm.surf.gii \
                  -o ${INDIV_SEED_FILE} \
                  --values=${PARCEL_ROI_FILE}

        surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_pial.surf.gii -o$PathOut/lh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
        surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_pial.surf.gii -o$PathOut/rh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
        
        echo "$PathOut/lh.pial.${mesh}.gii" > $PathOut/stop
        echo "$PathOut/rh.pial.${mesh}.gii" >> $PathOut/stop

        if [ ! -f ${PathOut}/fdt_matrix2.dot ]; then 
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
        fi

    done
done
