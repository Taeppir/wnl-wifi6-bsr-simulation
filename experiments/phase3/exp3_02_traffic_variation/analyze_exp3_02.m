function analyze_exp3_02(mat_file)
% ANALYZE_EXP3_02: 트래픽 다양성에 따른 v3 효과 분석

    if nargin < 1
        mat_files = dir('../../../results/phase3/exp3_02/mat/exp3_02_results_*.mat');
        if isempty(mat_files)
            error('결과 파일을 찾을 수 없습니다.');
        end
        [~, idx] = max([mat_files.datenum]);
        mat_file = fullfile(mat_files(idx).folder, mat_files(idx).name);
    end
    
    fprintf('========================================\n');
    fprintf('  Experiment 3-2 결과 분석\n');
    fprintf('  트래픽 다양성 검증\n');
    fprintf('========================================\n\n');
    
    load(mat_file);
    
    %% =================================================================
    %  1. 개선율 계산
    %  =================================================================
    
    % results_mean: (scheme, rho, mu_on)
    baseline_mean_delay = squeeze(results_mean.mean_delay_ms(1, :, :));
    v3_mean_delay = squeeze(results_mean.mean_delay_ms(2, :, :));
    
    baseline_p90_delay = squeeze(results_mean.p90_delay_ms(1, :, :));
    v3_p90_delay = squeeze(results_mean.p90_delay_ms(2, :, :));
    
    baseline_collision = squeeze(results_mean.collision_rate(1, :, :));
    v3_collision = squeeze(results_mean.collision_rate(2, :, :));
    
    baseline_implicit = squeeze(results_mean.implicit_bsr_ratio(1, :, :));
    v3_implicit = squeeze(results_mean.implicit_bsr_ratio(2, :, :));
    
    % 개선율 (%)
    improvement_mean = (baseline_mean_delay - v3_mean_delay) ./ baseline_mean_delay * 100;
    improvement_p90 = (baseline_p90_delay - v3_p90_delay) ./ baseline_p90_delay * 100;
    improvement_coll = (baseline_collision - v3_collision) ./ baseline_collision * 100;
    
    %% =================================================================
    %  2. 전체 결과 테이블
    %  =================================================================
    
    n_rho = length(rho_range);
    n_mu = length(mu_on_range);
    
    [rho_grid, mu_grid] = ndgrid(rho_range, mu_on_range);
    
    T = table(rho_grid(:), mu_grid(:), ...
        baseline_mean_delay(:), v3_mean_delay(:), improvement_mean(:), ...
        baseline_p90_delay(:), v3_p90_delay(:), improvement_p90(:), ...
        baseline_implicit(:)*100, v3_implicit(:)*100, ...
        baseline_collision(:)*100, v3_collision(:)*100, improvement_coll(:), ...
        'VariableNames', {'rho', 'mu_on', ...
        'BL_Mean', 'v3_Mean', 'Impr_Mean_%', ...
        'BL_P90', 'v3_P90', 'Impr_P90_%', ...
        'BL_Impl_%', 'v3_Impl_%', ...
        'BL_Coll_%', 'v3_Coll_%', 'Impr_Coll_%'});
    
    %% =================================================================
    %  3. P90 개선율 기준 정렬
    %  =================================================================
    
    fprintf('========================================\n');
    fprintf('  v3 개선율 순위 (P90 기준)\n');
    fprintf('========================================\n\n');
    
    T_sorted = sortrows(T, 'Impr_P90_%', 'descend');
    disp(T_sorted);
    
    %% =================================================================
    %  4. Best/Worst 조건
    %  =================================================================
    
    [max_impr_p90, max_idx] = max(improvement_p90(:));
    [i_rho_best, i_mu_best] = ind2sub(size(improvement_p90), max_idx);
    
    fprintf('\n========================================\n');
    fprintf('  ✨ Best Traffic Condition\n');
    fprintf('========================================\n\n');
    fprintf('  조건:\n');
    fprintf('    rho    = %.2f\n', rho_range(i_rho_best));
    fprintf('    mu_on  = %.2f\n', mu_on_range(i_mu_best));
    fprintf('\n  결과:\n');
    fprintf('    Baseline P90 = %.2f ms\n', baseline_p90_delay(i_rho_best, i_mu_best));
    fprintf('    v3 P90       = %.2f ms\n', v3_p90_delay(i_rho_best, i_mu_best));
    fprintf('    개선율       = %.1f%%  ⭐\n', max_impr_p90);
    fprintf('    Implicit BSR = %.1f%%\n\n', baseline_implicit(i_rho_best, i_mu_best)*100);
    
    [min_impr_p90, min_idx] = min(improvement_p90(:));
    [i_rho_worst, i_mu_worst] = ind2sub(size(improvement_p90), min_idx);
    
    fprintf('========================================\n');
    fprintf('  ⚠️  Worst Traffic Condition\n');
    fprintf('========================================\n\n');
    fprintf('  조건:\n');
    fprintf('    rho    = %.2f\n', rho_range(i_rho_worst));
    fprintf('    mu_on  = %.2f\n', mu_on_range(i_mu_worst));
    fprintf('\n  결과:\n');
    fprintf('    Baseline P90 = %.2f ms\n', baseline_p90_delay(i_rho_worst, i_mu_worst));
    fprintf('    v3 P90       = %.2f ms\n', v3_p90_delay(i_rho_worst, i_mu_worst));
    fprintf('    개선율       = %.1f%%\n', min_impr_p90);
    fprintf('    Implicit BSR = %.1f%%\n\n', baseline_implicit(i_rho_worst, i_mu_worst)*100);
    
    %% =================================================================
    %  5. CSV 저장
    %  =================================================================
    
    csv_dir = '../../../results/phase3/exp3_02/csv';
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    csv_file = sprintf('%s/exp3_02_traffic_%s.csv', csv_dir, timestamp);
    writetable(T_sorted, csv_file);
    fprintf('✓ CSV 저장: %s\n\n', csv_file);
    
    %% =================================================================
    %  6. 시각화
    %  =================================================================
    
    fprintf('시각화 생성 중...\n');
    
    fig1 = figure('Position', [100, 100, 1400, 900]);
    
    metrics = {'improvement_p90', 'improvement_mean', 'baseline_implicit'};
    titles = {'P90 Delay Improvement (%)', 'Mean Delay Improvement (%)', 'Baseline Implicit BSR (%)'};
    
    for i = 1:3
        subplot(2, 2, i);
        
        if i == 1
            data = improvement_p90;
        elseif i == 2
            data = improvement_mean;
        else
            data = baseline_implicit * 100;
        end
        
        imagesc(mu_on_range, rho_range, data);
        colorbar;
        colormap('jet');
        
        xlabel('mu\_on');
        ylabel('rho');
        title(titles{i});
        set(gca, 'YDir', 'normal');
        
        % 값 표시
        for r = 1:size(data, 1)
            for c = 1:size(data, 2)
                text(mu_on_range(c), rho_range(r), ...
                    sprintf('%.1f', data(r, c)), ...
                    'HorizontalAlignment', 'center', ...
                    'Color', 'white', 'FontWeight', 'bold');
            end
        end
    end
    
    % 4번째 서브플롯: Implicit BSR vs 개선율 scatter
    subplot(2, 2, 4);
    scatter(baseline_implicit(:)*100, improvement_p90(:), 100, 'filled');
    xlabel('Baseline Implicit BSR (%)');
    ylabel('P90 Improvement (%)');
    title('Improvement vs Implicit BSR Ratio');
    grid on;
    
    % 추세선
    p = polyfit(baseline_implicit(:)*100, improvement_p90(:), 1);
    x_fit = linspace(min(baseline_implicit(:)*100), max(baseline_implicit(:)*100), 100);
    y_fit = polyval(p, x_fit);
    hold on;
    plot(x_fit, y_fit, 'r--', 'LineWidth', 2);
    legend('Data', sprintf('Fit: y=%.2fx + %.2f', p(1), p(2)), 'Location', 'best');
    
    sgtitle('Exp 3-2: Traffic Variation Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    
    fig_dir = '../../../results/phase3/exp3_02/figures';
    saveas(fig1, sprintf('%s/exp3_02_traffic_%s.png', fig_dir, timestamp));
    
    fprintf('✓ Figure 저장 완료\n\n');
    
    %% =================================================================
    %  7. 핵심 인사이트
    %  =================================================================
    
    fprintf('========================================\n');
    fprintf('  핵심 인사이트\n');
    fprintf('========================================\n\n');
    
    fprintf('1. 개선율 범위: %.1f%% ~ %.1f%%\n', min_impr_p90, max_impr_p90);
    fprintf('2. 평균 개선율: %.1f%%\n', mean(improvement_p90(:)));
    fprintf('3. Implicit BSR 범위: %.1f%% ~ %.1f%%\n', ...
        min(baseline_implicit(:))*100, max(baseline_implicit(:))*100);
    fprintf('4. 상관관계: Implicit BSR ↑ → 개선율 ↓ (기울기: %.2f)\n\n', p(1));
    
    fprintf('========================================\n');
    fprintf('  분석 완료!\n');
    fprintf('========================================\n\n');
end