clear; close all; clc;

%% --- 1. 参数配置 ---
% [路径配置]
% 必须包含 gifti 工具箱
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

% 输入目录 (存放 ICA split components 的地方)
input_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/z/1_20_new_11/1_split_components_thre_4_sym_20/';

% 输出目录 (存放最终互不重叠的结果)
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/z/1_20_new_11/2_split_components_thre_4_sym_20_wta/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% [网络定义]
% 你选定的11个网络 ID
%target_ids = [1, 7, 8, 10, 11, 12, 13, 14, 15, 17, 19];
target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];
%target_ids = [1, 2, 4, 5, 6, 7, 9, 10, 12, 13, 14];

num_networks = length(target_ids);

% 半脑定义
hemispheres = {'L', 'R'};

%% --- 2. 循环处理左右半脑 ---
for h = 1:length(hemispheres)
    hemi = hemispheres{h}; % 当前半脑 'L' 或 'R'
    fprintf('正在处理半脑: %s ...\n', hemi);
    
    %% 2.1 读取所有网络数据到矩阵中
    % 我们需要构建一个矩阵: [顶点数 x 网络数]
    % 先读取第一个文件来获取顶点数量
    temp_name = fullfile(input_dir, sprintf('component_%02d_%s.func.gii', target_ids(1), hemi));
    g_ref = gifti(temp_name);
    num_verts = size(g_ref.cdata, 1);
    
    % 初始化大矩阵
    data_matrix = zeros(num_verts, num_networks);
    
    for i = 1:num_networks
        net_id = target_ids(i);
        % 注意文件名格式 component_01_L.func.gii (需要补零 %02d)
        fname = fullfile(input_dir, sprintf('component_%02d_%s.func.gii', net_id, hemi));
        
        if exist(fname, 'file')
            g = gifti(fname);
            data_matrix(:, i) = g.cdata;
        else
            warning('文件不存在: %s', fname);
        end
    end
    
    %% 2.2 执行 "赢者通吃" (Winner-Takes-All) 算法
    fprintf('  - 计算最大重叠归属...\n');
    
    % max 函数返回每一行的最大值(max_val)和对应的列索引(max_idx)
    % max_idx 的范围是 1 到 11
    [max_vals, max_idx] = max(data_matrix, [], 2);
    
    % 初始化最终标签图 (全为0)
    final_labels = zeros(num_verts, 1);
    
    % 只有当最大值大于0时，才进行赋值 (排除背景)
    % 如果你的原始数据有负值且代表反相关，这里可能需要取 abs(data_matrix)，但通常 component 图已处理为正值
    mask_valid = max_vals > 0; 
    
    % 将矩阵索引 (1-11) 映射回真实的 Network ID (1, 7, 19...)
    % max_idx(mask_valid) 提取了有效顶点的列号
    % target_ids(...) 将列号转为真实的 ID
    final_labels(mask_valid) = target_ids(max_idx(mask_valid));
    
    %% 2.3 保存完整的标签图谱 (Combined Map)
    out_name_combined = fullfile(output_dir, sprintf('Combined_Parcellation_11Net_%s.func.gii', hemi));
    
    g_out = g_ref; % 复制元数据结构
    g_out.cdata = single(final_labels); % 替换数据
    save(g_out, out_name_combined);
    fprintf('  - 已保存完整图谱: %s\n', out_name_combined);
    
    %% 2.4 保存独立的互不重叠网络 (Individual Split Maps)
    fprintf('  - 正在拆分保存独立的互不重叠网络...\n');
    
    for i = 1:num_networks
        real_id = target_ids(i);
        
        % 创建当前网络的独立 map
        network_map = zeros(num_verts, 1);
        
        % 逻辑：只保留 final_labels 等于当前 ID 的区域
        % 赋值：可以选择赋值为 1 (二值掩膜) 或者赋值为 原始强度值 (max_vals)
        % 这里采用：赋值为该网络在该点的原始强度值 (保留强度信息)
        vertex_indices = (final_labels == real_id);
        network_map(vertex_indices) = data_matrix(vertex_indices, i);
        
        % 保存
        out_name_single = fullfile(output_dir, sprintf('WTA_component_%02d_%s.func.gii', real_id, hemi));
        g_single = g_ref;
        g_single.cdata = single(network_map);
        save(g_single, out_name_single);
    end
end

fprintf('全部处理完成！\n');
fprintf('结果保存在: %s\n', output_dir);