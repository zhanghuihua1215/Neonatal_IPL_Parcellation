#!/bin/bash

#完成了三个步骤：Demean均值x - mean 部分、Normalize标准化/ std 部分（去均值的结果除以标准差）、Merge合并wb_command -metric-merge ... 命令，按照时间序列首尾相接
# --- 1. 配置路径 ---
SUBJ_LIST="/dat05/users/zhanghuihua/brain_development/demo/ica_finger_demo/Human_HCP_ica/list1.txt"
# 投影数据所在的根目录（假设你已经按照之前的建议重命名了 LR 和 RL 文件）
DATA_DIR="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface"
# 输出目录：存合并后的结果
OUT_ROOT="/dat05/users/zhanghuihua/brain_development/less_out/HCP_ICA_out/H0_volume_to_surface/rfMRI_REST1_Zscored_merged/"

mkdir -p "$OUT_ROOT"

# --- 2. 循环处理 ---
for hemi in L R; do
    echo "======================================================"
    echo "正在处理 ${hemi} 半球的 Z-score 变换与合并..."
    echo "======================================================"

    cat "${SUBJ_LIST}" | while read -r sub junk; do
        sub_id=$(echo "$sub" | xargs)
        [[ -z "$sub_id" ]] && continue
        
        # 定义输入路径（根据你之前的路径结构）
        # 假设 LR 在 H0/LR/...  RL 在 H0/RL/...
        dir_LR="${DATA_DIR}/rfMRI_REST1_LR/${hemi}/${sub_id}"
        dir_RL="${DATA_DIR}/rfMRI_REST1_RL/${hemi}/${sub_id}"
        
        # 输入文件（使用 masked 后的文件更准确）
        file_LR="${dir_LR}/${sub_id}_${hemi}_LR_bold_projected_masked.func.gii"
        file_RL="${dir_RL}/${sub_id}_${hemi}_RL_bold_projected_masked.func.gii"

        # 准备输出目录
        sub_out_dir="${OUT_ROOT}/${hemi}/${sub_id}"
        mkdir -p "$sub_out_dir"
        final_merged="${sub_out_dir}/${sub_id}_${hemi}_REST1_combined_zscored.func.gii"

        # 安全检查
        if [ ! -f "$file_LR" ] || [ ! -f "$file_RL" ]; then
            echo "跳过 $sub_id: 缺少文件。"
            continue
        fi

        echo "Processing Subject: $sub_id"

        # --- 第一部分：处理 LR Run ---
        # 1. 计算均值
        wb_command -metric-reduce "$file_LR" MEAN "${sub_out_dir}/tmp_LR_mean.func.gii"
        # 2. 计算标准差
        wb_command -metric-reduce "$file_LR" STDEV "${sub_out_dir}/tmp_LR_std.func.gii"
        # 3. Z-score 变换: (x - mean) / std (使用 -fixnan 0 避免内侧壁产生无效值)
        wb_command -metric-math "(x - mean) / std" "${sub_out_dir}/tmp_LR_z.func.gii" \
            -var x "$file_LR" \
            -var mean "${sub_out_dir}/tmp_LR_mean.func.gii" -column 1 -repeat \
            -var std "${sub_out_dir}/tmp_LR_std.func.gii" -column 1 -repeat \
            -fixnan 0

        # --- 第二部分：处理 RL Run ---
        wb_command -metric-reduce "$file_RL" MEAN "${sub_out_dir}/tmp_RL_mean.func.gii"
        wb_command -metric-reduce "$file_RL" STDEV "${sub_out_dir}/tmp_RL_std.func.gii"
        wb_command -metric-math "(x - mean) / std" "${sub_out_dir}/tmp_RL_z.func.gii" \
            -var x "$file_RL" \
            -var mean "${sub_out_dir}/tmp_RL_mean.func.gii" -column 1 -repeat \
            -var std "${sub_out_dir}/tmp_RL_std.func.gii" -column 1 -repeat \
            -fixnan 0

        # --- 第三部分：合并 (Merge) ---
        # 将 Z 变换后的 LR 和 RL 在时间维度上拼接
        wb_command -metric-merge "$final_merged" \
            -metric "${sub_out_dir}/tmp_LR_z.func.gii" \
            -metric "${sub_out_dir}/tmp_RL_z.func.gii"

        # --- 第四部分：清理临时文件 ---
        rm ${sub_out_dir}/tmp_*
        
        echo "  -> 已完成 $sub_id 的合并。"
    done
done

echo "所有任务处理完毕！"