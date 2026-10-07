import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import numpy as np
import os

base_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Later_out/Plot2_diff/'
os.makedirs(output_dir, exist_ok=True)

subregion_files = [
    'Subregion_1_Lateralization_Stats.csv',
    'Subregion_2_Lateralization_Stats.csv',
    'Subregion_3_Lateralization_Stats.csv',
    'Subregion_4_Lateralization_Stats.csv'
]

network_order = [
    'Lateral motor', 'Medial motor', 'Motor association', 'Frontoparietal',
    'Posterior parietal', 'Somatosensory', 'Visual', 'Temporoparietal',
    'Auditory', 'Prefrontal', 'Visual association'
]

network_acronyms = [
    'LM', 'MM', 'MA', 'FPN', 
    'PPN', 'SMN', 'VIS', 'TPN', 
    'AUD', 'PFC', 'VAN'
]

subregion_palette = {'C1': '#4e79a7', 'C2': '#f28e2b', 'C3': '#e15759', 'C4': '#76b7b2'}
subregion_order = ['C1', 'C2', 'C3', 'C4']

all_subregion_data = []
for file in subregion_files:
    file_path = os.path.join(base_dir, file)
    df = pd.read_csv(file_path)
    
    df['Subregion_Standard'] = df['Subregion'].apply(lambda x: str(x).split()[-1])
    df['Network'] = df['Network'].astype(str).str.strip().str.capitalize()
    
    df['Diff'] = pd.to_numeric(df['Diff'], errors='coerce')
    df['p_fdr'] = pd.to_numeric(df['p_fdr'], errors='coerce')
    df['p_val'] = pd.to_numeric(df['p_val'], errors='coerce')
    df['t_stat'] = pd.to_numeric(df['t_stat'], errors='coerce')
    
    df['SE'] = np.where(df['t_stat'] != 0, np.abs(df['Diff'] / df['t_stat']), 0)
    all_subregion_data.append(df)
    
combined_df = pd.concat(all_subregion_data, ignore_index=True)

network_order_clean = [name.strip().capitalize() for name in network_order]
combined_df = combined_df[combined_df['Network'].isin(network_order_clean)]

fig, ax = plt.subplots(figsize=(16, 7.8))

sns.barplot(
    data=combined_df,
    x='Network',
    y='Diff',
    hue='Subregion_Standard',
    order=network_order_clean, 
    hue_order=subregion_order,
    palette=subregion_palette,
    edgecolor='black',
    linewidth=1.2,
    ax=ax
)

shrink_factor = 0.8
for patch in ax.patches:
    current_width = patch.get_width()
    diff_width = current_width * (1 - shrink_factor)
    patch.set_width(current_width * shrink_factor)
    patch.set_x(patch.get_x() + diff_width / 2)

ax.axhline(0, color='grey', linestyle='--', linewidth=1)

ax.set_ylabel('Lateralization', fontsize=14, fontweight='bold')

ax.text(-0.015, 0.85, 'Left', transform=ax.transAxes, fontsize=12, 
        fontweight='bold', rotation=0, va='center', ha='right', color='black')

ax.text(-0.015, 0.15, 'Right', transform=ax.transAxes, fontsize=12, 
        fontweight='bold', rotation=0, va='center', ha='right', color='black')

ax.set_xlabel('') 
ax.set_xticklabels(network_acronyms, rotation=0, ha='center', fontsize=13, fontweight='bold')

ax.set_title('IPL Subregions Lateralization Pattern (C1-C4)', fontsize=20, fontweight='bold', pad=17)
ax.legend(title='Subregions', loc='upper right', frameon=False, bbox_to_anchor=(1, 1), fontsize=12, title_fontsize=12)

y_max = combined_df['Diff'].max() + combined_df['SE'].max()
y_min = combined_df['Diff'].min() - combined_df['SE'].max()
y_range = y_max - y_min
star_offset = 0.02 * y_range 

original_containers = [c for c in ax.containers if isinstance(c, matplotlib.container.BarContainer)]

for i, container in enumerate(original_containers):
    if i >= len(subregion_order):
        break
        
    current_subregion = subregion_order[i]
    
    for j, bar in enumerate(container):
        current_network_clean = network_order_clean[j]
        
        match_row = combined_df[(combined_df['Network'] == current_network_clean) & 
                                (combined_df['Subregion_Standard'] == current_subregion)]
        
        if not match_row.empty:
            p_value = match_row['p_fdr'].values[0] 
            diff = match_row['Diff'].values[0]
            se = match_row['SE'].values[0]
            
            x_center = bar.get_x() + bar.get_width() / 2
            
            if pd.notna(diff) and pd.notna(se) and se > 0:
                ax.errorbar(x_center, diff, yerr=se, fmt='none', ecolor='black', capsize=3, elinewidth=1, capthick=1)
            
            marker = ''
            if pd.notna(p_value):
                if p_value < 0.01: marker = '**'
                elif p_value < 0.05: marker = '*'
            
            if marker:
                if diff > 0:
                    final_y = diff + se + star_offset
                    va = 'bottom'
                else:
                    final_y = diff - se - star_offset
                    va = 'top'

                ax.text(x_center, final_y, marker, ha='center', va=va, color='red', fontsize=16, fontweight='bold')

ax.set_ylim(-0.025, y_max + 0.15 * y_range)
y_ticks = np.arange(-0.02, y_max + 0.15 * y_range, 0.02)
ax.set_yticks(y_ticks)

legend_text = "Significant levels: * p_fdr<0.05, ** p_fdr<0.01\n"
legend_text += "LM: Lateral motor, MM: Medial motor, MA: Motor association, FPN: Frontoparietal, PPN: Posterior parietal, SMN: Somatosensory\n"
legend_text += "VIS: Visual, TPN: Temporoparietal, AUD: Auditory, PFC: Prefrontal, VAN: Visual association"

fig.text(0.5, 0.01, legend_text, ha='center', fontsize=11, style='italic', color='dimgrey', linespacing=1.5)

plt.tight_layout()
plt.subplots_adjust(bottom=0.15, left=0.08)

output_file_path = os.path.join(output_dir, 'IPL_Subregions_Lateralization_Plot.png')
plt.savefig(output_file_path, dpi=300, bbox_inches='tight')
plt.close()
