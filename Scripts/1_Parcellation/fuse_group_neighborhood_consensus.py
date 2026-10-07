import os
import nibabel as nib
import numpy as np
from collections import Counter
import time

# --- 1. 用户配置区 (已修改) ---

# 输入的组水平文件路径
L_T2W_INPUT_FILE = "/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_IPL_FisherZ_parcellation/IPL_L_sc_FisherZ_norm_32k/IPL.L.4.32k.func.gii"
L_FMRI_INPUT_FILE = "/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_IPL_FisherZ_parcellation/IPL_L_sc_FisherZ_norm_32k/IPL.L.4.32k.func.gii"

# 根据左脑路径自动推断右脑路径 (请确认路径结构是否一致)
R_T2W_INPUT_FILE = L_T2W_INPUT_FILE.replace("IPL_L", "IPL_R").replace(".L.", ".R.")
R_FMRI_INPUT_FILE = L_FMRI_INPUT_FILE.replace("IPL_L", "IPL_R").replace(".L.", ".R.")

# 输出路径 (仅目录)
OUTPUT_DIR = "/dat05/users/zhanghuihua/brain_development/less_out/fused_out/"

# !! 关键 !! 曲面几何文件路径 (依然需要)
L_SURF_GEOMETRY_FILE = "/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-left_space-dhcpSym_dens-32k_midthickness.surf.gii"
R_SURF_GEOMETRY_FILE = "/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/week-40_hemi-right_space-dhcpSym_dens-32k_midthickness.surf.gii"

# --- 结束配置区 ---


def get_neighbor_map(geometry_file):
    """
    根据曲面几何文件，预先计算每个顶点的邻居列表。(此函数无任何修改)
    """
    print(f"    正在从 {os.path.basename(geometry_file)} 加载几何结构并计算邻居地图...")
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
        print(f"    邻居地图计算完成，共 {num_vertices} 个顶点。")
        return neighbor_map
    except FileNotFoundError:
        print(f"错误：未找到几何文件 {geometry_file}！")
        exit()
    except Exception as e:
        print(f"加载或处理几何文件时发生错误: {e}")
        exit()


def fuse_parcellations(t2w_gii_path, fmri_gii_path, neighbor_map):
    """
    执行单个文件的融合逻辑。(此函数无任何修改)
    """
    t2w_labels = nib.load(t2w_gii_path).darrays[0].data
    fmri_labels = nib.load(fmri_gii_path).darrays[0].data
    fused_labels = np.zeros_like(t2w_labels, dtype=t2w_labels.dtype)
    agreement_indices = np.where(t2w_labels == fmri_labels)[0]
    disagreement_indices = np.where(t2w_labels != fmri_labels)[0]
    fused_labels[agreement_indices] = t2w_labels[agreement_indices]
    
    print(f"    - 共有 {len(t2w_labels)} 个顶点。")
    print(f"    - {len(agreement_indices)} 个顶点达成一致 ({len(agreement_indices)/len(t2w_labels):.2%})。")
    print(f"    - {len(disagreement_indices)} 个顶点存在分歧，开始进行邻域共识仲裁...")

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
    
    if unresolved_count > 0:
        print(f"    - {unresolved_count} 个分歧顶点因无稳定邻居而采用'功能优先'规则。")
    print("    仲裁完成。")

    return fused_labels

# --- 主程序 (已修改) ---
if __name__ == "__main__":
    start_time = time.time()
    
    print("--- 开始对组水平(Group-Level)结果进行融合 ---")
    
    # 确保输出目录存在
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 预加载几何文件并计算邻居地图
    print("\n--- 预加载几何数据 ---")
    neighbor_map_L = get_neighbor_map(L_SURF_GEOMETRY_FILE)
    neighbor_map_R = get_neighbor_map(R_SURF_GEOMETRY_FILE)
    
    # 按左右半球顺序处理
    for hemi, neighbor_map, t2w_path, fmri_path in [
        ('L', neighbor_map_L, L_T2W_INPUT_FILE, L_FMRI_INPUT_FILE),
        ('R', neighbor_map_R, R_T2W_INPUT_FILE, R_FMRI_INPUT_FILE)
    ]:
        print(f"\n--- 正在处理半球: {'左脑' if hemi == 'L' else '右脑'} ---")
        
        # 定义输出文件名
        output_gii_path = os.path.join(OUTPUT_DIR, f"Group_Fused.{hemi}.4.32k.func.gii")

        # 检查输入文件是否存在
        if not os.path.exists(t2w_path) or not os.path.exists(fmri_path):
            print(f"    !! 错误: 缺少输入文件，跳过 {hemi} 半球。")
            print(f"    - 检查路径: {t2w_path}")
            print(f"    - 检查路径: {fmri_path}")
            continue

        # 执行融合
        fused_data = fuse_parcellations(t2w_path, fmri_path, neighbor_map)
        
        # 保存结果为新的.gii文件
        darray = nib.gifti.GiftiDataArray(fused_data, intent='NIFTI_INTENT_LABEL')
        gii_image = nib.gifti.GiftiImage(darrays=[darray])
        nib.save(gii_image, output_gii_path)
        
        print(f"    融合结果已保存至: {output_gii_path}")

    end_time = time.time()
    print(f"\n--- 所有处理完成！总耗时: {end_time - start_time:.2f} 秒 ---")