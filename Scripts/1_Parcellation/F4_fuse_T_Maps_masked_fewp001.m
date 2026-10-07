clear;
close all;
clc;

% --- 路径配置 (请确认路径无误) ---
addpath /dat05/users/zhanghuihua/soft/workbench/
wb_command_path = '/dat05/users/zhanghuihua/soft/workbench_v2.1.0/bin_linux64';
addpath /dat05/users/zhanghuihua/soft/gifti-main/;

% --- 核心参数 ---
hemi_to_process ='left'; % 'left' 或 'right'
smoothing_fwhm = 3; % 平滑核大小 (FWHM in mm)

% --- 输入输出路径 ---
surface_file_template = '/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/%s/%s/%s_%s_hemi-%s_midthickness.surf.gii';
base_individual_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions/';
% 【!!! 最终输出路径 !!!】
base_group_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/2_t_test/';

% --- 被试列表与子区 ---
subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';
num_subregions = 4;
subregion_labels = [1, 2, 3, 4];

%% --- 2. 初始化 ---
if strcmpi(hemi_to_process, 'left')
    hemi_short = 'L'; hemi_long = 'left';
    anat_struct = 'CortexLeft'; % <--- 添加这一行
elseif strcmpi(hemi_to_process, 'right')
    hemi_short = 'R'; hemi_long = 'right';
    anat_struct = 'CortexRight'; % <--- 添加这一行
else
    error("hemi_to_process 必须为 'left' 或 'right'"); 
end

individual_results_dir = fullfile(base_individual_dir, sprintf('IPL_%s_4_subregions', hemi_short));
group_analysis_output_dir = fullfile(base_group_output_dir, sprintf('IPL_%s_Group_Results_Masked_T_Maps', hemi_short));

list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
num_subjects = length(list_subj);

if ~exist(group_analysis_output_dir, 'dir'), mkdir(group_analysis_output_dir); end

% 临时平滑目录
tmp_smooth_dir = fullfile(individual_results_dir, 'tmp_smoothed_combined');
if ~exist(tmp_smooth_dir, 'dir'), mkdir(tmp_smooth_dir); end

fprintf('--- 开始处理 %s 半球：T值计算 + FWE校正 Mask --- \n', hemi_long);
fprintf('输出目录: %s\n', group_analysis_output_dir);

%% --- 3. 循环处理子区 ---
for sr_idx = 1:num_subregions
    current_label = subregion_labels(sr_idx);
    fprintf('\n--- 正在处理子区 %d ---\n', current_label);
    
    % ---------------------------------------------------------
    % A. 数据准备 (加载 & 平滑)
    % ---------------------------------------------------------
    fprintf('  [1/4] 加载并平滑被试数据...\n');
    first_file_path = fullfile(individual_results_dir, sprintf('%s_Subregion_%d_FC.%s.func.gii', list_subj{1}, current_label, hemi_short));
    if ~exist(first_file_path, 'file'), warning('跳过子区 %d (文件缺失)', current_label); continue; end
    
    g_template = gifti(first_file_path);
    num_vertices = length(g_template.cdata);
    all_subjects_data = NaN(num_vertices, num_subjects);
    
    for subj_idx = 1:num_subjects
        sub_id = list_subj{subj_idx};
        ses_id = list_ses{subj_idx};
        file_path_in = fullfile(individual_results_dir, sprintf('%s_Subregion_%d_FC.%s.func.gii', sub_id, current_label, hemi_short));
        file_path_smoothed = fullfile(tmp_smooth_dir, sprintf('%s_Subregion_%d_FC.%s.smoothed.func.gii', sub_id, current_label, hemi_short));
        
        if exist(file_path_in, 'file')
            surface_file = sprintf(surface_file_template, sub_id, ses_id, sub_id, ses_id, hemi_long);
            if exist(surface_file, 'file')
                cmd = sprintf('%s/wb_command -metric-smoothing %s %s %d %s', wb_command_path, surface_file, file_path_in, smoothing_fwhm, file_path_smoothed);
                [status, ~] = system(cmd);
                if status == 0
                    g_subj = gifti(file_path_smoothed);
                    z_values = g_subj.cdata;
                    all_subjects_data(:, subj_idx) = z_values;
                end
            end
        end
    end
    
    % ---------------------------------------------------------
    % B. 统计计算 (同时获取 T值 和 P值)
    % ---------------------------------------------------------
    fprintf('  [2/4] 计算 T统计量 和 原始P值...\n');
    t_values_raw = zeros(num_vertices, 1);
    p_values_raw = ones(num_vertices, 1);
    valid_tests = 0;
    
    for i = 1:num_vertices
        vertex_data = all_subjects_data(i, :);
        vertex_data = vertex_data(~isnan(vertex_data));
        
        if length(vertex_data) > 1
            [~, p, ~, stats] = ttest(vertex_data);
            t_values_raw(i) = stats.tstat;
            p_values_raw(i) = p;
            valid_tests = valid_tests + 1;
        else
            t_values_raw(i) = 0;
            p_values_raw(i) = 1;
        end
    end
    t_values_raw(isnan(t_values_raw)) = 0; % 清理 NaN
    
    % ---------------------------------------------------------
    % C. FWE 校正 与 Mask 生成
    % ---------------------------------------------------------
    fprintf('  [3/4] 执行 FWE 校正并生成 Mask...\n');
    
    % 1. 计算 FWE P值
    p_values_fwe = p_values_raw * valid_tests;
    p_values_fwe(p_values_fwe > 1) = 1;
    
    % 2. 计算 -log10(p_fwe)
    neg_log10_p_fwe = -log10(p_values_fwe);
    neg_log10_p_fwe(isinf(neg_log10_p_fwe)) = 300; % 处理 Inf
    neg_log10_p_fwe(isnan(neg_log10_p_fwe)) = 0;   % 处理 NaN
    
    % 3. 定义阈值
    thresh_val_05  = -log10(0.05);   % 约 1.301
    thresh_val_001 = -log10(0.001);  % 3.000
    
    % 4. 生成 Mask (逻辑索引)
    mask_05  = neg_log10_p_fwe > thresh_val_05;
    mask_001 = neg_log10_p_fwe > thresh_val_001;
    
% ---------------------------------------------------------
    % D. 应用 Mask 并保存结果
    % ---------------------------------------------------------
    fprintf('  [4/4] 应用 Mask 到 T值图并保存...\n');
    
    % --- 构造元数据 (Metadata) ---
    clear meta;
    meta(1).name = 'AnatomicalStructurePrimary';
    meta(1).value = anat_struct;
    meta(2).name = 'Intent';
    meta(2).value = 'NIFTI_INTENT_TTEST'; % 告诉软件这是 T 统计量图
    
    % --- 1. 保存原始 T 值图 ---
    g_out = gifti; 
    g_out.cdata = t_values_raw;
    g_out.private.metadata = meta; % <--- 注入头文件
    save(g_out, fullfile(group_analysis_output_dir, sprintf('Raw_T_Map_Subregion_%d.%s.func.gii', current_label, hemi_short)), 'Base64Binary');
    
    % --- 2. 保存 -log10(p) FWE 图 ---
    % 注意：P值的 Intent 略有不同
    meta_p = meta;
    meta_p(2).value = 'NIFTI_INTENT_PVAL'; 
    g_out.cdata = neg_log10_p_fwe;
    g_out.private.metadata = meta_p; % <--- 注入头文件
    save(g_out, fullfile(group_analysis_output_dir, sprintf('NegLog10P_FWE_Map_Subregion_%d.%s.func.gii', current_label, hemi_short)), 'Base64Binary');
    
    % --- 3. 保存 Masked T (p < 0.05) ---
    t_values_masked_05 = t_values_raw;
    t_values_masked_05(~mask_05) = 0;
    g_out.cdata = t_values_masked_05;
    g_out.private.metadata = meta; % <--- 注入头文件
    out_name_05 = fullfile(group_analysis_output_dir, sprintf('Masked_T_Map_FWE05_Subregion_%d.%s.func.gii', current_label, hemi_short));
    save(g_out, out_name_05, 'Base64Binary');
    
    % --- 4. 保存 Masked T (p < 0.001) ---
    t_values_masked_001 = t_values_raw;
    t_values_masked_001(~mask_001) = 0;
    g_out.cdata = t_values_masked_001;
    g_out.private.metadata = meta; % <--- 注入头文件
    out_name_001 = fullfile(group_analysis_output_dir, sprintf('Masked_T_Map_FWE001_Subregion_%d.%s.func.gii', current_label, hemi_short));
    save(g_out, out_name_001, 'Base64Binary');
    fprintf('      -> 保存完成: Masked T-Map (p<0.001)\n');
    
end

% --- 清理 ---
rmdir(tmp_smooth_dir, 's');
fprintf('\n====================================================\n');
fprintf('处理完成。生成的 T 值图仅保留了显著(FWE)的区域。\n');
fprintf('====================================================\n');