clear; clc;
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

% --- 1. 初始化参数 ---
ROI = 'IPL';
species = 'neonatal';
hems = {'L'};
hemi_long = 'left';
hem = 1; % 只处理左半球
method = 'sc_FisherZ'; % 更新方法名以作区分
threshold = 0; % 使用您原始个体代码中的threshold=2
mesh = '32k';


% --- 2. 设置路径 ---
SubjectPath = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_probtrack/';
PathWork = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_IPL_FisherZ_parcellation/'; % 使用您的新路径

% 读取被试列表
list_subj = textread('/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt', '%s');

% --- 3. 加载公共数据 (包括空间坐标，在循环外执行一次) ---
fprintf('Loading common template and ROI data once...\n');
% 模板脑表面文件路径 (用于获取坐标)
SurfPath = ['/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/' 'week-40_hemi-' hemi_long '_space-dhcpSym_dens-32k_wm.surf.gii']; 
surf_geo = gifti(SurfPath);
vertices_coord = surf_geo.vertices; % 获取所有顶点的 [x, y, z] 坐标

% 加载ROI的mask文件
ROIsurf_path = ['/dat05/users/zhanghuihua/brain_development/border/less/' species '.' ROI '.'  hems{hem} '.' mesh '.func.gii'];
mygifti_roi = gifti(ROIsurf_path);
ROI_ind = find(mygifti_roi.cdata > 0);

% 提取ROI内顶点的Y坐标 (用于排序)
roi_coords_Y = vertices_coord(ROI_ind, 2); 

% --- 4. 主循环：为每个被试进行独立分区处理 ---
for subj = 1: length(list_subj)
    Subject = list_subj{subj};
    
    fprintf('\n--- Processing Subject: %s ---\n', Subject);
    
    % --- 为当前被试加载连接数据 ---
    path_track = [SubjectPath '/' Subject '/' ROI '_less' '_' hems{hem} '_probtrackx'];
    
    if exist([path_track '/conn.mat'], 'file') 
        data = load([path_track '/conn.mat']);
        matrix = data.conn;
    else
        matrix = save_connection_surf([path_track '/fdt_matrix2.dot']);
    end
    
    % --- 预处理连接矩阵 ---
    matrix(matrix < threshold) = 0;
    nozero = any(matrix);
    matrix = matrix(:, nozero);
    
    % =======================================================================
    %                       核心修改部分 (方案A)
    % =======================================================================
    
    % 1. 计算皮尔逊相关系数矩阵
    matrix_r = corr(matrix'); 
    
    % 2. 应用Fisher-Z变换
    matrix_z = atanh(matrix_r);
    
    % 3. 处理对角线（自相关产生的Inf）和可能的NaN值
    matrix_z(isinf(matrix_z)) = 0;
    matrix_z(isnan(matrix_z)) = 0;
    
    % 4. 去除对角线以便聚类
    matrix_z = matrix_z - diag(diag(matrix_z));
    
    % =======================================================================
    
    % --- 内循环：生成 2-10 分区结果 ---
    for k = 2:10
        display(strcat('  Clustering into ', num2str(k), ' parcels...'));
        
        % --- 执行聚类 (作用于当前被试的matrix_z上) ---
        index = sc3(k, matrix_z);
        
        % --- 按Y轴坐标对分区标签进行排序 (从前到后为1-N) ---
        label_sorted = zeros(size(index));
        unique_labels = unique(index);
        centroid_Y = [];
        for i = 1:length(unique_labels)
            label = unique_labels(i);
            centroid_Y(i) = mean(roi_coords_Y(index == label));
        end
        
        % !! 核心修改：降序排序，Y坐标大的(前)排在前面 !!
        [~, sorted_order] = sort(centroid_Y, 'descend');
        
        for i = 1:k
            original_label = unique_labels(sorted_order(i));
            label_sorted(index == original_label) = i;
        end
        
        % --- 保存结果到指定路径 ---
        % 1. 构建输出路径
        path_Sc = [PathWork '/' Subject '/' ROI '_' hems{hem} '_' method '_norm_' mesh '/'];
        if ~exist(path_Sc, 'dir'); mkdir(path_Sc); end
        
        % 2. 构建文件名
        filename = [path_Sc '/' ROI '.' hems{hem} '.' num2str(k) '.' mesh '.func.gii'];
        
        % 3. 保存.gii文件
        coord = mygifti_roi.cdata;
        coord(ROI_ind) = label_sorted; % 使用排序后的标签
        mygifti_roi.cdata = coord;
        save(mygifti_roi, filename);
        
        fprintf('  Result for k=%d saved to: %s\n', k, filename);
    end
end
fprintf('\n\nAll subjects have been processed.\n');