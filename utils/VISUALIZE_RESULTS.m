function figs = VISUALIZE_RESULTS(results, cfg)
% VISUALIZE_RESULTS: 시뮬레이션 결과 시각화
%
% 입력:
%   results - ANALYZE_RESULTS_v2의 결과 구조체
%   cfg     - 설정 구조체
%
% 출력:
%   figs - figure 핸들 배열
%
% 생성되는 그래프:
%   1. 큐잉 지연 CDF
%   2. 큐잉 지연 히스토그램
%   3. UORA 효율성 (충돌/성공/유휴)
%   4. BSR 통계
%   5. 단말별 공평성
%   6. 시계열 (Stage별 메트릭)

    figs = [];
    
    %% =====================================================================
    %  Figure 1: 큐잉 지연 CDF (누적 분포 함수)
    %  =====================================================================
    
    if ~isempty(results.packet_level.delay_samples)
        figs(end+1) = figure('Name', 'Queuing Delay CDF', 'Position', [100, 100, 800, 600]);
        
        delays_ms = results.packet_level.delay_samples * 1000;  % ms 단위
        
        % CDF 계산
        sorted_delays = sort(delays_ms);
        cdf_y = (1:length(sorted_delays)) / length(sorted_delays);
        
        plot(sorted_delays, cdf_y, 'b-', 'LineWidth', 2);
        grid on;
        xlabel('Queuing Delay [ms]', 'FontSize', 12);
        ylabel('CDF', 'FontSize', 12);
        title(sprintf('Queuing Delay CDF (%s, %d STAs, L_{cell}=%.2f)', ...
            results.metadata.scheme_name, cfg.num_STAs, cfg.L_cell), ...
            'FontSize', 14);
        
        % P50, P90, P99 선 표시
        hold on;
        p50 = results.packet_level.p50_delay * 1000;
        p90 = results.packet_level.p90_delay * 1000;
        p99 = results.packet_level.p99_delay * 1000;
        
        yline(0.5, 'r--', sprintf('P50: %.2f ms', p50), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
        yline(0.9, 'g--', sprintf('P90: %.2f ms', p90), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
        yline(0.99, 'm--', sprintf('P99: %.2f ms', p99), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
        
        xlim([0, min(max(sorted_delays), prctile(sorted_delays, 99.5))]);  % 99.5% 범위
        ylim([0, 1]);
    end
    
    %% =====================================================================
    %  Figure 2: 큐잉 지연 히스토그램
    %  =====================================================================
    
    if ~isempty(results.packet_level.delay_samples)
        figs(end+1) = figure('Name', 'Queuing Delay Histogram', 'Position', [150, 150, 800, 600]);
        
        delays_ms = results.packet_level.delay_samples * 1000;
        
        histogram(delays_ms, 50, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'k');
        grid on;
        xlabel('Queuing Delay [ms]', 'FontSize', 12);
        ylabel('Count', 'FontSize', 12);
        title(sprintf('Queuing Delay Distribution (%s)', results.metadata.scheme_name), ...
            'FontSize', 14);
        
        % 평균선 표시
        hold on;
        mean_delay_ms = results.packet_level.mean_delay * 1000;
        xline(mean_delay_ms, 'r--', sprintf('Mean: %.2f ms', mean_delay_ms), ...
            'LineWidth', 2, 'LabelVerticalAlignment', 'top');
    end
    
    %% =====================================================================
    %  Figure 3: UORA 효율성 (Pie Chart)
    %  =====================================================================
    
    figs(end+1) = figure('Name', 'UORA Efficiency', 'Position', [200, 200, 1000, 500]);
    
    % Subplot 1: Pie Chart
    subplot(1, 2, 1);
    
    collision_rate = results.uora.collision_rate * 100;
    success_rate = results.uora.success_rate * 100;
    idle_rate = results.uora.idle_rate * 100;
    
    pie_data = [success_rate, collision_rate, idle_rate];
    labels = {sprintf('Success\n%.1f%%', success_rate), ...
              sprintf('Collision\n%.1f%%', collision_rate), ...
              sprintf('Idle\n%.1f%%', idle_rate)};
    
    pie(pie_data);
    colormap([0.2, 0.8, 0.2; 0.8, 0.2, 0.2; 0.7, 0.7, 0.7]);  % 초록, 빨강, 회색
    legend(labels, 'Location', 'best', 'FontSize', 10);
    title('UORA RU Utilization', 'FontSize', 14);
    
    % Subplot 2: Bar Chart
    subplot(1, 2, 2);
    
    bar_data = [success_rate; collision_rate; idle_rate];
    bar_labels = {'Success', 'Collision', 'Idle'};
    
    b = bar(bar_data, 'FaceColor', 'flat');
    b.CData = [0.2, 0.8, 0.2; 0.8, 0.2, 0.2; 0.7, 0.7, 0.7];
    
    set(gca, 'XTickLabel', bar_labels, 'FontSize', 11);
    ylabel('Percentage [%]', 'FontSize', 12);
    title('UORA Statistics', 'FontSize', 14);
    grid on;
    ylim([0, 100]);
    
    % 값 표시
    for i = 1:length(bar_data)
        text(i, bar_data(i) + 2, sprintf('%.1f%%', bar_data(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    %% =====================================================================
    %  Figure 4: BSR 통계
    %  =====================================================================
    
    figs(end+1) = figure('Name', 'BSR Statistics', 'Position', [250, 250, 1000, 500]);
    
    % Subplot 1: Explicit vs Implicit
    subplot(1, 2, 1);
    
    explicit_ratio = results.bsr.explicit_ratio * 100;
    implicit_ratio = results.bsr.implicit_ratio * 100;
    
    pie_bsr = [explicit_ratio, implicit_ratio];
    labels_bsr = {sprintf('Explicit\n%.1f%%', explicit_ratio), ...
                  sprintf('Implicit\n%.1f%%', implicit_ratio)};
    
    pie(pie_bsr);
    colormap([0.9, 0.5, 0.2; 0.2, 0.5, 0.9]);  % 주황, 파랑
    legend(labels_bsr, 'Location', 'best', 'FontSize', 10);
    title('BSR Type Distribution', 'FontSize', 14);
    
    % Subplot 2: BSR 카운트
    subplot(1, 2, 2);
    
    bar_bsr = [results.bsr.total_explicit, results.bsr.total_implicit];
    bar(bar_bsr, 'FaceColor', 'flat', 'CData', [0.9, 0.5, 0.2; 0.2, 0.5, 0.9]);
    
    set(gca, 'XTickLabel', {'Explicit', 'Implicit'}, 'FontSize', 11);
    ylabel('Count', 'FontSize', 12);
    title('BSR Counts', 'FontSize', 14);
    grid on;
    
    % 값 표시
    for i = 1:length(bar_bsr)
        text(i, bar_bsr(i) + max(bar_bsr)*0.02, sprintf('%d', bar_bsr(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    %% =====================================================================
    %  Figure 5: 단말별 공평성
    %  =====================================================================
    
    figs(end+1) = figure('Name', 'Per-STA Fairness', 'Position', [300, 300, 1000, 600]);
    
    % Subplot 1: 단말별 처리량
    subplot(2, 1, 1);
    
    throughput_kb = results.fairness.throughput_per_sta / 1e3;  % KB
    
    bar(throughput_kb, 'FaceColor', [0.4, 0.6, 0.8]);
    xlabel('STA ID', 'FontSize', 12);
    ylabel('Throughput [KB]', 'FontSize', 12);
    title(sprintf('Per-STA Throughput (Jain Index: %.3f)', results.fairness.jain_index), ...
        'FontSize', 14);
    grid on;
    
    % 평균선
    hold on;
    mean_throughput = mean(throughput_kb);
    yline(mean_throughput, 'r--', sprintf('Mean: %.1f KB', mean_throughput), ...
        'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    
    % Subplot 2: 단말별 평균 지연
    subplot(2, 1, 2);
    
    delays_per_sta_ms = results.fairness.mean_delay_per_sta * 1000;  % ms
    
    bar(delays_per_sta_ms, 'FaceColor', [0.8, 0.4, 0.4]);
    xlabel('STA ID', 'FontSize', 12);
    ylabel('Mean Delay [ms]', 'FontSize', 12);
    title('Per-STA Mean Queuing Delay', 'FontSize', 14);
    grid on;
    
    % 평균선
    hold on;
    mean_delay_all = mean(delays_per_sta_ms, 'omitnan');
    yline(mean_delay_all, 'r--', sprintf('Mean: %.2f ms', mean_delay_all), ...
        'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    
    %% =====================================================================
    %  Figure 6: 요약 대시보드
    %  =====================================================================
    
    figs(end+1) = figure('Name', 'Summary Dashboard', 'Position', [400, 400, 1200, 800]);
    
    % 6개 서브플롯으로 핵심 메트릭 표시
    
    % (1) 지연 통계
    subplot(2, 3, 1);
    delay_stats = [results.summary.mean_delay_ms, ...
                   results.summary.p90_delay_ms, ...
                   results.summary.p99_delay_ms];
    bar(delay_stats, 'FaceColor', [0.3, 0.6, 0.9]);
    set(gca, 'XTickLabel', {'Mean', 'P90', 'P99'}, 'FontSize', 10);
    ylabel('Delay [ms]', 'FontSize', 11);
    title('Queuing Delay', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    
    % (2) 처리율
    subplot(2, 3, 2);
    bar(results.summary.throughput_mbps, 'FaceColor', [0.6, 0.8, 0.3]);
    ylabel('Throughput [Mb/s]', 'FontSize', 11);
    title('Network Throughput', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'XTickLabel', {''});
    grid on;
    text(1, results.summary.throughput_mbps/2, sprintf('%.2f Mb/s', results.summary.throughput_mbps), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    
    % (3) UORA 효율
    subplot(2, 3, 3);
    uora_stats = [results.summary.collision_rate * 100, ...
                  results.summary.success_rate * 100];
    bar(uora_stats, 'FaceColor', 'flat', 'CData', [0.8, 0.2, 0.2; 0.2, 0.8, 0.2]);
    set(gca, 'XTickLabel', {'Collision', 'Success'}, 'FontSize', 10);
    ylabel('Rate [%]', 'FontSize', 11);
    title('UORA Efficiency', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    ylim([0, 100]);
    
    % (4) BSR
    subplot(2, 3, 4);
    bar(results.summary.implicit_bsr_ratio * 100, 'FaceColor', [0.2, 0.5, 0.9]);
    ylabel('Implicit BSR [%]', 'FontSize', 11);
    title('BSR Type', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'XTickLabel', {''});
    grid on;
    ylim([0, 100]);
    text(1, 50, sprintf('%.1f%%', results.summary.implicit_bsr_ratio * 100), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    
    % (5) 공평성
    subplot(2, 3, 5);
    bar(results.summary.jain_index, 'FaceColor', [0.9, 0.6, 0.2]);
    ylabel('Jain Index', 'FontSize', 11);
    title('Fairness', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'XTickLabel', {''});
    grid on;
    ylim([0, 1]);
    text(1, 0.5, sprintf('%.3f', results.summary.jain_index), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    
    % (6) 완료율
    subplot(2, 3, 6);
    bar(results.summary.completion_rate * 100, 'FaceColor', [0.5, 0.5, 0.5]);
    ylabel('Completion Rate [%]', 'FontSize', 11);
    title('Packet Completion', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'XTickLabel', {''});
    grid on;
    ylim([0, 100]);
    text(1, 50, sprintf('%.1f%%', results.summary.completion_rate * 100), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    
    % 전체 제목
    sgtitle(sprintf('Simulation Summary: %s | %d STAs | L_{cell}=%.2f | \\rho=%.2f', ...
        results.metadata.scheme_name, cfg.num_STAs, cfg.L_cell, cfg.rho), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    %% =====================================================================
    %  완료 메시지
    %  =====================================================================
    
    fprintf('Generated %d figures\n', length(figs));
end