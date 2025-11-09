%% test_full_simulation.m
% 전체 시뮬레이션 테스트
%
% 검증 내용:
%   - 짧은/중간 시뮬레이션
%   - 다양한 부하 조건
%   - 재현성

clear; close all; clc;

fprintf('========================================\n');
fprintf('  전체 시뮬레이션 테스트\n');
fprintf('========================================\n\n');

total_tests = 0;
passed_tests = 0;

%% Test 1: 짧은 시뮬레이션 (Baseline)
fprintf('[Test 1] 짧은 시뮬레이션 (Baseline, 5초)\n');
fprintf('----------------------------------------\n');

cfg = config_default();
cfg.num_STAs = 10;
cfg.simulation_time = 5.0;
cfg.warmup_time = 1.0;
cfg.scheme_id = 0;
cfg.verbose = 0;

results = main_sim_v2(cfg);

total_tests = total_tests + 1;

if results.total_completed_packets > 0 && ...
   ~isnan(results.summary.mean_delay_ms) && ...
   results.summary.throughput_mbps > 0
    fprintf('  ✅ PASS: 시뮬레이션 정상 완료\n');
    fprintf('    완료 패킷: %d\n', results.total_completed_packets);
    fprintf('    평균 지연: %.2f ms\n', results.summary.mean_delay_ms);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 시뮬레이션 오류\n');
end

fprintf('\n');

%% Test 2: 정책 비교 (짧은 시뮬레이션)
fprintf('[Test 2] 정책 비교 (Baseline vs v1-v3)\n');
fprintf('----------------------------------------\n');

schemes = [0, 1, 2, 3];
scheme_names = {'Baseline', 'v1', 'v2', 'v3'};

cfg_compare = config_default();
cfg_compare.num_STAs = 10;
cfg_compare.simulation_time = 3.0;
cfg_compare.warmup_time = 1.0;
cfg_compare.verbose = 0;

fprintf('%-15s | %10s | %10s | %10s\n', 'Scheme', 'Delay(ms)', 'Coll(%)', 'Impl(%)');
fprintf('%s\n', repmat('-', 1, 50));

all_schemes_ok = true;

for s = 1:length(schemes)
    cfg_compare.scheme_id = schemes(s);
    
    try
        r = main_sim_v2(cfg_compare);
        
        fprintf('%-15s | %10.2f | %10.1f | %10.1f\n', ...
            scheme_names{s}, ...
            r.summary.mean_delay_ms, ...
            r.summary.collision_rate * 100, ...
            r.summary.implicit_bsr_ratio * 100);
    catch ME
        fprintf('%-15s | ERROR: %s\n', scheme_names{s}, ME.message);
        all_schemes_ok = false;
    end
end

total_tests = total_tests + 1;

if all_schemes_ok
    fprintf('\n  ✅ PASS: 모든 정책 실행 성공\n');
    passed_tests = passed_tests + 1;
else
    fprintf('\n  ❌ FAIL: 일부 정책 실행 실패\n');
end

fprintf('\n');

%% Test 3: 다양한 부하 조건
fprintf('[Test 3] 다양한 부하 조건\n');
fprintf('----------------------------------------\n');

loads = [0.3, 0.6, 0.9];

fprintf('%-10s | %10s | %10s | %10s\n', 'L_cell', 'Delay(ms)', 'Tput(Mb/s)', 'Compl(%)');
fprintf('%s\n', repmat('-', 1, 50));

load_tests_ok = true;

for L = loads
    cfg_load = config_default();
    cfg_load.num_STAs = 10;
    cfg_load.simulation_time = 3.0;
    cfg_load.warmup_time = 1.0;
    cfg_load.L_cell = L;
    cfg_load.scheme_id = 0;
    cfg_load.verbose = 0;
    
    cfg_load = recompute_pareto_lambda(cfg_load);
    
    try
        r = main_sim_v2(cfg_load);
        
        fprintf('%-10.1f | %10.2f | %10.2f | %10.1f\n', ...
            L, r.summary.mean_delay_ms, r.summary.throughput_mbps, ...
            r.summary.completion_rate * 100);
    catch ME
        fprintf('%-10.1f | ERROR\n', L);
        load_tests_ok = false;
    end
end

total_tests = total_tests + 1;

if load_tests_ok
    fprintf('\n  ✅ PASS: 모든 부하 조건 정상\n');
    passed_tests = passed_tests + 1;
else
    fprintf('\n  ❌ FAIL: 일부 부하 조건 실패\n');
end

fprintf('\n');

%% Test 4: 재현성
fprintf('[Test 4] 재현성 (난수 시드)\n');
fprintf('----------------------------------------\n');

cfg_seed = config_default();
cfg_seed.num_STAs = 10;
cfg_seed.simulation_time = 2.0;
cfg_seed.warmup_time = 0.5;
cfg_seed.verbose = 0;

rng(42);
r1 = main_sim_v2(cfg_seed);

rng(42);
r2 = main_sim_v2(cfg_seed);

fprintf('  실행 1: %d packets, %.2f ms\n', ...
    r1.total_completed_packets, r1.summary.mean_delay_ms);
fprintf('  실행 2: %d packets, %.2f ms\n', ...
    r2.total_completed_packets, r2.summary.mean_delay_ms);

pkts_match = (r1.total_completed_packets == r2.total_completed_packets);

delay_match = true;
if ~isnan(r1.summary.mean_delay_ms) && ~isnan(r2.summary.mean_delay_ms)
    delay_diff = abs(r1.summary.mean_delay_ms - r2.summary.mean_delay_ms);
    delay_match = (delay_diff < 1e-6);
end

total_tests = total_tests + 1;

if pkts_match && delay_match
    fprintf('  ✅ PASS: 재현성 확인\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 재현성 오류\n');
end

fprintf('\n');

%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 전체 시뮬레이션 테스트 완료!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end