#!/bin/bash

# 输入改为文本列表文件
INPUT_LIST="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/input_files.txt"
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/2_Melodic_Results.ica_15/"

# 检查输入列表是否存在
if [ ! -f "$INPUT_LIST" ]; then
    echo "Error: 找不到输入列表文件 $INPUT_LIST"
    exit 1
fi

echo "开始运行 Melodic Group ICA (自动启用 MIGP)..."
echo "输入列表: $INPUT_LIST"

# 运行命令
# -a concat: 指定为拼接模式，你的版本会自动开启 MIGP
# --nomask: 不使用 Mask
# --bgthreshold=-1: 不去除背景
# --sep_vn: (推荐) 对每个被试单独做方差归一化，这对多中心/多被试数据很有用

melodic -i $INPUT_LIST \
        -o $OUTPUT_DIR \
        -a concat \
        --nomask \
        --bgthreshold=-1 \
        --sep_vn \
        -d 15 \
        --Oall \
        --report \
        -v

echo "运行结束！"