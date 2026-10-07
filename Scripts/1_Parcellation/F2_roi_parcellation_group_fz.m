%% 主脚本: 基于功能连接模式的ROI内部功能分区 (Parcellation)
% ... (前面的注释保持不变) ...

clear;
close all;
clc;

%% --- 1. 参数配置区 ---
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

% --- 分析控制 ---
start_subject = 1;
hemi_to_process = 'right';
k_values = 2:10; % ROI内部要划分成多少个子区

% --- 文件与目录路径 ---
subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';

fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/';
roi_base_dir = '/dat05/users/zhanghuihua/brain_development/border/less/';
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_ROI_parcellation_fz/';
%%% 新增/修改 %%% --- 为排序步骤添加模板路径 ---
template_base_dir = '/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/';


%% --- 2. 初始化与准备工作 ---

list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
if length(list_subj) ~= length(list_ses)
    error('被试列表和会话列表的行数不一致。');
end
num_subjects = length(list_subj);

if strcmpi(hemi_to_process, 'left')
    hemi_short = 'L';
    hemi_long = 'left';
elseif strcmpi(hemi_to_process, 'right')
    hemi_short = 'R';
    hemi_long = 'right';
else
    error("hemi_to_process 变量必须设置为 'left' 或 'right'");
end

roi_file = fullfile(roi_base_dir, sprintf('neonatal.IPL.%s.32k.func.gii', hemi_short));

%%% 新增/修改 %%% --- 这里您的代码有潜在的格式化错误，已修正 ---
output_dir_hemi = fullfile(main_output_dir, sprintf('IPL_%s_sc_FisherZ_norm_32k', hemi_short));
if ~exist(output_dir_hemi, 'dir')
    mkdir(output_dir_hemi);
end

fprintf('--- 初始化完成: ROI内部功能分区分析 ---\n');
fprintf('准备处理 %d 位被试的 %s 半球数据。\n', num_subjects - start_subject + 1, hemi_long);
fprintf('使用的ROI文件: %s\n', roi_file);


%% --- 3. 预加载公共数据并准备汇总矩阵 ---

try
    g_roi_info = gifti(roi_file);
    roi_mask_vector = g_roi_info.cdata;
    
    roi_indices = find(roi_mask_vector ~= 0);
    non_roi_indices = find(roi_mask_vector == 0);
    
    num_roi_vertices = length(roi_indices);
    num_non_roi_vertices = length(non_roi_indices);
    
    if num_roi_vertices == 0
        error('ROI掩码为空，无法进行分区。');
    end
    
    all_z_conn_matrices = NaN(num_roi_vertices, num_non_roi_vertices, num_subjects);
    
    fprintf('ROI顶点数: %d, 非ROI顶点数: %d\n', num_roi_vertices, num_non_roi_vertices);

    %%% 新增/修改 %%% --- 加载模板坐标用于排序 ---
    fprintf('加载模板表面坐标用于分区排序...\n');
    surf_file = fullfile(template_base_dir, sprintf('week-40_hemi-%s_space-dhcpSym_dens-32k_wm.surf.gii', hemi_long));
    if ~exist(surf_file, 'file')
        error('找不到模板表面文件: %s', surf_file);
    end
    g_surf = gifti(surf_file);
    vertices_coord = g_surf.vertices;
    roi_coords_Y = vertices_coord(roi_indices, 2); % 提取ROI内所有顶点的Y坐标
    
catch ME
    error('无法加载公共数据。错误信息: %s', ME.message);
end


%% --- 4. 逐个被试计算连接指纹矩阵 ---
% ... (这部分代码完全不变，所以省略以保持简洁) ...
fprintf('\n--- 开始处理被试循环 ---\n');

for subj_idx = start_subject:num_subjects
    sub = list_subj{subj_idx};
    ses = list_ses{subj_idx};
    
    fprintf('\n正在处理被试 %d/%d: %s\n', subj_idx, num_subjects, sub);
    
    fmri_subj_dir = fullfile(fmri_base_dir, hemi_long, sub);
    fmri_file = fullfile(fmri_subj_dir, sprintf('%s_hemi-%s_bold_projected_masked.func.gii', sub, hemi_long));
    
    if ~exist(fmri_file, 'file')
        warning('未找到fMRI文件，已跳过: %s', fmri_file);
        continue;
    end
    
    try
        % --- a. 加载数据并分割 ---
        fprintf('  加载并分割数据...');
        g_fmri = gifti(fmri_file);
        fmri_data = g_fmri.cdata;
        
        roi_data = fmri_data(roi_indices, :);
        non_roi_data = fmri_data(non_roi_indices, :);
        fprintf(' 完成。\n');
        
        % --- b. 计算连接指纹矩阵 ---
        fprintf('  计算连接指纹矩阵 (这可能需要一些时间)...');
        corr_matrix = corr(roi_data', non_roi_data');
        fprintf(' 完成。\n'); % 将完成信息提前
        
        % ================================================================
        %           【!!! 核心修正：增加容错和后处理 !!!】
        % ================================================================
        
        % 步骤 1: 将计算中产生的 NaN 值替换为 0
        % 这模仿了您旧代码的行为，处理由零方差数据点导致的相关性计算失败
        nan_count = sum(isnan(corr_matrix), 'all');
        if nan_count > 0
            fprintf('  警告: 在相关矩阵中发现并替换了 %d 个 NaN 值。\n', nan_count);
            corr_matrix(isnan(corr_matrix)) = 0;
        end

        % 步骤 2: 进行稳健的 Fisher-z 变换
        % 这模仿了您的自定义 FisherTransform 函数
        fprintf('  正在进行Fisher-z变换...');
        % 首先将r值限制在一个安全的范围内，避免无穷大
        corr_matrix(corr_matrix > 0.9999) = 0.9999;
        corr_matrix(corr_matrix < -0.9999) = -0.9999;
        
        z_matrix = atanh(corr_matrix);
        % atanh(0) 是 0，所以之前的 NaN->0 转换在这里是安全的
        fprintf(' 完成。\n');

        % ================================================================
        %                         【修正结束】
        % ================================================================

        % --- d. 存储结果 ---
        all_z_conn_matrices(:, :, subj_idx) = z_matrix;
        
    catch ME
        warning('处理被试 %s 时发生错误，已跳过。\n错误信息: %s', sub, ME.message);
        continue;
    end
end

%% --- 5. 组水平分析与对ROI进行聚类 ---

fprintf('\n--- 开始进行组水平分析 ---\n');
fprintf('正在对 %d 个被试的连接矩阵进行平均...\n', sum(~isnan(all_z_conn_matrices(1,1,:))));
group_z_conn_matrix = mean(all_z_conn_matrices, 3, 'omitnan');

fprintf('正在对ROI内部顶点进行谱聚类 (K = %s)...\n', num2str(k_values));
data_to_cluster = group_z_conn_matrix;

for k = k_values
    fprintf('  正在计算 K = %d 的情况...', k);
    
    % 获取初始的、无序的聚类标签
    cluster_labels_roi = spectralcluster(data_to_cluster, k);
    
    %%% 新增/修改 %%% --- 按Y轴坐标对分区标签进行排序 (从前到后为1-N) ---
    sorted_labels_roi = zeros(size(cluster_labels_roi));
    unique_labels = unique(cluster_labels_roi);
    
    % 1. 计算每个初始分区的质心Y坐标
    centroid_Y = zeros(length(unique_labels), 1);
    for i = 1:length(unique_labels)
        label = unique_labels(i);
        centroid_Y(i) = mean(roi_coords_Y(cluster_labels_roi == label));
    end
    
    % 2. 按Y坐标降序排序 (Y值越大=位置越靠前)
    [~, sorted_order] = sort(centroid_Y, 'descend');
    
    % 3. 根据排序结果赋予新的、有序的标签 (1=最前, 2=次之, ...)
    for i = 1:k
        original_label = unique_labels(sorted_order(i));
        sorted_labels_roi(cluster_labels_roi == original_label) = i;
    end
    
    %%% 新增/修改 %%% --- 将【排序后】的聚类结果映射回全脑坐标并保存 ---
    final_parcellation_map = zeros(size(roi_mask_vector));
    final_parcellation_map(roi_indices) = sorted_labels_roi; % 使用排序后的标签
    
    g_output = g_roi_info; 
    g_output.cdata = final_parcellation_map;
    
    output_filename = fullfile(output_dir_hemi, sprintf('IPL.%s.%d.32k.func.gii', hemi_short, k));
    save(g_output, output_filename, 'Base64Binary');
    
    fprintf(' 已保存至 %s\n', output_filename);
end

fprintf('\n====================================================\n');
fprintf('ROI功能分区分析全部完成！\n');
fprintf('所有分区结果文件已保存在:\n%s\n', output_dir_hemi);