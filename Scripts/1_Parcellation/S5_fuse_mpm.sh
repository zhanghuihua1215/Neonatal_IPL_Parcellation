#!/bin/bash

################################################################################
#                                                                              #
#                      用户配置区域 (请在这里修改)                             #
#                                                                              #
################################################################################

# <<< 修改这里: 设置为 'L' 来处理左半球, 或设置为 'R' 来处理右半球
HEMI_TO_RUN="L"

# 设置阈值
THRESHOLD=0.05

# --- 输入文件基础路径 (减少重复代码) ---
# 注意路径最后有一个斜杠 '/'
BASE_PATH="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/"

# --- 输出目录 ---
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/MPM_0.05_results/"

################################################################################
#                                                                              #
#                      脚本主逻辑 (通常无需修改)                               #
#                                                                              #
################################################################################

# (可选) 自动创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 HEMI_TO_RUN 变量是否有效
if [ "$HEMI_TO_RUN" == "L" ]; then
    # ------------------ 处理左半球 (L) ------------------
    echo "--- 正在处理左半球 (Hemi = L) ---"

    # 1. 定义该半球的所有输入文件
    C1_IN="${BASE_PATH}IPL_connection_C1/average_L_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_L_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_L_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_L_projection_C4_native.func.gii"
    
    # 2. 定义该半球的输出文件名
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_L.func.gii"
    
elif [ "$HEMI_TO_RUN" == "R" ]; then
    # ------------------ 处理右半球 (R) ------------------
    echo "--- 正在处理右半球 (Hemi = R) ---"

    # 1. 定义该半球的所有输入文件
    C1_IN="${BASE_PATH}IPL_connection_C1/average_R_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_R_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_R_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_R_projection_C4_native.func.gii"
    
    # 2. 定义该半球的输出文件名
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_R.func.gii"

else
    # ------------------ 无效输入处理 ------------------
    echo "错误: 脚本顶部的 HEMI_TO_RUN 变量必须设置为 'L' 或 'R'。"
    echo "当前设置为: '$HEMI_TO_RUN'。脚本已终止。"
    exit 1
fi

# 3. 执行统一的MPM计算命令 (无论L或R, 逻辑都一样)
echo "输入文件:"
echo "  C1: $C1_IN"
echo "  C2: $C2_IN"
echo "  C3: $C3_IN"
echo "  C4: $C4_IN"
echo "阈值: $THRESHOLD"
echo "输出文件: $OUTPUT_MPM"
echo "正在计算 MPM..."

# ####################################################################
# ######### 这是最终修正后的命令 (注意THR被替换为$THRESHOLD) #########
# ####################################################################
wb_command -metric-math \
   "max( \
        (C1 > $THRESHOLD) * C1, \
        max( (C2 > $THRESHOLD) * C2, \
             max( (C3 > $THRESHOLD) * C3, (C4 > $THRESHOLD) * C4 ) \
           ) \
      )" \
   "$OUTPUT_MPM" \
   -var C1 "$C1_IN" \
   -var C2 "$C2_IN" \
   -var C3 "$C3_IN" \
   -var C4 "$C4_IN"
 
echo "--- 计算完成! ---"
echo "最终MPM文件保存在: $OUTPUT_MPM"