import matplotlib
# 1. 必须在最开始设置后端，防止在没有图形界面的 Linux 服务器上报错 "xcb"
matplotlib.use('Agg') 

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from math import pi
import matplotlib.ticker as ticker 

# ================= 1. 配置区 =================
# [输入] 功能连接结果 CSV 路径
#csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/6_SC_Fingerprint_thre_4_sym_20/OPT11_Structure_Function_Fingerprint_C1-C4.csv"
csv_path = "/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/6_FC_Fingerprint_thre_4_sym_20/OPT11_Functional_Fingerprint_C1-C4.csv"
# [输出] 图片保存路径与名称
output_dir = os.path.dirname(csv_path)
save_name = "S71.png"

# ================= 2. 读取数据 =================
print(f"正在读取数据: {csv_path}")
# 读取CSV文件，假设第一列是原本冗长的网络名称，将其设定为索引
df = pd.read_csv(csv_path, index_col=0)

# ================= 3. 定义网络缩写名称 =================
# [核心修改] 直接定义 11 个网络的标准缩写，用于雷达图的外圈标签
network_acronyms = [
    'LM', 'MM', 'MA', 'FPN', 
    'PPN', 'SMN', 'VIS', 'TPN', 
    'AUD', 'PFC', 'VAN'
]
# N 表示网络（变量）的数量，这里是 11
N = len(network_acronyms)

# ================= 4. 准备雷达图的角度 =================
# 计算圆周上每个变量的角度 (将 2π 等分为 N 份)
angles = [n / float(N) * 2 * pi for n in range(N)]
# 闭合雷达图的线条：将第一个角度加到列表末尾，使数据首尾相连
angles += angles[:1] 

# ================= 5. 计算统一的 Y 轴上限 =================
# 获取整个数据框中的最大值
global_max = df.max().max()
# 将上限设置为最大值的 1.1 倍，留出视觉空间，避免图线顶到图表边缘
y_limit = global_max * 1.1 
print(f"检测到数据最大值为: {global_max:.4f}，将统一设置 Y 轴上限为: {y_limit:.4f}")

# ================= 6. 初始化画布 (2行 x 4列) =================
# 创建一个 24x12 英寸的画板，包含 8 个子图，开启极坐标模式 (polar=True)
fig, axs = plt.subplots(nrows=2, ncols=4, figsize=(18, 10), subplot_kw=dict(polar=True))

# 定义左脑和右脑对应的列名（必须和您 CSV 中的列名一致）
row1_cols = ['C1_L', 'C2_L', 'C3_L', 'C4_L']
row2_cols = ['C1_R', 'C2_R', 'C3_R', 'C4_R']

# 定义雷达图配色
color_L = '#1f77b4' # 左脑用经典蓝
color_R = '#d62728' # 右脑用经典红

# ================= 7. 核心绘图函数 =================
def draw_one_radar(ax, col_name, color, title_y=1.2):
    """
    在指定的单个子图 (ax) 上绘制雷达图
    :param ax: 当前操作的 matplotlib 子图对象
    :param col_name: 要提取的 CSV 列名 (如 'C1_L')
    :param color: 雷达图的线框和填充颜色
    :param title_y: 标题在垂直方向的偏移量，防止和外圈标签重叠
    """
    # 取出该列的所有数值，并打平为列表
    values = df[col_name].values.flatten().tolist()
    # 闭合数据点：将第一个数据加到列表末尾，确保线条闭合
    values += values[:1]
    
    # 设置极坐标零点位置：pi/2 代表将起始点 (0度) 放在正上方
    ax.set_theta_offset(pi / 2)
    # 设置旋转方向：-1 代表数值顺时针排布
    ax.set_theta_direction(-1)
    
    # 设置 X 轴的刻度线位置 (即 11 个角的顶点)
    ax.set_xticks(angles[:-1])
    
    # [核心修改] 给 8 个图全部换上网络缩写标签
    # pad=20 用于把文字往外推一点，防止缩写和最外圈的数值撞车
    # 取消了 rotation=-45，因为缩写很短，水平放置最符合学术审美
    ax.tick_params(axis='x', pad=12) 
    ax.set_xticklabels(network_acronyms, fontsize=14, fontweight='bold')
    
    # 设置 Y 轴数值标签 (如 0.20, 0.40) 的显示位置，0 代表在顶部的垂直轴上显示
    ax.set_rlabel_position(0)
    
    # 强制统一 8 个子图的 Y 轴范围，确保它们在视觉上具备严格可比性
    ax.set_ylim(0, y_limit)
    
    # 1. 精确画出 6 个等距的同心圆
    y_ticks = np.linspace(0, y_limit, 7)[1:]
    ax.set_yticks(y_ticks)
    
    # 2. [核心修改] 手动生成标签，并将最外圈的标签设为空白
    # 先把所有刻度转换成保留两位小数的字符串
    labels = [f"{val:.2f}" for val in y_ticks]
    # 把列表中的最后一个元素（也就是最外圈的数值）替换为空字符串
    labels[-1] = "" 
    
    # 3. 将修改后的标签应用到图表上 (此时不再需要 FormatStrFormatter)
    ax.set_yticklabels(labels)
    
    # 设置 Y 轴数值标签的字体大小和颜色
    plt.setp(ax.get_yticklabels(), fontsize=13, color="black") 
    
    # 定制雷达图内部蜘蛛网格线和最外圈边框的样式
    # ax.grid(True, color='black', linestyle='-', linewidth=1.5, alpha=0.5) 
    
    # 1. 只开启 Y 轴网格（保留一圈一圈的同心圆）
    ax.yaxis.grid(True, color='black', linestyle='-', linewidth=1.5, alpha=0.5) 
    # 2. 强制关闭 X 轴网格（去掉从圆心辐射出去的竖线）
    ax.xaxis.grid(False)
    
    ax.spines['polar'].set_linewidth(2.0) 
    ax.spines['polar'].set_color('black')
    
    # 绘制雷达图的加粗折线轮廓
    ax.plot(angles, values, linewidth=2, linestyle='solid', color=color)
    
    # 填充雷达图折线内部的颜色并设置透明度
    ax.fill(angles, values, color=color, alpha=0.25)
    
    # ================= 修改 1：动态修改子图标题 =================
    # 将 'C1_L' 截取为 'C1'
    display_title = col_name.split('_')[0]
    ax.set_title(display_title, size=22, fontweight='bold', color=color, y=title_y)
    # ============================================================

# ================= 8. 循环调用绘图 =================
# 绘制第一排 (左脑)，传入专属的蓝色
for i, col_name in enumerate(row1_cols):
    print(f"  - 绘制: {col_name}")
    draw_one_radar(axs[0, i], col_name, color_L, title_y=1.17)

# 绘制第二排 (右脑)，传入专属的红色
for i, col_name in enumerate(row2_cols):
    print(f"  - 绘制: {col_name}")
    draw_one_radar(axs[1, i], col_name, color_R, title_y=1.17)

# ================= 9. 添加底部说明文本与侧边行标签 =================
# [核心修改] 准备您提供的底部缩写释义文字
legend_text = "LM: Lateral motor, MM: Medial motor, MA: Motor association, FPN: Frontoparietal, PPN: Posterior parietal, SMN: Somatosensory\n"
legend_text += "VIS: Visual, TPN: Temporoparietal, AUD: Auditory, PFC: Prefrontal, VAN: Visual association"

# 在整个画板底部的中间偏下位置 (x=0.5, y=0.02) 插入说明文本
fig.text(0.5, 0.06, legend_text, ha='center', fontsize=12, style='italic', color='dimgrey', linespacing=1.5)

# ================= 修改 2：在整个画布最左侧添加行标签 =================
fig.text(0.015, 0.75, 'Left Hemisphere', va='center', ha='center', rotation='vertical', fontsize=18, fontweight='bold')
fig.text(0.015, 0.31, 'Right Hemisphere', va='center', ha='center', rotation='vertical', fontsize=18, fontweight='bold')
# ====================================================================

# ================= 10. 调整布局并保存 =================
# 自动收紧周围的空白
plt.tight_layout()

# 手动调整 left=0.08 为行标签留出空间，bottom=0.15 腾出空间给底部的说明文本
plt.subplots_adjust(left=0.05, right=0.95, bottom=0.15, top=0.9, hspace=0.5, wspace=0.3)

# 拼接完整的保存路径
save_path = os.path.join(output_dir, save_name)
# 以 300 分辨率保存高清图片
plt.savefig(save_path, dpi=300, bbox_inches='tight')

print("-" * 30)
print(f"绘图完成！图片已保存至:\n{save_path}")
print("-" * 30)
# 关闭画板，释放服务器内存
plt.close()