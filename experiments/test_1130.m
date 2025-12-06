%% 진단: BSR 감소 적용 현황 확인
clear; close all; clc;

% 단일 시뮬레이션 실행 (v3, verbose)
cfg = config_default();
cfg.scheme_id = 3;  % v3 EMA-based
cfg.L_cell = 0.30;
cfg.rho = 0.5;
cfg.mu_on = 0.05;
cfg.simulation_time = 10.0;
cfg.verbose = 0;
cfg.collect_bsr_trace = true;

% 파라미터 설정
cfg.v3_EMA_alpha = 0.1;
cfg.v3_max_reduction = 0.7;
cfg.reduction_threshold = 500;  % 현재 설정

cfg = recompute_pareto_lambda(cfg);
rng(1);

[results, metrics] = main_sim_v2(cfg);

%% 분석: BSR 트레이스
trace_idx = metrics.policy_level.trace_idx;
Q_values = metrics.policy_level.trace.Q(1:trace_idx);
R_values = metrics.policy_level.trace.R(1:trace_idx);

% 유효한 데이터만
valid = ~isnan(Q_values) & Q_values > 0;
Q_valid = Q_values(valid);
R_valid = R_values(valid);

fprintf('=== BSR 감소 진단 ===\n\n');
fprintf('[전체 BSR 이벤트]\n');
fprintf('  총 BSR 횟수: %d\n', sum(valid));
fprintf('  Q > 0인 경우: %d\n', sum(Q_valid > 0));

% 감소 적용 여부
reduction_applied = (R_valid < Q_valid);
fprintf('\n[감소 적용 현황]\n');
fprintf('  감소 적용: %d회 (%.1f%%)\n', sum(reduction_applied), mean(reduction_applied)*100);
fprintf('  감소 미적용 (R=Q): %d회 (%.1f%%)\n', sum(~reduction_applied), mean(~reduction_applied)*100);

% 큐 크기 분포
fprintf('\n[큐 크기 분포 (Q > 0인 경우)]\n');
fprintf('  평균: %.0f bytes\n', mean(Q_valid));
fprintf('  중앙값: %.0f bytes\n', median(Q_valid));
fprintf('  P10: %.0f bytes\n', prctile(Q_valid, 10));
fprintf('  P90: %.0f bytes\n', prctile(Q_valid, 90));

% reduction_threshold 대비
below_threshold = sum(Q_valid < cfg.reduction_threshold);
fprintf('\n[Threshold 분석]\n');
fprintf('  reduction_threshold: %d bytes\n', cfg.reduction_threshold);
fprintf('  Q < threshold: %d회 (%.1f%%) ← 이 경우 감소 안 됨!\n', ...
    below_threshold, below_threshold/length(Q_valid)*100);

% 감소량 분석
if sum(reduction_applied) > 0
    reduction_amounts = Q_valid(reduction_applied) - R_valid(reduction_applied);
    reduction_ratios = reduction_amounts ./ Q_valid(reduction_applied);
    
    fprintf('\n[감소량 분석 (적용된 경우만)]\n');
    fprintf('  평균 감소량: %.0f bytes\n', mean(reduction_amounts));
    fprintf('  평균 감소율: %.1f%%\n', mean(reduction_ratios)*100);
end

%% 시각화
figure('Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
histogram(Q_valid, 50);
hold on;
xline(cfg.reduction_threshold, 'r--', 'LineWidth', 2);
xlabel('Q [bytes]');
ylabel('Count');
title('큐 크기 분포');
legend('Q', sprintf('Threshold=%d', cfg.reduction_threshold));

subplot(1, 3, 2);
scatter(Q_valid, R_valid, 10, 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
plot([0, max(Q_valid)], [0, max(Q_valid)], 'r--', 'LineWidth', 2);
xlabel('Q (실제 큐)');
ylabel('R (보고된 BSR)');
title('Q vs R 관계');
legend('Data', 'R=Q (no reduction)');

subplot(1, 3, 3);
reduction_ratio_all = 1 - R_valid ./ Q_valid;
reduction_ratio_all(Q_valid == 0) = 0;
histogram(reduction_ratio_all * 100, 50);
xlabel('Reduction Ratio [%]');
ylabel('Count');
title('감소율 분포');

sgtitle(sprintf('v3 BSR 진단 (L=%.2f, threshold=%d)', cfg.L_cell, cfg.reduction_threshold));

%% 추가 진단: Explicit vs Implicit BSR에서의 감소 적용 현황

% Explicit BSR: RA-RU 성공 시 (UL_TRANSMITTING_v2의 RA-RU 처리 부분)
% Implicit BSR: SA-RU 전송 후 (UL_TRANSMITTING_v2의 SA-RU 처리 부분)

fprintf('\n=== Explicit vs Implicit 구분 필요 ===\n');
fprintf('총 BSR 이벤트: %d\n', trace_idx);
fprintf('  - Explicit BSR: %d (%.1f%%)\n', results.bsr.total_explicit, ...
    results.bsr.total_explicit / (results.bsr.total_explicit + results.bsr.total_implicit) * 100);
fprintf('  - Implicit BSR: %d (%.1f%%)\n', results.bsr.total_implicit, ...
    results.bsr.total_implicit / (results.bsr.total_explicit + results.bsr.total_implicit) * 100);

fprintf('\n핵심 질문: Explicit BSR에서만 감소해도 효과가 있는가?\n');
fprintf('  → Explicit BSR가 UORA contention의 원인\n');
fprintf('  → Implicit BSR는 이미 SA-RU 할당받은 상태에서 piggyback\n');