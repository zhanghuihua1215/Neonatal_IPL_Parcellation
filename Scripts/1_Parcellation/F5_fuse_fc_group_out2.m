clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

subj_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
data_root = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/1_FC_out_subregions/';
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/fused_out/3_function_connection_out/2_Group_Analysis/';

if ~exist(output_dir, 'dir')
    mkdir(output_dir); 
end

subregions = 1:4;         
hemispheres = {'L', 'R'}; 

raw_list = readcell(subj_list_file);
subj_list = raw_list(~cellfun('isempty', raw_list));
num_sub = length(subj_list);

for h = 1:length(hemispheres)
    hemi = hemispheres{h};
    curr_input_folder = fullfile(data_root, sprintf('IPL_%s_4_subregions', hemi));
    
    for r = subregions
        sum_data = []; 
        valid_count = 0; 
        ref_gifti = [];  
        
        for s = 1:num_sub
            raw_id = subj_list{s};
            if isnumeric(raw_id)
                sub_id = num2str(raw_id); 
            else
                sub_id = char(raw_id); 
            end
            sub_id = strtrim(sub_id);
            
            fname = sprintf('%s_Subregion_%d_FC.%s.func.gii', sub_id, r, hemi);
            fpath = fullfile(curr_input_folder, fname);
            
            if ~isfile(fpath)
                continue;
            end
            
            g = gifti(fpath);
            data = double(g.cdata); 
            
            if isempty(sum_data)
                sum_data = zeros(size(data));
                ref_gifti = g; 
            elseif size(data, 1) ~= size(sum_data, 1)
                continue;
            end
            
            sum_data = sum_data + data;
            valid_count = valid_count + 1;
        end
        
        if valid_count > 0
            mean_data = sum_data / valid_count;
            g_out = ref_gifti; 
            g_out.cdata = single(mean_data); 
            
            out_name = sprintf('Group_Mean_Subregion_%d_FC.%s.func.gii', r, hemi);
            out_path = fullfile(output_dir, out_name);
            save(g_out, out_path);
        end
    end
end
