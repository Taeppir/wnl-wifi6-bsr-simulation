%% exp_sweetspot_search.m
% 목적: BSR 최적화 효과의 sweet spot 탐색
%
% 변수:
%   1. numSTA: 5, 10, 15, 20
%   2. numRU_RA: 1, 2
%
% 배경:
%   - 5 STA, RA-RU=1: collision 1.6%, 개선 10.7%
%   - 20 STA, RA-RU=1: collision 23.6%, 개선 2.0%
%   → 중간 지점과 RA-RU 증가 효과 탐색
%
% 예상 소요 시간: ~15분

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

fprintf('=== Sweet Spot 탐색 실험 ===\n\n');

% 스윕 변수
numSTA_list = [5, 10, 15, 20];
numRU_RA_list = [1, 2];

% 공통 파라미터
rho = 0.5;
L_cell = 0.30;
mu_on = 0.05;
simulation_time = 30.0;
n_runs = 5;

% v3 파라미터
v3_params = struct();
v3_params.EMA_alpha = 0.1;
v3_params.max_reduction = 0.7;
v3_params.reduction_threshold = 4000;
v3_params.burst_threshold = 30000;
v3_params.sensitivity = 1.0;

fprintf('[실험 설정]\n');
fprintf('  numSTA: [%s]\n', num2str(numSTA_list));
fprintf('  numRU_RA: [%s]\n', num2str(numRU_RA_list));
fprintf('  공통: L_cell=%.2f, rho=%.1f, mu_on=%.2f\n', L_cell, rho, mu_on);
fprintf('  반복: %d회\n', n_runs);
fprintf('  총 시뮬레이션: %d회\n\n', length(numSTA_list) * length(numRU_RA_list) * 2 * n_runs);

%% =====================================================================
%  2. 결과 저장 구조
%  =====================================================================

n_sta = length(numSTA_list);
n_ru = length(numRU_RA_list);

% 결과 매트릭스 [numSTA, numRU_RA]
results = struct();
results.baseline_delay = zeros(n_sta, n_ru);
results.v3_delay = zeros(n_sta, n_ru);
results.improvement = zeros(n_sta, n_ru);
results.p90_improvement = zeros(n_sta, n_ru);
results.explicit_ratio = zeros(n_sta, n_ru);
results.collision_rate = zeros(n_sta, n_ru);
results.collision_improvement = zeros(n_sta, n_ru);

%% =====================================================================
%  3. 시뮬레이션 실행
%  =====================================================================

seed_list = 1:n_runs;
mu_off = mu_on * rho / (1 - rho);
tic_total = tic;

for s = 1:n_sta
    numSTA = numSTA_list(s);
    
    for r = 1:n_ru
        numRU_RA = numRU_RA_list(r);
        
        fprintf('[%d/%d] numSTA=%d, RA-RU=%d: ', ...
            (s-1)*n_ru + r, n_sta*n_ru, numSTA, numRU_RA);
        
        % 임시 저장
        baseline_delays = zeros(1, n_runs);
        baseline_p90 = zeros(1, n_runs);
        baseline_collision = zeros(1, n_runs);
        baseline_explicit = zeros(1, n_runs);
        baseline_implicit = zeros(1, n_runs);
        
        v3_delays = zeros(1, n_runs);
        v3_p90 = zeros(1, n_runs);
        v3_collision = zeros(1, n_runs);
        
        %% Baseline
        for run = 1:n_runs
            cfg = config_default();
            
            cfg.num_STAs = numSTA;
            cfg.numRU_RA = numRU_RA;
            cfg.numRU_SA = 9 - numRU_RA;  % 총 RU 9개 유지
            cfg.mu_on = mu_on;
            cfg.mu_off = mu_off;
            cfg.L_cell = L_cell;
            cfg.rho = rho;
            cfg.alpha = 1.5;
            
            cfg.simulation_time = simulation_time;
            cfg.warmup_time = 0.0;
            cfg.verbose = 0;
            cfg.collect_bsr_trace = true;
            cfg.max_packets_per_sta = 50000;
            cfg.max_delays = 100000;
            
            cfg.scheme_id = 0;
            cfg = recompute_pareto_lambda(cfg);
            
            rng(seed_list(run));
            
            try
                [sim_results, ~] = main_sim_v2(cfg);
                baseline_delays(run) = sim_results.summary.mean_delay_ms;
                baseline_p90(run) = sim_results.summary.p90_delay_ms;
                baseline_collision(run) = sim_results.summary.collision_rate;
                baseline_explicit(run) = sim_results.summary.explicit_bsr_count;
                baseline_implicit(run) = sim_results.summary.implicit_bsr_count;
            catch
                baseline_delays(run) = NaN;
            end
            
            clear sim_results cfg;
        end
        
        %% v3
        for run = 1:n_runs
            cfg = config_default();
            
            cfg.num_STAs = numSTA;
            cfg.numRU_RA = numRU_RA;
            cfg.numRU_SA = 9 - numRU_RA;
            cfg.mu_on = mu_on;
            cfg.mu_off = mu_off;
            cfg.L_cell = L_cell;
            cfg.rho = rho;
            cfg.alpha = 1.5;
            
            cfg.simulation_time = simulation_time;
            cfg.warmup_time = 0.0;
            cfg.verbose = 0;
            cfg.collect_bsr_trace = true;
            cfg.max_packets_per_sta = 50000;
            cfg.max_delays = 100000;
            
            cfg.scheme_id = 3;
            cfg.v3_EMA_alpha = v3_params.EMA_alpha;
            cfg.v3_max_reduction = v3_params.max_reduction;
            cfg.reduction_threshold = v3_params.reduction_threshold;
            cfg.burst_threshold = v3_params.burst_threshold;
            cfg.v3_sensitivity = v3_params.sensitivity;
            
            cfg = recompute_pareto_lambda(cfg);
            
            rng(seed_list(run));
            
            try
                [sim_results, ~] = main_sim_v2(cfg);
                v3_delays(run) = sim_results.summary.mean_delay_ms;
                v3_p90(run) = sim_results.summary.p90_delay_ms;
                v3_collision(run) = sim_results.summary.collision_rate;
            catch
                v3_delays(run) = NaN;
            end
            
            clear sim_results cfg;
        end
        
        %% 결과 저장
        mean_bl = mean(baseline_delays, 'omitnan');
        mean_v3 = mean(v3_delays, 'omitnan');
        
        results.baseline_delay(s, r) = mean_bl;
        results.v3_delay(s, r) = mean_v3;
        results.improvement(s, r) = (1 - mean_v3 / mean_bl) * 100;
        results.p90_improvement(s, r) = (1 - mean(v3_p90, 'omitnan') / mean(baseline_p90, 'omitnan')) * 100;
        results.explicit_ratio(s, r) = mean(baseline_explicit) / (mean(baseline_explicit) + mean(baseline_implicit)) * 100;
        results.collision_rate(s, r) = mean(baseline_collision, 'omitnan') * 100;
        results.collision_improvement(s, r) = (1 - mean(v3_collision, 'omitnan') / mean(baseline_collision, 'omitnan')) * 100;
        
        fprintf('Baseline=%.1fms, v3=%.1fms (%+.1f%%), Collision=%.1f%%\n', ...
            mean_bl, mean_v3, results.improvement(s, r), results.collision_rate(s, r));
    end
end

total_time = toc(tic_total);
fprintf('\n총 소요 시간: %.1f분\n', total_time / 60);

%% =====================================================================
%  4. 결과 테이블
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  결과 요약\n');
fprintf('========================================\n\n');

fprintf('--- Mean Delay 개선률 [%%] ---\n');
fprintf('%10s |', 'numSTA');
for r = 1:n_ru
    fprintf(' RA-RU=%d ', numRU_RA_list(r));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 10 + n_ru * 10));
for s = 1:n_sta
    fprintf('%10d |', numSTA_list(s));
    for r = 1:n_ru
        fprintf(' %+6.1f%% ', results.improvement(s, r));
    end
    fprintf('\n');
end

fprintf('\n--- Baseline Collision Rate [%%] ---\n');
fprintf('%10s |', 'numSTA');
for r = 1:n_ru
    fprintf(' RA-RU=%d ', numRU_RA_list(r));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 10 + n_ru * 10));
for s = 1:n_sta
    fprintf('%10d |', numSTA_list(s));
    for r = 1:n_ru
        fprintf(' %6.1f%% ', results.collision_rate(s, r));
    end
    fprintf('\n');
end

fprintf('\n--- Explicit BSR 비율 [%%] ---\n');
fprintf('%10s |', 'numSTA');
for r = 1:n_ru
    fprintf(' RA-RU=%d ', numRU_RA_list(r));
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 10 + n_ru * 10));
for s = 1:n_sta
    fprintf('%10d |', numSTA_list(s));
    for r = 1:n_ru
        fprintf(' %6.1f%% ', results.explicit_ratio(s, r));
    end
    fprintf('\n');
end

%% =====================================================================
%  5. 시각화
%  =====================================================================

figure('Position', [100 100 1400 900]);

% 서브플롯 1: Mean Delay 개선률
subplot(2, 2, 1);
bar(numSTA_list, results.improvement);
xlabel('numSTA');
ylabel('Mean Delay 개선률 [%]');
title('v3 Mean Delay 개선률');
legend(arrayfun(@(x) sprintf('RA-RU=%d', x), numRU_RA_list, 'UniformOutput', false), ...
    'Location', 'northeast');
grid on;
set(gca, 'XTick', numSTA_list);

% 서브플롯 2: Collision Rate
subplot(2, 2, 2);
bar(numSTA_list, results.collision_rate);
xlabel('numSTA');
ylabel('Baseline Collision Rate [%]');
title('Baseline Collision Rate');
legend(arrayfun(@(x) sprintf('RA-RU=%d', x), numRU_RA_list, 'UniformOutput', false), ...
    'Location', 'northwest');
grid on;
set(gca, 'XTick', numSTA_list);

% 서브플롯 3: 개선률 vs Collision (산점도)
subplot(2, 2, 3);
hold on;
colors = lines(n_ru);
for r = 1:n_ru
    scatter(results.collision_rate(:, r), results.improvement(:, r), ...
        150, colors(r, :), 'filled', 'DisplayName', sprintf('RA-RU=%d', numRU_RA_list(r)));
    
    % 각 점에 numSTA 레이블
    for s = 1:n_sta
        text(results.collision_rate(s, r) + 0.5, results.improvement(s, r), ...
            sprintf('%d', numSTA_list(s)), 'FontSize', 10);
    end
end
hold off;
xlabel('Baseline Collision Rate [%]');
ylabel('Mean Delay 개선률 [%]');
title('개선률 vs Collision Rate');
legend('Location', 'northeast');
grid on;

% 서브플롯 4: P90 개선률
subplot(2, 2, 4);
bar(numSTA_list, results.p90_improvement);
xlabel('numSTA');
ylabel('P90 Delay 개선률 [%]');
title('v3 P90 Delay 개선률');
legend(arrayfun(@(x) sprintf('RA-RU=%d', x), numRU_RA_list, 'UniformOutput', false), ...
    'Location', 'northeast');
grid on;
set(gca, 'XTick', numSTA_list);

sgtitle('Sweet Spot 탐색: numSTA × RA-RU 영향', 'FontSize', 14, 'FontWeight', 'bold');

% 저장
plot_dir = 'results/figures';
if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
saveas(gcf, fullfile(plot_dir, 'exp_sweetspot_search.png'));
fprintf('\n그래프 저장: %s\n', fullfile(plot_dir, 'exp_sweetspot_search.png'));

%% =====================================================================
%  6. 핵심 발견
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  핵심 발견\n');
fprintf('========================================\n\n');

% 최고 개선률 찾기
[best_impr, best_idx] = max(results.improvement(:));
[best_s, best_r] = ind2sub([n_sta, n_ru], best_idx);

fprintf('[최고 개선률]\n');
fprintf('  환경: numSTA=%d, RA-RU=%d\n', numSTA_list(best_s), numRU_RA_list(best_r));
fprintf('  Mean 개선: %.1f%%\n', best_impr);
fprintf('  P90 개선: %.1f%%\n', results.p90_improvement(best_s, best_r));
fprintf('  Collision: %.1f%%\n', results.collision_rate(best_s, best_r));

% RA-RU 효과
fprintf('\n[RA-RU 증가 효과 (RA-RU=1 → 2)]\n');
for s = 1:n_sta
    diff = results.improvement(s, 2) - results.improvement(s, 1);
    coll_diff = results.collision_rate(s, 1) - results.collision_rate(s, 2);
    fprintf('  numSTA=%d: 개선률 %+.1f%%, Collision %.1f%% 감소\n', ...
        numSTA_list(s), diff, coll_diff);
end

% Sweet spot 결론
fprintf('\n[Sweet Spot 분석]\n');
sweet_mask = results.improvement > 5;  % 5% 이상 개선
if any(sweet_mask(:))
    fprintf('  효과적인 환경 (개선률 > 5%%):\n');
    for s = 1:n_sta
        for r = 1:n_ru
            if sweet_mask(s, r)
                fprintf('    - numSTA=%d, RA-RU=%d: %.1f%% 개선, Collision %.1f%%\n', ...
                    numSTA_list(s), numRU_RA_list(r), results.improvement(s, r), results.collision_rate(s, r));
            end
        end
    end
else
    fprintf('  5%% 이상 개선되는 환경 없음\n');
end

fprintf('\n🎉 실험 완료!\n');

%% =====================================================================
%  7. 결과 저장
%  =====================================================================

save('results/mat/exp_sweetspot_search.mat', 'results', 'numSTA_list', 'numRU_RA_list');
fprintf('결과 저장: results/mat/exp_sweetspot_search.mat\n');