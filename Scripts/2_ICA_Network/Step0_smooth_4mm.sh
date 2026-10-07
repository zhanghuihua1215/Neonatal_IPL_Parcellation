#!/bin/bash

# ==============================================================================
# 脚本功能：对 dHCP fMRI 数据进行表面平滑 (4mm FWHM)
# 修正重点：去除 Windows 换行符 (\r)，严格匹配功能像路径
# ==============================================================================

# --- 1. 路径配置 ---

LIST_SUBJ="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"
LIST_SES="/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt"

# [输入] 功能像目录 (F1)
INPUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface"

# [输入] 解剖像目录 (Anatomy)
ANAT_ROOT="/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat"

# [输出] 结果目录 (F3)
OUTPUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F3_volume_to_surface_s4mm"

# [参数]
SIGMA=1.6985 # 4mm FWHM

echo "------------------------------------------------"
echo "开始处理..."
echo "解剖基准: $ANAT_ROOT"
echo "输出目录: $OUTPUT_ROOT"
echo "------------------------------------------------"

# --- 2. 循环处理 ---

# [重要] 使用 tr -d '\r' 去除可能存在的 Windows 回车符
paste "$LIST_SUBJ" "$LIST_SES" | tr -d '\r' | grep -v "^$" | while read sub_id ses_id; do
    
    # 去除空格 (防御性编程)
    sub_id=$(echo $sub_id | xargs)
    ses_id=$(echo $ses_id | xargs)
    
    # 跳过空行
    if [ -z "$sub_id" ] || [ -z "$ses_id" ]; then continue; fi

    echo "正在处理: $sub_id (Session: $ses_id)"

    # === 1. 准备输出目录 ===
    out_dir_L="${OUTPUT_ROOT}/left/${sub_id}"
    out_dir_R="${OUTPUT_ROOT}/right/${sub_id}"
    mkdir -p "$out_dir_L" "$out_dir_R"

    # === 2. 定义功能像路径 (Input) ===
    # 你的路径结构: /left/sub-CC00067XX10/sub-CC00067XX10_hemi-left...
    # 这里的 sub_id 变量本身已经包含了 "sub-CC00067XX10"
    
    func_L_in="${INPUT_ROOT}/left/${sub_id}/${sub_id}_hemi-left_bold_projected_masked.func.gii"
    func_R_in="${INPUT_ROOT}/right/${sub_id}/${sub_id}_hemi-right_bold_projected_masked.func.gii"

    # === 3. 定义输出文件名 ===
    func_L_out="${out_dir_L}/${sub_id}_hemi-left_bold_projected_masked_s4mm.func.gii"
    func_R_out="${out_dir_R}/${sub_id}_hemi-right_bold_projected_masked_s4mm.func.gii"

    # === 4. 定义解剖路径 (Anatomy) ===
    # 结构: /sub-CC.../ses-20200/sub-CC..._ses-20200_hemi-left...
    anat_filename_base="${sub_id}_${ses_id}"
    
    surf_L="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-left_midthickness.surf.gii"
    surf_R="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-right_midthickness.surf.gii"

    # === 5. 检查并运行 ===

    # 调试信息：如果找不到文件，打印出脚本具体在找什么路径
    if [ ! -f "$func_L_in" ]; then
        echo "  [错误] 找不到功能像文件！"
        echo "  脚本尝试读取: $func_L_in"
        continue
    fi

    if [ ! -f "$surf_L" ]; then
        # 尝试备选命名 (hemi-L)
        surf_L_alt="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-L_midthickness.surf.gii"
        if [ -f "$surf_L_alt" ]; then
            surf_L=$surf_L_alt
            surf_R="${ANAT_ROOT}/${sub_id}/${ses_id}/${anat_filename_base}_hemi-R_midthickness.surf.gii"
            # echo "  [提示] 使用 hemi-L 命名格式"
        else
            echo "  [错误] 找不到解剖文件！"
            echo "  脚本尝试读取: $surf_L"
            continue
        fi
    fi

    # 执行 wb_command
    wb_command -metric-smoothing "$surf_L" "$func_L_in" "$SIGMA" "$func_L_out"
    wb_command -metric-smoothing "$surf_R" "$func_R_in" "$SIGMA" "$func_R_out"
    
    echo "  -> 完成"

done

echo "所有处理已完成。"