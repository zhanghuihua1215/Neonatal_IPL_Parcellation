clear; close all; clc;

%% --- 1. 参数与路径配置 ---
% 必须包含 gifti 工具箱
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

% 输入目录 (存放上一步 WTA 结果的地方)
input_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/5_split_components_thre_4_sym_20_wta/wall_masked/';

% 输出目录 (存放二值化 Mask 结果的地方)
output_dir = fullfile(input_dir, 'mask_maps'); 
if ~exist(output_dir, 'dir')
    mkdir(output_dir); % 如果文件夹不存在则自动创建
end

% 你的11个网络 ID 和 半脑
%target_ids = [1, 2, 4, 5, 6, 7, 9, 10, 12, 13, 14];
target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];
hemispheres = {'L', 'R'};

fprintf('开始将 WTA 结果转换为二值化 Mask 文件...\n');
fprintf('输出文件夹: %s\n\n', output_dir);

%% --- 2. 循环处理生成 Mask ---
for h = 1:length(hemispheres)
    hemi = hemispheres{h};
    
    for i = 1:length(target_ids)
        net_id = target_ids(i);
        
        % 构建输入和输出文件名
        in_filename = sprintf('WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
        out_filename = sprintf('mask_WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
        
        in_filepath = fullfile(input_dir, in_filename);
        out_filepath = fullfile(output_dir, out_filename);
        
        % 检查文件是否存在
        if exist(in_filepath, 'file')
            % 1. 读取原始的 WTA gifti 数据
            g = gifti(in_filepath);
            
            % 2. 核心操作：二值化 (Mask)
            % 将大于 0 的信号变成 1，等于 0 的依然是 0
            mask_cdata = single(g.cdata > 0); 
            
            % 3. 赋值并保存
            g.cdata = mask_cdata;
            save(g, out_filepath);
            
            fprintf('已生成: %s\n', out_filename);
        else
            warning('找不到文件: %s，已跳过。', in_filename);
        end
        
    end
end

fprintf('\n所有 Mask 文件转换完成！\n');