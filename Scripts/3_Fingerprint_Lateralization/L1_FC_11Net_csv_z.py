import pandas as pd
import numpy as np
import nibabel as nib
import os

# ==========================================
# 1. 路径与变量配置
# ==========================================
# 被试列表
subject_list_file = "/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt"

# 左右脑全脑 FC 文件的基础目录
fc_dir_L = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions_zscore/IPL_L_4_subregions/"
fc_dir_R = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions_zscore/IPL_R_4_subregions/"

# ICA 网络 Mask 文件的基础目录
mask_dir = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/5_split_components_thre_4_sym_20_wta/mask_maps/"

# 指定 11 个网络编号
target_networks = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19]

# 输出目录 (如果不存在则创建)
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L1_FC_11Net_csv/"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print(f"创建输出目录: {output_dir}")

# ==========================================
# 2. 读取受试者列表
# ==========================================
with open(subject_list_file, 'r') as f:
    subjects = [line.strip() for line in f.readlines() if line.strip()]

print(f"成功读取受试者列表，共计 {len(subjects)} 名受试者。")

# ==========================================
# 3. 预加载 11 个网络的 Mask 数据 (只加载一次，节省时间)
# ==========================================
print("正在预加载 11 个目标网络的 Mask...")
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

print(f"成功加载 {len(network_masks)} 个网络的 Mask。")

# ==========================================
# 4. 核心循环：依次处理子区域 1, 2, 3, 4
# ==========================================
for sub_id in [1, 2, 3, 4]:
    print(f"\n--- 正在处理 Subregion {sub_id} ---")
    all_subjects_data = []

    for sub in subjects:
        sub_data_row = {'Subject': sub}
        
        # 动态构建当前子区域的 FC 文件名
        file_fc_L = os.path.join(fc_dir_L, f"{sub}_Subregion_{sub_id}_FC.L.func.gii")
        file_fc_R = os.path.join(fc_dir_R, f"{sub}_Subregion_{sub_id}_FC.R.func.gii")
        
        if not os.path.exists(file_fc_L) or not os.path.exists(file_fc_R):
            print(f"  警告: 找不到 {sub} 的 Subregion {sub_id} 文件，已跳过。")
            continue
            
        # 读取原始 Z 值
        fc_z_L = nib.load(file_fc_L).darrays[0].data
        fc_z_R = nib.load(file_fc_R).darrays[0].data
        
        
        
        #-----------------------------------------------
#        # 执行 Fisher's Z 变换 (r -> z)
#        fc_z_L = np.arctanh(np.clip(fc_r_L, -0.9999, 0.9999))
#        fc_z_R = np.arctanh(np.clip(fc_r_R, -0.9999, 0.9999))
#        
        #----------------------------------------------
        
        # 对 11 个网络依次计算平均 Z 值
        for net_id in target_networks:
            net_str = f"{net_id:02d}"
            idx_L = network_masks[net_id]['idx_L']
            idx_R = network_masks[net_id]['idx_R']
            
            # 计算平均 Z 值
            mean_z_L = np.mean(fc_z_L[idx_L]) if len(idx_L) > 0 else np.nan
            mean_z_R = np.mean(fc_z_R[idx_R]) if len(idx_R) > 0 else np.nan
            
            # 存入字典，列名根据子区域动态命名，如 C1_L_Net01
            sub_data_row[f'C{sub_id}_L_Net{net_str}'] = mean_z_L
            sub_data_row[f'C{sub_id}_R_Net{net_str}'] = mean_z_R

        all_subjects_data.append(sub_data_row)
        # print(f"  - {sub} 处理完成") # 如果觉得输出太多可以关掉这行

    # ==========================================
    # 5. 导出当前子区域的 CSV 结果
    # ==========================================
    df_subregion = pd.DataFrame(all_subjects_data)
    current_output_csv = os.path.join(output_dir, f"Subregion_{sub_id}_FC_to_11Networks.csv")
    df_subregion.to_csv(current_output_csv, index=False)

    print(f"Subregion {sub_id} 提取完成！文件保存至: {current_output_csv}")
    print(f"数据维度: {df_subregion.shape}")

print("\n所有子区域 (C1-C4) 处理全部大功告成！")