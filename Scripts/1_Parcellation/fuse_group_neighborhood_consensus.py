import os
import nibabel as nib
import numpy as np
from collections import Counter
import time

L_T2W_INPUT_FILE = "/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_IPL_FisherZ_parcellation/IPL_L_sc_FisherZ_norm_32k/IPL.L.4.32k.func.gii"
L_FMRI_INPUT_FILE = "/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_IPL_FisherZ_parcellation/IPL_L_sc_FisherZ_norm_32k/IPL.L.4.32k.func.gii"

R_T2W_INPUT_FILE = L_T2W_INPUT_FILE.replace("IPL_L", "IPL_R").replace(".L.", ".R.")
R_FMRI_INPUT_FILE = L_FMRI_INPUT_FILE.replace("IPL_L", "IPL_R").replace(".L.", ".R.")

OUTPUT_DIR = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/"

L_SURF_GEOMETRY_FILE = "/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii"
R_SURF_GEOMETRY_FILE = "/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii"

def get_neighbor_map(geometry_file):
    try:
        surf = nib.load(geometry_file)
        faces = surf.darrays[1].data
        num_vertices = surf.darrays[0].data.shape[0]
        
        neighbors = [set() for _ in range(num_vertices)]
        for face in faces:
            neighbors[face[0]].update([face[1], face[2]])
            neighbors[face[1]].update([face[0], face[2]])
            neighbors[face[2]].update([face[0], face[1]])
            
        neighbor_map = {i: list(n) for i, n in enumerate(neighbors)}
        return neighbor_map
    except Exception:
        exit()

def fuse_parcellations(t2w_gii_path, fmri_gii_path, neighbor_map):
    t2w_labels = nib.load(t2w_gii_path).darrays[0].data
    fmri_labels = nib.load(fmri_gii_path).darrays[0].data
    fused_labels = np.zeros_like(t2w_labels, dtype=t2w_labels.dtype)
    agreement_indices = np.where(t2w_labels == fmri_labels)[0]
    disagreement_indices = np.where(t2w_labels != fmri_labels)[0]
    fused_labels[agreement_indices] = t2w_labels[agreement_indices]

    unresolved_count = 0
    for vertex_idx in disagreement_indices:
        neighbors = neighbor_map.get(vertex_idx, [])
        if not neighbors:
            fused_labels[vertex_idx] = fmri_labels[vertex_idx]
            unresolved_count += 1
            continue
        neighbor_labels = fused_labels[neighbors]
        stable_neighbor_labels = neighbor_labels[neighbor_labels > 0]
        if len(stable_neighbor_labels) > 0:
            vote_counts = Counter(stable_neighbor_labels)
            winner_label = vote_counts.most_common(1)[0][0]
            fused_labels[vertex_idx] = winner_label
        else:
            fused_labels[vertex_idx] = fmri_labels[vertex_idx]
            unresolved_count += 1

    return fused_labels

if __name__ == "__main__":
    start_time = time.time()
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    neighbor_map_L = get_neighbor_map(L_SURF_GEOMETRY_FILE)
    neighbor_map_R = get_neighbor_map(R_SURF_GEOMETRY_FILE)
    
    for hemi, neighbor_map, t2w_path, fmri_path in [
        ('L', neighbor_map_L, L_T2W_INPUT_FILE, L_FMRI_INPUT_FILE),
        ('R', neighbor_map_R, R_T2W_INPUT_FILE, R_FMRI_INPUT_FILE)
    ]:
        output_gii_path = os.path.join(OUTPUT_DIR, f"Group_Fused.{hemi}.4.32k.func.gii")

        if not os.path.exists(t2w_path) or not os.path.exists(fmri_path):
            continue

        fused_data = fuse_parcellations(t2w_path, fmri_path, neighbor_map)
        
        darray = nib.gifti.GiftiDataArray(fused_data, intent='NIFTI_INTENT_LABEL')
        gii_image = nib.gifti.GiftiImage(darrays=[darray])
        nib.save(gii_image, output_gii_path)

    end_time = time.time()
