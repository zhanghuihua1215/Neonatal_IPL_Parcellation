#!/bin/bash

# --- 【修改点 1】: 定义大脑半球变量 ---
# 在这里修改 'left' 为 'right' 即可处理右脑
hemi="right"

# --- 定义包含被试和会话ID的列表文件路径 ---
SUBJECT_LIST_FILE="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
SESSION_LIST_FILE="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"


# --- 检查列表文件是否存在 ---
if [ ! -f "$SUBJECT_LIST_FILE" ] || [ ! -f "$SESSION_LIST_FILE" ]; then
    echo "错误: 被试或会话列表文件不存在！请检查路径。"
    exit 1
fi

# --- 使用 paste 和 while read 来正确地并行循环 ---
paste "${SUBJECT_LIST_FILE}" "${SESSION_LIST_FILE}" | while IFS=$'\t' read -r sub ses; do

    echo "======================================================"
    echo "Processing Subject: ${sub}, Session: ${ses}, Hemisphere: ${hemi}"
    echo "======================================================"

  
    # --- 固定的模板和主输出目录 ---
    # 注意：掩码文件也是左脑的，如果处理右脑，请确保有对应的右脑掩码文件
    medial_mask="/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwall_mask.shape.gii"
    main_output_dir="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/${hemi}"
  

     # --- 输入文件路径 (使用 ${hemi} 变量) ---
    fmri_volume="/dat05/users/zhanghuihua/brain_development/template/rel3_dhcp_fmri_pipeline/${sub}/${ses}/func/${sub}_${ses}_task-rest_desc-preproc_bold.nii.gz"
    
    # --- 【修改点 2】: 为 ribbon-constrained 方法定义内外表面 ---
    # 内表面 (通常是白质表面)
    inner_surface="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${sub}/${ses}/${sub}_${ses}_hemi-${hemi}_wm.surf.gii"
    # 外表面 (通常是软脑膜表面)
    outer_surface="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/${sub}/${ses}/${sub}_${ses}_hemi-${hemi}_pial.surf.gii"

    # --- 输出设置 (使用 ${hemi} 变量) ---
    output_dir="${main_output_dir}/${sub}/"
    mkdir -p "${output_dir}"

    base_name="${sub}_hemi-${hemi}_bold" 
    output_projected="${output_dir}/${base_name}_projected.func.gii"
    output_final="${output_dir}/${base_name}_projected_masked.func.gii"
    
    # --- 安全检查：在运行前确认所有输入文件是否存在 ---
    if [ ! -f "$fmri_volume" ]; then
        echo "错误: fMRI文件未找到: $fmri_volume"
        continue
    fi
    if [ ! -f "$inner_surface" ]; then
        echo "错误: 内表面文件未找到: $inner_surface"
        continue
    fi
    if [ ! -f "$outer_surface" ]; then
        echo "错误: 外表面文件未找到: $outer_surface"
        continue
    fi
    if [ ! -f "$medial_mask" ]; then
        echo "警告: 内侧壁掩码文件未找到: $medial_mask"
        # 根据需求决定是否要因为mask缺失而退出
    fi

    # --- 【修改点 3】: 使用 -ribbon-constrained 算法进行投影 ---
    echo "步骤 1: 开始使用 ribbon-constrained 算法投影fMRI数据..."
    wb_command -volume-to-surface-mapping \
      "${fmri_volume}" \
      "${inner_surface}" \
      "${output_projected}" \
      -ribbon-constrained \
      "${inner_surface}" \
      "${outer_surface}"


    # --- 步骤 2: 应用内侧壁掩码 ---
    echo "步骤 2: 应用内侧壁掩码..."
    wb_command -metric-mask \
      "${output_projected}" \
      "${medial_mask}" \
      "${output_final}"

    echo "流程完成！最终文件保存在: ${output_final}"
    echo ""

    # (可选) 删除中间文件
    # rm "${output_projected}"

done # 循环结束

echo "======================================================"
echo "所有被试处理完毕！"
echo "======================================================"