clear; close all; clc;

%% --- 1. 参数配置区 ---
% [工具箱路径]
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

% [被试列表]
subj_list_file = '/dat05/users/zhanghuihua/brain_development/demo/msm_newborn_adult_demo/list_40.txt';


data_root = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/4_FC_out_subregions/';

% [输出路径]
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/5_Group_Analysis/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% [参数定义]
subregions = 1:4;         % 4个亚区
hemispheres = {'L', 'R'}; % 左右脑

% 读取被试列表
raw_list = readcell(subj_list_file);
subj_list = raw_list(~cellfun('isempty', raw_list));
num_sub = length(subj_list);

fprintf('检测到 %d 个被试，准备开始计算组平均...\n', num_sub);

%% --- 2. 循环处理 (半脑 -> 亚区 -> 被试) ---

for h = 1:length(hemispheres)
    hemi = hemispheres{h};
    
    % [路径] 
    curr_input_folder = fullfile(data_root, sprintf('IPL_%s_4_subregions', hemi));
    
    fprintf('------------------------------------------------\n');
    fprintf('正在处理半脑: %s (输入目录: %s)\n', hemi, curr_input_folder);
    
    for r = subregions
        fprintf('  > 正在计算 Subregion %d 的组平均...\n', r);
        
        sum_data = []; % 用于累加数据的容器
        valid_count = 0; % 记录有效读取的被试数
        ref_gifti = [];  % 保存第一个成功的gifti结构用于输出
        
        % --- 遍历所有被试 ---
        for s = 1:num_sub
            % 获取被试ID
            raw_id = subj_list{s};
            if isnumeric(raw_id), sub_id = num2str(raw_id); else, sub_id = char(raw_id); end
            sub_id = strtrim(sub_id);
            
            % 构建文件名
            fname = sprintf('%s_Subregion_%d_FC.%s.func.gii', sub_id, r, hemi);
            fpath = fullfile(curr_input_folder, fname);
            
            if ~isfile(fpath)
                warning('    [缺失] 文件未找到: %s', fname);
                continue;
            end
            
            % 读取数据
            try
                g = gifti(fpath);
                data = double(g.cdata); % 转为 double 防止精度丢失
                
                if isempty(sum_data)
                    % 如果是第一个被试，初始化累加器
                    sum_data = zeros(size(data));
                    ref_gifti = g; % 记录模板
                elseif size(data, 1) ~= size(sum_data, 1)
                    warning('    [维度错误] 被试 %s 顶点数不匹配，跳过！', sub_id);
                    continue;
                end
                
                % 累加
                sum_data = sum_data + data;
                valid_count = valid_count + 1;
                
            catch ME
                warning('    [读取错误] %s: %s', sub_id, ME.message);
            end
        end
        
        % --- 计算平均并保存 ---
        if valid_count > 0
            % 计算平均值
            mean_data = sum_data / valid_count;
            
            % 构建输出结构体
            g_out = ref_gifti; 
            g_out.cdata = single(mean_data); % 转回 single 节省空间
            
            % 输出文件名
            % 例如: Group_Mean_Subregion_1_FC.L.func.gii
            out_name = sprintf('Group_Mean_Subregion_%d_FC.%s.func.gii', r, hemi);
            out_path = fullfile(output_dir, out_name);
            
            save(g_out, out_path);
            fprintf('    [完成] 已保存组平均 (N=%d): %s\n', valid_count, out_name);
        else
            warning('    [失败] Subregion %d 没有有效数据！\n', r);
        end
    end
end

fprintf('------------------------------------------------\n');
fprintf('全部处理完毕！结果保存在: %s\n', output_dir);