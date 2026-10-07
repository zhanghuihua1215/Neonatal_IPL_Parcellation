%% 主脚本: 比较【组水平】分区一致性、对称性及【综合最优性】
%
% 版本: 4.1 (Group-Level with Consistent Optimality Range)
% 目的: 除了计算Dice系数和对称性，此脚本还计算一个综合最优分数
%       (所有指标的平均值)，以确定在所有标准下的最佳k值。
% 修改日志:
%   - 统一了所有四个图表的逻辑，高亮的“最优值”均在 k=3 到 k=10 的范围内查找。
%
clear; clc; close all;

% --- 添加必要的工具包路径 ---
addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

% ==============================================================================
%                            参数设置区域
% ==============================================================================

% 1. 结构分区文件模板
struc_path_template = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/2_neonatal_IPL_FisherZ_parcellation/IPL_%s_sc_FisherZ_norm_32k/IPL.%s.%d.32k.func.gii';

% 2. 功能分区文件模板
func_path_template = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_IPL_FisherZ_parcellation/IPL_%s_fc_FisherZ_norm_32k/IPL.%s.%d.32k.func.gii';

% 3. 要处理的分区数量 (k) 的范围
k_range = 2:10;

% 4. 输出设置
output_figure_path = '/dat05/users/zhanghuihua/brain_development/less_out/validation_out';
output_filename = '3_group_level_overall_optimality_vs_k_consistent_range.png'; % 更新文件名

% ==============================================================================
%                           主逻辑 (与之前版本相同)
% ==============================================================================

% --- 步骤 1-3: 计算各半球Dice系数 ---
fprintf('步骤 1-3: 计算各半球Dice系数...\n');
hemispheres = {'left', 'right'};
num_k = length(k_range);
group_dice_results = NaN(num_k, 2);
for h = 1:2
    hemi_short_cap = upper(hemispheres{h}(1));
    for i = 1:num_k
        k = k_range(i);
        struc_filepath = sprintf(struc_path_template, hemi_short_cap, hemi_short_cap, k);
        func_filepath = sprintf(func_path_template, hemi_short_cap, hemi_short_cap, k);
        if ~exist(struc_filepath, 'file') || ~exist(func_filepath, 'file'); continue; end
        try
            func_data = gifti(func_filepath).cdata;
            struc_data = gifti(struc_filepath).cdata;
            dice_per_label = zeros(k, 1);
            for label = 1:k
                indices_func = find(func_data == label);
                indices_struc = find(struc_data == label);
                intersection_size = length(intersect(indices_func, indices_struc));
                denominator = length(indices_func) + length(indices_struc);
                if denominator > 0; dice_per_label(label) = (2 * intersection_size) / denominator; end
            end
            
            group_dice_results(i, h) = mean(dice_per_label, 'omitnan');
        catch ME; fprintf('  k=%d: 错误! %s\n', k, ME.message); end
    end
end
fprintf('Dice系数计算完毕！\n');

% --- 步骤 4: 计算半球对称性指数 ---
fprintf('步骤 4: 计算半球对称性指数...\n');
dice_L = group_dice_results(:, 1);
dice_R = group_dice_results(:, 2);
symmetry_index = ones(num_k, 1);
valid_indices = (dice_L + dice_R) > 0;
symmetry_index(valid_indices) = 1 - (abs(dice_L(valid_indices) - dice_R(valid_indices)) ./ (dice_L(valid_indices) + dice_R(valid_indices)));
fprintf('对称性指数计算完毕！\n');

% %%% --- 新增代码块: 打印与子图1和2对应的总结数据 --- %%%
fprintf('\n================== 结果汇总 (子图1 & 2 数据) ==================\n');
fprintf(' k | 左半球平均Dice | 右半球平均Dice\n');
fprintf('---|----------------|----------------\n');
for i = 1:num_k
    fprintf('%2d |     %.4f     |     %.4f\n', k_range(i), dice_L(i), dice_R(i));
end
fprintf('==================================================================\n\n');
% %%% --------------------------------------------------- %%%

% --- 步骤 5: 计算综合最优分数 ---
fprintf('步骤 5: 计算综合最优分数...\n');
all_metrics = [dice_L, dice_R, symmetry_index];
optimality_score = mean(all_metrics, 2, 'omitnan');
fprintf('综合最优分数计算完毕！\n');

% ==============================================================================
%                           步骤 6: 绘图 (2x2布局)
% ==============================================================================
fprintf('步骤 6: 开始绘图...\n');

%figure('Name', 'Group-Level Overall Optimality Analysis', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 1200, 1000]);
%figure('Name', 'Group-Level Overall Optimality Analysis', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 1500, 380]);
figure('Name', 'Group-Level Overall Optimality Analysis', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100,2000, 380]);
% --- 子图 1: 左半球Dice (逻辑不变) ---
subplot(1, 4, 1);
% plot(k_range, dice_L, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice Coefficient');
plot(k_range, dice_L, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice');
hold on;
search_indices = 2:length(k_range); data_to_search = dice_L(search_indices);
[max_dice, local_max_idx] = max(data_to_search);
if ~isempty(max_dice) && ~isnan(max_dice)
    global_max_idx = search_indices(local_max_idx); best_k = k_range(global_max_idx);
    plot(best_k, max_dice, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (Dice = %.3f)', best_k, max_dice));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('LEFT Hemisphere'); xlabel('Number of clusters'); ylabel('Average Dice Coefficient'); set(gca, 'FontSize', 12); xticks(k_range);

% --- 子图 2: 右半球Dice (逻辑不变) ---
subplot(1, 4, 2);
% plot(k_range, dice_R, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice Coefficient');
plot(k_range, dice_R, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice');
hold on;
search_indices = 2:length(k_range); data_to_search = dice_R(search_indices);
[max_dice, local_max_idx] = max(data_to_search);
if ~isempty(max_dice) && ~isnan(max_dice)
    global_max_idx = search_indices(local_max_idx); best_k = k_range(global_max_idx);
    plot(best_k, max_dice, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (Dice = %.3f)', best_k, max_dice));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('RIGHT Hemisphere'); xlabel('Number of clusters'); ylabel('Average Dice Coefficient'); set(gca, 'FontSize', 12); xticks(k_range);

% % --- 子图 3: 对称性指数 ---
subplot(1, 4, 3);
plot(k_range, symmetry_index, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.47 0.67 0.19], 'DisplayName', 'Symmetry Index');
hold on;
%%% 新增/修改 %%% --- 将峰值查找逻辑统一为 k=3 到 10 ---
search_indices = 2:length(k_range); % 定义搜索范围为 k=3..10
data_to_search_sym = symmetry_index(search_indices);
[max_sym, local_max_idx] = max(data_to_search_sym);
if ~isempty(max_sym) && ~isnan(max_sym)
    global_max_idx = search_indices(local_max_idx); % 转换回全局索引
    best_k_sym = k_range(global_max_idx);
    plot(best_k_sym, max_sym, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (%.3f)', best_k_sym, max_sym));
    legend('Location', 'southwest');
end
hold off; grid on; box on; title('Inter-hemispheric Symmetry'); ylabel('Symmetry Index'); xlabel('Number of clusters'); set(gca, 'FontSize', 12); xticks(k_range);

% --- 子图 4: 综合最优分数 ---
subplot(1, 4, 4);
plot(k_range, optimality_score, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8500 0.3250 0.0980], 'DisplayName', 'Optimality Score');
hold on;
%%% 新增/修改 %%% --- 将峰值查找逻辑统一为 k=3 到 10 ---
search_indices = 2:length(k_range); % 定义搜索范围为 k=3..10
data_to_search_overall = optimality_score(search_indices);
[max_score, local_max_idx] = max(data_to_search_overall);
if ~isempty(max_score) && ~isnan(max_score)
    global_max_idx = search_indices(local_max_idx); % 转换回全局索引
    best_k_overall = k_range(global_max_idx);
    plot(best_k_overall, max_score, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Best Overall k = %d (Score = %.3f)', best_k_overall, max_score));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('Overall Optimality Score', 'FontWeight', 'bold'); xlabel('Number of clusters'); ylabel('Combined Score '); set(gca, 'FontSize', 12, 'FontWeight', 'normal'); xticks(k_range);

% --- 添加总标题 ---
% sgtitle('Comprehensive Analysis of Parcellation Schemes', 'FontSize', 16, 'FontWeight', 'bold');

% --- 步骤 7: 保存结果图 ---
if ~exist(output_figure_path, 'dir'); mkdir(output_figure_path); end
saveas(gcf, fullfile(output_figure_path, output_filename));
fprintf('\n结果图已自动保存到: %s\n', fullfile(output_figure_path, output_filename));