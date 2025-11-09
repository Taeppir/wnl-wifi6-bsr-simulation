% %% test_traffic_parameters.m
% % 트래픽 파라미터 검증 및 비교
% %
% % 목적: 다양한 파라미터 조합의 특성 확인

% clear; close all; clc;

% fprintf('========================================\n');
% fprintf('  트래픽 파라미터 비교 분석\n');
% fprintf('========================================\n\n');

% %% 파라미터 조합 정의
% configs = {
%     % {name, alpha, mu_on, mu_off, L_cell}
%     {'현재 설정', 1.5, 0.05, 0.01, 0.6};
%     {'제안 1 (균형)', 1.5, 0.03, 0.03, 0.6};
%     {'제안 2 (버스티)', 1.2, 0.02, 0.05, 0.5};
%     {'제안 3 (실제)', 1.5, 0.04, 0.02, 0.6};
% };

% %% 시뮬레이션 설정
% num_STAs = 20;
% sim_time = 10.0;
% size_MPDU = 2000;
% numRU_SA = 8;
% data_rate_per_RU = 6.67e6;

% total_capacity = numRU_SA * data_rate_per_RU;

% %% 결과 저장
% results = table();

% fprintf('%-20s | %-6s | %-6s | %-6s | %-10s | %-10s | %-15s\n', ...
%     '설정', 'α', 'ρ', 'L', 'On(ms)', 'Off(ms)', 'Empty 비율(%)');
% fprintf('%s\n', repmat('-', 1, 90));

% for i = 1:length(configs)
%     cfg_info = configs{i};
%     name = cfg_info{1};
%     alpha = cfg_info{2};
%     mu_on = cfg_info{3};
%     mu_off = cfg_info{4};
%     L_cell = cfg_info{5};
    
%     % rho 계산
%     rho = mu_on / (mu_on + mu_off);
    
%     % cfg 생성
%     cfg = config_default();
%     cfg.num_STAs = num_STAs;
%     cfg.simulation_time = sim_time;
%     cfg.warmup_time = 2.0;
%     cfg.alpha = alpha;
%     cfg.mu_on = mu_on;
%     cfg.mu_off = mu_off;
%     cfg.rho = rho;
%     cfg.L_cell = L_cell;
%     cfg.verbose = 0;
    
%     % Lambda 재계산
%     cfg.lambda_network = cfg.L_cell * total_capacity / (size_MPDU * 8);
%     cfg.lambda = cfg.lambda_network / num_STAs;
    
%     % 트래픽 생성
%     STAs = DEFINE_STAs_v2(num_STAs, cfg.OCW_min, cfg);
%     STAs = gen_onoff_pareto_v2(STAs, cfg);
    
%     % 통계 계산
%     total_pkts = sum([STAs.num_of_packets]);
    
%     % 버퍼 Empty 시간 추정 (간접적)
%     % (패킷이 없는 단말 비율로 근사)
%     empty_stas = sum([STAs.num_of_packets] == 0);
%     empty_ratio = empty_stas / num_STAs * 100;
    
%     % 출력
%     fprintf('%-20s | %6.1f | %6.2f | %6.1f | %10.1f | %10.1f | %15.1f\n', ...
%         name, alpha, rho, L_cell, mu_on*1000, mu_off*1000, empty_ratio);
    
%     % 결과 저장
%     row = table();
%     row.name = {name};
%     row.alpha = alpha;
%     row.rho = rho;
%     row.L_cell = L_cell;
%     row.mu_on_ms = mu_on * 1000;
%     row.mu_off_ms = mu_off * 1000;
%     row.total_pkts = total_pkts;
%     row.empty_ratio = empty_ratio;
    
%     results = [results; row];
% end

% fprintf('\n');

% %% 분석 및 추천
% fprintf('========================================\n');
% fprintf('  분석 및 추천\n');
% fprintf('========================================\n\n');

% fprintf('📊 관찰:\n');
% fprintf('  • 현재 설정 (ρ=%.2f): Empty 비율 %.1f%%\n', ...
%     configs{1}{3}/(configs{1}{3}+configs{1}{4}), results.empty_ratio(1));
% fprintf('    → 비포화 특성이 약함\n\n');

% fprintf('  • 제안 1 (ρ=0.50): Empty 비율 증가 예상\n');
% fprintf('    → 균형잡힌 On/Off, UORA 경쟁 활발\n');
% fprintf('    → ✅ 제안 기법 효과 측정에 최적\n\n');

% fprintf('  • 제안 2 (ρ=0.29): Empty 비율 최대\n');
% fprintf('    → 극단적 비포화, UORA 경쟁 매우 빈번\n');
% fprintf('    → 버스트 트래픽 환경 시뮬레이션\n\n');

% fprintf('  • 제안 3 (ρ=0.67): 실제 트래픽 패턴\n');
% fprintf('    → 현재 설정의 완화 버전\n\n');

% fprintf('🎯 추천:\n');
% fprintf('  1순위: 제안 1 (ρ=0.5, On=Off=30ms)\n');
% fprintf('    - 비포화 특성 명확\n');
% fprintf('    - BSR 경쟁 활발\n');
% fprintf('    - 제안 기법 효과 측정에 최적\n\n');

% fprintf('  2순위: 제안 3 (ρ=0.67, On=40ms, Off=20ms)\n');
% fprintf('    - 실제 환경에 가까움\n');
% fprintf('    - 적당한 경쟁\n\n');

% fprintf('========================================\n\n');

% %% 실제 시뮬레이션으로 검증
% fprintf('실제 시뮬레이션으로 검증 중...\n\n');

% fprintf('%-20s | %-12s | %-12s | %-12s\n', ...
%     '설정', 'UORA 시도', 'Expl. BSR', 'Impl. BSR');
% fprintf('%s\n', repmat('-', 1, 65));

% for i = 1:min(2, length(configs))  % 처음 2개만 테스트
%     cfg_info = configs{i};
%     name = cfg_info{1};
    
%     cfg = config_default();
%     cfg.num_STAs = 10;  % 빠른 테스트
%     cfg.simulation_time = 5.0;
%     cfg.warmup_time = 1.0;
%     cfg.alpha = cfg_info{2};
%     cfg.mu_on = cfg_info{3};
%     cfg.mu_off = cfg_info{4};
%     cfg.rho = cfg.mu_on / (cfg.mu_on + cfg.mu_off);
%     cfg.L_cell = cfg_info{5};
%     cfg.scheme_id = 0;
%     cfg.verbose = 0;
    
%     % Lambda 재계산
%     cfg.lambda_network = cfg.L_cell * total_capacity / (size_MPDU * 8);
%     cfg.lambda = cfg.lambda_network / cfg.num_STAs;
    
%     % 실행
%     results_sim = main_sim_v2(cfg);
    
%     fprintf('%-20s | %12d | %12d | %12d\n', ...
%         name, ...
%         results_sim.uora.total_attempts, ...
%         results_sim.bsr.total_explicit, ...
%         results_sim.bsr.total_implicit);
% end

% fprintf('\n✅ 파라미터 검증 완료!\n\n');



%% test_traffic_parameters.m
% 트래픽 파라미터 비교 분석 및 시각화
%
% 목적:
%   - 다양한 Pareto On-Off 파라미터 조합의 특성 비교
%   - 버퍼 크기 분포 확인
%   - 비포화 특성 정량화
%   - 실제 시뮬레이션 결과 검증

clear; close all; clc;

fprintf('\n');
fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   트래픽 파라미터 비교 분석            ║\n');
fprintf('╚════════════════════════════════════════╝\n');
fprintf('\n');

%% =====================================================================
%  1. 파라미터 조합 정의
%  =====================================================================

configs = {
    % {이름, alpha, mu_on, mu_off, L_cell, 설명}
    {'현재 설정', 1.5, 0.05, 0.01, 0.5, '준-포화 (ρ=0.833)'};
    {'제안 1 (균형)', 1.5, 0.03, 0.03, 0.5, 'On=Off (ρ=0.5)'};
    {'제안 2 (버스티)', 1.2, 0.02, 0.05, 0.5, '짧은 버스트 (ρ=0.286)'};
    {'제안 3 (실제)', 1.5, 0.04, 0.02, 0.5, '실제 패턴 (ρ=0.667)'};
};

num_configs = length(configs);

%% =====================================================================
%  2. 기본 시뮬레이션 파라미터
%  =====================================================================

num_STAs = 20;
sim_time = 10.0;
warmup_time = 2.0;
size_MPDU = 2000;
numRU_SA = 8;
data_rate_per_RU = 6.67e6;
total_capacity = numRU_SA * data_rate_per_RU;

%% =====================================================================
%  3. 트래픽 생성 및 통계 수집
%  =====================================================================

fprintf('[1/4] 트래픽 생성 중...\n');

traffic_data = cell(num_configs, 1);
buffer_traces = cell(num_configs, 1);

for i = 1:num_configs
    cfg_info = configs{i};
    
    fprintf('  [%d/%d] %s... ', i, num_configs, cfg_info{1});
    
    % 설정 생성
    cfg = config_default();
    cfg.num_STAs = num_STAs;
    cfg.simulation_time = sim_time;
    cfg.warmup_time = warmup_time;
    cfg.alpha = cfg_info{2};
    cfg.mu_on = cfg_info{3};
    cfg.mu_off = cfg_info{4};
    cfg.rho = cfg.mu_on / (cfg.mu_on + cfg.mu_off);
    cfg.L_cell = cfg_info{5};
    cfg.verbose = 0;
    
    % Lambda 재계산
    cfg.lambda_network = cfg.L_cell * total_capacity / (size_MPDU * 8);
    cfg.lambda = cfg.lambda_network / num_STAs;
    
    % 트래픽 생성
    rng(42);  % 재현성
    STAs = DEFINE_STAs_v2(num_STAs, cfg.OCW_min, cfg);
    STAs = gen_onoff_pareto_v2(STAs, cfg);
    
    % 통계 수집
    data = struct();
    
    % 패킷 도착 시간 수집
    all_arrivals = [];
    for s = 1:num_STAs
        if ~isempty(STAs(s).packet_list)
            arrivals = [STAs(s).packet_list.arrival_time];
            all_arrivals = [all_arrivals, arrivals];
        end
    end
    all_arrivals = sort(all_arrivals);
    
    % Inter-arrival time
    if length(all_arrivals) > 1
        inter_arrivals = diff(all_arrivals);
    else
        inter_arrivals = [];
    end
    
    % 통계 저장
    data.cfg = cfg;
    data.STAs = STAs;
    data.all_arrivals = all_arrivals;
    data.inter_arrivals = inter_arrivals;
    data.total_packets = length(all_arrivals);
    data.packets_per_sta = [STAs.num_of_packets];
    data.empty_stas = sum([STAs.num_of_packets] == 0);
    
    traffic_data{i} = data;
    
    fprintf('완료 (%d packets)\n', data.total_packets);
end

fprintf('\n');

%% =====================================================================
%  4. 버퍼 크기 추적 시뮬레이션
%  =====================================================================

fprintf('[2/4] 버퍼 크기 추적 중...\n');

for i = 1:num_configs
    cfg_info = configs{i};
    
    fprintf('  [%d/%d] %s... ', i, num_configs, cfg_info{1});
    
    cfg = traffic_data{i}.cfg;
    cfg.simulation_time = 5.0;  % 빠른 추적을 위해 짧게
    cfg.warmup_time = 0.5;
    
    % 시뮬레이션 실행
    rng(42);
    [results, metrics] = main_sim_v2(cfg);
    
    % BSR 트레이스에서 버퍼 크기 추출
    if cfg.collect_bsr_trace && metrics.policy_level.trace_idx > 0
        idx = 1:metrics.policy_level.trace_idx;
        buffer_trace = struct();
        buffer_trace.time = metrics.policy_level.trace.time(idx);
        buffer_trace.Q = metrics.policy_level.trace.Q(idx);
        buffer_trace.sta_id = metrics.policy_level.trace.sta_id(idx);
    else
        buffer_trace = struct();
        buffer_trace.time = [];
        buffer_trace.Q = [];
        buffer_trace.sta_id = [];
    end
    
    buffer_traces{i} = buffer_trace;
    
    fprintf('완료 (%d samples)\n', length(buffer_trace.Q));
end

fprintf('\n');

%% =====================================================================
%  5. 실제 시뮬레이션 결과 비교
%  =====================================================================

fprintf('[3/4] 실제 시뮬레이션 실행 중...\n');

sim_results = cell(num_configs, 1);

for i = 1:num_configs
    cfg_info = configs{i};
    
    fprintf('  [%d/%d] %s... ', i, num_configs, cfg_info{1});
    
    cfg = traffic_data{i}.cfg;
    cfg.num_STAs = 20;
    cfg.simulation_time = 10.0;
    cfg.warmup_time = 2.0;
    cfg.scheme_id = 0;  % Baseline
    
    rng(100);  % 다른 시드
    results = main_sim_v2(cfg);
    
    sim_results{i} = results;
    
    fprintf('완료\n');
end

fprintf('\n');

%% =====================================================================
%  6. 수치 비교표 출력
%  =====================================================================

fprintf('[4/4] 결과 분석 중...\n\n');

fprintf('========================================\n');
fprintf('  파라미터 조합 비교\n');
fprintf('========================================\n\n');

fprintf('%-20s | %-6s | %-6s | %-6s | %-10s | %-10s | %-12s\n', ...
    '설정', 'α', 'ρ', 'L', 'On(ms)', 'Off(ms)', 'Empty(%)');
fprintf('%s\n', repmat('-', 1, 85));

for i = 1:num_configs
    cfg_info = configs{i};
    data = traffic_data{i};
    
    name = cfg_info{1};
    alpha = cfg_info{2};
    mu_on = cfg_info{3};
    mu_off = cfg_info{4};
    L_cell = cfg_info{5};
    rho = mu_on / (mu_on + mu_off);
    
    empty_ratio = data.empty_stas / num_STAs * 100;
    
    fprintf('%-20s | %6.1f | %6.2f | %6.1f | %10.1f | %10.1f | %12.1f\n', ...
        name, alpha, rho, L_cell, mu_on*1000, mu_off*1000, empty_ratio);
end

fprintf('\n');

%% =====================================================================
%  7. 시뮬레이션 결과 비교
%  =====================================================================

fprintf('========================================\n');
fprintf('  시뮬레이션 결과 비교\n');
fprintf('========================================\n\n');

fprintf('%-20s | %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    '설정', 'Expl.BSR', 'Impl.BSR', 'UORA시도', '충돌률(%)', '지연(ms)');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:num_configs
    cfg_info = configs{i};
    results = sim_results{i};
    
    name = cfg_info{1};
    expl = results.bsr.total_explicit;
    impl = results.bsr.total_implicit;
    uora_attempts = results.uora.total_attempts;
    coll_rate = results.summary.collision_rate * 100;
    delay_ms = results.summary.mean_delay_ms;
    
    fprintf('%-20s | %10d | %10d | %10d | %10.1f | %10.2f\n', ...
        name, expl, impl, uora_attempts, coll_rate, delay_ms);
end

fprintf('\n');

%% =====================================================================
%  8. 시각화
%  =====================================================================

fprintf('시각화 생성 중...\n\n');

% ─────────────────────────────────────────────────────────────────────
% Figure 1: 패킷 도착 패턴
% ─────────────────────────────────────────────────────────────────────

fig1 = figure('Position', [100, 100, 1400, 900]);
sgtitle('패킷 도착 패턴 비교', 'FontSize', 16, 'FontWeight', 'bold');

for i = 1:num_configs
    cfg_info = configs{i};
    data = traffic_data{i};
    
    % Subplot: 누적 패킷 도착
    subplot(2, 2, i);
    
    if ~isempty(data.all_arrivals)
        plot(data.all_arrivals, 1:length(data.all_arrivals), 'b-', 'LineWidth', 1.5);
        hold on;
        
        % 이론적 기울기
        t_theory = linspace(0, sim_time, 100);
        n_theory = data.cfg.lambda_network * t_theory;
        plot(t_theory, n_theory, 'r--', 'LineWidth', 1.5);
        
        xlabel('Time [s]');
        ylabel('Cumulative Packets');
        title(sprintf('%s\n(ρ=%.2f, L=%.1f)', ...
            cfg_info{1}, data.cfg.rho, data.cfg.L_cell));
        legend('Actual', 'Theoretical', 'Location', 'northwest');
        grid on;
        
        % 텍스트 정보
        text(0.05, 0.95, sprintf('총 패킷: %d개\nEmpty: %.0f%%', ...
            data.total_packets, data.empty_stas/num_STAs*100), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', ...
            'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end

saveas(fig1, 'results/traffic_arrival_patterns.png');

% ─────────────────────────────────────────────────────────────────────
% Figure 2: Inter-Arrival Time 분포
% ─────────────────────────────────────────────────────────────────────

fig2 = figure('Position', [150, 150, 1400, 900]);
sgtitle('Inter-Arrival Time 분포', 'FontSize', 16, 'FontWeight', 'bold');

for i = 1:num_configs
    cfg_info = configs{i};
    data = traffic_data{i};
    
    subplot(2, 2, i);
    
    if ~isempty(data.inter_arrivals)
        % 히스토그램
        histogram(data.inter_arrivals * 1000, 50, ...
            'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'k');
        
        xlabel('Inter-Arrival Time [ms]');
        ylabel('Count');
        title(sprintf('%s\n(ρ=%.2f)', cfg_info{1}, data.cfg.rho));
        grid on;
        
        % 통계 정보
        mean_ia = mean(data.inter_arrivals) * 1000;
        std_ia = std(data.inter_arrivals) * 1000;
        cv_ia = std_ia / mean_ia;
        
        text(0.6, 0.95, sprintf('평균: %.2f ms\n표준편차: %.2f ms\nCV: %.2f', ...
            mean_ia, std_ia, cv_ia), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', ...
            'BackgroundColor', 'white', 'EdgeColor', 'black');
        
        % Heavy-tail 여부 확인
        if cv_ia > 1
            text(0.6, 0.7, '✓ Heavy-tail', ...
                'Units', 'normalized', 'Color', 'green', ...
                'FontWeight', 'bold', 'FontSize', 12);
        end
    end
end

saveas(fig2, 'results/traffic_interarrival_dist.png');

% ─────────────────────────────────────────────────────────────────────
% Figure 3: 버퍼 크기 추적
% ─────────────────────────────────────────────────────────────────────

fig3 = figure('Position', [200, 200, 1400, 900]);
sgtitle('버퍼 크기 시계열 (대표 단말)', 'FontSize', 16, 'FontWeight', 'bold');

for i = 1:num_configs
    cfg_info = configs{i};
    buffer_trace = buffer_traces{i};
    
    subplot(2, 2, i);
    
    if ~isempty(buffer_trace.Q)
        % 단말 1의 버퍼 크기만 추출
        sta1_mask = (buffer_trace.sta_id == 1);
        t_sta1 = buffer_trace.time(sta1_mask);
        Q_sta1 = buffer_trace.Q(sta1_mask);
        
        if ~isempty(Q_sta1)
            % Area plot (버퍼 채워진 정도 시각화)
            area(t_sta1, Q_sta1, 'FaceColor', [0.8, 0.9, 1.0], ...
                'EdgeColor', [0.3, 0.5, 0.9], 'LineWidth', 1.5);
            
            xlabel('Time [s]');
            ylabel('Buffer Size [bytes]');
            title(sprintf('%s (STA 1)\n(ρ=%.2f)', cfg_info{1}, ...
                cfg_info{3}/(cfg_info{3}+cfg_info{4})));
            grid on;
            
            % 버퍼 Empty 시점 표시
            empty_times = t_sta1(Q_sta1 == 0);
            if ~isempty(empty_times)
                hold on;
                plot(empty_times, zeros(size(empty_times)), 'ro', ...
                    'MarkerSize', 6, 'MarkerFaceColor', 'red');
            end
            
            % 통계
            avg_Q = mean(Q_sta1);
            empty_ratio = sum(Q_sta1 == 0) / length(Q_sta1) * 100;
            
            text(0.05, 0.95, sprintf('평균: %.0f B\nEmpty: %.1f%%', ...
                avg_Q, empty_ratio), ...
                'Units', 'normalized', 'VerticalAlignment', 'top', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

saveas(fig3, 'results/buffer_size_traces.png');

% ─────────────────────────────────────────────────────────────────────
% Figure 4: 버퍼 크기 분포
% ─────────────────────────────────────────────────────────────────────

fig4 = figure('Position', [250, 250, 1400, 900]);
sgtitle('버퍼 크기 분포 (전체 단말)', 'FontSize', 16, 'FontWeight', 'bold');

for i = 1:num_configs
    cfg_info = configs{i};
    buffer_trace = buffer_traces{i};
    
    subplot(2, 2, i);
    
    if ~isempty(buffer_trace.Q)
        % 히스토그램
        histogram(buffer_trace.Q, 50, 'FaceColor', [0.9, 0.6, 0.3], ...
            'EdgeColor', 'k');
        
        xlabel('Buffer Size [bytes]');
        ylabel('Count');
        title(sprintf('%s\n(ρ=%.2f)', cfg_info{1}, ...
            cfg_info{3}/(cfg_info{3}+cfg_info{4})));
        grid on;
        
        % 통계
        avg_Q = mean(buffer_trace.Q);
        p50_Q = prctile(buffer_trace.Q, 50);
        p90_Q = prctile(buffer_trace.Q, 90);
        empty_count = sum(buffer_trace.Q == 0);
        empty_ratio = empty_count / length(buffer_trace.Q) * 100;
        
        text(0.55, 0.95, sprintf('평균: %.0f B\np50: %.0f B\np90: %.0f B\nEmpty: %.1f%%', ...
            avg_Q, p50_Q, p90_Q, empty_ratio), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', ...
            'BackgroundColor', 'white', 'EdgeColor', 'black');
        
        % Empty 비율 시각적 강조
        hold on;
        xline(0, 'r--', sprintf('Empty: %.1f%%', empty_ratio), ...
            'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');
    end
end

saveas(fig4, 'results/buffer_size_distributions.png');

% ─────────────────────────────────────────────────────────────────────
% Figure 5: 시뮬레이션 결과 비교 (Bar Chart)
% ─────────────────────────────────────────────────────────────────────

fig5 = figure('Position', [300, 300, 1400, 600]);
sgtitle('시뮬레이션 결과 비교', 'FontSize', 16, 'FontWeight', 'bold');

% 데이터 추출
names = cell(num_configs, 1);
expl_bsr = zeros(num_configs, 1);
impl_bsr = zeros(num_configs, 1);
uora_attempts = zeros(num_configs, 1);
coll_rates = zeros(num_configs, 1);
delays = zeros(num_configs, 1);

for i = 1:num_configs
    names{i} = configs{i}{1};
    results = sim_results{i};
    
    expl_bsr(i) = results.bsr.total_explicit;
    impl_bsr(i) = results.bsr.total_implicit;
    uora_attempts(i) = results.uora.total_attempts;
    coll_rates(i) = results.summary.collision_rate * 100;
    delays(i) = results.summary.mean_delay_ms;
end

% Subplot 1: BSR 타입
subplot(1, 3, 1);
b = bar([expl_bsr, impl_bsr], 'grouped');
b(1).FaceColor = [0.9, 0.5, 0.2];
b(2).FaceColor = [0.2, 0.5, 0.9];
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15);
ylabel('Count');
title('BSR 타입 비교');
legend('Explicit', 'Implicit', 'Location', 'best');
grid on;

% Subplot 2: UORA 활동성
subplot(1, 3, 2);
bar(uora_attempts, 'FaceColor', [0.5, 0.8, 0.5]);
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15);
ylabel('Count');
title('UORA 시도 횟수');
grid on;

% 값 표시
for i = 1:num_configs
    text(i, uora_attempts(i), sprintf('%d', uora_attempts(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

% Subplot 3: 충돌률 & 지연
subplot(1, 3, 3);
yyaxis left;
bar(coll_rates, 'FaceColor', [0.8, 0.3, 0.3]);
ylabel('충돌률 [%]');
ylim([0, max(coll_rates)*1.2]);

yyaxis right;
plot(1:num_configs, delays, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('평균 지연 [ms]');

set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15);
title('충돌률 & 지연');
grid on;

saveas(fig5, 'results/simulation_comparison.png');

% ─────────────────────────────────────────────────────────────────────
% Figure 6: 종합 요약 대시보드
% ─────────────────────────────────────────────────────────────────────

fig6 = figure('Position', [350, 350, 1400, 800]);
sgtitle('트래픽 파라미터 종합 비교', 'FontSize', 18, 'FontWeight', 'bold');

% 데이터 준비
rho_values = zeros(num_configs, 1);
empty_ratios = zeros(num_configs, 1);
total_pkts = zeros(num_configs, 1);

for i = 1:num_configs
    rho_values(i) = configs{i}{3} / (configs{i}{3} + configs{i}{4});
    empty_ratios(i) = traffic_data{i}.empty_stas / num_STAs * 100;
    total_pkts(i) = traffic_data{i}.total_packets;
end

% Subplot 1: ρ vs Empty 비율
subplot(2, 3, 1);
scatter(rho_values, empty_ratios, 150, 'filled');
xlabel('ρ (On 비율)');
ylabel('Empty STA 비율 [%]');
title('ρ vs 비포화 특성');
grid on;
for i = 1:num_configs
    text(rho_values(i), empty_ratios(i), sprintf('  %d', i), ...
        'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 2: ρ vs UORA 시도
subplot(2, 3, 2);
scatter(rho_values, uora_attempts, 150, 'filled', 'MarkerFaceColor', [0.5, 0.8, 0.5]);
xlabel('ρ (On 비율)');
ylabel('UORA 시도 횟수');
title('ρ vs UORA 활동성');
grid on;
for i = 1:num_configs
    text(rho_values(i), uora_attempts(i), sprintf('  %d', i), ...
        'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 3: ρ vs Explicit BSR
subplot(2, 3, 3);
scatter(rho_values, expl_bsr, 150, 'filled', 'MarkerFaceColor', [0.9, 0.5, 0.2]);
xlabel('ρ (On 비율)');
ylabel('Explicit BSR 횟수');
title('ρ vs Explicit BSR');
grid on;
for i = 1:num_configs
    text(rho_values(i), expl_bsr(i), sprintf('  %d', i), ...
        'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 4: Explicit vs Implicit BSR
subplot(2, 3, 4);
scatter(expl_bsr, impl_bsr, 150, rho_values, 'filled');
xlabel('Explicit BSR');
ylabel('Implicit BSR');
title('BSR 타입 분포');
colorbar;
colormap(jet);
caxis([min(rho_values), max(rho_values)]);
grid on;
for i = 1:num_configs
    text(expl_bsr(i), impl_bsr(i), sprintf('  %d', i), ...
        'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 5: 충돌률 vs 지연
subplot(2, 3, 5);
scatter(coll_rates, delays, 150, 'filled', 'MarkerFaceColor', [0.8, 0.3, 0.3]);
xlabel('충돌률 [%]');
ylabel('평균 지연 [ms]');
title('충돌률 vs 지연');
grid on;
for i = 1:num_configs
    text(coll_rates(i), delays(i), sprintf('  %d', i), ...
        'FontSize', 10, 'FontWeight', 'bold');
end

% Subplot 6: 범례 및 요약
subplot(2, 3, 6);
axis off;

% 텍스트 요약
summary_text = sprintf('파라미터 조합:\n\n');
for i = 1:num_configs
    summary_text = [summary_text, sprintf('%d. %s\n', i, configs{i}{1})];
    summary_text = [summary_text, sprintf('   ρ=%.2f, L=%.1f\n', ...
        rho_values(i), configs{i}{5})];
    summary_text = [summary_text, sprintf('   Empty: %.0f%%, UORA: %d\n\n', ...
        empty_ratios(i), uora_attempts(i))];
end

text(0.1, 0.9, summary_text, 'FontSize', 10, ...
    'VerticalAlignment', 'top', 'FontName', 'FixedWidth');

saveas(fig6, 'results/traffic_summary_dashboard.png');

fprintf('✅ 시각화 완료!\n');
fprintf('   저장 위치: results/\n\n');

%% =====================================================================
%  9. 추천 및 결론
%  =====================================================================

fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   분석 결과 및 추천                    ║\n');
fprintf('╚════════════════════════════════════════╝\n\n');

% 가장 비포화 특성이 강한 설정 찾기
[max_empty, best_idx] = max(empty_ratios);
[max_uora, most_active_idx] = max(uora_attempts);

fprintf('📊 주요 발견:\n\n');

fprintf('1. 비포화 특성 (Empty STA 비율):\n');
for i = 1:num_configs
    if i == best_idx
        fprintf('   ✅ %s: %.1f%% (최대)\n', configs{i}{1}, empty_ratios(i));
    else
        fprintf('      %s: %.1f%%\n', configs{i}{1}, empty_ratios(i));
    end
end
fprintf('\n');

fprintf('2. UORA 활동성:\n');
for i = 1:num_configs
    if i == most_active_idx
        fprintf('   ✅ %s: %d회 (최대)\n', configs{i}{1}, uora_attempts(i));
    else
        fprintf('      %s: %d회\n', configs{i}{1}, uora_attempts(i));
    end
end
fprintf('\n');

fprintf('3. BSR 타입 분포:\n');
for i = 1:num_configs
    total = expl_bsr(i) + impl_bsr(i);
    if total > 0
        expl_ratio = expl_bsr(i) / total * 100;
        fprintf('   %s: Explicit %.1f%%, Implicit %.1f%%\n', ...
            configs{i}{1}, expl_ratio, 100-expl_ratio);
    end
end
fprintf('\n');

fprintf('🎯 추천:\n\n');

if rho_values(best_idx) <= 0.5
    fprintf('   1순위: %s (ρ=%.2f)\n', configs{best_idx}{1}, rho_values(best_idx));
    fprintf('      - 비포화 특성 가장 강함 (Empty: %.1f%%)\n', max_empty);
    fprintf('      - UORA 경쟁 활발 (%d회)\n', uora_attempts(best_idx));
    fprintf('      - BSR 감소 기법 효과 측정에 최적\n\n');
end

fprintf('   💡 선택 기준:\n');
fprintf('      - ρ = 0.5 전후: 균형잡힌 On/Off\n');
fprintf('      - Empty 비율 > 20%%: 충분한 비포화 특성\n');
fprintf('      - UORA 시도 > 300회: 활발한 경쟁\n');
fprintf('      - Explicit BSR > 150회: 제안 기법 적용 기회\n\n');

fprintf('╚════════════════════════════════════════╝\n\n');

fprintf('결과 파일:\n');
fprintf('  - traffic_arrival_patterns.png\n');
fprintf('  - traffic_interarrival_dist.png\n');
fprintf('  - buffer_size_traces.png\n');
fprintf('  - buffer_size_distributions.png\n');
fprintf('  - simulation_comparison.png\n');
fprintf('  - traffic_summary_dashboard.png\n\n');

fprintf('🚀 다음 단계: config_default.m에 최적 파라미터 적용\n\n');