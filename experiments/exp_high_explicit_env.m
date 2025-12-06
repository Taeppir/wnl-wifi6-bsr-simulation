%% exp_high_explicit_env.m
% 목적: Explicit BSR 비율이 높은 환경에서 v3 정책 효과 검증
%
% 핵심 가설:
%   기존 환경(mu_on=0.05, numSTA=5)에서 Explicit BSR 비율이 11%로 낮아
%   BSR 최적화 효과가 제한적. 더 높은 Explicit 환경에서 효과 극대화 기대.
%
% 환경 비교:
%   - Low Explicit:  mu_on=0.05, numSTA=5  → Explicit ~11%
%   - High Explicit: mu_on=0.1,  numSTA=20 → Explicit ~50% (예측)
%
% 예상 소요 시간: ~5분

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

fprintf('=== High Explicit BSR 환경 실험 ===\n\n');

% 두 환경 정의
environments = struct();

% 환경 1: 기존 (Low Explicit)
environments(1).name = 'Low Explicit';
environments(1).mu_on = 0.05;      % 평균 ON = 50ms
environments(1).numSTA = 5;
environments(1).desc = 'mu_on=0.05 (50ms), 5 STA';

% 환경 2: 신규 (High Explicit) - mu_on 줄여서 짧은 burst
environments(2).name = 'High Explicit';
environments(2).mu_on = 0.02;      % 평균 ON = 20ms (더 짧은 burst)
environments(2).numSTA = 20;
environments(2).desc = 'mu_on=0.02 (20ms), 20 STA';

% 공통 파라미터
rho = 0.5;
L_cell = 0.30;
simulation_time = 30.0;  % 초 (기존 실험과 동일)
n_runs = 5;              % 반복 횟수

% v3 정책 파라미터 (기존 최적값)
v3_params = struct();
v3_params.EMA_alpha = 0.1;
v3_params.max_reduction = 0.7;
v3_params.reduction_threshold = 4000;
v3_params.burst_threshold = 30000;
v3_params.sensitivity = 1.0;

fprintf('[실험 설정]\n');
fprintf('  환경 1: %s\n', environments(1).desc);
fprintf('  환경 2: %s\n', environments(2).desc);
fprintf('  공통: L_cell=%.2f, rho=%.1f, sim_time=%.0fs\n', L_cell, rho, simulation_time);
fprintf('  반복 횟수: %d\n', n_runs);
fprintf('  v3 파라미터: alpha=%.1f, max_red=%.1f\n', ...
    v3_params.EMA_alpha, v3_params.max_reduction);
fprintf('\n  [이론적 예측]\n');
fprintf('    환경 1: 평균 ON=%.0fms, 사이클=%.0f/30s → Explicit ~%.0f%%\n', ...
    environments(1).mu_on*1000, 30/(2*environments(1).mu_on), 100/(1 + 50*environments(1).mu_on/0.1));
fprintf('    환경 2: 평균 ON=%.0fms, 사이클=%.0f/30s → Explicit ~%.0f%%\n\n', ...
    environments(2).mu_on*1000, 30/(2*environments(2).mu_on), 100/(1 + 50*environments(2).mu_on/0.1));

%% =====================================================================
%  2. 결과 저장 구조 초기화
%  =====================================================================

n_env = length(environments);
n_schemes = 2;  % Baseline, v3

% 결과 저장
results = struct();
for e = 1:n_env
    results(e).env_name = environments(e).name;
    results(e).baseline = struct();
    results(e).v3 = struct();
    
    % 메트릭 초기화
    metrics_list = {'mean_delay', 'p90_delay', 'std_delay', ...
                    'mean_uora', 'explicit_count', 'implicit_count', ...
                    'collision_rate', 'buffer_empty_ratio'};
    for m = 1:length(metrics_list)
        results(e).baseline.(metrics_list{m}) = zeros(1, n_runs);
        results(e).v3.(metrics_list{m}) = zeros(1, n_runs);
    end
end

%% =====================================================================
%  3. 시뮬레이션 실행
%  =====================================================================

seed_list = 1:n_runs;
tic_total = tic;

for e = 1:n_env
    env = environments(e);
    mu_off = env.mu_on * rho / (1 - rho);
    
    fprintf('========================================\n');
    fprintf('  환경 %d: %s\n', e, env.name);
    fprintf('========================================\n');
    fprintf('  mu_on=%.3f (avg ON=%.0fms), numSTA=%d\n', ...
        env.mu_on, env.mu_on*1000, env.numSTA);
    fprintf('  mu_off=%.3f (avg OFF=%.0fms)\n\n', mu_off, mu_off*1000);
    
    %% Baseline 실행
    fprintf('[1/2] Baseline (v0) 실행: ');
    
    for run = 1:n_runs
        % 설정 생성
        cfg = config_default();
        
        % 환경별 파라미터
        cfg.num_STAs = env.numSTA;
        cfg.mu_on = env.mu_on;
        cfg.mu_off = mu_off;
        cfg.L_cell = L_cell;
        cfg.rho = rho;
        cfg.alpha = 1.5;
        
        % 시뮬레이션 설정
        cfg.simulation_time = simulation_time;
        cfg.warmup_time = 0.0;
        cfg.verbose = 0;
        cfg.collect_bsr_trace = true;
        
        % 사전 할당 크기 증가 (STA 수 적을 때 STA당 패킷 많아짐)
        cfg.max_packets_per_sta = 50000;
        cfg.max_delays = 100000;
        
        % Baseline
        cfg.scheme_id = 0;
        
        % Lambda 재계산
        cfg = recompute_pareto_lambda(cfg);
        
        % 시드 설정
        rng(seed_list(run));
        
        try
            [sim_results, ~] = main_sim_v2(cfg);
            
            % 결과 저장
            results(e).baseline.mean_delay(run) = sim_results.summary.mean_delay_ms;
            results(e).baseline.p90_delay(run) = sim_results.summary.p90_delay_ms;
            results(e).baseline.std_delay(run) = sim_results.summary.std_delay_ms;
            results(e).baseline.mean_uora(run) = sim_results.summary.mean_uora_delay_ms;
            results(e).baseline.explicit_count(run) = sim_results.summary.explicit_bsr_count;
            results(e).baseline.implicit_count(run) = sim_results.summary.implicit_bsr_count;
            results(e).baseline.collision_rate(run) = sim_results.summary.collision_rate;
            results(e).baseline.buffer_empty_ratio(run) = sim_results.summary.buffer_empty_ratio;
            
            fprintf('.');
        catch ME
            fprintf('X');
            results(e).baseline.mean_delay(run) = NaN;
        end
        
        clear sim_results cfg;
    end
    
    % Baseline 요약
    mean_bl = mean(results(e).baseline.mean_delay, 'omitnan');
    explicit_ratio = mean(results(e).baseline.explicit_count) / ...
        (mean(results(e).baseline.explicit_count) + mean(results(e).baseline.implicit_count)) * 100;
    fprintf(' %.1f ms, Explicit %.1f%%\n', mean_bl, explicit_ratio);
    results(e).baseline.explicit_ratio = explicit_ratio;
    
    %% v3 실행
    fprintf('[2/2] v3 (EMA-based) 실행: ');
    
    for run = 1:n_runs
        % 설정 생성
        cfg = config_default();
        
        % 환경별 파라미터
        cfg.num_STAs = env.numSTA;
        cfg.mu_on = env.mu_on;
        cfg.mu_off = mu_off;
        cfg.L_cell = L_cell;
        cfg.rho = rho;
        cfg.alpha = 1.5;
        
        % 시뮬레이션 설정
        cfg.simulation_time = simulation_time;
        cfg.warmup_time = 0.0;
        cfg.verbose = 0;
        cfg.collect_bsr_trace = true;
        
        % 사전 할당 크기 증가
        cfg.max_packets_per_sta = 50000;
        cfg.max_delays = 100000;
        
        % v3 정책
        cfg.scheme_id = 3;
        cfg.v3_EMA_alpha = v3_params.EMA_alpha;
        cfg.v3_max_reduction = v3_params.max_reduction;
        cfg.reduction_threshold = v3_params.reduction_threshold;
        cfg.burst_threshold = v3_params.burst_threshold;
        cfg.v3_sensitivity = v3_params.sensitivity;
        
        % Lambda 재계산
        cfg = recompute_pareto_lambda(cfg);
        
        % 시드 설정 (Baseline과 동일)
        rng(seed_list(run));
        
        try
            [sim_results, ~] = main_sim_v2(cfg);
            
            % 결과 저장
            results(e).v3.mean_delay(run) = sim_results.summary.mean_delay_ms;
            results(e).v3.p90_delay(run) = sim_results.summary.p90_delay_ms;
            results(e).v3.std_delay(run) = sim_results.summary.std_delay_ms;
            results(e).v3.mean_uora(run) = sim_results.summary.mean_uora_delay_ms;
            results(e).v3.explicit_count(run) = sim_results.summary.explicit_bsr_count;
            results(e).v3.implicit_count(run) = sim_results.summary.implicit_bsr_count;
            results(e).v3.collision_rate(run) = sim_results.summary.collision_rate;
            results(e).v3.buffer_empty_ratio(run) = sim_results.summary.buffer_empty_ratio;
            
            fprintf('.');
        catch ME
            fprintf('X');
            results(e).v3.mean_delay(run) = NaN;
        end
        
        clear sim_results cfg;
    end
    
    % v3 요약
    mean_v3 = mean(results(e).v3.mean_delay, 'omitnan');
    improvement = (1 - mean_v3 / mean_bl) * 100;
    fprintf(' %.1f ms (%+.1f%%)\n\n', mean_v3, improvement);
    
    %% 개선폭 계산
    results(e).improvement = struct();
    results(e).improvement.mean_delay = improvement;
    results(e).improvement.p90_delay = (1 - mean(results(e).v3.p90_delay, 'omitnan') / ...
        mean(results(e).baseline.p90_delay, 'omitnan')) * 100;
    results(e).improvement.std_delay = (1 - mean(results(e).v3.std_delay, 'omitnan') / ...
        mean(results(e).baseline.std_delay, 'omitnan')) * 100;
    results(e).improvement.mean_uora = (1 - mean(results(e).v3.mean_uora, 'omitnan') / ...
        mean(results(e).baseline.mean_uora, 'omitnan')) * 100;
    results(e).improvement.collision = (1 - mean(results(e).v3.collision_rate, 'omitnan') / ...
        mean(results(e).baseline.collision_rate, 'omitnan')) * 100;
end

total_time = toc(tic_total);
fprintf('총 소요 시간: %.1f분\n\n', total_time / 60);

%% =====================================================================
%  4. 결과 비교 테이블
%  =====================================================================

fprintf('========================================\n');
fprintf('  환경별 결과 비교\n');
fprintf('========================================\n\n');

fprintf('%-25s %-18s %-18s\n', '', environments(1).name, environments(2).name);
fprintf('%s\n', repmat('-', 1, 60));

% 환경 정보
fprintf('%-25s %-18d %-18d\n', 'numSTA', environments(1).numSTA, environments(2).numSTA);
fprintf('%-25s %-18.2f %-18.2f\n', 'mu_on', environments(1).mu_on, environments(2).mu_on);
fprintf('%-25s %-18.0f %-18.0f\n', 'avg ON [slots]', 1/environments(1).mu_on, 1/environments(2).mu_on);
fprintf('%s\n', repmat('-', 1, 60));

% Explicit BSR 비율
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'Explicit BSR 비율', ...
    results(1).baseline.explicit_ratio, results(2).baseline.explicit_ratio);

% Baseline 성능
fprintf('%-25s %-18.1f %-18.1f\n', 'Baseline Mean [ms]', ...
    mean(results(1).baseline.mean_delay, 'omitnan'), ...
    mean(results(2).baseline.mean_delay, 'omitnan'));
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'Baseline Collision', ...
    mean(results(1).baseline.collision_rate, 'omitnan') * 100, ...
    mean(results(2).baseline.collision_rate, 'omitnan') * 100);

fprintf('%s\n', repmat('-', 1, 60));

% 개선폭
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'Mean Delay 개선', ...
    results(1).improvement.mean_delay, results(2).improvement.mean_delay);
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'P90 Delay 개선', ...
    results(1).improvement.p90_delay, results(2).improvement.p90_delay);
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'T_uora 개선', ...
    results(1).improvement.mean_uora, results(2).improvement.mean_uora);
fprintf('%-25s %-18.1f%% %-18.1f%%\n', 'Collision 개선', ...
    results(1).improvement.collision, results(2).improvement.collision);

%% =====================================================================
%  5. 시각화
%  =====================================================================

figure('Position', [100 100 1400 500]);

% 서브플롯 1: Explicit BSR 비율
subplot(1, 3, 1);
bar_data = [results(1).baseline.explicit_ratio, results(2).baseline.explicit_ratio];
b = bar(bar_data, 'FaceColor', 'flat');
b.CData(1,:) = [0.3 0.6 0.9];  % 파랑
b.CData(2,:) = [0.9 0.4 0.3];  % 빨강
set(gca, 'XTickLabel', {environments(1).name, environments(2).name});
ylabel('Explicit BSR 비율 [%]');
title('Explicit BSR 비율');
ylim([0 max(bar_data) * 1.3]);
grid on;

for i = 1:2
    text(i, bar_data(i) + 2, sprintf('%.1f%%', bar_data(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);
end

% 서브플롯 2: 개선폭 비교
subplot(1, 3, 2);
improvement_data = [results(1).improvement.mean_delay, results(2).improvement.mean_delay; ...
                    results(1).improvement.p90_delay, results(2).improvement.p90_delay];
b2 = bar(improvement_data);
set(gca, 'XTickLabel', {'Mean Delay', 'P90 Delay'});
ylabel('개선폭 [%]');
title('v3 정책 개선폭');
legend({environments(1).name, environments(2).name}, 'Location', 'northwest');
grid on;

% 서브플롯 3: 절대 지연값 비교
subplot(1, 3, 3);
delay_data = [mean(results(1).baseline.mean_delay, 'omitnan'), mean(results(1).v3.mean_delay, 'omitnan'); ...
              mean(results(2).baseline.mean_delay, 'omitnan'), mean(results(2).v3.mean_delay, 'omitnan')];
b3 = bar(delay_data);
set(gca, 'XTickLabel', {environments(1).name, environments(2).name});
ylabel('Mean Delay [ms]');
title('절대 지연값');
legend({'Baseline', 'v3'}, 'Location', 'northwest');
grid on;

sgtitle('High Explicit BSR 환경 실험 결과', 'FontSize', 14, 'FontWeight', 'bold');

% 저장
plot_dir = 'results/figures';
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
saveas(gcf, fullfile(plot_dir, 'exp_high_explicit_env.png'));
fprintf('\n그래프 저장: %s\n', fullfile(plot_dir, 'exp_high_explicit_env.png'));

%% =====================================================================
%  6. 결론
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  결론\n');
fprintf('========================================\n\n');

ratio_diff = results(2).baseline.explicit_ratio / results(1).baseline.explicit_ratio;
impr_diff = results(2).improvement.mean_delay / max(0.1, results(1).improvement.mean_delay);

fprintf('[Explicit BSR 비율]\n');
fprintf('  Low Explicit:  %.1f%%\n', results(1).baseline.explicit_ratio);
fprintf('  High Explicit: %.1f%% (%.1fx 증가)\n', results(2).baseline.explicit_ratio, ratio_diff);

fprintf('\n[v3 개선폭]\n');
fprintf('  Low Explicit:  %.1f%%\n', results(1).improvement.mean_delay);
fprintf('  High Explicit: %.1f%%\n', results(2).improvement.mean_delay);

if results(2).improvement.mean_delay > results(1).improvement.mean_delay * 1.5
    fprintf('\n✓ High Explicit 환경에서 BSR 최적화 효과 증가!\n');
    fprintf('  → 논문 스코프: "짧은 burst 트래픽 환경에서 효과적"\n');
elseif results(2).improvement.mean_delay > results(1).improvement.mean_delay
    fprintf('\n△ High Explicit 환경에서 개선폭 소폭 증가\n');
    fprintf('  → 추가 파라미터 튜닝 필요\n');
else
    fprintf('\n✗ 환경 변화에도 개선폭 유사/감소\n');
    fprintf('  → 근본적 한계 확인, 다른 접근 필요\n');
end

fprintf('\n🎉 실험 완료!\n\n');