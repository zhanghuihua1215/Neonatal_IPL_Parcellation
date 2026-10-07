import pandas as pd
import numpy as np
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

input_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/Plot1_t_star/"

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

all_data = []
for i in range(1, 5):
    file_path = os.path.join(input_dir, f"Subregion_{i}_Lateralization_Stats.csv")
    if os.path.exists(file_path):
        df = pd.read_csv(file_path)
        all_data.append(df)

if not all_data:
    exit()

full_df = pd.concat(all_data)

t_matrix = full_df.pivot(index='Subregion', columns='Network', values='t_stat')
p_matrix = full_df.pivot(index='Subregion', columns='Network', values='p_fdr')

plt.figure(figsize=(16, 8))

ax = sns.heatmap(t_matrix, annot=True, cmap='RdBu_r', center=0, fmt=".2f",
                 linewidths=0.5, linecolor='gray',
                 cbar_kws={'label': 't-statistic (Positive: Left > Right)'})

for i in range(len(t_matrix.index)):
    for j in range(len(t_matrix.columns)):
        p_val = p_matrix.iloc[i, j]
        if p_val < 0.05:
            star = '*'
            if p_val < 0.01: star = '**'
            if p_val < 0.001: star = '***'
            
            ax.text(j + 0.5, i + 0.15, star, 
                    ha='center', va='center', 
                    color='black', fontsize=20, fontweight='bold')

plt.title('IPL Subregions Lateralization Pattern (C1-C4)\nSignificant levels: * p_fdr<0.05, ** p_fdr<0.01, *** p_fdr<0.001', 
          fontsize=16, pad=20)
plt.ylabel('IPL Subregions', fontsize=14)
plt.xlabel('ICA Functional Networks', fontsize=14)

plt.tight_layout()

save_path_png = os.path.join(output_dir, "IPL_C1-C4_Lateralization_Heatmap.png")
save_path_pdf = os.path.join(output_dir, "IPL_C1-C4_Lateralization_Heatmap.pdf")

plt.savefig(save_path_png, dpi=300, bbox_inches='tight')
plt.savefig(save_path_pdf, bbox_inches='tight')
plt.close()
