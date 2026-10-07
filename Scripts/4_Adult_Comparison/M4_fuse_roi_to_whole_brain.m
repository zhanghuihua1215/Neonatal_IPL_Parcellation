clear; close all; clc;

addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

start_subject = 1;
hemi = 'R'; 

subject_list_file = '/dat05/users/zhanghuihua/brain_development/demo/msm_newborn_adult_demo/list_40.txt';
fmri_base_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/0_volume_to_surface/rfMRI_REST1_merged/';
main_output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/Msm_newborn_adult/4_FC_out_subregions/'; 
parcellation_file_template = '/dat05/users/zhanghuihua/brain_development/border/HCP_IPL_4/human.IPL.%s.4.32k.func.gii';

fid = fopen(subject_list_file);
list_subj = textscan(fid, '%s'); 
fclose(fid);
list_subj = list_subj{1}; 
num_subjects = length(list_subj);

parcellation_file = sprintf(parcellation_file_template, hemi);
output_dir_hemi = fullfile(main_output_dir, sprintf('IPL_%s_4_subregions', hemi));
if ~exist(output_dir_hemi, 'dir'), mkdir(output_dir_hemi, 'recursive'); end

g_parc_info = gifti(parcellation_file);
parcellation_map = g_parc_info.cdata;
subregion_labels = unique(parcellation_map);
subregion_labels(subregion_labels <= 0) = []; 
num_subregions = length(subregion_labels);

for subj_idx = start_subject:num_subjects
    temp_sub = list_subj{subj_idx};
    if isnumeric(temp_sub)
        sub = num2str(temp_sub, '%d');
    else
        sub = strtrim(char(temp_sub));
    end
    
    fmri_file = fullfile(fmri_base_dir, hemi, sub, sprintf('%s_%s_REST1_combined_zscored.func.gii', sub, hemi));
    
    if ~exist(fmri_file, 'file')
        continue; 
    end
    
    g_fmri = gifti(fmri_file);
    whole_brain_data = g_fmri.cdata; 

    for sr_idx = 1:num_subregions
        current_label = subregion_labels(sr_idx);
        
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
        
        g_out = g_fmri; 
        if isfield(g_out.private, 'data') && iscell(g_out.private.data)
            g_out.private.data = g_out.private.data(1); 
        end
        
        g_out.cdata = single(z_map'); 
        
        if strcmpi(hemi, 'R')
            final_struct_name = 'CortexRight';
        else
            final_struct_name = 'CortexLeft';
        end
        
        g_out.private.metadata(1).name = 'AnatomicalStructurePrimary';
        g_out.private.metadata(1).value = final_struct_name;
        
        out_name = fullfile(output_dir_hemi, sprintf('%s_Subregion_%d_FC.%s.func.gii', sub, current_label, hemi));
        save(g_out, out_name);
    end
end
