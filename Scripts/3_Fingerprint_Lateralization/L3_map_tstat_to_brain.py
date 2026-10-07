import pandas as pd
import numpy as np
import nibabel as nib
import os

csv_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"
mask_dir = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/5_split_components_thre_4_sym_20_wta/mask_maps/"
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L3_Brain_Maps/"
os.makedirs(output_dir, exist_ok=True)

network_to_id = {
    'Lateral motor': 1, 'Medial motor': 6, 'Motor association': 7,
    'Frontoparietal': 8, 'Posterior parietal': 9, 'Somatosensory': 11,
    'Visual': 12, 'Temporoparietal': 14, 'Auditory': 15,
    'Prefrontal': 16, 'Visual association': 19
}

template_gii_L = os.path.join(mask_dir, "mask_WTA_component_01_L_masked.func.gii")
template_gii_R = os.path.join(mask_dir, "mask_WTA_component_01_R_masked.func.gii")
img_L_temp = nib.load(template_gii_L)
img_R_temp = nib.load(template_gii_R)
num_vertices_L = img_L_temp.darrays[0].data.shape[0]
num_vertices_R = img_R_temp.darrays[0].data.shape[0]

summary_data = []

for sub_id in [1, 2, 3, 4]:
    current_csv = os.path.join(csv_dir, f"Subregion_{sub_id}_Lateralization_Stats.csv")
    
    if not os.path.exists(current_csv):
        continue

    df_sub = pd.read_csv(current_csv)
    df_sub['Network'] = df_sub['Network'].astype(str).str.strip().str.capitalize()

    significant_t_map = {}
    for index, row in df_sub.iterrows():
        net_name = row['Network']
        if net_name in network_to_id:
            net_id = network_to_id[net_name]
            
            if row['p_fdr'] < 0.05:
                significant_t_map[net_id] = row['t_stat']
                
                summary_data.append({
                    'Subregion': f"C{sub_id}",
                    'Network': net_name,
                    'T_value': round(row['t_stat'], 3)
                })
            else:
                significant_t_map[net_id] = 0.0

    final_brain_L = np.zeros(num_vertices_L, dtype=np.float32)
    final_brain_R = np.zeros(num_vertices_R, dtype=np.float32)

    for net_id in network_to_id.values():
        t_value = significant_t_map.get(net_id, 0.0)
        
        if t_value != 0:
            net_str = f"{net_id:02d}"
            file_mask_L = os.path.join(mask_dir, f"mask_WTA_component_{net_str}_L_masked.func.gii")
            file_mask_R = os.path.join(mask_dir, f"mask_WTA_component_{net_str}_R_masked.func.gii")
            
            mask_L = nib.load(file_mask_L).darrays[0].data
            mask_R = nib.load(file_mask_R).darrays[0].data
            
            final_brain_L[mask_L > 0] = t_value
            final_brain_R[mask_R > 0] = t_value

    img_L_temp.darrays[0].data = final_brain_L
    img_R_temp.darrays[0].data = final_brain_R

    out_L = os.path.join(output_dir, f"Significant_Lateralization_Tmap_C{sub_id}_L.func.gii")
    out_R = os.path.join(output_dir, f"Significant_Lateralization_Tmap_C{sub_id}_R.func.gii")

    nib.save(img_L_temp, out_L)
    nib.save(img_R_temp, out_R)

if summary_data:
    summary_df = pd.DataFrame(summary_data)
    summary_csv_path = os.path.join(output_dir, "Significant_Networks_Summary.csv")
    summary_df.to_csv(summary_csv_path, index=False)
