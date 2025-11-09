%% test_phaseA_v2.m
% Phase A: 단일 파라미터 스윕 분석 (통계 버전)
%
% 수정사항:
%   ✓ 각 파라미터 값당 num_runs회 반복 실행
%   ✓ 평균 ± 표준편차 계산
%   ✓ 통계적 신뢰성 확보

clear; close all; clc;

fprintf('\n');
fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   Phase A: 파라미터 스윕 (통계 버전)  ║\n');
fprintf('╚════════════════════════════════════════╝\n');
fprintf('\n');

%% =====================================================================
%  0. 기본 설정
%  =====================================================================

% 기본 시뮬레이션 파라미터
base_cfg = config_default();
base_cfg.num_STAs = 20;
base_cfg.simulation_time = 10.0;
base_cfg.warmup_time = 2.0;
base_cfg.scheme_id = 0;  % Baseline
base_cfg.verbose = 0;
base_cfg.collect_bsr_trace = true;

% ⭐ 반복 실행 횟수
num_runs = 2;  % 각 파라미터 값당 5회 실행

fprintf('반복 실행: 각 파라미터 값당 %d회\n', num_runs);
fprintf('  → 평균 및 표준편차 계산\n\n');

% 결과 저장 디렉토리
if ~exist('results', 'dir')
    mkdir('results');
end

%% =====================================================================
%  A-1: ρ (On 비율) 스윕
%  =====================================================================

fprintf('════════════════════════════════════════\n');
fprintf('  A-1: ρ (On 비율) 스윕\n');
fprintf('════════════════════════════════════════\n\n');

% 파라미터 설정
rho_values = [0.3, 0.5, 0.7, 0.9];
num_rho = length(rho_values);

% μ_on, μ_off 계산
mu_total = 0.06;
mu_on_values = rho_values * mu_total;
mu_off_values = (1 - rho_values) * mu_total;

fprintf('ρ 값: %s\n', mat2str(rho_values, 2));
fprintf('고정: α=%.1f, L_cell=%.1f\n', base_cfg.alpha, base_cfg.L_cell);
fprintf('각 ρ 값당 %d회 반복\n\n', num_runs);

% 결과 저장
results_A1 = struct();
results_A1.rho_values = rho_values;
results_A1.data = cell(num_rho, 1);

fprintf('%-5s | %-12s | %-12s | %-12s | %-12s\n', ...
    'ρ', 'Empty(%)', 'Expl.BSR', 'Delay(ms)', 'Coll.(%)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:num_rho
    rho = rho_values(i);
    
    % 반복 실행 저장소
    temp_empty = zeros(num_runs, 1);
    temp_expl = zeros(num_runs, 1);
    temp_delay = zeros(num_runs, 1);
    temp_coll = zeros(num_runs, 1);
    
    for run = 1:num_runs
        cfg = base_cfg;
        cfg.alpha = 1.5;
        cfg.mu_on = mu_on_values(i);
        cfg.mu_off = mu_off_values(i);
        cfg.rho = rho;
        cfg.L_cell = 0.5;
        
        total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
        cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
        cfg.lambda = cfg.lambda_network / cfg.num_STAs;
        
        rng(42 + run);
        [results, metrics] = main_sim_v2(cfg);
        
        if metrics.policy_level.trace_idx > 0
            idx = 1:metrics.policy_level.trace_idx;
            Q_all = metrics.policy_level.trace.Q(idx);
            temp_empty(run) = sum(Q_all == 0) / length(Q_all) * 100;
        else
            temp_empty(run) = NaN;
        end
        
        temp_expl(run) = results.bsr.total_explicit;
        temp_delay(run) = results.summary.mean_delay_ms;
        temp_coll(run) = results.summary.collision_rate * 100;
    end
    
    % 평균 및 표준편차
    data = struct();
    data.mean_empty = mean(temp_empty);
    data.std_empty = std(temp_empty);
    data.mean_expl = mean(temp_expl);
    data.std_expl = std(temp_expl);
    data.mean_delay = mean(temp_delay);
    data.std_delay = std(temp_delay);
    data.mean_coll = mean(temp_coll);
    data.std_coll = std(temp_coll);
    
    results_A1.data{i} = data;
    
    fprintf('%5.2f | %7.1f±%-3.1f | %8.0f±%-3.0f | %8.1f±%-3.1f | %7.1f±%-2.1f\n', ...
        rho, data.mean_empty, data.std_empty, ...
        data.mean_expl, data.std_expl, ...
        data.mean_delay, data.std_delay, ...
        data.mean_coll, data.std_coll);
end

fprintf('\n✅ A-1 완료 (총 %d회 실행)\n\n', num_rho * num_runs);

%% =====================================================================
%  A-2: L_cell (네트워크 부하) 스윕
%  =====================================================================

fprintf('════════════════════════════════════════\n');
fprintf('  A-2: L_cell (네트워크 부하) 스윕\n');
fprintf('════════════════════════════════════════\n\n');

L_values = [0.3, 0.5, 0.7, 0.9];
num_L = length(L_values);

fprintf('L_cell 값: %s\n', mat2str(L_values, 1));
fprintf('고정: α=%.1f, ρ=%.1f\n', base_cfg.alpha, 0.5);
fprintf('각 L_cell 값당 %d회 반복\n\n', num_runs);

results_A2 = struct();
results_A2.L_values = L_values;
results_A2.data = cell(num_L, 1);

fprintf('%-7s | %-12s | %-12s | %-12s | %-12s\n', ...
    'L_cell', 'Avg.Q(B)', 'Delay(ms)', 'Compl.(%)', 'Empty(%)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:num_L
    L = L_values(i);
    
    temp_avgQ = zeros(num_runs, 1);
    temp_delay = zeros(num_runs, 1);
    temp_compl = zeros(num_runs, 1);
    temp_empty = zeros(num_runs, 1);
    
    for run = 1:num_runs
        cfg = base_cfg;
        cfg.alpha = 1.5;
        cfg.mu_on = 0.03;
        cfg.mu_off = 0.03;
        cfg.rho = 0.5;
        cfg.L_cell = L;
        
        total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
        cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
        cfg.lambda = cfg.lambda_network / cfg.num_STAs;
        
        rng(42 + run);
        [results, metrics] = main_sim_v2(cfg);
        
        if metrics.policy_level.trace_idx > 0
            idx = 1:metrics.policy_level.trace_idx;
            Q_all = metrics.policy_level.trace.Q(idx);
            temp_avgQ(run) = mean(Q_all);
            temp_empty(run) = sum(Q_all == 0) / length(Q_all) * 100;
        else
            temp_avgQ(run) = NaN;
            temp_empty(run) = NaN;
        end
        
        temp_delay(run) = results.summary.mean_delay_ms;
        temp_compl(run) = results.summary.completion_rate * 100;
    end
    
    data = struct();
    data.mean_avgQ = mean(temp_avgQ);
    data.std_avgQ = std(temp_avgQ);
    data.mean_delay = mean(temp_delay);
    data.std_delay = std(temp_delay);
    data.mean_compl = mean(temp_compl);
    data.std_compl = std(temp_compl);
    data.mean_empty = mean(temp_empty);
    data.std_empty = std(temp_empty);
    
    results_A2.data{i} = data;
    
    fprintf('%7.1f | %8.0f±%-4.0f | %8.1f±%-3.1f | %8.1f±%-3.1f | %7.1f±%-2.1f\n', ...
        L, data.mean_avgQ, data.std_avgQ, ...
        data.mean_delay, data.std_delay, ...
        data.mean_compl, data.std_compl, ...
        data.mean_empty, data.std_empty);
end

fprintf('\n✅ A-2 완료 (총 %d회 실행)\n\n', num_L * num_runs);

%% =====================================================================
%  A-3: α (Heavy-tail 강도) 스윕
%  =====================================================================

fprintf('════════════════════════════════════════\n');
fprintf('  A-3: α (Heavy-tail 강도) 스윕\n');
fprintf('════════════════════════════════════════\n\n');

alpha_values = [1.3, 1.5, 1.7, 1.9];
num_alpha = length(alpha_values);

fprintf('α 값: %s\n', mat2str(alpha_values, 1));
fprintf('고정: ρ=%.1f, L_cell=%.1f\n', 0.5, 0.5);
fprintf('각 α 값당 %d회 반복\n\n', num_runs);

results_A3 = struct();
results_A3.alpha_values = alpha_values;
results_A3.data = cell(num_alpha, 1);

fprintf('%-5s | %-12s | %-12s | %-12s | %-12s\n', ...
    'α', 'CV(지연)', 'Var(Q)', 'Delay(ms)', 'Empty(%)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:num_alpha
    alpha = alpha_values(i);
    
    temp_cv = zeros(num_runs, 1);
    temp_varQ = zeros(num_runs, 1);
    temp_delay = zeros(num_runs, 1);
    temp_empty = zeros(num_runs, 1);
    
    for run = 1:num_runs
        cfg = base_cfg;
        cfg.alpha = alpha;
        cfg.mu_on = 0.03;
        cfg.mu_off = 0.03;
        cfg.rho = 0.5;
        cfg.L_cell = 0.5;
        
        total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
        cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
        cfg.lambda = cfg.lambda_network / cfg.num_STAs;
        
        rng(42 + run);
        [results, metrics] = main_sim_v2(cfg);
        
        if ~isempty(results.packet_level.delay_samples)
            delays = results.packet_level.delay_samples;
            temp_cv(run) = std(delays) / mean(delays);
        else
            temp_cv(run) = NaN;
        end
        
        if metrics.policy_level.trace_idx > 0
            idx = 1:metrics.policy_level.trace_idx;
            Q_all = metrics.policy_level.trace.Q(idx);
            temp_varQ(run) = var(Q_all);
            temp_empty(run) = sum(Q_all == 0) / length(Q_all) * 100;
        else
            temp_varQ(run) = NaN;
            temp_empty(run) = NaN;
        end
        
        temp_delay(run) = results.summary.mean_delay_ms;
    end
    
    data = struct();
    data.mean_cv = mean(temp_cv);
    data.std_cv = std(temp_cv);
    data.mean_varQ = mean(temp_varQ);
    data.std_varQ = std(temp_varQ);
    data.mean_delay = mean(temp_delay);
    data.std_delay = std(temp_delay);
    data.mean_empty = mean(temp_empty);
    data.std_empty = std(temp_empty);
    
    results_A3.data{i} = data;
    
    fprintf('%5.1f | %7.2f±%-4.2f | %8.0f±%-5.0f | %8.1f±%-3.1f | %7.1f±%-2.1f\n', ...
        alpha, data.mean_cv, data.std_cv, ...
        data.mean_varQ, data.std_varQ, ...
        data.mean_delay, data.std_delay, ...
        data.mean_empty, data.std_empty);
end

fprintf('\n✅ A-3 완료 (총 %d회 실행)\n\n', num_alpha * num_runs);

%% =====================================================================
%  결과 저장
%  =====================================================================

fprintf('결과 저장 중...\n');

phaseA_results = struct();
phaseA_results.A1_rho = results_A1;
phaseA_results.A2_Lcell = results_A2;
phaseA_results.A3_alpha = results_A3;
phaseA_results.num_runs = num_runs;
phaseA_results.timestamp = datetime('now');

save('results/phaseA_results.mat', 'phaseA_results');

fprintf('  저장 위치: results/phaseA_results.mat\n\n');

%% =====================================================================
%  요약 출력
%  =====================================================================

fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   Phase A 실험 완료                    ║\n');
fprintf('╚════════════════════════════════════════╝\n\n');

total_runs = (num_rho + num_L + num_alpha) * num_runs;
fprintf('총 실험 횟수: %d회\n', total_runs);
fprintf('  - A-1 (ρ 스윕): %d × %d = %d회\n', num_rho, num_runs, num_rho * num_runs);
fprintf('  - A-2 (L_cell 스윕): %d × %d = %d회\n', num_L, num_runs, num_L * num_runs);
fprintf('  - A-3 (α 스윕): %d × %d = %d회\n\n', num_alpha, num_runs, num_alpha * num_runs);

fprintf('다음 단계:\n');
fprintf('  >> analyze_phaseA_v2  %% 결과 분석 및 시각화 (점선 제거 버전)\n\n');