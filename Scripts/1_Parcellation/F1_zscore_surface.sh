#!/bin/bash

# ==========================================
# 1. 配置路径
# ==========================================
# 被试列表路径
SUBJ_LIST="/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"

# 输入数据根目录
IN_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface"

# 输出数据根目录
OUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface_zscore"

# ==========================================
# 2. 开始循环处理
# ==========================================
echo "======================================================"
echo "开始批量执行 Z-score 变换..."
echo "======================================================"

# 读取被试列表
cat "$SUBJ_LIST" | while read -r sub_id; do
    # 去除可能的首尾空格，跳过空行
    # 增加 tr -d '\r' 强制删除回车符
    sub_id=$(echo "$sub_id" | tr -d '\r' | xargs)
    [[ -z "$sub_id" ]] && continue

    echo "Processing Subject: $sub_id"

    # 遍历左右半球 (根据你的路径，这里是 left 和 right)
    for hemi in left right; do
        
        # 定义输入路径和文件 (使用 masked 文件)
        in_dir="${IN_ROOT}/${hemi}/${sub_id}"
        in_file="${in_dir}/${sub_id}_hemi-${hemi}_bold_projected_masked.func.gii"

        # 定义输出路径和文件
        out_dir="${OUT_ROOT}/${hemi}/${sub_id}"
        mkdir -p "$out_dir" # 确保输出目录存在
        out_file="${out_dir}/${sub_id}_hemi-${hemi}_bold_projected_masked_zscored.func.gii"

        # 临时文件路径 (存放在各自的输出目录下)
        tmp_mean="${out_dir}/tmp_mean.func.gii"
        tmp_std="${out_dir}/tmp_std.func.gii"

        # 安全检查：确保输入文件存在
        if [ ! -f "$in_file" ]; then
            echo "  [警告] 跳过: 找不到文件 $in_file"
            continue
        fi

        echo "  -> Hemisphere: $hemi"

        # --- 核心计-
        
        # 1. 计算时间序列的均值 (mean)
        wb_command -metric-reduce "$in_file" MEAN "$tmp_mean"

        # 2. 计算时间序列的标准差 (std)
        wb_command -metric-reduce "$in_file" STDEV "$tmp_std"

        # 3. Z-score 变换: (x - mean) / std 
        # 使用 -fixnan 0 将除以0（比如在mask外部的全0区域）产生的 NaN 替换为 0
        wb_command -metric-math "(x - mean) / std" "$out_file" \
            -var x "$in_file" \
            -var mean "$tmp_mean" -column 1 -repeat \
            -var std "$tmp_std" -column 1 -repeat \
            -fixnan 0

        # 4. 清理临时文件
        rm "$tmp_mean" "$tmp_std"

    done
    echo "------------------------------------------------------"
done

echo "所有40个被试的 Z-score 计算完毕！结果保存在: $OUT_ROOT"