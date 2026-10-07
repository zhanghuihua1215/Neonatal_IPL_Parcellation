import pandas as pd
import numpy as np
import nibabel as nib
import os

subject_list_file = "/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"

fc_dir_L = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions_zscore/IPL_L_4_subregions/"
fc_dir_R = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions_zscore/IPL_R_4_subregions/"

mask_dir = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/5_split_components_thre_4_sym_20_wta/mask_maps/"

target_networks = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19]

output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L1_FC_11Net_csv/"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

with open(subject_list_file, 'r') as f:
    subjects = [line.strip() for line in f.readlines() if line.strip()]

network_masks = {}

for net_id in target_networks:
    net_str = f"{net_id:02d}" 
    file_mask_L = os.path.join(mask_dir, f"mask_WTA_component_{net_str}_L_masked.func.gii")
    file_mask_R = os.path.join(mask_dir, f"mask_WTA_component_{net_str}_R_masked.func.gii")
    
    mask_data_L = nib.load(file_mask_L).darrays[0].data
    mask_data_R = nib.load(file_mask_R).darrays[0].data
    
    idx_L = np.where(mask_data_L > 0)[0]
    idx_R = np.where(mask_data_R > 0)[0]
    
    network_masks[net_id] = {'idx_L': idx_L, 'idx_R': idx_R}

for sub_id in [1, 2, 3, 4]:
    all_subjects_data = []

    for sub in subjects:
        sub_data_row = {'Subject': sub}
        
        file_fc_L = os.path.join(fc_dir_L, f"{sub}_Subregion_{sub_id}_FC.L.func.gii")
        file_fc_R = os.path.join(fc_dir_R, f"{sub}_Subregion_{sub_id}_FC.R.func.gii")
        
        if not os.path.exists(file_fc_L) or not os.path.exists(file_fc_R):
            continue
            
        fc_z_L = nib.load(file_fc_L).darrays[0].data
        fc_z_R = nib.load(file_fc_R).darrays[0].data
        
        for net_id in target_networks:
            net_str = f"{net_id:02d}"
            idx_L = network_masks[net_id]['idx_L']
            idx_R = network_masks[net_id]['idx_R']
            
            mean_z_L = np.mean(fc_z_L[idx_L]) if len(idx_L) > 0 else np.nan
            mean_z_R = np.mean(fc_z_R[idx_R]) if len(idx_R) > 0 else np.nan
            
            sub_data_row[f'C{sub_id}_L_Net{net_str}'] = mean_z_L
            sub_data_row[f'C{sub_id}_R_Net{net_str}'] = mean_z_R

        all_subjects_data.append(sub_data_row)

    df_subregion = pd.DataFrame(all_subjects_data)
    current_output_csv = os.path.join(output_dir, f"Subregion_{sub_id}_FC_to_11Networks.csv")
    df_subregion.to_csv(current_output_csv, index=False)
