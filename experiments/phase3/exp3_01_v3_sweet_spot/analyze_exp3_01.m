function analyze_exp3_01(mat_file)
% ANALYZE_EXP3_01: v3 vs Baseline 개선율 분석

    if nargin < 1
        mat_files = dir('../../../results/phase3/exp3_01/mat/exp3_01_results_*.mat');
        if isempty(mat_files)
            error('결과 파일을 찾을 수 없습니다.');
        end
        [~, idx] = max([mat_files.datenum]);
        mat_file = fullfile(mat_files(idx).folder, mat_files(idx).name);
    end
    
    fprintf('========================================\n');
    fprintf('  Experiment 3-1 결과 분석\n');
    fprintf('  v3 vs Baseline 개선율\n');
    fprintf('========================================\n\n');
    
    load(mat_file);
    
    %% =================================================================
    %  1. 개선율 계산
    %  =================================================================
    
    % results_mean: (scheme, L, RA, STA)
    % scheme 1 = Baseline (v0)
    % scheme 2 = v3
    
    baseline_mean_delay = squeeze(results_mean.mean_delay_ms(1, :, :, :));
    v3_mean_delay = squeeze(results_mean.mean_delay_ms(2, :, :, :));
    
    baseline_p90_delay = squeeze(results_mean.p90_delay_ms(1, :, :, :));
    v3_p90_delay = squeeze(results_mean.p90_delay_ms(2, :, :, :));
    
    baseline_collision = squeeze(results_mean.collision_rate(1, :, :, :));
    v3_collision = squeeze(results_mean.collision_rate(2, :, :, :));
    
    % 개선율 (%) = (Baseline - v3) / Baseline * 100
    improvement_mean = (baseline_mean_delay - v3_mean_delay) ./ baseline_mean_delay * 100;
    improvement_p90 = (baseline_p90_delay - v3_p90_delay) ./ baseline_p90_delay * 100;
    improvement_coll = (baseline_collision - v3_collision) ./ baseline_collision * 100;
    
    %% =================================================================
    %  2. 전체 결과 테이블 (벡터화 수정)
    %  =================================================================
    
    n_L = length(L_cell_range);
    n_RA = length(numRU_RA_range);
    n_STA = length(num_STAs_range);
    
    % ⭐ meshgrid 사용하여 순서 보장
    [L_grid, RA_grid, STA_grid] = ndgrid(L_cell_range, numRU_RA_range, num_STAs_range);
    
    T = table(L_grid(:), RA_grid(:), STA_grid(:), ...
        baseline_mean_delay(:), v3_mean_delay(:), improvement_mean(:), ...
        baseline_p90_delay(:), v3_p90_delay(:), improvement_p90(:), ...
        baseline_collision(:)*100, v3_collision(:)*100, improvement_coll(:), ...
        'VariableNames', {'L_cell', 'RA_RU', 'STAs', ...
        'BL_Mean', 'v3_Mean', 'Impr_Mean_%', ...
        'BL_P90', 'v3_P90', 'Impr_P90_%', ...
        'BL_Coll_%', 'v3_Coll_%', 'Impr_Coll_%'});
    
    %% =================================================================
    %  3. P90 개선율 기준 정렬
    %  =================================================================
    
    fprintf('========================================\n');
    fprintf('  v3 개선율 순위 (P90 기준, Top 10)\n');
    fprintf('========================================\n\n');
    
    T_sorted = sortrows(T, 'Impr_P90_%', 'descend');
    disp(T_sorted(1:min(10, height(T_sorted)), :));
    
    %% =================================================================
    %  4. Mean Delay 개선율 기준 정렬
    %  =================================================================
    
    fprintf('\n========================================\n');
    fprintf('  v3 개선율 순위 (Mean 기준, Top 10)\n');
    fprintf('========================================\n\n');
    
    T_sorted_mean = sortrows(T, 'Impr_Mean_%', 'descend');
    disp(T_sorted_mean(1:min(10, height(T_sorted_mean)), :));
    
    %% =================================================================
    %  5. Sweet Spot 요약
    %  =================================================================
    
    [max_impr_p90, max_idx] = max(improvement_p90(:));
    [i_L, i_RA, i_STA] = ind2sub(size(improvement_p90), max_idx);
    
    fprintf('\n========================================\n');
    fprintf('  ✨ v3 Sweet Spot (최대 P90 개선)\n');
    fprintf('========================================\n\n');
    fprintf('  조건:\n');
    fprintf('    L_cell   = %.2f\n', L_cell_range(i_L));
    fprintf('    numRU_RA = %d\n', numRU_RA_range(i_RA));
    fprintf('    num_STAs = %d\n', num_STAs_range(i_STA));
    fprintf('\n  결과:\n');
    fprintf('    Baseline P90 = %.2f ms\n', baseline_p90_delay(i_L, i_RA, i_STA));
    fprintf('    v3 P90       = %.2f ms\n', v3_p90_delay(i_L, i_RA, i_STA));
    fprintf('    개선율       = %.1f%%  ⭐\n\n', max_impr_p90);
    
    %% =================================================================
    %  6. Worst Case (최악의 개선율)
    %  =================================================================
    
    [min_impr_p90, min_idx] = min(improvement_p90(:));
    [i_L2, i_RA2, i_STA2] = ind2sub(size(improvement_p90), min_idx);
    
    fprintf('\n========================================\n');
    fprintf('  ⚠️  v3 Worst Case (최소 개선)\n');
    fprintf('========================================\n\n');
    fprintf('  조건:\n');
    fprintf('    L_cell   = %.2f\n', L_cell_range(i_L2));
    fprintf('    numRU_RA = %d\n', numRU_RA_range(i_RA2));
    fprintf('    num_STAs = %d\n', num_STAs_range(i_STA2));
    fprintf('\n  결과:\n');
    fprintf('    Baseline P90 = %.2f ms\n', baseline_p90_delay(i_L2, i_RA2, i_STA2));
    fprintf('    v3 P90       = %.2f ms\n', v3_p90_delay(i_L2, i_RA2, i_STA2));
    fprintf('    개선율       = %.1f%%\n\n', min_impr_p90);
    
    %% =================================================================
    %  7. CSV 저장
    %  =================================================================
    
    csv_dir = '../../../results/phase3/exp3_01/csv';
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    csv_file = sprintf('%s/exp3_01_improvement_%s.csv', csv_dir, timestamp);
    writetable(T_sorted, csv_file);
    fprintf('✓ CSV 저장: %s\n\n', csv_file);
    
    %% =================================================================
    %  8. 시각화
    %  =================================================================
    
    fprintf('시각화 생성 중...\n');
    
    fig1 = figure('Position', [100, 100, 1400, 400]);
    
    for i_STA = 1:n_STA
        subplot(1, 3, i_STA);
        
        data_slice = squeeze(improvement_p90(:, :, i_STA));
        
        imagesc(numRU_RA_range, L_cell_range, data_slice);
        colorbar;
        colormap('jet');
        caxis([min(improvement_p90(:)), max(improvement_p90(:))]);
        
        xlabel('numRU\_RA');
        ylabel('L\_cell');
        title(sprintf('STAs = %d', num_STAs_range(i_STA)));
        set(gca, 'YDir', 'normal');
        
        % 값 표시
        for i = 1:size(data_slice, 1)
            for j = 1:size(data_slice, 2)
                val = data_slice(i, j);
                if val > 0
                    text(numRU_RA_range(j), L_cell_range(i), ...
                        sprintf('%.1f', val), ...
                        'HorizontalAlignment', 'center', ...
                        'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
                else
                    text(numRU_RA_range(j), L_cell_range(i), ...
                        sprintf('%.1f', val), ...
                        'HorizontalAlignment', 'center', ...
                        'Color', 'black', 'FontWeight', 'bold', 'FontSize', 9);
                end
            end
        end
    end
    
    sgtitle('v3 P90 Delay Improvement (%) - Higher is Better', ...
        'FontSize', 14, 'FontWeight', 'bold');
    
    fig_dir = '../../../results/phase3/exp3_01/figures';
    saveas(fig1, sprintf('%s/improvement_p90_%s.png', fig_dir, timestamp));
    
    fprintf('✓ Figure 저장 완료\n\n');
    
    fprintf('========================================\n');
    fprintf('  분석 완료!\n');
    fprintf('========================================\n\n');
end