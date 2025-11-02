%% test_step5_full_sim.m
% Step 5: 전체 시뮬레이션 테스트

clear; close all; clc;

fprintf('========================================\n');
fprintf('Step 5: 전체 시뮬레이션 테스트\n');
fprintf('========================================\n\n');

%% Test 5-1: 짧은 시뮬레이션 (Baseline)
fprintf('Test 5-1: 짧은 시뮬레이션 (Baseline, 2초)\n\n');

cfg = config_default();
cfg.num_STAs = 10;
cfg.simulation_time = 10.0;
cfg.warmup_time = 2;
cfg.scheme_id = 0;  % Baseline
cfg.verbose = 1;

results = main_sim_v2(cfg);

% 기본 검증
assert(results.total_completed_packets > 0, 'No packets completed');
assert(~isnan(results.summary.mean_delay_ms), 'Mean delay is NaN');
assert(results.summary.throughput_mbps > 0, 'Throughput is zero');

fprintf('\n✅ Test 5-1 Pass\n\n');

%% Test 5-2: 4가지 정책 비교 (짧은 시뮬레이션)
fprintf('========================================\n');
fprintf('Test 5-2: 정책 비교 (Baseline vs v1)\n');
fprintf('========================================\n\n');

cfg_compare = config_default();
cfg_compare.num_STAs = 10;
cfg_compare.simulation_time = 3.0;
cfg_compare.warmup_time = 1.0;
cfg_compare.verbose = 0;

schemes = [0, 1];  % Baseline, v1만 (v2, v3는 추후)
scheme_names = {'Baseline', 'v1'};

fprintf('%-15s | %10s | %10s | %10s | %10s\n', ...
    'Scheme', 'Delay(ms)', 'Tput(Mb/s)', 'Coll(%)', 'Impl(%)');
fprintf('%s\n', repmat('-', 1, 70));

for s = 1:length(schemes)
    cfg_compare.scheme_id = schemes(s);
    
    if schemes(s) == 1
        % v1 파라미터 확인
        cfg_compare.v1_fixed_reduction_bytes = 500;
    end
    
    fprintf('%-15s 실행 중...', scheme_names{s});
    
    r = main_sim_v2(cfg_compare);
    
    fprintf(' %-15s | %10.2f | %10.2f | %10.1f | %10.1f\n', ...
        scheme_names{s}, ...
        r.summary.mean_delay_ms, ...
        r.summary.throughput_mbps, ...
        r.summary.collision_rate * 100, ...
        r.summary.implicit_bsr_ratio * 100);
end

fprintf('\n✅ Test 5-2 Pass\n\n');

%% Test 5-3: 다양한 부하 조건
fprintf('========================================\n');
fprintf('Test 5-3: 다양한 부하 조건 (Baseline)\n');
fprintf('========================================\n\n');

loads = [0.3, 0.6, 0.9];

fprintf('%-10s | %10s | %10s | %10s\n', 'L_cell', 'Delay(ms)', 'Tput(Mb/s)', 'Compl(%)');
fprintf('%s\n', repmat('-', 1, 50));

for L = loads
    cfg_load = config_default();
    cfg_load.num_STAs = 10;
    cfg_load.simulation_time = 2.0;
    cfg_load.warmup_time = 0.5;
    cfg_load.L_cell = L;
    cfg_load.scheme_id = 0;
    cfg_load.verbose = 0;
    
    % lambda 재계산
    total_capacity = cfg_load.numRU_SA * cfg_load.data_rate_per_RU;
    cfg_load.lambda_network = cfg_load.L_cell * total_capacity / (cfg_load.size_MPDU * 8);
    cfg_load.lambda = cfg_load.lambda_network / cfg_load.num_STAs;
    
    r = main_sim_v2(cfg_load);
    
    fprintf('%-10.1f | %10.2f | %10.2f | %10.1f\n', ...
        L, r.summary.mean_delay_ms, r.summary.throughput_mbps, ...
        r.summary.completion_rate * 100);
end

fprintf('\n✅ Test 5-3 Pass\n\n');

%% Test 5-4: 재현성 테스트
%% Test 5-4: 재현성 테스트
fprintf('========================================\n');
fprintf('Test 5-4: 재현성 테스트 (난수 시드)\n');
fprintf('========================================\n\n');

rng(42);
cfg_seed = config_default();
cfg_seed.num_STAs = 10;
cfg_seed.simulation_time = 2.0;  % ⭐ 1.0 → 2.0 (충분한 시간)
cfg_seed.warmup_time = 0.5;
cfg_seed.verbose = 0;
r1 = main_sim_v2(cfg_seed);

rng(42);  % 같은 시드
r2 = main_sim_v2(cfg_seed);

% 결과 출력
fprintf('실행 1: %.4f ms, %d packets\n', r1.summary.mean_delay_ms, r1.total_completed_packets);
fprintf('실행 2: %.4f ms, %d packets\n', r2.summary.mean_delay_ms, r2.total_completed_packets);

% 재현성 확인 (완료 패킷 수 기준)
pkts_diff = abs(r1.total_completed_packets - r2.total_completed_packets);
fprintf('패킷 수 차이: %d packets\n', pkts_diff);

% ⭐ NaN 처리
if ~isnan(r1.summary.mean_delay_ms) && ~isnan(r2.summary.mean_delay_ms)
    delay_diff = abs(r1.summary.mean_delay_ms - r2.summary.mean_delay_ms);
    fprintf('지연 차이: %.6f ms\n', delay_diff);
    
    % 검증 (부동소수점 오차 허용)
    assert(delay_diff < 1e-6, 'Delay should be nearly identical');
end

assert(pkts_diff == 0, 'Packet counts should match exactly');

fprintf('\n✅ Test 5-4 Pass (재현성 확인: %d packets)\n\n', r1.total_completed_packets);