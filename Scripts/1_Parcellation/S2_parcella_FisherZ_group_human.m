clear; clc; % 清空工作区并清除命令窗口
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/ % 添加外部工具包的路径

% --- 1. 初始化参数 ---
list = fopen('/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt');
list_subj = textscan(list,'%s');
fclose(list);
list_subj = list_subj{1}; % 读取被试

ROI = 'IPL';
species = 'neonatal';
hems = {'R'};
hemi_long = 'right';
hem = 1; % 只处理左半球
method = 'sc_FisherZ'; 
threshold = 0;
mesh = '32k';

% --- 2. 设置路径 ---
SubjectPath = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_probtrack/';
% !! 核心修改：更新输出路径 !!
PathWork = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_IPL_FisherZ_parcellation/'; 

path_Sc = [PathWork '/' ROI '_' hems{hem} '_' method '_norm_' mesh '/'];
if ~exist(path_Sc, 'dir'); mkdir(path_Sc); end % 创建输出目录

% --- 3. 加载公共数据 (包括空间坐标) ---
fprintf('Loading common ROI mask and template geometry...\n');
% 模板脑表面文件路径 (用于获取坐标)
SurfPath = ['/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/' 'week-40_hemi-' hemi_long '_space-dhcpSym_dens-32k_wm.surf.gii'];
surf_geo = gifti(SurfPath);
vertices_coord = surf_geo.vertices; % 获取所有顶点的 [x, y, z] 坐标

% 加载ROI的mask文件以获取ROI顶点索引
ROIsurf_path = ['/dat05/users/zhanghuihua/brain_development/border/less/' species '.' ROI '.'  hems{hem} '.' mesh '.func.gii'];
mygifti_roi = gifti(ROIsurf_path);
ROI_ind = find(mygifti_roi.cdata > 0); % 找到 ROI 的索引

% 提取ROI内顶点的Y坐标 (用于排序)
roi_coords_Y = vertices_coord(ROI_ind, 2); 


% --- 4. 主循环：计算每个被试的Fisher-Z变换后的相似性矩阵 ---
matrix_all_z = []; 
for subj = 1: length(list_subj)
    Subject = list_subj{subj};
    
    disp(strcat(Subject, '_', ROI, '_', hems{hem}, ' processing...'));
    path_track = [SubjectPath '/' Subject '/' ROI '_less_' hems{hem} '_probtrackx'];
    
    if exist([path_track '/conn.mat'], 'file')
        data = load([path_track '/conn.mat']);
        matrix = data.conn;
    else
        matrix = save_connection_surf([path_track '/fdt_matrix2.dot']);
    end
    
    matrix(matrix < threshold) = 0;
    nozero = any(matrix);
    matrix = matrix(:, nozero);
    
    matrix_r = corr(matrix'); 
    matrix_z = atanh(matrix_r);
    matrix_z(isinf(matrix_z)) = 0;
    matrix_z(isnan(matrix_z)) = 0;
    matrix_all_z(:,:,subj) = matrix_z;
end

% --- 5. 计算群体平均矩阵 ---
matrix_mean_z = mean(matrix_all_z, 3);
save([path_Sc '/' ROI '_' hems{hem} '_' mesh '_matrix_mean_z.mat'], 'matrix_mean_z', '-v6');
matrix_mean_z = matrix_mean_z - diag(diag(matrix_mean_z));

% --- 6. 核心修改：循环生成2-10个分区的结果，并进行排序 ---
fprintf('\nStarting clustering for k = 2 to 10 parcels...\n');
for k = 2:10
    
    display(strcat('  Clustering and sorting for k = ', num2str(k), ' parcels...'));
    
    % --- 执行聚类 ---
    index = sc3(k, matrix_mean_z); 
    
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
    
    for i = 1:k % k是当前的分区数
        original_label = unique_labels(sorted_order(i));
        label_sorted(index == original_label) = i;
    end
    
    % --- 保存当前k值的结果 ---
    filename = [path_Sc '/' ROI '.' hems{hem} '.' num2str(k) '.' mesh '.func.gii'];
    
    coord = mygifti_roi.cdata;
    coord(ROI_ind) = label_sorted; % 使用排序后的标签
    mygifti_roi.cdata = coord;
    save(mygifti_roi, filename);
    
    % (可选) 保存每个k值的文本索引文件
    dlmwrite([path_Sc '/' ROI '_' hems{hem} '_' num2str(k) '_idx.txt'], label_sorted); 
    
    fprintf('  Result for k=%d saved to: %s\n', k, filename);
end

fprintf('\nAll clustering tasks are complete.\n');