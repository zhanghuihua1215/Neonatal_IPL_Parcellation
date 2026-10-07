clear; close all; clc;

%% --- 1. 参数配置 ---
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

% 1. 结构连接图谱的根目录 (C1-C4 的上级目录)
struct_root_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/2_structure_out_4/';

% 2. 功能网络 Mask 的目录 (之前生成的 11 个 mask)
mask_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/5_split_components_thre_4_sym_20_wta/mask_maps/';

% 3. 输出 CSV 保存路径
output_csv_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/6_SC_Fingerprint_thre_4_sym_20/';
if ~exist(output_csv_dir, 'dir'), mkdir(output_csv_dir); end
output_csv_name = fullfile(output_csv_dir, 'OPT11_Structure_Function_Fingerprint_C1-C4.csv');

% 4. 定义参数
partitions = 1:4;               % C1 - C4
hemispheres = {'L', 'R'};       % 左脑 右脑
%target_ids = [1, 2, 4, 5, 6, 7, 9, 10, 12, 13, 14]; % 你的11个网络ID
target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];
%% --- 2. 循环提取数据 ---
fprintf('开始计算 4个分区 x 11个网络 的指纹数据...\n');

% 初始化一个表格容器
% 行数 = 网络数 (11), 列数 = 2 * 分区数 (8)
data_matrix = zeros(length(target_ids), length(partitions) * 2);
col_names = cell(1, length(partitions) * 2);

col_counter = 1;

% 外层循环：遍历 C1, C2, C3, C4
for p = 1:length(partitions)
    c_id = partitions(p);
    
    % 内层循环：遍历左右脑
    for h = 1:length(hemispheres)
        hemi = hemispheres{h};
        
        % 构建列名 (例如 C1_L)
        col_name = sprintf('C%d_%s', c_id, hemi);
        col_names{col_counter} = col_name;
        
        fprintf('正在处理结构分区: %s ...\n', col_name);
        
        % 1. 读取结构连接文件
        % 路径逻辑: .../IPL_connection_C1/average_L_projection_C1_native.func.gii
        struct_folder = sprintf('IPL_connection_C%d', c_id);
        struct_file = sprintf('average_%s_projection_C%d_native.func.gii', hemi, c_id);
        struct_path = fullfile(struct_root_dir, struct_folder, struct_file);
        
        if ~isfile(struct_path)
            warning('  [缺失] 结构文件不存在: %s', struct_path);
            col_counter = col_counter + 1;
            continue;
        end
        
        g_struct = gifti(struct_path);
        struct_data = g_struct.cdata;
        
        % 2. 遍历 11 个功能网络 Mask
        for n = 1:length(target_ids)
            net_id = target_ids(n);
            
            % 读取 Mask
            % 路径逻辑: mask_component_01_L.func.gii
            mask_file = sprintf('mask_WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
            mask_path = fullfile(mask_dir, mask_file);
            
            val = 0;
            if isfile(mask_path)
                g_mask = gifti(mask_path);
                
                % 提取 Mask 区域内的平均结构连接强度
                indices = find(g_mask.cdata > 0);
                if ~isempty(indices)
                    % 确保索引不超过数据范围
                    valid_indices = indices(indices <= length(struct_data));
                    if ~isempty(valid_indices)
                        val = mean(struct_data(valid_indices));
                    end
                end
            else
                warning('    [缺失] Mask 文件不存在: %s', mask_file);
            end
            
            % 存入矩阵 (行=网络, 列=分区)
            data_matrix(n, col_counter) = val;
        end
        
        col_counter = col_counter + 1;
    end
end

%% --- 3. 保存为 CSV ---
% 将矩阵转为 Table
T = array2table(data_matrix, 'VariableNames', col_names);
% 添加 Network ID 列
T_ids = table(target_ids', 'VariableNames', {'NetworkID'});
T_final = [T_ids, T];

% 保存
writetable(T_final, output_csv_name);
fprintf('--------------------------------------\n');
fprintf('数据提取完成！CSV 已保存至:\n%s\n', output_csv_name);