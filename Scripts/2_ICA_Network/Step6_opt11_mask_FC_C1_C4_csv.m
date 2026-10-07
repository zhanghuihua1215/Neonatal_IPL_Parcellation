clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');

fc_root_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/2_Group_Analysis/';
mask_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/5_split_components_thre_4_sym_20_wta/mask_maps/';
output_csv_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/6_FC_Fingerprint_thre_4_sym_20/';
if ~exist(output_csv_dir, 'dir'), mkdir(output_csv_dir); end
output_csv_name = fullfile(output_csv_dir, 'OPT11_Functional_Fingerprint_C1-C4.csv');

partitions = 1:4;
hemispheres = {'L', 'R'};
target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];

data_matrix = zeros(length(target_ids), length(partitions) * 2);
col_names = cell(1, length(partitions) * 2);

col_counter = 1;

for p = 1:length(partitions)
    c_id = partitions(p);
    
    for h = 1:length(hemispheres)
        hemi = hemispheres{h};
        
        col_name = sprintf('C%d_%s', c_id, hemi);
        col_names{col_counter} = col_name;
        
        fc_file = sprintf('Group_Mean_Subregion_%d_FC.%s.func.gii', c_id, hemi);
        fc_path = fullfile(fc_root_dir, fc_file);
        
        if ~isfile(fc_path)
            col_counter = col_counter + 1;
            continue;
        end
        
        g_fc = gifti(fc_path);
        fc_data = g_fc.cdata;
        
        for n = 1:length(target_ids)
            net_id = target_ids(n);
            
            mask_file = sprintf('mask_WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
            mask_path = fullfile(mask_dir, mask_file);
            
            val = 0;
            if isfile(mask_path)
                g_mask = gifti(mask_path);
                indices = find(g_mask.cdata > 0);
                if ~isempty(indices)
                    valid_indices = indices(indices <= length(fc_data));
                    if ~isempty(valid_indices)
                        val = mean(fc_data(valid_indices));
                    end
                end
            end
            
            data_matrix(n, col_counter) = val;
        end
        
        col_counter = col_counter + 1;
    end
end

T = array2table(data_matrix, 'VariableNames', col_names);
T_ids = table(target_ids', 'VariableNames', {'NetworkID'});
T_final = [T_ids, T];

writetable(T_final, output_csv_name);clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');

fc_root_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/2_Group_Analysis/';
mask_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/5_split_components_thre_4_sym_20_wta/mask_maps/';
output_csv_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/6_FC_Fingerprint_thre_4_sym_20/';
if ~exist(output_csv_dir, 'dir'), mkdir(output_csv_dir); end
output_csv_name = fullfile(output_csv_dir, 'OPT11_Functional_Fingerprint_C1-C4.csv');

partitions = 1:4;
hemispheres = {'L', 'R'};
target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];

data_matrix = zeros(length(target_ids), length(partitions) * 2);
col_names = cell(1, length(partitions) * 2);

col_counter = 1;

for p = 1:length(partitions)
    c_id = partitions(p);
    
    for h = 1:length(hemispheres)
        hemi = hemispheres{h};
        
        col_name = sprintf('C%d_%s', c_id, hemi);
        col_names{col_counter} = col_name;
        
        fc_file = sprintf('Group_Mean_Subregion_%d_FC.%s.func.gii', c_id, hemi);
        fc_path = fullfile(fc_root_dir, fc_file);
        
        if ~isfile(fc_path)
            col_counter = col_counter + 1;
            continue;
        end
        
        g_fc = gifti(fc_path);
        fc_data = g_fc.cdata;
        
        for n = 1:length(target_ids)
            net_id = target_ids(n);
            
            mask_file = sprintf('mask_WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
            mask_path = fullfile(mask_dir, mask_file);
            
            val = 0;
            if isfile(mask_path)
                g_mask = gifti(mask_path);
                indices = find(g_mask.cdata > 0);
                if ~isempty(indices)
                    valid_indices = indices(indices <= length(fc_data));
                    if ~isempty(valid_indices)
                        val = mean(fc_data(valid_indices));
                    end
                end
            end
            
            data_matrix(n, col_counter) = val;
        end
        
        col_counter = col_counter + 1;
    end
end

T = array2table(data_matrix, 'VariableNames', col_names);
T_ids = table(target_ids', 'VariableNames', {'NetworkID'});
T_final = [T_ids, T];

writetable(T_final, output_csv_name);
