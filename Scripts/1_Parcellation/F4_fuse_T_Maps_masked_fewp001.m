clear; close all; clc;

addpath /dat05/users/zhanghuihua/soft/workbench/
wb_command_path = '/dat05/users/zhanghuihua/soft/workbench_v2.1.0/bin_linux64';
addpath /dat05/users/zhanghuihua/soft/gifti-main/;

hemi_to_process ='left'; 
smoothing_fwhm = 3; 

surface_file_template = '/dat05/data/human/dHCP_preprocessed/rel3_dhcp_anat/%s/%s/%s_%s_hemi-%s_midthickness.surf.gii';
base_individual_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions/';
base_group_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/2_t_test/';

subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';
num_subregions = 4;
subregion_labels = [1, 2, 3, 4];

if strcmpi(hemi_to_process, 'left')
    hemi_short = 'L'; hemi_long = 'left'; anat_struct = 'CortexLeft'; 
else
    hemi_short = 'R'; hemi_long = 'right'; anat_struct = 'CortexRight'; 
end

individual_results_dir = fullfile(base_individual_dir, sprintf('IPL_%s_4_subregions', hemi_short));
group_analysis_output_dir = fullfile(base_group_output_dir, sprintf('IPL_%s_Group_Results_Masked_T_Maps', hemi_short));

list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
num_subjects = length(list_subj);

if ~exist(group_analysis_output_dir, 'dir')
    mkdir(group_analysis_output_dir); 
end

tmp_smooth_dir = fullfile(individual_results_dir, 'tmp_smoothed_combined');
if ~exist(tmp_smooth_dir, 'dir')
    mkdir(tmp_smooth_dir); 
end

for sr_idx = 1:num_subregions
    current_label = subregion_labels(sr_idx);
    
    first_file_path = fullfile(individual_results_dir, sprintf('%s_Subregion_%d_FC.%s.func.gii', list_subj{1}, current_label, hemi_short));
    if ~exist(first_file_path, 'file'), continue; end
    
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
                    all_subjects_data(:, subj_idx) = g_subj.cdata;
                end
            end
        end
    end
    
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
    t_values_raw(isnan(t_values_raw)) = 0; 
    
    p_values_fwe = p_values_raw * valid_tests;
    p_values_fwe(p_values_fwe > 1) = 1;
    
    neg_log10_p_fwe = -log10(p_values_fwe);
    neg_log10_p_fwe(isinf(neg_log10_p_fwe)) = 300; 
    neg_log10_p_fwe(isnan(neg_log10_p_fwe)) = 0;   
    
    thresh_val_05  = -log10(0.05);   
    thresh_val_001 = -log10(0.001);  
    
    mask_05  = neg_log10_p_fwe > thresh_val_05;
    mask_001 = neg_log10_p_fwe > thresh_val_001;
    
    clear meta;
    meta(1).name = 'AnatomicalStructurePrimary';
    meta(1).value = anat_struct;
    meta(2).name = 'Intent';
    meta(2).value = 'NIFTI_INTENT_TTEST'; 
    
    g_out = gifti; 
    g_out.cdata = t_values_raw;
    g_out.private.metadata = meta; 
    save(g_out, fullfile(group_analysis_output_dir, sprintf('Raw_T_Map_Subregion_%d.%s.func.gii', current_label, hemi_short)), 'Base64Binary');
    
    meta_p = meta;
    meta_p(2).value = 'NIFTI_INTENT_PVAL'; 
    g_out.cdata = neg_log10_p_fwe;
    g_out.private.metadata = meta_p; 
    save(g_out, fullfile(group_analysis_output_dir, sprintf('NegLog10P_FWE_Map_Subregion_%d.%s.func.gii', current_label, hemi_short)), 'Base64Binary');
    
    t_values_masked_05 = t_values_raw;
    t_values_masked_05(~mask_05) = 0;
    g_out.cdata = t_values_masked_05;
    g_out.private.metadata = meta; 
    out_name_05 = fullfile(group_analysis_output_dir, sprintf('Masked_T_Map_FWE05_Subregion_%d.%s.func.gii', current_label, hemi_short));
    save(g_out, out_name_05, 'Base64Binary');
    
    t_values_masked_001 = t_values_raw;
    t_values_masked_001(~mask_001) = 0;
    g_out.cdata = t_values_masked_001;
    g_out.private.metadata = meta;
    out_name_001 = fullfile(group_analysis_output_dir, sprintf('Masked_T_Map_FWE001_Subregion_%d.%s.func.gii', current_label, hemi_short));
    save(g_out, out_name_001, 'Base64Binary');
    
end

rmdir(tmp_smooth_dir, 's');
