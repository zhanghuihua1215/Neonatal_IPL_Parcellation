import numpy as np
import nibabel as nib
from scipy import stats
import os
import subprocess
from itertools import permutations
from statsmodels.stats.multitest import multipletests 

base_dir = "/dat05/users/zhanghuihua/brain_development"
template_dir  = os.path.join(base_dir, "template/dhcpSym_template/")
sub_list_path = os.path.join(base_dir, "dHCP_40_list.txt")
ses_list_path = os.path.join(base_dir, "dHCP_ses_list.txt")
input_root = os.path.join(base_dir, "less_out/fused_out/3_function_connection_out/1_FC_out_subregions")
output_dir = os.path.join(base_dir, "less_out/fused_out/3_function_connection_out/3_paired_t_test/smooth3_stat_fdrp_0.01/")
temp_dir = os.path.join(output_dir, "temp_smooth_files")

os.makedirs(output_dir, exist_ok=True)
os.makedirs(temp_dir, exist_ok=True)

L_surface = os.path.join(template_dir, "week-40_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii")
R_surface = os.path.join(template_dir, "week-40_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii")

SMOOTH_FWHM = 3.0
P_THRESH = 0.01 
wb_command_path = "wb_command"

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
    temp_input_path = save_custom_gii(z_val, f"temp_in_{base_name}", hemi, template_gii, temp_dir)
    temp_smooth_path = os.path.join(temp_dir, f"smoothed_{base_name}")
    
    surf = L_surface if hemi == 'L' else R_surface
    sigma = SMOOTH_FWHM / 2.35482
    
    cmd = f"{wb_command_path} -metric-smoothing {surf} {temp_input_path} {sigma} {temp_smooth_path}"
    subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    smoothed_data = nib.load(temp_smooth_path).darrays[0].data
    
    if os.path.exists(temp_input_path): os.remove(temp_input_path)
    if os.path.exists(temp_smooth_path): os.remove(temp_smooth_path)
    return smoothed_data

with open(sub_list_path, 'r') as f:
    subs = [line.strip() for line in f.readlines() if line.strip()]
with open(ses_list_path, 'r') as f:
    sess = [line.strip() for line in f.readlines() if line.strip()]
    
subjects = list(zip(subs, sess))
subregions = [1, 2, 3, 4]
hemis = ['L', 'R']
pairs = list(permutations(subregions, 2))

data_store = {h: {} for h in hemis}
templates = {h: None for h in hemis}

for h in hemis:
    for roi in subregions:
        roi_list = []
        for sub, ses in subjects:
            fname = f"sub-{sub}_Subregion_{roi}_FC.{h}.func.gii"
            path = os.path.join(input_root, f"IPL_{h}_4_subregions", fname)
            if not os.path.exists(path):
                path = os.path.join(input_root, f"IPL_{h}_4_subregions", f"{sub}_Subregion_{roi}_FC.{h}.func.gii")
            try:
                if templates[h] is None: 
                    templates[h] = nib.load(path)
                roi_list.append(process_and_smooth_subject(path, h, templates[h]))
            except: 
                pass
        data_store[h][roi] = np.array(roi_list)

for h in hemis:
    for i, j in pairs:
        data_i = data_store[h][i]
        data_j = data_store[h][j]
        
        t_stats, p_vals = stats.ttest_rel(data_i, data_j, axis=0)
        
        mask_nan = np.isnan(p_vals)
        p_valid = p_vals[~mask_nan]
        
        reject = np.zeros_like(p_vals, dtype=bool)
        p_fdr = np.full_like(p_vals, 1.0)
        
        if len(p_valid) > 0:
            res_reject, res_pvals = multipletests(p_valid, alpha=P_THRESH, method='fdr_bh')[:2]
            reject[~mask_nan] = res_reject
            p_fdr[~mask_nan] = res_pvals
        
        valid_mask_condition = (reject == True) & (t_stats > 0)
        
        raw_pos_t = np.where(t_stats > 0, t_stats, 0) 
        binary_mask = np.where(valid_mask_condition, 1.0, 0.0) 
        masked_pos_t = np.where(valid_mask_condition, t_stats, 0) 
        
        prefix = f"{h}_Sub_{i}_gt_{j}"
        save_custom_gii(raw_pos_t, f"{prefix}_1_RawPosT.func.gii", h, templates[h])
        save_custom_gii(binary_mask, f"{prefix}_2_FDRP01_Mask.func.gii", h, templates[h])
        save_custom_gii(masked_pos_t, f"{prefix}_3_FDRMaskedPosT.func.gii", h, templates[h])
        save_custom_gii(p_fdr, f"{prefix}_4_FDR_Pvals.func.gii", h, templates[h])

try: 
    os.rmdir(temp_dir)
except: 
    pass
