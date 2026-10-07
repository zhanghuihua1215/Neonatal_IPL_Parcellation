clear; close all; clc;

addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

start_subject = 10;
hemi_to_process = 'left';
k_values = 2:10; 

subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';
fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/';
roi_base_dir = '/dat05/users/zhanghuihua/brain_development/border/less/';
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_ROI_parcellation_fz/';
template_base_dir = '/dat05/users/zhanghuihua/brain_development/template/dhcpSym_template/';

list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
num_subjects = length(list_subj);

if strcmpi(hemi_to_process, 'left')
    hemi_short = 'L';
    hemi_long = 'left';
elseif strcmpi(hemi_to_process, 'right')
    hemi_short = 'R';
    hemi_long = 'right';
end

roi_file = fullfile(roi_base_dir, sprintf('neonatal.IPL.%s.32k.func.gii', hemi_short));
g_roi_info = gifti(roi_file);
roi_mask_vector = g_roi_info.cdata;

roi_indices = find(roi_mask_vector ~= 0);
non_roi_indices = find(roi_mask_vector == 0);

surf_file = fullfile(template_base_dir, sprintf('week-40_hemi-%s_space-dhcpSym_dens-32k_wm.surf.gii', hemi_long));
g_surf = gifti(surf_file);
vertices_coord = g_surf.vertices;
roi_coords_Y = vertices_coord(roi_indices, 2); 

for subj_idx = start_subject:num_subjects
    sub = list_subj{subj_idx};
    ses = list_ses{subj_idx};
    
    subject_folder_name = sprintf('IPL_%s_sc_FisherZ_norm_32k', hemi_short);
    output_dir_subject = fullfile(main_output_dir, sub, subject_folder_name);
    
    if ~exist(output_dir_subject, 'dir')
        mkdir(output_dir_subject);
    end
    
    fmri_subj_dir = fullfile(fmri_base_dir, hemi_long, sub);
    fmri_file = fullfile(fmri_subj_dir, sprintf('%s_hemi-%s_bold_projected_masked.func.gii', sub, hemi_long));
    
    if ~exist(fmri_file, 'file')
        continue;
    end
    
    g_fmri = gifti(fmri_file);
    fmri_data = g_fmri.cdata;
    
    roi_data = fmri_data(roi_indices, :);
    non_roi_data = fmri_data(non_roi_indices, :);
    
    corr_matrix = corr(roi_data', non_roi_data');
    
    corr_matrix(isnan(corr_matrix)) = 0;
    corr_matrix(corr_matrix > 0.9999) = 0.9999;
    corr_matrix(corr_matrix < -0.9999) = -0.9999;
    z_matrix = atanh(corr_matrix);

    for k = k_values
        cluster_labels_roi = spectralcluster(z_matrix, k);
        
        sorted_labels_roi = zeros(size(cluster_labels_roi));
        unique_labels = unique(cluster_labels_roi);
        
        centroid_Y = zeros(length(unique_labels), 1);
        for i = 1:length(unique_labels)
            label = unique_labels(i);
            centroid_Y(i) = mean(roi_coords_Y(cluster_labels_roi == label));
        end
        
        [~, sorted_order] = sort(centroid_Y, 'descend');
        
        for i = 1:k
            original_label = unique_labels(sorted_order(i));
            sorted_labels_roi(cluster_labels_roi == original_label) = i;
        end
        
        final_parcellation_map = zeros(size(roi_mask_vector));
        final_parcellation_map(roi_indices) = sorted_labels_roi; 
        
        g_output = g_roi_info; 
        g_output.cdata = final_parcellation_map;
        
        output_file_base = sprintf('IPL.%s.%d.32k.func.gii', hemi_short, k);
        output_filename = fullfile(output_dir_subject, output_file_base);
        save(g_output, output_filename, 'Base64Binary');
    end
end
