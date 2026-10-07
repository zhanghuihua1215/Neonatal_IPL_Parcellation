clear; clc;

input_file = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/2_Melodic_Results.ica_15/melodic_IC.nii.gz';
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/3_split_components_15/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

num_components = 15;
vertex_count = 64984;
header_size = 352;

unzipped_list = gunzip(input_file, tempdir);
raw_nii_path = unzipped_list{1};

fid = fopen(raw_nii_path, 'rb');
fseek(fid, header_size, 'bof');
raw_data = fread(fid, inf, 'float32');
fclose(fid);
delete(raw_nii_path);

ICA_Matrix = reshape(raw_data, [vertex_count, num_components]);

addpath('/dat05/users/zhanghuihua/soft/gifti-main/');
n_L = 32492;

for i = 1:num_components
    full_data = ICA_Matrix(:, i);
    data_L = full_data(1:n_L);
    data_R = full_data(n_L+1:end);
    
    name_L = fullfile(output_dir, sprintf('component_%02d_L.func.gii', i));
    name_R = fullfile(output_dir, sprintf('component_%02d_R.func.gii', i));
    
    gL = gifti; gL.cdata = data_L; save(gL, name_L);
    gR = gifti; gR.cdata = data_R; save(gR, name_R);
end
