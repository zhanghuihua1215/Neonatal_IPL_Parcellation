clear; close all; clc;

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');

subj_list_file = '/dat05/users/zhanghuihua/brain_development/dHCP_40_list.txt';
data_root = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F3_volume_to_surface_s4mm/';
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/1_Individual_Inputs/';
list_txt_file = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/input_files.txt';

if ~exist(output_dir, 'dir'), mkdir(output_dir); end

raw_list = readcell(subj_list_file);
raw_list = raw_list(~cellfun('isempty', raw_list));
num_sub = length(raw_list);

fid_list = fopen(list_txt_file, 'w');

for i = 1:num_sub
    raw_id = raw_list{i};
    if isnumeric(raw_id), sub_id = num2str(raw_id); else, sub_id = char(raw_id); end
    sub_id = strtrim(sub_id);
    
    f_L = fullfile(data_root, 'left', sub_id, sprintf('%s_hemi-left_bold_projected_masked_s4mm.func.gii', sub_id));
    f_R = fullfile(data_root, 'right', sub_id, sprintf('%s_hemi-right_bold_projected_masked_s4mm.func.gii', sub_id));
    
    if ~isfile(f_L) || ~isfile(f_R)
        continue;
    end
    
    gL = gifti(f_L);
    gR = gifti(f_R);
    
    data_sub = [gL.cdata; gR.cdata];
    [n_v, n_t] = size(data_sub);
    
    fake_nii = reshape(single(data_sub), [n_v, 1, 1, n_t]);
    out_name = fullfile(output_dir, [sub_id, '_fake.nii']);
    
    niftiwrite(fake_nii, out_name);
    fprintf(fid_list, '%s\n', out_name);
end

fclose(fid_list);
