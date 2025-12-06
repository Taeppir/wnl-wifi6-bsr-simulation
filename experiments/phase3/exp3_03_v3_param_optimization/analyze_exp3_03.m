function analyze_exp3_03(mat_file)
% ANALYZE_EXP3_03: v3 파라미터 최적화 분석

    if nargin < 1
        mat_files = dir('../../../results/phase3/exp3_03/mat/exp3_03_results_*.mat');
        if isempty(mat_files)
            error('결과 파일을 찾을 수 없습니다.');
        end
        [~, idx] = max([mat_files.datenum]);
        mat_file = fullfile(mat_files(idx).folder, mat_files(idx).name);
    end
    
    fprintf('========================================\n');
    fprintf('  Experiment 3-3 결과 분석\n');
    fprintf('  v3 파라미터 최적화\n');
    fprintf('========================================\n\n');
    
    load(mat_file);
    
    %% =================================================================
    %  1. 개선율 계산
    %  =================================================================
    
    % results_mean: (scheme, EMA, red)
    baseline_p90 = squeeze(results_mean.p90_delay_ms(1, :, :));
    v3_p90 = squeeze(results_mean.p90_delay_ms(2, :, :));
    
    baseline_mean = squeeze(results_mean.mean_delay_ms(1, :, :));
    v3_mean = squeeze(results_mean.mean_delay_ms(2, :, :));
    
    baseline_coll = squeeze(results_mean.collision_rate(1, :, :));
    v3_coll = squeeze(results_mean.collision_rate(2, :, :));
    
    % 개선율 (%)
    improvement_p90 = (baseline_p90 - v3_p90) ./ baseline_p90 * 100;
    improvement_mean = (baseline_mean - v3_mean) ./ baseline_mean * 100;
    improvement_coll = (baseline_coll - v3_coll) ./ baseline_coll * 100;
    
    %% =================================================================
    %  2. 전체 결과 테이블
    %  =================================================================
    
    n_EMA = length(EMA_alpha_range);
    n_red = length(max_red_range);
    
    [EMA_grid, red_grid] = ndgrid(EMA_alpha_range, max_red_range);
    
    T = table(EMA_grid(:), red_grid(:), ...
        baseline_p90(:), v3_p90(:), improvement_p90(:), ...
        baseline_mean(:), v3_mean(:), improvement_mean(:), ...
        baseline_coll(:)*100, v3_coll(:)*100, improvement_coll(:), ...
        'VariableNames', {'EMA_α', 'max_red', ...
        'BL_P90', 'v3_P90', 'Impr_P90_%', ...
        'BL_Mean', 'v3_Mean', 'Impr_Mean_%', ...
        'BL_Coll_%', 'v3_Coll_%', 'Impr_Coll_%'});
    
    %% =================================================================
    %  3. P90 개선율 기준 정렬
    %  =================================================================
    
    fprintf('========================================\n');
    fprintf('  v3 파라미터 최적화 결과 (P90 기준)\n');
    fprintf('========================================\n\n');
    
    T_sorted = sortrows(T, 'Impr_P90_%', 'descend');
    disp(T_sorted);
    
    %% =================================================================
    %  4. Best 조건
    %  =================================================================
    
    [max_impr, max_idx] = max(improvement_p90(:));
    [i_EMA_best, i_red_best] = ind2sub(size(improvement_p90), max_idx);
    
    fprintf('\n========================================\n');
    fprintf('  ✨ 최적 v3 파라미터\n');
    fprintf('========================================\n\n');
    fprintf('  파라미터:\n');
    fprintf('    EMA_α      = %.2f\n', EMA_alpha_range(i_EMA_best));
    fprintf('    max_red    = %.2f\n', max_red_range(i_red_best));
    fprintf('\n  결과:\n');
    fprintf('    Baseline P90 = %.2f ms\n', baseline_p90(i_EMA_best, i_red_best));
    fprintf('    v3 P90       = %.2f ms\n', v3_p90(i_EMA_best, i_red_best));
    fprintf('    개선율       = %.1f%%  ⭐\n\n', max_impr);
    
    % 기존 파라미터와 비교
    % 기존: EMA_α=0.1, max_red=0.7
    idx_old = find(EMA_alpha_range == 0.1);
    idx_old2 = find(max_red_range == 0.7);
    if ~isempty(idx_old) && ~isempty(idx_old2)
        old_impr = improvement_p90(idx_old, idx_old2);
        fprintf('  기존 파라미터 (EMA=0.1, red=0.7):\n');
        fprintf('    개선율 = %.1f%%\n', old_impr);
        fprintf('    향상   = %.1f%% → %.1f%% (+%.1f%%p)\n\n', ...
            old_impr, max_impr, max_impr - old_impr);
    end
    
    %% =================================================================
    %  5. CSV 저장
    %  =================================================================
    
    csv_dir = '../../../results/phase3/exp3_03/csv';
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    csv_file = sprintf('%s/exp3_03_v3_params_%s.csv', csv_dir, timestamp);
    writetable(T_sorted, csv_file);
    fprintf('✓ CSV 저장: %s\n\n', csv_file);
    
    %% =================================================================
    %  6. 시각화
    %  =================================================================
    
    fprintf('시각화 생성 중...\n');
    
    fig1 = figure('Position', [100, 100, 1200, 400]);
    
    % 히트맵 1: P90 개선율
    subplot(1, 3, 1);
    imagesc(max_red_range, EMA_alpha_range, improvement_p90);
    colorbar;
    colormap('jet');
    xlabel('max\_reduction');
    ylabel('EMA\_alpha');
    title('P90 Delay Improvement (%)');
    set(gca, 'YDir', 'normal');
    
    % 값 표시
    for i = 1:n_EMA
        for j = 1:n_red
            text(max_red_range(j), EMA_alpha_range(i), ...
                sprintf('%.1f', improvement_p90(i, j)), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'white', 'FontWeight', 'bold');
        end
    end
    
    % 히트맵 2: Mean 개선율
    subplot(1, 3, 2);
    imagesc(max_red_range, EMA_alpha_range, improvement_mean);
    colorbar;
    colormap('jet');
    xlabel('max\_reduction');
    ylabel('EMA\_alpha');
    title('Mean Delay Improvement (%)');
    set(gca, 'YDir', 'normal');
    
    for i = 1:n_EMA
        for j = 1:n_red
            text(max_red_range(j), EMA_alpha_range(i), ...
                sprintf('%.1f', improvement_mean(i, j)), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'white', 'FontWeight', 'bold');
        end
    end
    
    % 히트맵 3: Collision 개선율
    subplot(1, 3, 3);
    imagesc(max_red_range, EMA_alpha_range, improvement_coll);
    colorbar;
    colormap('jet');
    xlabel('max\_reduction');
    ylabel('EMA\_alpha');
    title('Collision Rate Improvement (%)');
    set(gca, 'YDir', 'normal');
    
    for i = 1:n_EMA
        for j = 1:n_red
            text(max_red_range(j), EMA_alpha_range(i), ...
                sprintf('%.1f', improvement_coll(i, j)), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'white', 'FontWeight', 'bold');
        end
    end
    
    sgtitle('Exp 3-3: v3 Parameter Optimization', 'FontSize', 14, 'FontWeight', 'bold');
    
    fig_dir = '../../../results/phase3/exp3_03/figures';
    saveas(fig1, sprintf('%s/exp3_03_v3_params_%s.png', fig_dir, timestamp));
    
    fprintf('✓ Figure 저장 완료\n\n');
    
    fprintf('========================================\n');
    fprintf('  분석 완료!\n');
    fprintf('========================================\n\n');
end