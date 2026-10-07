clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');

input_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_20_new_11/5_split_components_thre_4_sym_20_wta/wall_masked/';
output_dir = fullfile(input_dir, 'mask_maps'); 
if ~exist(output_dir, 'dir')
    mkdir(output_dir); 
end

target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];
hemispheres = {'L', 'R'};

for h = 1:length(hemispheres)
    hemi = hemispheres{h};
    
    for i = 1:length(target_ids)
        net_id = target_ids(i);
        
        in_filename = sprintf('WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
        out_filename = sprintf('mask_WTA_component_%02d_%s_masked.func.gii', net_id, hemi);
        
        in_filepath = fullfile(input_dir, in_filename);
        out_filepath = fullfile(output_dir, out_filename);
        
        if exist(in_filepath, 'file')
            g = gifti(in_filepath);
            mask_cdata = single(g.cdata > 0); 
            
            g.cdata = mask_cdata;
            save(g, out_filepath);
        end
    end
end
