import pandas as pd
import numpy as np
import os
import matplotlib
matplotlib.use('Agg') # 必须在 pyplot 导入之前调用
import matplotlib.pyplot as plt
import seaborn as sns

# ==========================================
# 1. 路径配置
# ==========================================
# 输入目录：存放之前的 4 个统计 CSV
input_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"

# 输出目录：存放绘图结果
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/Plot1_t_star/"

# 如果输出目录不存在则创建
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print(f"已创建输出目录: {output_dir}")

# ==========================================
# 2. 读取并合并数据
# ==========================================
all_data = []
for i in range(1, 5):
    file_path = os.path.join(input_dir, f"Subregion_{i}_Lateralization_Stats.csv")
    if os.path.exists(file_path):
        df = pd.read_csv(file_path)
        all_data.append(df)
    else:
        print(f"警告: 找不到文件 {file_path}")

if not all_data:
    print("错误: 没有读取到任何数据，请检查输入路径。")
    exit()

full_df = pd.concat(all_data)

# 准备绘图矩阵：横坐标是 Network，纵坐标是 Subregion
t_matrix = full_df.pivot(index='Subregion', columns='Network', values='t_stat')
p_matrix = full_df.pivot(index='Subregion', columns='Network', values='p_fdr')

# ==========================================
# 3. 绘制热图
# ==========================================
plt.figure(figsize=(16, 8))

# 使用 RdBu_r 调色盘（红色代表左偏，蓝色代表右偏，中心白色代表对称）
# annot=True 会在格子里显示 t 值
ax = sns.heatmap(t_matrix, annot=True, cmap='RdBu_r', center=0, fmt=".2f",
                 linewidths=0.5, linecolor='gray',
                 cbar_kws={'label': 't-statistic (Positive: Left > Right)'})

# 在显著的格子上添加星号 (*)
for i in range(len(t_matrix.index)):
    for j in range(len(t_matrix.columns)):
        p_val = p_matrix.iloc[i, j]
        # 根据显著性水平决定星号数量
        if p_val < 0.05:
            star = '*'
            if p_val < 0.01: star = '**'
            if p_val < 0.001: star = '***'
            
            # 将星号绘制在格子的中上部
            ax.text(j + 0.5, i + 0.15, star, 
                    ha='center', va='center', 
                    color='black', fontsize=20, fontweight='bold')

plt.title('IPL Subregions Lateralization Pattern (C1-C4)\nSignificant levels: * p_fdr<0.05, ** p_fdr<0.01, *** p_fdr<0.001', 
          fontsize=16, pad=20)
plt.ylabel('IPL Subregions', fontsize=14)
plt.xlabel('ICA Functional Networks', fontsize=14)

# 调整布局防止标签被遮挡
plt.tight_layout()

# ==========================================
# 4. 保存结果
# ==========================================
save_path_png = os.path.join(output_dir, "IPL_C1-C4_Lateralization_Heatmap.png")
save_path_pdf = os.path.join(output_dir, "IPL_C1-C4_Lateralization_Heatmap.pdf")

plt.savefig(save_path_png, dpi=300, bbox_inches='tight')
plt.savefig(save_path_pdf, bbox_inches='tight')

print(f"\n可视化大功告成！")
print(f"PNG 图片已保存至: {save_path_png}")
print(f"PDF 文件已保存至: {save_path_pdf}")

# 如果在有显示桌面的环境下可以显示
# plt.show()