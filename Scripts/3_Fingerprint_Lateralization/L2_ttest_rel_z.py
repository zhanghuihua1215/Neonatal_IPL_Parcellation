import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.stats.multitest import multipletests
import os

input_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L1_FC_11Net_csv/"
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

target_networks = ['01', '06', '07', '08', '09', '11', '12', '14', '15', '16', '19']

def get_direction(row):
    if row['p_fdr'] < 0.05:
        return 'Left' if row['t_stat'] > 0 else 'Right'
    else:
        return 'Symmetric'

for sub_id in [1, 2, 3, 4]:
    input_file = os.path.join(input_dir, f"Subregion_{sub_id}_FC_to_11Networks.csv")
    
    if not os.path.exists(input_file):
        continue
    
    df = pd.read_csv(input_file)
    stats_results = []

    for net in target_networks:
        l_col = f'C{sub_id}_L_Net{net}'
        r_col = f'C{sub_id}_R_Net{net}'
        
        l_vals = df[l_col]
        r_vals = df[r_col]
        
        t_stat, p_val = stats.ttest_rel(l_vals, r_vals)
        
        stats_results.append({
            'Subregion': f'C{sub_id}',
            'Network': f'Net{net}',
            'Mean_L': l_vals.mean(),
            'Mean_R': r_vals.mean(),
            't_stat': t_stat,
            'p_val': p_val,
            'Diff': l_vals.mean() - r_vals.mean()
        })

    res_df = pd.DataFrame(stats_results)

    _, p_fdr, _, _ = multipletests(res_df['p_val'], method='fdr_bh')
    res_df['p_fdr'] = p_fdr

    res_df['Lateralization'] = res_df.apply(get_direction, axis=1)

    output_file = os.path.join(output_dir, f"Subregion_{sub_id}_Lateralization_Stats.csv")
    res_df.to_csv(output_file, index=False)
