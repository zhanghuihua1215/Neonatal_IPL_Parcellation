clear; clc; close all;

addpath /dat05/users/zhanghuihua/soft/gifti-main/
addpath /dat05/users/zhanghuihua/soft/mymatlab/

struc_path_template = '/dat05/users/zhanghuihua/brain_development/less_out/T2w_out/2_neonatal_IPL_FisherZ_parcellation/IPL_%s_sc_FisherZ_norm_32k/IPL.%s.%d.32k.func.gii';
func_path_template = '/dat05/users/zhanghuihua/brain_development/less_out/fmri_out/F2_IPL_FisherZ_parcellation/IPL_%s_fc_FisherZ_norm_32k/IPL.%s.%d.32k.func.gii';

k_range = 2:10;
output_figure_path = '/dat05/users/zhanghuihua/brain_development/less_out/validation_out';
output_filename = '3_group_level_overall_optimality_vs_k_consistent_range.png';

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
        catch ME
        end
    end
end

dice_L = group_dice_results(:, 1);
dice_R = group_dice_results(:, 2);
symmetry_index = ones(num_k, 1);
valid_indices = (dice_L + dice_R) > 0;
symmetry_index(valid_indices) = 1 - (abs(dice_L(valid_indices) - dice_R(valid_indices)) ./ (dice_L(valid_indices) + dice_R(valid_indices)));

all_metrics = [dice_L, dice_R, symmetry_index];
optimality_score = mean(all_metrics, 2, 'omitnan');

figure('Name', 'Group-Level Overall Optimality Analysis', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 2000, 380]);

subplot(1, 4, 1);
plot(k_range, dice_L, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice');
hold on;
search_indices = 2:length(k_range); 
data_to_search = dice_L(search_indices);
[max_dice, local_max_idx] = max(data_to_search);
if ~isempty(max_dice) && ~isnan(max_dice)
    global_max_idx = search_indices(local_max_idx); best_k = k_range(global_max_idx);
    plot(best_k, max_dice, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (Dice = %.3f)', best_k, max_dice));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('LEFT Hemisphere'); xlabel('Number of clusters'); ylabel('Average Dice Coefficient'); set(gca, 'FontSize', 12); xticks(k_range);

subplot(1, 4, 2);
plot(k_range, dice_R, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Dice');
hold on;
search_indices = 2:length(k_range); 
data_to_search = dice_R(search_indices);
[max_dice, local_max_idx] = max(data_to_search);
if ~isempty(max_dice) && ~isnan(max_dice)
    global_max_idx = search_indices(local_max_idx); best_k = k_range(global_max_idx);
    plot(best_k, max_dice, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (Dice = %.3f)', best_k, max_dice));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('RIGHT Hemisphere'); xlabel('Number of clusters'); ylabel('Average Dice Coefficient'); set(gca, 'FontSize', 12); xticks(k_range);

subplot(1, 4, 3);
plot(k_range, symmetry_index, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.47 0.67 0.19], 'DisplayName', 'Symmetry Index');
hold on;
search_indices = 2:length(k_range); 
data_to_search_sym = symmetry_index(search_indices);
[max_sym, local_max_idx] = max(data_to_search_sym);
if ~isempty(max_sym) && ~isnan(max_sym)
    global_max_idx = search_indices(local_max_idx); 
    best_k_sym = k_range(global_max_idx);
    plot(best_k_sym, max_sym, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Optimal k = %d (%.3f)', best_k_sym, max_sym));
    legend('Location', 'southwest');
end
hold off; grid on; box on; title('Inter-hemispheric Symmetry'); ylabel('Symmetry Index'); xlabel('Number of clusters'); set(gca, 'FontSize', 12); xticks(k_range);

subplot(1, 4, 4);
plot(k_range, optimality_score, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8500 0.3250 0.0980], 'DisplayName', 'Optimality Score');
hold on;
search_indices = 2:length(k_range); 
data_to_search_overall = optimality_score(search_indices);
[max_score, local_max_idx] = max(data_to_search_overall);
if ~isempty(max_score) && ~isnan(max_score)
    global_max_idx = search_indices(local_max_idx); 
    best_k_overall = k_range(global_max_idx);
    plot(best_k_overall, max_score, 'r*', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('Best Overall k = %d (Score = %.3f)', best_k_overall, max_score));
    legend('Location', 'northeast');
end
hold off; grid on; box on; title('Overall Optimality Score', 'FontWeight', 'bold'); xlabel('Number of clusters'); ylabel('Combined Score '); set(gca, 'FontSize', 12, 'FontWeight', 'normal'); xticks(k_range);

if ~exist(output_figure_path, 'dir'); mkdir(output_figure_path); end
saveas(gcf, fullfile(output_figure_path, output_filename));
