import numpy as np
import nibabel as nib
from scipy import stats
import os
import subprocess
from itertools import permutations
# --- 新增导入 ---
from statsmodels.stats.multitest import multipletests 

# ================= 1. 配置路径 =================
base_dir = "/dat05/users/zhanghuihua/brain_development"
template_dir  = "/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/"
sub_list_path = os.path.join(base_dir, "dHCP_40_list.txt")
ses_list_path = os.path.join(base_dir, "dHCP_ses_list.txt")
input_root = os.path.join(base_dir, "less_out/fused_out/3_function_connection_out/1_FC_out_subregions")

# 修改输出目录名称以区分
output_dir = os.path.join(base_dir, "less_out/fused_out/3_function_connection_out/3_paired_t_test/smooth3_stat_fdrp_0.01/")
temp_dir = os.path.join(output_dir, "temp_smooth_files")

if not os.path.exists(output_dir): os.makedirs(output_dir)
if not os.path.exists(temp_dir): os.makedirs(temp_dir)

# 表面文件路径
L_surface = os.path.join(template_dir, "week-40_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii")
R_surface = os.path.join(template_dir, "week-40_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii")

# 参数设置
SMOOTH_FWHM = 3.0
P_THRESH = 0.01 # FDR 阈值
wb_command_path = "wb_command"

# ================= 2. 辅助函数 =================
# (save_custom_gii 和 process_and_smooth_subject 函数保持不变，见原代码)
def save_custom_gii(data, filename, hemi, template_gii, out_folder=output_dir):
    new_img = nib.gifti.GiftiImage()
    structure = 'CortexLeft' if hemi == 'L' else 'CortexRight'
    meta = {'AnatomicalStructurePrimary': structure}
    new_img.meta = nib.gifti.GiftiMetaData(meta)
    darray = nib.gifti.GiftiDataArray(data.astype(np.float32), intent=template_gii.darrays[0].intent, datatype=template_gii.darrays[0].datatype)
    darray.meta = nib.gifti.GiftiMetaData(meta)
    new_img.add_gifti_data_array(darray)
    path = os.path.join(out_folder, filename)
    nib.save(new_img, path)
    return path

def process_and_smooth_subject(in_path, hemi, template_gii):
  
    gii = nib.load(in_path)
    z_val = gii.darrays[0].data 
    base_name = os.path.basename(in_path)
    # 1. 将当前数据存为临时文件（Workbench 平滑命令需要文件输入）
    temp_input_path = save_custom_gii(z_val, f"temp_in_{base_name}", hemi, template_gii, temp_dir)
    temp_smooth_path = os.path.join(temp_dir, f"smoothed_{base_name}")
    # 2. 确定对应的表面文件
    surf = L_surface if hemi == 'L' else R_surface
    # 3. 计算 Sigma (FWHM = 2.35482 * sigma)
    sigma = SMOOTH_FWHM / 2.35482
    # 4. 调用 Workbench 进行表面平滑
    # -metric-smoothing 参数：<表面文件> <输入metric> <sigma> <输出路径>
    cmd = f"{wb_command_path} -metric-smoothing {surf} {temp_input_path} {sigma} {temp_smooth_path}"
    subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # 5. 读取平滑后的数据回内存
    smoothed_data = nib.load(temp_smooth_path).darrays[0].data
    # 6. 清理生成的临时磁盘文件
    if os.path.exists(temp_input_path): os.remove(temp_input_path)
    if os.path.exists(temp_smooth_path): os.remove(temp_smooth_path)
    return smoothed_data

# ================= 3. 数据准备 (同原代码) =================
with open(sub_list_path, 'r') as f:
    subs = [line.strip() for line in f.readlines() if line.strip()]
with open(ses_list_path, 'r') as f:
    sess = [line.strip() for line in f.readlines() if line.strip()]
subjects = list(zip(subs, sess))
subregions = [1, 2, 3, 4]
hemis = ['L', 'R']
pairs = list(permutations(subregions, 2))

# ================= 4. 读取与预处理 (同原代码) =================
data_store = {h: {} for h in hemis}
templates = {h: None for h in hemis}
print(f"开始加载数据并平滑...")
for h in hemis:
    for roi in subregions:
        roi_list = []
        for sub, ses in subjects:
            fname = f"sub-{sub}_Subregion_{roi}_FC.{h}.func.gii"
            path = os.path.join(input_root, f"IPL_{h}_4_subregions", fname)
            if not os.path.exists(path):
                path = os.path.join(input_root, f"IPL_{h}_4_subregions", f"{sub}_Subregion_{roi}_FC.{h}.func.gii")
            try:
                if templates[h] is None: templates[h] = nib.load(path)
                roi_list.append(process_and_smooth_subject(path, h, templates[h]))
            except Exception: pass
        data_store[h][roi] = np.array(roi_list)
        print(f"[{h}] Subregion {roi} 完成")

# ================= 5. 统计与生成结果 (重点修改部分) =================
print("\n开始进行配对 T 检验并进行 FDR 校正...")

for h in hemis:
    for i, j in pairs:
        print(f"正在计算 {h}: {i} > {j} (FDR)...")
        
        data_i = data_store[h][i]
        data_j = data_store[h][j]
        
        # 1. 配对 t 检验
        t_stats, p_vals = stats.ttest_rel(data_i, data_j, axis=0)
        
        # 2. FDR 校正处理
        # 处理 NaN (Medial Wall)
        mask_nan = np.isnan(p_vals)
        p_valid = p_vals[~mask_nan]
        
        # 初始化 FDR 结果数组
        reject = np.zeros_like(p_vals, dtype=bool)
        p_fdr = np.full_like(p_vals, 1.0)
        
        if len(p_valid) > 0:
            # 执行 Benjamini-Hochberg FDR 校正
            # reject: 显著性布尔值; pvals_corrected: 校正后的P值
            res_reject, res_pvals = multipletests(p_valid, alpha=P_THRESH, method='fdr_bh')[:2]
            reject[~mask_nan] = res_reject
            p_fdr[~mask_nan] = res_pvals
        
        # 3. 核心掩码逻辑：FDR 校正后的 P < 0.05 且 T > 0
        valid_mask_condition = (reject == True) & (t_stats > 0)
        
        # 4. 生成结果
        raw_pos_t = np.where(t_stats > 0, t_stats, 0) # 原始正 T
        binary_mask = np.where(valid_mask_condition, 1.0, 0.0) # FDR Mask
        masked_pos_t = np.where(valid_mask_condition, t_stats, 0) # 被 FDR 过滤后的 T
        
        # 5. 保存结果
        prefix = f"{h}_Sub_{i}_gt_{j}"
        save_custom_gii(raw_pos_t, f"{prefix}_1_RawPosT.func.gii", h, templates[h])
        save_custom_gii(binary_mask, f"{prefix}_2_FDRP01_Mask.func.gii", h, templates[h])
        save_custom_gii(masked_pos_t, f"{prefix}_3_FDRMaskedPosT.func.gii", h, templates[h])
        # 可选：保存校正后的 P 值图
        save_custom_gii(p_fdr, f"{prefix}_4_FDR_Pvals.func.gii", h, templates[h])

# 删除临时文件夹
try: os.rmdir(temp_dir)
except: pass

print(f"\n全部计算完成！结果保存在: {output_dir}")