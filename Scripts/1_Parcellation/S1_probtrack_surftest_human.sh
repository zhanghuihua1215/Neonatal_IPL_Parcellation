#! /bin/bash 
## human


paste /dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt \
      /dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt | while read Subject ses; do

ROI=IPL_less # BA44 BA45
species=neonatal
PathData=/dat05/users/zhanghuihua/brain_development/rel3_dhcp_anat_pipeline/$Subject/$ses
bedpostx=/dat05/data/human/dHCP_preprocessed/rel3_dhcp_dwi/$Subject/$ses
PathOut=/dat05/users/zhanghuihua/brain_development/less_out/neonatal_probtrack/$Subject
PathSurf=/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/$Subject/$ses
PathROI=/dat05/users/zhanghuihua/brain_development/border/less/
side=hemi-right #L,R
Hemi=R #L,R
mesh=32k

mkdir -p $PathOut
surf2surf -i $PathSurf/${Subject}_${ses}_${side}_wm.surf.gii -o $PathOut/${ROI}.${Hemi}.white.${mesh}.gii \
	--values=$PathROI/${species}.${ROI}.${Hemi}.${mesh}.func.gii #roi从标准空间映射到个体空间


surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_wm.surf.gii -o $PathOut/lh.white.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
surf2surf -i $PathSurf/${Subject}_${ses}_hemi-left_pial.surf.gii -o $PathOut/lh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-left_space-dhcpSym40_thickness.shape.gii
surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_wm.surf.gii -o $PathOut/rh.white.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
surf2surf -i $PathSurf/${Subject}_${ses}_hemi-right_pial.surf.gii -o $PathOut/rh.pial.${mesh}.gii --values=$PathSurf/dhcpSym_32k/${Subject}_${ses}_hemi-right_space-dhcpSym40_thickness.shape.gii
echo "$PathOut/lh.white.${mesh}.gii" > $PathOut/wtstop
echo "$PathOut/rh.white.${mesh}.gii" >> $PathOut/wtstop
echo "$PathOut/lh.pial.${mesh}.gii" > $PathOut/stop
echo "$PathOut/rh.pial.${mesh}.gii" >> $PathOut/stop

#LowResMask3
if [ ! -f $PathOut/"$ROI"_"$Hemi"_probtrackx${pd}/fdt_matrix2.dot ] ; then 
/mnt/soft/fsl-6.0.7.15/bin/probtrackx2_gpu10.2 --samples=$bedpostx/Diffusion.bedpostX/merged \
      --mask=$bedpostx/Diffusion.bedpostX/nodif_brain_mask \
      --xfm=$bedpostx/xfm/${Subject}_${ses}_from-T2w_to-dwi_mode-image.mat \
      --invxfm=$bedpostx/xfm/${Subject}_${ses}_from-dwi_to-T2w_mode-image.mat \
      --seedref=$PathSurf/${Subject}_${ses}_T2w.nii.gz \
      -P 5000 --loopcheck --forcedir -c 0.2 --sampvox=2 --randfib=1 \
      -x $PathOut/${ROI}.${Hemi}.white.${mesh}.gii \
      --omatrix2 --target2=$bedpostx/Diffusion.bedpostX/nodif_brain_mask \
      --dir=$PathOut/"$ROI"_"$Hemi"_probtrackx${pd} --opd \
      --stop=$PathOut/stop --ompl
fi
done
# bash /dat01/zhanghuihua/chimpanzee-broca-main/scripts/chimpanzee/4.create_atlas/S1_probtrack_surftest_human.sh

 