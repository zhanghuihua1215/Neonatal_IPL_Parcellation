import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.stats.multitest import multipletests
import os

# ==========================================
# 1. 路径与变量配置
# ==========================================
# 输入 CSV 所在的目录（上一步脚本生成的结果）
input_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L1_FC_11Net_csv/"

# 统计结果输出目录
output_dir = "/dat05/users/zhanghuihua/brain_development/less_out/Later_out/L2_tt_Later_result_csv/"

# 如果输出目录不存在则创建
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print(f"创建输出目录: {output_dir}")

target_networks = ['01', '06', '07', '08', '09', '11', '12', '14', '15', '16', '19']

# 定义判断偏侧化方向的函数
def get_direction(row):
    if row['p_fdr'] < 0.05:
        return 'Left' if row['t_stat'] > 0 else 'Right'
    else:
        return 'Symmetric'

# ==========================================
# 2. 核心循环：依次计算 Subregion 1, 2, 3, 4
# ==========================================
for sub_id in [1, 2, 3, 4]:
    print(f"\n--- 正在统计 Subregion {sub_id} ---")
    
    # 构建输入文件名
    input_file = os.path.join(input_dir, f"Subregion_{sub_id}_FC_to_11Networks.csv")
    
    # 检查文件是否存在
    if not os.path.exists(input_file):
        print(f"  警告: 找不到文件 {input_file}，跳过该子区域。")
        continue
    
    # 读取数据
    df = pd.read_csv(input_file)
    stats_results = []

    # 逐一网络计算配对 t 检验
    for net in target_networks:
        # 这里的列名对应上一步生成的 C1_L_Net01, C2_L_Net01 等
        l_col = f'C{sub_id}_L_Net{net}'
        r_col = f'C{sub_id}_R_Net{net}'
        
        l_vals = df[l_col]
        r_vals = df[r_col]
        
        # 配对样本 t 检验 (Left vs Right)
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

    # 整理成表格
    res_df = pd.DataFrame(stats_results)

    # 进行 FDR 多重比较校正 (针对当前子区域的 11 个网络)
    _, p_fdr, _, _ = multipletests(res_df['p_val'], method='fdr_bh')
    res_df['p_fdr'] = p_fdr

    # 判定偏侧化方向
    res_df['Lateralization'] = res_df.apply(get_direction, axis=1)

    # 打印简要结果
    print(res_df[['Network', 't_stat', 'p_fdr', 'Lateralization']])

    # 保存单个子区域的统计结果
    output_file = os.path.join(output_dir, f"Subregion_{sub_id}_Lateralization_Stats.csv")
    res_df.to_csv(output_file, index=False)
    print(f"Subregion {sub_id} 统计完成，结果已保存至: {output_file}")

print("\n所有子区域 (C1-C4) 的统计分析已全部完成！")