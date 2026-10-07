%% 主脚本: 计算预定义功能子区与全脑的功能连接图 (完全修复版)
clear; close all; clc;

%% --- 1. 参数配置区 ---
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

start_subject = 1;
hemi = 'R'; 

subject_list_file = '/dat05/users/zhanghuihua/brain_development/demo/msm_newborn_adult_demo/list_40.txt';
fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/0_volume_to_surface/rfMRI_REST1_merged/';
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/4_FC_out_subregions/'; 

parcellation_file_template = '/dat05/users/zhanghuihua/brain_development/border/HCP_IPL_4/human.IPL.%s.4.32k.func.gii';

%% --- 2. 初始化 ---
fid = fopen(subject_list_file);
list_subj = textscan(fid, '%s'); 
fclose(fid);
list_subj = list_subj{1}; 
num_subjects = length(list_subj);

parcellation_file = sprintf(parcellation_file_template, hemi);
output_dir_hemi = fullfile(main_output_dir, sprintf('IPL_%s_4_subregions', hemi));
if ~exist(output_dir_hemi, 'dir'), mkdir(output_dir_hemi, 'recursive'); end

fprintf('--- 开始处理: %d 位被试, %s 半球 ---\n', num_subjects - start_subject + 1, hemi);

%% --- 3. 预加载分区 ---
try
    g_parc_info = gifti(parcellation_file);
    parcellation_map = g_parc_info.cdata;
    subregion_labels = unique(parcellation_map);
    subregion_labels(subregion_labels <= 0) = []; 
    num_subregions = length(subregion_labels);
    fprintf('已加载分区文件，共找到 %d 个子区。\n', num_subregions);
catch ME
    error('分区文件加载失败: %s', ME.message);
end

%% --- 4. 主循环 ---
for subj_idx = start_subject:num_subjects
    % 彻底解决 ID 转换问题
    temp_sub = list_subj{subj_idx};
    if isnumeric(temp_sub)
        sub = num2str(temp_sub, '%d');
    else
        sub = strtrim(char(temp_sub));
    end
    
    fprintf('\n正在处理被试 [%d/%d]: %s', subj_idx, num_subjects, sub);
    
    % 注意：根据你实际文件名调整是否带 _hemi_
    fmri_file = fullfile(fmri_base_dir, hemi, sub, sprintf('%s_%s_REST1_combined_zscored.func.gii', sub, hemi));
    
    if ~exist(fmri_file, 'file')
        warning('\n跳过: 找不到fMRI文件 %s', fmri_file); 
        continue; 
    end
    
    try
        g_fmri = gifti(fmri_file);
        whole_brain_data = g_fmri.cdata; 

        for sr_idx = 1:num_subregions
            current_label = subregion_labels(sr_idx);
            
            % --- 核心计算 ---
            subregion_indices = (parcellation_map == current_label);
            if ~any(subregion_indices), continue; end
            
            mean_ts = mean(whole_brain_data(subregion_indices, :), 1, 'omitnan');
            
            if var(mean_ts) > 1e-10
                r_map = corr(mean_ts', whole_brain_data');
                r_map(r_map > 0.9999) = 0.9999;
                r_map(r_map < -0.9999) = -0.9999;
                z_map = atanh(r_map);
                z_map(isnan(z_map)) = 0;
            else
                z_map = zeros(1, size(whole_brain_data, 1));
            end
            
            % --- 【关键修正】保存逻辑 ---
            % 1. 克隆整个对象结构
            g_out = g_fmri; 
            
            % 2. 强制只保留第1列的元数据结构，解决 Syntax not implemented
            if isfield(g_out.private, 'data') && iscell(g_out.private.data)
                g_out.private.data = g_out.private.data(1); 
            end
            
            % 3. 赋值计算好的 Z 图（Vertices x 1）
            g_out.cdata = single(z_map'); 
            
            % 4. 修正解剖标签 (修正了之前的变量名错误)
            if strcmpi(hemi, 'R')
                final_struct_name = 'CortexRight';
            else
                final_struct_name = 'CortexLeft';
            end
            
            % 注入解剖标识到 Metadata
            g_out.private.metadata(1).name = 'AnatomicalStructurePrimary';
            g_out.private.metadata(1).value = final_struct_name;
            
            % 定义文件名
            out_name = fullfile(output_dir_hemi, sprintf('%s_Subregion_%d_FC.%s.func.gii', sub, current_label, hemi));
            
            % 保存
            save(g_out, out_name);
            fprintf('.'); 
        end
        fprintf(' 完成！');
        
    catch ME
        fprintf('\n处理被试 %s 时出错: %s', sub, ME.message);
    end
end
fprintf('\n\n全部处理完毕！\n');