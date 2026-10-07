clear; close all; clc;

addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

start_subject = 1;
hemi_to_process = 'right'; 

subject_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
session_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_ses_list.txt';
fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F1_volume_to_surface/';
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions/'; 
parcellation_file_template = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/IPL_group_Neighborhood_Consensus/Group_Fused_NC.%s.4.32k.func.gii';

list_subj = readcell(subject_list_file);
list_ses = readcell(session_list_file);
num_subjects = length(list_subj);

if strcmpi(hemi_to_process, 'left')
    hemi_short = 'L'; hemi_long = 'left';
else
    hemi_short = 'R'; hemi_long = 'right'; 
end

parcellation_file = sprintf(parcellation_file_template, hemi_short);
output_dir_hemi = fullfile(main_output_dir, sprintf('IPL_%s_4_subregions', hemi_short));
if ~exist(output_dir_hemi, 'dir')
    mkdir(output_dir_hemi); 
end

g_parc_info = gifti(parcellation_file);
parcellation_map = g_parc_info.cdata;
subregion_labels = unique(parcellation_map);
subregion_labels(subregion_labels == 0) = [];
num_subregions = length(subregion_labels);

for subj_idx = start_subject:num_subjects
    sub = list_subj{subj_idx};
    
    fmri_file = fullfile(fmri_base_dir, hemi_long, sub, sprintf('%s_hemi-%s_bold_projected_masked.func.gii', sub, hemi_long));
    g_fmri = gifti(fmri_file);
    whole_brain_data = g_fmri.cdata;

    for sr_idx = 1:num_subregions
        current_label = subregion_labels(sr_idx);
        subregion_indices = find(parcellation_map == current_label);
        mean_ts = mean(whole_brain_data(subregion_indices, :), 1, 'omitnan');
        
        r_map = corr(mean_ts', whole_brain_data');
        
        r_map(r_map > 0.9999) = 0.9999;
        r_map(r_map < -0.9999) = -0.9999;
        z_map = atanh(r_map);
        z_map(isnan(z_map)) = 0;
        
        clear g_out;
        g_out = gifti; 
        g_out.cdata = z_map'; 
        g_out.private.metadata(1).name = 'Intent';
        g_out.private.metadata(1).value = 'NIFTI_INTENT_CORREL'; 
        
        out_name = fullfile(output_dir_hemi, sprintf('%s_Subregion_%d_FC.%s.func.gii', sub, current_label, hemi_short));
        save(g_out, out_name, 'Base64Binary');
    end
end
