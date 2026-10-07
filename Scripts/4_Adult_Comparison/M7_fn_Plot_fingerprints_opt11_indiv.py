import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from math import pi

csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/6_FC_Fingerprint_map/OPT11_Functional_Fingerprint_C1-C4.csv"
output_dir = os.path.dirname(csv_path)
save_name = "Fingerprint_Subplots_2x4.png"

df = pd.read_csv(csv_path, index_col=0)

categories = list(df.index)
N = len(categories)

angles = [n / float(N) * 2 * pi for n in range(N)]
angles += angles[:1] 

global_max = df.max().max()
y_limit = global_max * 1.1 

fig, axs = plt.subplots(nrows=2, ncols=4, figsize=(24, 12), subplot_kw=dict(polar=True))

row1_cols = ['C1_L', 'C2_L', 'C3_L', 'C4_L']
row2_cols = ['C1_R', 'C2_R', 'C3_R', 'C4_R']

color_L = '#1f77b4' 
color_R = '#d62728' 

def draw_one_radar(ax, col_name, color):
    values = df[col_name].values.flatten().tolist()
    values += values[:1]
    
    ax.set_theta_offset(pi / 2)
    ax.set_theta_direction(-1)
    
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(categories, fontsize=9)
    
    ax.set_rlabel_position(0)
    plt.yticks(fontsize=8, color="grey")
    
    ax.set_ylim(0, y_limit)
    
    ax.plot(angles, values, linewidth=2, linestyle='solid', color=color)
    ax.fill(angles, values, color=color, alpha=0.25)
    
    ax.set_title(col_name, size=16, color=color, y=1.1)

for i, col_name in enumerate(row1_cols):
    draw_one_radar(axs[0, i], col_name, color_L)

for i, col_name in enumerate(row2_cols):
    draw_one_radar(axs[1, i], col_name, color_R)

plt.tight_layout()
plt.subplots_adjust(hspace=0.4) 

save_path = os.path.join(output_dir, save_name)
plt.savefig(save_path, dpi=300, bbox_inches='tight')
plt.close()
