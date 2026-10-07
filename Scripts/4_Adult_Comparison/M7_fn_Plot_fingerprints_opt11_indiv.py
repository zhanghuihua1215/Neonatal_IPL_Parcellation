import matplotlib
# 1. 必须在最开始设置后端，防止服务器报错 "xcb"
matplotlib.use('Agg') 

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from math import pi

# ================= 配置区 =================
# [输入] 功能连接结果 CSV 路径
csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/6_FC_Fingerprint_map/OPT11_Functional_Fingerprint_C1-C4.csv"
#结构连接结果CSV路径
#csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/6_SC_Fingerprint_thre_3_sym_15/OPT11_Structure_Function_Fingerprint_C1-C4.csv"
# 图片保存路径
output_dir = os.path.dirname(csv_path)
save_name = "Fingerprint_Subplots_2x4.png"

# ================= 读取数据 =================
print(f"正在读取数据: {csv_path}")
df = pd.read_csv(csv_path, index_col=0)

# ================= 准备绘图参数 =================
# 1. 网络标签 (IC01, IC02...)
categories = list(df.index)
N = len(categories)

# 2. 计算角度 (将圆周分为 N 份)
angles = [n / float(N) * 2 * pi for n in range(N)]
angles += angles[:1] # 闭合圆周，让线条首尾相连

# 3. 计算统一的 Y 轴上限
# 为了让8张图可以相互比较，我们需要找到所有数据中的最大值
# 稍微加一点余量 (e.g., +0.02) 让图好看点
global_max = df.max().max()
y_limit = global_max * 1.1 
print(f"检测到数据最大值为: {global_max:.4f}，将统一设置 Y 轴上限为: {y_limit:.4f}")

# ================= 开始绘图 (2行 x 4列) =================
# figsize 设置图片大小 (宽, 高)，因为是 2x4，宽设大一点
fig, axs = plt.subplots(nrows=2, ncols=4, figsize=(24, 12), subplot_kw=dict(polar=True))

# 定义要画的列名顺序
# 第一排：左脑
row1_cols = ['C1_L', 'C2_L', 'C3_L', 'C4_L']
# 第二排：右脑
row2_cols = ['C1_R', 'C2_R', 'C3_R', 'C4_R']

# 定义颜色 (左脑用蓝色系，右脑用红色系，或者统一颜色)
color_L = '#1f77b4' # 经典蓝
color_R = '#d62728' # 经典红

# --- 辅助绘图函数 ---
def draw_one_radar(ax, col_name, color):
    # 获取数据并闭合
    values = df[col_name].values.flatten().tolist()
    values += values[:1]
    
    # 设置方向 (0度在顶部，顺时针)
    ax.set_theta_offset(pi / 2)
    ax.set_theta_direction(-1)
    
    # 设置 X 轴标签 (IC01...IC10)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(categories, fontsize=9)
    
    # 设置 Y 轴标签 (数值刻度)
    # 只要显示几个刻度即可，避免太乱
    ax.set_rlabel_position(0)
    plt.yticks(fontsize=8, color="grey")
    
    # 【关键】设置统一的 Y 轴范围
    ax.set_ylim(0, y_limit)
    
    # 画线
    ax.plot(angles, values, linewidth=2, linestyle='solid', color=color)
    
    # 填充面积
    ax.fill(angles, values, color=color, alpha=0.25)
    
    # 设置子图标题
    ax.set_title(col_name, size=16, color=color, y=1.1)

# --- 循环绘制 ---

# 1. 绘制第一排 (左脑)
for i, col_name in enumerate(row1_cols):
    print(f"  - 绘制: {col_name}")
    draw_one_radar(axs[0, i], col_name, color_L)

# 2. 绘制第二排 (右脑)
for i, col_name in enumerate(row2_cols):
    print(f"  - 绘制: {col_name}")
    draw_one_radar(axs[1, i], col_name, color_R)

# ================= 保存图片 =================
# 调整布局，防止标签重叠
plt.tight_layout()
plt.subplots_adjust(hspace=0.4) # 增加行间距

save_path = os.path.join(output_dir, save_name)
plt.savefig(save_path, dpi=300, bbox_inches='tight')

print("-" * 30)
print(f"绘图完成！图片已保存至:\n{save_path}")
print("-" * 30)
plt.close()