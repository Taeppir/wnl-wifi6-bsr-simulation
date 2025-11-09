%% phaseA_parameter_sweep.m
% Phase A: 단일 파라미터 스윕 분석
%
% 실험 구성:
%   A-1: ρ (On 비율) 스윕
%   A-2: L_cell (네트워크 부하) 스윕
%   A-3: α (Heavy-tail 강도) 스윕
%
% 출력:
%   - results/phaseA_results.mat
%   - results/phaseA_*.png (시각화)

clear; close all; clc;

fprintf('\n');
fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   Phase A: 파라미터 스윕 분석          ║\n');
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
rho_values = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
num_rho = length(rho_values);

% μ_on, μ_off 계산 (평균 On+Off 기간 = 60ms 유지)
mu_total = 0.06;  % 60 ms
mu_on_values = rho_values * mu_total;
mu_off_values = (1 - rho_values) * mu_total;

fprintf('ρ 값: %s\n', mat2str(rho_values, 2));
fprintf('고정: α=%.1f, L_cell=%.1f\n\n', base_cfg.alpha, base_cfg.L_cell);

% 결과 저장 구조
results_A1 = struct();
results_A1.rho_values = rho_values;
results_A1.data = cell(num_rho, 1);

fprintf('%-5s | %-8s | %-8s | %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    'ρ', 'On(ms)', 'Off(ms)', 'Empty(%)', 'Expl.BSR', 'Impl.BSR', 'UORA', 'Delay(ms)');
fprintf('%s\n', repmat('-', 1, 95));

for i = 1:num_rho
    rho = rho_values(i);
    
    fprintf('%5.2f | ', rho);
    
    % 설정 생성
    cfg = base_cfg;
    cfg.alpha = 1.5;
    cfg.mu_on = mu_on_values(i);
    cfg.mu_off = mu_off_values(i);
    cfg.rho = rho;
    cfg.L_cell = 0.5;  % 고정
    
    % Lambda 재계산
    total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
    cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
    cfg.lambda = cfg.lambda_network / cfg.num_STAs;
    
    % 시뮬레이션 실행
    rng(42);  % 재현성
    [results, metrics] = main_sim_v2(cfg);
    
    % 버퍼 Empty 비율 계산
    if metrics.policy_level.trace_idx > 0
        idx = 1:metrics.policy_level.trace_idx;
        Q_all = metrics.policy_level.trace.Q(idx);
        empty_ratio = sum(Q_all == 0) / length(Q_all) * 100;
    else
        empty_ratio = NaN;
    end
    
    % 결과 저장
    data = struct();
    data.cfg = cfg;
    data.results = results;
    data.metrics = metrics;
    data.empty_ratio = empty_ratio;
    
    results_A1.data{i} = data;
    
    % 출력
    fprintf('%8.1f | %8.1f | %10.1f | %10d | %10d | %10d | %10.2f\n', ...
        cfg.mu_on*1000, cfg.mu_off*1000, empty_ratio, ...
        results.bsr.total_explicit, results.bsr.total_implicit, ...
        results.uora.total_attempts, results.summary.mean_delay_ms);
end

fprintf('\n✅ A-1 완료\n\n');

%% =====================================================================
%  A-2: L_cell (네트워크 부하) 스윕
%  =====================================================================

fprintf('════════════════════════════════════════\n');
fprintf('  A-2: L_cell (네트워크 부하) 스윕\n');
fprintf('════════════════════════════════════════\n\n');

% 파라미터 설정
L_values = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
num_L = length(L_values);

fprintf('L_cell 값: %s\n', mat2str(L_values, 1));
fprintf('고정: α=%.1f, ρ=%.1f\n\n', base_cfg.alpha, 0.5);

% 결과 저장 구조
results_A2 = struct();
results_A2.L_values = L_values;
results_A2.data = cell(num_L, 1);

fprintf('%-7s | %-10s | %-10s | %-10s | %-10s | %-10s | %-12s\n', ...
    'L_cell', 'Avg.Q(B)', 'Delay(ms)', 'Coll.(%)', 'Compl.(%)', 'Tput(Mb/s)', 'Empty(%)');
fprintf('%s\n', repmat('-', 1, 85));

for i = 1:num_L
    L = L_values(i);
    
    fprintf('%7.1f | ', L);
    
    % 설정 생성
    cfg = base_cfg;
    cfg.alpha = 1.5;
    cfg.mu_on = 0.03;   % ρ = 0.5 고정
    cfg.mu_off = 0.03;
    cfg.rho = 0.5;
    cfg.L_cell = L;
    
    % Lambda 재계산
    total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
    cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
    cfg.lambda = cfg.lambda_network / cfg.num_STAs;
    
    % 시뮬레이션 실행
    rng(42);
    [results, metrics] = main_sim_v2(cfg);
    
    % 평균 버퍼 크기 계산
    if metrics.policy_level.trace_idx > 0
        idx = 1:metrics.policy_level.trace_idx;
        Q_all = metrics.policy_level.trace.Q(idx);
        avg_Q = mean(Q_all);
        empty_ratio = sum(Q_all == 0) / length(Q_all) * 100;
    else
        avg_Q = NaN;
        empty_ratio = NaN;
    end
    
    % 결과 저장
    data = struct();
    data.cfg = cfg;
    data.results = results;
    data.metrics = metrics;
    data.avg_Q = avg_Q;
    data.empty_ratio = empty_ratio;
    
    results_A2.data{i} = data;
    
    % 출력
    fprintf('%10.0f | %10.2f | %10.1f | %10.1f | %12.2f | %12.1f\n', ...
        avg_Q, results.summary.mean_delay_ms, ...
        results.summary.collision_rate * 100, ...
        results.summary.completion_rate * 100, ...
        results.summary.throughput_mbps, empty_ratio);
end

fprintf('\n✅ A-2 완료\n\n');

%% =====================================================================
%  A-3: α (Heavy-tail 강도) 스윕
%  =====================================================================

fprintf('════════════════════════════════════════\n');
fprintf('  A-3: α (Heavy-tail 강도) 스윕\n');
fprintf('════════════════════════════════════════\n\n');

% 파라미터 설정
alpha_values = [1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0];
num_alpha = length(alpha_values);

fprintf('α 값: %s\n', mat2str(alpha_values, 1));
fprintf('고정: ρ=%.1f, L_cell=%.1f\n\n', 0.5, 0.5);

% 결과 저장 구조
results_A3 = struct();
results_A3.alpha_values = alpha_values;
results_A3.data = cell(num_alpha, 1);

fprintf('%-5s | %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    'α', 'CV(IA)', 'Var(Q)', 'Var(D)', 'Delay(ms)', 'Empty(%)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:num_alpha
    alpha = alpha_values(i);
    
    fprintf('%5.1f | ', alpha);
    
    % 설정 생성
    cfg = base_cfg;
    cfg.alpha = alpha;
    cfg.mu_on = 0.03;
    cfg.mu_off = 0.03;
    cfg.rho = 0.5;
    cfg.L_cell = 0.5;
    
    % Lambda 재계산
    total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
    cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8);
    cfg.lambda = cfg.lambda_network / cfg.num_STAs;
    
    % 시뮬레이션 실행
    rng(42);
    [results, metrics] = main_sim_v2(cfg);
    
    % Inter-arrival CV 계산 (간접적)
    % (실제로는 트래픽 생성 후 계산해야 하지만, 여기서는 결과 기반)
    if ~isempty(results.packet_level.delay_samples)
        delays = results.packet_level.delay_samples;
        cv_delay = std(delays) / mean(delays);
    else
        cv_delay = NaN;
    end
    
    % 버퍼 분산
    if metrics.policy_level.trace_idx > 0
        idx = 1:metrics.policy_level.trace_idx;
        Q_all = metrics.policy_level.trace.Q(idx);
        var_Q = var(Q_all);
        empty_ratio = sum(Q_all == 0) / length(Q_all) * 100;
    else
        var_Q = NaN;
        empty_ratio = NaN;
    end
    
    % 지연 분산
    var_delay = results.packet_level.std_delay;
    
    % 결과 저장
    data = struct();
    data.cfg = cfg;
    data.results = results;
    data.metrics = metrics;
    data.cv_delay = cv_delay;
    data.var_Q = var_Q;
    data.var_delay = var_delay;
    data.empty_ratio = empty_ratio;
    
    results_A3.data{i} = data;
    
    % 출력
    fprintf('%10.2f | %10.0f | %10.4f | %10.2f | %10.1f\n', ...
        cv_delay, var_Q, var_delay, ...
        results.summary.mean_delay_ms, empty_ratio);
end

fprintf('\n✅ A-3 완료\n\n');

%% =====================================================================
%  결과 저장
%  =====================================================================

fprintf('결과 저장 중...\n');

phaseA_results = struct();
phaseA_results.A1_rho = results_A1;
phaseA_results.A2_Lcell = results_A2;
phaseA_results.A3_alpha = results_A3;
phaseA_results.timestamp = datetime('now');

save('results/phaseA_results.mat', 'phaseA_results');

fprintf('  저장 위치: results/phaseA_results.mat\n\n');

%% =====================================================================
%  요약 출력
%  =====================================================================

fprintf('╔════════════════════════════════════════╗\n');
fprintf('║   Phase A 실험 완료                    ║\n');
fprintf('╚════════════════════════════════════════╝\n\n');

fprintf('총 실험 횟수: %d회\n', num_rho + num_L + num_alpha);
fprintf('  - A-1 (ρ 스윕): %d회\n', num_rho);
fprintf('  - A-2 (L_cell 스윕): %d회\n', num_L);
fprintf('  - A-3 (α 스윕): %d회\n\n', num_alpha);

fprintf('다음 단계:\n');
fprintf('  >> analyze_phaseA  %% 결과 분석 및 시각화\n\n');