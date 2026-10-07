clear; clc;

%% --- 1. 参数配置 ---
% 输入文件路径
input_file = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/2_Melodic_Results.ica_15/melodic_IC.nii.gz';

% [修改] 输出目录：指定为您要求的新路径
output_dir = '/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/3_split_components_15/';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% 数据参数 (根据之前的分析)
num_components = 15;     % 成分数量
vertex_count = 64984;    % 顶点总数 (32492左 + 32492右)
header_size = 352;       % NIfTI 头文件大小 

%% --- 2. 读取原始数据 (绕过坏头文件) ---
fprintf('正在解压并读取数据...\n');
try
    % 解压到临时文件夹
    unzipped_list = gunzip(input_file, tempdir);
    raw_nii_path = unzipped_list{1};
    
    % 打开二进制文件
    fid = fopen(raw_nii_path, 'rb');
    if fid == -1, error('无法打开解压文件'); end
    
    % 跳过头文件
    fseek(fid, header_size, 'bof');
    
    % 读取所有数据 (Float32)
    raw_data = fread(fid, inf, 'float32');
    fclose(fid);
    delete(raw_nii_path); % 清理临时文件
    
    % 检查数据完整性
    expected_size = vertex_count * num_components;
    if length(raw_data) ~= expected_size
        error('数据大小不匹配！预期 %d, 实际 %d', expected_size, length(raw_data));
    end
    
    % 重塑矩阵 [顶点数 x 成分数]
    ICA_Matrix = reshape(raw_data, [vertex_count, num_components]);
    
    fprintf('读取成功！数据维度: %d vertices x %d components\n', size(ICA_Matrix, 1), size(ICA_Matrix, 2));
    
catch ME
    error('读取失败: %s', ME.message);
end

%% --- 3. 保存为 GIFTI 文件 ---
% 确保 Gifti 库在路径中
addpath('/dat05/users/zhanghuihua/soft/gifti-main/'); 

n_L = 32492; % 左半球顶点数
n_R = 32492; % 右半球顶点数

fprintf('开始拆分并保存为 GIFTI (.func.gii) 到: %s\n', output_dir);

for i = 1:num_components
    % 提取数据
    full_data = ICA_Matrix(:, i);
    
    % 拆分左右半球
    data_L = full_data(1:n_L);
    data_R = full_data(n_L+1 : end);
    
    % 构造文件名
    name_L = fullfile(output_dir, sprintf('component_%02d_L.func.gii', i));
    name_R = fullfile(output_dir, sprintf('component_%02d_R.func.gii', i));
    
    % 保存左半球
    gL = gifti; 
    gL.cdata = data_L; 
    save(gL, name_L);
    
    % 保存右半球
    gR = gifti; 
    gR.cdata = data_R; 
    save(gR, name_R);
    
    if mod(i, 5) == 0
        fprintf('  - 已保存成分 %d (L/R)\n', i);
    end
end

fprintf('全部完成！文件保存在: %s\n', output_dir);