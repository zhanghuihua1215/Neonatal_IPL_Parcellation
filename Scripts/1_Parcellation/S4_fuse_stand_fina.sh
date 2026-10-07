#!/bin/bash

# ==============================================================================
# Batch Normalize and Average Surface Data (Updated Input Structure)
#
# 版本 2.1: 参数化半球选择 (L/R)
#
# 此脚本读取被试列表，找到他们各自的表面度量文件，
# 并对每个文件执行两步标准化：
#   1. Log变换: 对每个数据点应用 log(x+1) 来压缩动态范围。
#   2. 归一化: 将log变换后的结果除以其自身的最大值。
# 最后，为每个指定的大脑分区计算一个组平均图。
# ==============================================================================


# --- 核心设定 ---
set -e
export LC_NUMERIC="C"


# --- ###################### 用户配置区 ###################### ---

# --- [!!] 半球选择开关 [!!] ---
# --- [!!] 只需修改下面这一行来切换左右脑 ('L' 或 'R') [!!] ---
HEMI_CHOICE='L'
# ----------------------------------------------------------------

# --- wb_command 路径 ---
WB_COMMAND_PATH="wb_command"

# --- 基础目录 ---
BASE_DIR="/dat05/users/zhanghuihua/brain_development"
# 注意：您的原始路径是 less_out/fuse_out，这里更正为 less_out/fused_out 以匹配之前的脚本
BASE_OUTPUT_DIR="${BASE_DIR}/less_out/fused_out/out_4" 

# --- 被试列表文件 ---
SUBJECT_LIST="${BASE_DIR}/dHCP_40_list.txt"

# --- 定义要处理的分区 ---
REGIONS="C1 C2 C3 C4"


# --- ###################### 脚本主程序 ###################### ---

# --- 【新增】根据用户的选择，自动派生其他必要的变量 ---
if [ "$HEMI_CHOICE" = "L" ]; then
    Hemi="L"
elif [ "$HEMI_CHOICE" = "R" ]; then
    Hemi="R"
else
    echo "!!! 错误: 无效的 HEMI_CHOICE ('${HEMI_CHOICE}')。请设置为 'L' 或 'R'。"
    exit 1
fi

echo "================================================================"
echo "=== 开始对分区 C1-C4 的结果进行标准化和平均 (V2.1) ==="
echo "===                  当前处理的半球: ${Hemi}                  ==="
echo "================================================================"
echo

# --- 循环遍历所有分区 ---
for region in $REGIONS; do
    echo ""
    echo "################## 开始处理分区: ${region} ##################"
    echo ""

    # --- 定义输出和临时目录 ---
    OUTPUT_DIR="${BASE_OUTPUT_DIR}/IPL_connection_${region}"
    NORM_DIR="${OUTPUT_DIR}/tmp_normalized_files_${Hemi}" # 临时目录也加上半球标识，避免冲突

    if [ ! -d "$OUTPUT_DIR" ]; then
        echo "!!! 警告: 分区 ${region} 的基础目录不存在，跳过处理 !!!"
        echo "查找路径: ${OUTPUT_DIR}"
        continue
    fi

    mkdir -p "$NORM_DIR"

    # ==============================================================================
    # ---                              核心修改区域                           ---
    # ==============================================================================
    echo "--- 步骤 1: 对每个被试的文件进行 Log 变换和归一化 ---"

    while read -r subject; do
        # 【修改点】动态构建每个被试的输入文件路径，使用 ${Hemi} 变量
        subject_file="${OUTPUT_DIR}/${subject}/${subject}_${Hemi}_probtrack_on_native_surf.func.gii"

        # 检查当前被试的文件是否存在
        if [ -f "$subject_file" ]; then
            filename=$(basename "$subject_file" .func.gii)
            
            log_temp_file="${NORM_DIR}/${filename}_log_temp.func.gii"
            normalized_file="${NORM_DIR}/${filename}_normalized.func.gii"
            
            echo "正在处理: $(basename "$subject_file")"

            # 步骤 a: 应用 log(x+1) 变换
            "$WB_COMMAND_PATH" -metric-math "log(x+1)" "$log_temp_file" -var x "$subject_file"
            
            # 步骤 b: 获取 log 变换后数据的最大值
            log_max_val=$("$WB_COMMAND_PATH" -metric-stats "$log_temp_file" -reduce MAX)
            echo "  (Log变换后的最大值 = ${log_max_val})"

            # 步骤 c: 使用 log 变换后的最大值进行归一化
            if awk -v val="$log_max_val" 'BEGIN { exit !(val > 0) }'; then
                "$WB_COMMAND_PATH" -metric-math "x / ${log_max_val}" "$normalized_file" -var x "$log_temp_file"
            else
                echo "  -> 注意: Log变换后的最大值为0，将生成一个零文件用于平均。"
                "$WB_COMMAND_PATH" -metric-math "x * 0" "$normalized_file" -var x "$log_temp_file"
            fi

        else
            echo "!!! 警告: 找不到被试 ${subject} 在分区 ${region} 的输入文件，跳过 !!!"
            echo "    查找路径: ${subject_file}"
        fi
    done < "$SUBJECT_LIST"
    
    echo ""
    echo "--- 步骤 2: 使用迭代法平均所有标准化文件 ---"
    
    shopt -s nullglob
    normalized_files_array=("${NORM_DIR}"/*_normalized.func.gii)
    shopt -u nullglob
    
    num_files=${#normalized_files_array[@]}

    if [ "$num_files" -eq 0 ]; then
        echo "!!! 警告: 未能找到或生成任何标准化文件，跳过分区 ${region} !!!"
        rm -r "$NORM_DIR"
        continue
    fi

    echo "找到 ${num_files} 个标准化文件，开始计算总和..."

    sum_file="${NORM_DIR}/temp_sum.func.gii"
    
    cp "${normalized_files_array[0]}" "$sum_file"
    echo "  (1/${num_files}) 初始化总和文件..."

    for (( i=1; i<${num_files}; i++ )); do
        current_file="${normalized_files_array[$i]}"
        echo "  ($((i+1))/${num_files}) 累加文件: $(basename "$current_file")"
        "$WB_COMMAND_PATH" -metric-math "s + n" "$sum_file" -var s "$sum_file" -var n "$current_file"
    done
    
    echo "所有文件累加完毕。"
    echo "--- 步骤 2.5: 计算最终平均值 ---"
    
    # 【修改点】最终平均值的文件名也使用 ${Hemi} 变量
    final_average_file="${OUTPUT_DIR}/average_${Hemi}_projection_${region}_native.func.gii"
    
    "$WB_COMMAND_PATH" -metric-math "s / ${num_files}" "$final_average_file" -var s "$sum_file"

    echo "分区 ${region} 的平均结果已生成: ${final_average_file}"
    echo ""

    echo "--- 步骤 3: 清理临时文件 ---"
    rm -r "$NORM_DIR"
    echo "临时目录 ${NORM_DIR} 已被删除。"
    echo ""
    echo "================================================================"
    echo "################## 分区 ${region} 处理完毕 ##################"
    echo "================================================================"
    echo ""

done

echo "所有分区处理流程结束。"