clear; close all; clc;
%% --- 1. 参数配置区 ---
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/
%% --- 0. 环境配置 (照旧) ---
warning('off', 'MATLAB:rmpath:DirNotFound');
rmpath(genpath('/dat05/users/zhanghuihua/soft/mymatlab/')); 
rmpath(genpath('/dat05/users/zhanghuihua/soft/gifti-main/')); 
warning('on', 'MATLAB:rmpath:DirNotFound');
% 请替换为你正确的高效 gifti 库路径
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

%% --- 1. 参数配置 ---
subj_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
data_root = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F3_volume_to_surface_s4mm/';

% [修改] 输出目录：存放40个单独的.nii文件
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_Individual_Inputs/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% [新增] 输出列表文件：给 Melodic 用的清单
list_txt_file = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/input_files.txt';

%% --- 2. 准备工作 ---
raw_list = readcell(subj_list_file);
raw_list = raw_list(~cellfun('isempty', raw_list));
num_sub = length(raw_list);
fprintf('共处理 %d 个被试。\n', num_sub);

% 打开列表文件准备写入
fid_list = fopen(list_txt_file, 'w');

%% --- 3. 循环处理每个被试 ---
fprintf('开始单独转换每个被试...\n');

% 记录第一个被试的维度用于校验
ref_verts = 0; 

for i = 1:num_sub
    % 获取 ID
    raw_id = raw_list{i};
    if isnumeric(raw_id), sub_id = num2str(raw_id); else, sub_id = char(raw_id); end
    sub_id = strtrim(sub_id);
    
    % 路径
    f_L = fullfile(data_root, 'left', sub_id, sprintf('%s_hemi-left_bold_projected_masked_s4mm.func.gii', sub_id));
    f_R = fullfile(data_root, 'right', sub_id, sprintf('%s_hemi-right_bold_projected_masked_s4mm.func.gii', sub_id));
    
    if ~isfile(f_L) || ~isfile(f_R)
        warning('跳过缺失文件: %s', sub_id);
        continue;
    end
    
    % 读取
    gL = gifti(f_L);
    gR = gifti(f_R);
    
    % 校验维度
    curr_verts = size(gL.cdata, 1) + size(gR.cdata, 1);
    if i == 1
        ref_verts = curr_verts;
        fprintf('  - 基准顶点数: %d\n', ref_verts);
    else
        if curr_verts ~= ref_verts
            warning('被试 %s 顶点数不匹配 (%d vs %d)，跳过！', sub_id, curr_verts, ref_verts);
            continue;
        end
    end
    
    % 拼接 (Space x Time)
    data_sub = [gL.cdata; gR.cdata];
    [n_v, n_t] = size(data_sub);
    
    % 转换为 4D NIfTI [X=顶点, Y=1, Z=1, T=时间]
    % 注意：这里使用 single 类型极大地减小文件体积
    fake_nii = reshape(single(data_sub), [n_v, 1, 1, n_t]);
    
    % 输出文件名
    out_name = fullfile(output_dir, [sub_id, '_fake.nii']);
    
    % 保存
    niftiwrite(fake_nii, out_name);
    
    % 写入路径到列表文件 (Linux 路径)
    fprintf(fid_list, '%s\n', out_name);
    
    if mod(i, 5) == 0
        fprintf('  - 已完成 %d / %d\n', i, num_sub);
    end
end

fclose(fid_list);

fprintf('Step 1 V2 完成！\n');
fprintf('生成了独立文件目录: %s\n', output_dir);
fprintf('生成了 Melodic 输入列表: %s\n', list_txt_file);