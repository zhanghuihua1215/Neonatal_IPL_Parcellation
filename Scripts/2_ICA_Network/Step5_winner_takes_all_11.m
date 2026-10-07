clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');

input_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/z/1_20_new_11/1_split_components_thre_4_sym_20/';
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/z/1_20_new_11/2_split_components_thre_4_sym_20_wta/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

target_ids = [1, 6, 7, 8, 9, 11, 12, 14, 15, 16, 19];
num_networks = length(target_ids);
hemispheres = {'L', 'R'};

for h = 1:length(hemispheres)
    hemi = hemispheres{h};
    
    temp_name = fullfile(input_dir, sprintf('component_%02d_%s.func.gii', target_ids(1), hemi));
    g_ref = gifti(temp_name);
    num_verts = size(g_ref.cdata, 1);
    
    data_matrix = zeros(num_verts, num_networks);
    
    for i = 1:num_networks
        net_id = target_ids(i);
        fname = fullfile(input_dir, sprintf('component_%02d_%s.func.gii', net_id, hemi));
        if exist(fname, 'file')
            g = gifti(fname);
            data_matrix(:, i) = g.cdata;
        end
    end
    
    [max_vals, max_idx] = max(data_matrix, [], 2);
    final_labels = zeros(num_verts, 1);
    mask_valid = max_vals > 0;
    final_labels(mask_valid) = target_ids(max_idx(mask_valid));
    
    out_name_combined = fullfile(output_dir, sprintf('Combined_Parcellation_11Net_%s.func.gii', hemi));
    g_out = g_ref;
    g_out.cdata = single(final_labels);
    save(g_out, out_name_combined);
    
    for i = 1:num_networks
        real_id = target_ids(i);
        network_map = zeros(num_verts, 1);
        vertex_indices = (final_labels == real_id);
        network_map(vertex_indices) = data_matrix(vertex_indices, i);
        
        out_name_single = fullfile(output_dir, sprintf('WTA_component_%02d_%s.func.gii', real_id, hemi));
        g_single = g_ref;
        g_single.cdata = single(network_map);
        save(g_single, out_name_single);
    end
end
