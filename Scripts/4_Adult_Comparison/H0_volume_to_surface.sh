#!/bin/bash

# --- 【修改点 1】: 定义大脑半球变量 ---
# 注意：HCP 命名规则使用 "L" 或 "R"
hemi="R" # 处理左脑改为 "L"，处理右脑改为 "R"

# --- 定义列表文件路径 ---
SUBJECT_LIST_FILE="/dat05/users/zhanghuihua/brain_development/demo/ica_finger_demo/Human_HCP_ica/list1.txt"

# --- 检查列表文件是否存在 ---
if [ ! -f "$SUBJECT_LIST_FILE" ] ; then
    echo "错误: 列表文件不存在！"
    exit 1
fi

# --- 循环处理 ---
# 如果 list_40.txt 只有一列 ID，只需用 read sub
# 如果有两列且你想忽略第二列，用 read sub junk
cat "${SUBJECT_LIST_FILE}" | while read -r sub junk; do

    # 跳过空行
    [[ -z "$sub" ]] && continue

    echo "======================================================"
    echo "Processing Subject: ${sub}, Hemisphere: ${hemi}"
    echo "======================================================"

    # --- 路径定义 ---
    # 根据你的截图，HCP 路径下文件名为：sub.L.xxx 或 sub.R.xxx
    hcp_dir="/dat05/data/HCP/HCPS1200/${sub}/MNINonLinear/fsaverage_LR32k"
    
    medial_mask="${hcp_dir}/${sub}.${hemi}.atlasroi.32k_fs_LR.shape.gii"
    inner_surface="${hcp_dir}/${sub}.${hemi}.white.32k_fs_LR.surf.gii"
    outer_surface="${hcp_dir}/${sub}.${hemi}.pial.32k_fs_LR.surf.gii"
    # 建议投影到 midthickness 表面 (如果有的话)
    mid_surface="${hcp_dir}/${sub}.${hemi}.midthickness.32k_fs_LR.surf.gii"
    
    fmri_volume="/dat05/data/HCP/HCPS1200/${sub}/MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_hp2000_clean.nii.gz"
    
    main_output_dir="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface/rfMRI_REST1_LR/${hemi}"
    output_dir="${main_output_dir}/${sub}"
    mkdir -p "${output_dir}"

    base_name="${sub}_${hemi}_LR_bold" 
    output_projected="${output_dir}/${base_name}_projected.func.gii"
    output_final="${output_dir}/${base_name}_projected_masked.func.gii"
    
    # --- 安全检查 ---
    if [ ! -f "$fmri_volume" ]; then echo "跳过: 未找到 fMRI: $fmri_volume"; continue; fi
    if [ ! -f "$inner_surface" ]; then echo "跳过: 未找到内表面: $inner_surface"; continue; fi
    if [ ! -f "$outer_surface" ]; then echo "跳过: 未找到外表面: $outer_surface"; continue; fi
    if [ ! -f "$medial_mask" ]; then echo "跳过: 未找到掩码: $medial_mask"; continue; fi

    # --- 步骤 1: 投影 (Volume to Surface) ---
    echo "步骤 1: 投影数据..."
    # 推荐用法：投影到 midthickness，由 white 和 pial 约束范围
    # 如果没有 midthickness，也可以用 inner_surface 代替第一个表面参数
    wb_command -volume-to-surface-mapping \
      "${fmri_volume}" \
      "${mid_surface}" \
      "${output_projected}" \
      -ribbon-constrained \
      "${inner_surface}" \
      "${outer_surface}"

    # --- 步骤 2: 应用内侧壁掩码 ---
    echo "步骤 2: 应用内侧壁掩码 (AtlasROI)..."
    wb_command -metric-mask \
      "${output_projected}" \
      "${medial_mask}" \
      "${output_final}"

    echo "完成: ${output_final}"
    echo ""

done

echo "所有任务处理完毕！"