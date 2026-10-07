#!/bin/bash

paste /dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt \
      /dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt | while read Subject ses; do

    ROI="IPL_less"
    species="neonatal"
    bedpostx="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_dwi/$Subject/$ses"
    PathOut="/dat05/users/zhanghuihua/brain_development/less_out/neonatal_probtrack/$Subject"
    PathSurf="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/$Subject/$ses"
    PathROI="/dat05/users/zhanghuihua/brain_development/border/less/"
    side="hemi-right"
    Hemi="R"
    mesh="32k"

    mkdir -p $PathOut

    surf2surf -i $PathSurf/${Subject}_${ses}_${side}_wm.surf.gii \
        -o $PathOut/${ROI}.${Hemi}.white.${mesh}.gii \
        --values=$PathROI/${species}.${ROI}.${Hemi}.${mesh}.func.gii

    surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_wm.surf.gii -o$PathOut/lh.white.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
    surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_pial.surf.gii -o$PathOut/lh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
    surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_wm.surf.gii -o$PathOut/rh.white.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
    surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_pial.surf.gii -o$PathOut/rh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
    
    # 保留这四个echo，因为它们是用于生成FSL运行所需的 stop 文本文件，而非打印信息
    echo "$PathOut/lh.white.${mesh}.gii" > $PathOut/wtstop
    echo "$PathOut/rh.white.${mesh}.gii" >> $PathOut/wtstop
    echo "$PathOut/lh.pial.${mesh}.gii" > $PathOut/stop
    echo "$PathOut/rh.pial.${mesh}.g
