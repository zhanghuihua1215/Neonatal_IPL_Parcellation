clear; clc;
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

ROI = 'IPL';
species = 'neonatal';
hems = {'L'};
hemi_long = 'left';
hem = 1; 
method = 'sc_FisherZ'; 
threshold = 0; 
mesh = '32k';

SubjectPath = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_probtrack/';
PathWork = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/neonatal_IPL_FisherZ_parcellation/'; 

list_subj = textread('/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt', '%s');

SurfPath = ['/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/' 'week-40_hemi-' hemi_long '_space-dhcpSym_dens-32k_wm.surf.gii']; 
surf_geo = gifti(SurfPath);
vertices_coord = surf_geo.vertices; 

ROIsurf_path = ['/dat05/users/zhanghuihua/brain_development/border/less/' species '.' ROI '.'  hems{hem} '.' mesh '.func.gii'];
mygifti_roi = gifti(ROIsurf_path);
ROI_ind = find(mygifti_roi.cdata > 0);

roi_coords_Y = vertices_coord(ROI_ind, 2); 

for subj = 1: length(list_subj)
    Subject = list_subj{subj};
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
    matrix_z = matrix_z - diag(diag(matrix_z));
    
    for k = 2:10
        index = sc3(k, matrix_z);
        
        label_sorted = zeros(size(index));
        unique_labels = unique(index);
        centroid_Y = zeros(1, length(unique_labels));
        for i = 1:length(unique_labels)
            label = unique_labels(i);
            centroid_Y(i) = mean(roi_coords_Y(index == label));
        end
        
        [~, sorted_order] = sort(centroid_Y, 'descend');
        
        for i = 1:k
            original_label = unique_labels(sorted_order(i));
            label_sorted(index == original_label) = i;
        end
        
        path_Sc = [PathWork '/' Subject '/' ROI '_' hems{hem} '_' method '_norm_' mesh '/'];
        if ~exist(path_Sc, 'dir')
            mkdir(path_Sc); 
        end
        
        filename = [path_Sc '/' ROI '.' hems{hem} '.' num2str(k) '.' mesh '.func.gii'];
        
        coord = mygifti_roi.cdata;
        coord(ROI_ind) = label_sorted; 
        mygifti_roi.cdata = coord;
        save(mygifti_roi, filename);
    end
end
