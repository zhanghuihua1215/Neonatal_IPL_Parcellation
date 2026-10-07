import matplotlib
matplotlib.use('Agg') 

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from math import pi

csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/6_FC_Fingerprint_thre_4_sym_20/OPT11_Functional_Fingerprint_C1-C4.csv"
output_dir = os.path.dirname(csv_path)
save_name = "S71.png"

df = pd.read_csv(csv_path, index_col=0)

network_acronyms = [
    'LM', 'MM', 'MA', 'FPN', 
    'PPN', 'SMN', 'VIS', 'TPN', 
    'AUD', 'PFC', 'VAN'
]
N = len(network_acronyms)

angles = [n / float(N) * 2 * pi for n in range(N)]
angles += angles[:1] 

global_max = df.max().max()
y_limit = global_max * 1.1 

fig, axs = plt.subplots(nrows=2, ncols=4, figsize=(18, 10), subplot_kw=dict(polar=True))

row1_cols = ['C1_L', 'C2_L', 'C3_L', 'C4_L']
row2_cols = ['C1_R', 'C2_R', 'C3_R', 'C4_R']

color_L = '#1f77b4' 
color_R = '#d62728' 

def draw_one_radar(ax, col_name, color, title_y=1.2):
    values = df[col_name].values.flatten().tolist()
    values += values[:1]
    
    ax.set_theta_offset(pi / 2)
    ax.set_theta_direction(-1)
    
    ax.set_xticks(angles[:-1])
    ax.tick_params(axis='x', pad=12) 
    ax.set_xticklabels(network_acronyms, fontsize=14, fontweight='bold')
    
    ax.set_rlabel_position(0)
    ax.set_ylim(0, y_limit)
    
    y_ticks = np.linspace(0, y_limit, 7)[1:]
    ax.set_yticks(y_ticks)
    
    labels = [f"{val:.2f}" for val in y_ticks]
    labels[-1] = "" 
    
    ax.set_yticklabels(labels)
    plt.setp(ax.get_yticklabels(), fontsize=13, color="black") 
    
    ax.yaxis.grid(True, color='black', linestyle='-', linewidth=1.5, alpha=0.5) 
    ax.xaxis.grid(False)
    
    ax.spines['polar'].set_linewidth(2.0) 
    ax.spines['polar'].set_color('black')
    
    ax.plot(angles, values, linewidth=2, linestyle='solid', color=color)
    ax.fill(angles, values, color=color, alpha=0.25)
    
    display_title = col_name.split('_')[0]
    ax.set_title(display_title, size=22, fontweight='bold', color=color, y=title_y)

for i, col_name in enumerate(row1_cols):
    draw_one_radar(axs[0, i], col_name, color_L, title_y=1.17)

for i, col_name in enumerate(row2_cols):
    draw_one_radar(axs[1, i], col_name, color_R, title_y=1.17)

legend_text = "LM: Lateral motor, MM: Medial motor, MA: Motor association, FPN: Frontoparietal, PPN: Posterior parietal, SMN: Somatosensory\n"
legend_text += "VIS: Visual, TPN: Temporoparietal, AUD: Auditory, PFC: Prefrontal, VAN: Visual association"

fig.text(0.5, 0.06, legend_text, ha='center', fontsize=12, style='italic', color='dimgrey', linespacing=1.5)

fig.text(0.015, 0.75, 'Left Hemisphere', va='center', ha='center', rotation='vertical', fontsize=18, fontweight='bold')
fig.text(0.015, 0.31, 'Right Hemisphere', va='center', ha='center', rotation='vertical', fontsize=18, fontweight='bold')

plt.tight_layout()
plt.subplots_adjust(left=0.05, right=0.95, bottom=0.15, top=0.9, hspace=0.5, wspace=0.3)

save_path = os.path.join(output_dir, save_name)
plt.savefig(save_path, dpi=300, bbox_inches='tight')
plt.close()
