%% 主脚本: 计算预定义功能子区与全脑的功能连接图 (个体结果_修正保存版)
clear; close all; clc;

%% --- 1. 参数配置区 ---
% 请确保这些路径与您刚才诊断成功时用的一模一样
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

start_subject = 1;
hemi_to_process = 'right'; 

subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';
fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/';

% 建议新建一个空目录来存放这次的结果，避免混淆
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions/'; 

parcellation_file_template = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/IPL_group_Neighborhood_Consensus/Group_Fused_NC.%s.4.32k.func.gii';

%% --- 2. 初始化 ---
list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
num_subjects = length(list_subj);

if strcmpi(hemi_to_process, 'left'), hemi_short = 'L'; hemi_long = 'left';
else, hemi_short = 'R'; hemi_long = 'right'; end

parcellation_file = sprintf(parcellation_file_template, hemi_short);
output_dir_hemi = fullfile(main_output_dir, sprintf('IPL_%s_4_subregions', hemi_short));
if ~exist(output_dir_hemi, 'dir'), mkdir(output_dir_hemi); end

fprintf('--- 开始处理: %d 位被试, %s 半球 ---\n', num_subjects - start_subject + 1, hemi_long);

%% --- 3. 预加载分区 ---
try
    g_parc_info = gifti(parcellation_file);
    parcellation_map = g_parc_info.cdata;
    subregion_labels = unique(parcellation_map);
    subregion_labels(subregion_labels == 0) = [];
    num_subregions = length(subregion_labels);
    fprintf('已加载分区文件，共找到 %d 个子区。\n', num_subregions);
catch ME
    error('分区文件加载失败: %s', ME.message);
end

%% --- 4. 主循环 ---
for subj_idx = start_subject:num_subjects
    sub = list_subj{subj_idx};
    fprintf('\n正在处理被试 %d/%d: %s\n', subj_idx, num_subjects, sub);
    
    fmri_file = fullfile(fmri_base_dir, hemi_long, sub, sprintf('%s_hemi-%s_bold_projected_masked.func.gii', sub, hemi_long));
    if ~exist(fmri_file, 'file'), warning('跳过: 找不到fMRI文件 %s', fmri_file); continue; end
    
    try
        g_fmri = gifti(fmri_file);
        whole_brain_data = g_fmri.cdata;

        for sr_idx = 1:num_subregions
            current_label = subregion_labels(sr_idx);
            fprintf('  - 子区 %d: 计算...', current_label);
            
            % --- 核心计算 ---
            subregion_indices = find(parcellation_map == current_label);
            mean_ts = mean(whole_brain_data(subregion_indices, :), 1, 'omitnan');
            
            if var(mean_ts) > 1e-10
                r_map = corr(mean_ts', whole_brain_data');
               
                r_map(r_map > 0.9999) = 0.9999;
                r_map(r_map < -0.9999) = -0.9999;
                z_map = atanh(r_map);
             
                z_map(isnan(z_map)) = 0;
            else
                warning('子区信号无方差，结果将全为0。');
                z_map = zeros(1, size(whole_brain_data, 1));
            end
            
            % --- 【关键修正】更稳健的保存方式 ---
            % 我们创建一个新的结构体来明确指定数据和意图
            clear g_out;
            g_out = gifti; % 创建一个新的空白 gifti 对象
            g_out.cdata = z_map'; % 确保是列向量 (N_vertices x 1)
            g_out.private.metadata(1).name = 'Intent';
            g_out.private.metadata(1).value = 'NIFTI_INTENT_CORREL'; % 标记为相关性数据
            
            % 定义文件名
            out_name = fullfile(output_dir_hemi, sprintf('%s_Subregion_%d_FC.%s.func.gii', sub, current_label, hemi_short));
            
            % 保存
            save(g_out, out_name, 'Base64Binary');
            fprintf(' 已保存至 %s\n', out_name);
        end
        
    catch ME
        warning('处理被试 %s 时出错: %s', sub, ME.message);
    end
end
fprintf('\n全部完成！\n');