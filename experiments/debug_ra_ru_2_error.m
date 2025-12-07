%% debug_ra_ru_2_error.m
% RA-RU=2일 때 발생하는 에러 디버깅
%
% 목적: "Arrays have incompatible sizes" 에러의 원인 파악

clear; close all; clc;

fprintf('========================================\n');
fprintf('  RA-RU=2 에러 디버깅\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 경로 설정
%  =====================================================================

if exist('setup_paths.m', 'file')
    setup_paths;
end

%% =====================================================================
%  2. 문제 설정으로 단일 실행
%  =====================================================================

fprintf('[1/3] 문제 설정으로 실행\n');
fprintf('----------------------------------------\n');

cfg = config_default();

% 실패하는 설정
cfg.L_cell = 0.3;
cfg.rho = 0.3;
cfg.mu_on = 0.05;
cfg.num_STAs = 10;
cfg.numRU_RA = 2;  % ⭐ 문제 발생 지점

% ⭐⭐⭐ numRU_SA 자동 계산 (numRU_total=9 고정)
cfg.numRU_SA = cfg.numRU_total - cfg.numRU_RA;  % = 9 - 2 = 7

cfg.simulation_time = 10.0;
cfg.warmup_time = 0.0;
cfg.scheme_id = 0;
cfg.verbose = 1;  % 출력 활성화
cfg.collect_bsr_trace = false;

% Lambda 재계산
cfg = recompute_pareto_lambda(cfg);

fprintf('설정:\n');
fprintf('  L_cell: %.1f\n', cfg.L_cell);
fprintf('  rho: %.1f\n', cfg.rho);
fprintf('  num_STAs: %d\n', cfg.num_STAs);
fprintf('  numRU_RA: %d ⭐\n', cfg.numRU_RA);
fprintf('  numRU_SA: %d (= %d - %d)\n', cfg.numRU_SA, cfg.numRU_total, cfg.numRU_RA);
fprintf('  numRU_total: %d (고정)\n', cfg.numRU_total);

fprintf('\n시뮬레이션 실행 중...\n');

try
    rng(42);
    [results, ~] = main_sim_v2(cfg);
    
    fprintf('\n✅ 성공!\n');
    fprintf('  완료 패킷: %d\n', results.total_completed_packets);
    fprintf('  평균 지연: %.2f ms\n', results.summary.mean_delay_ms);
    
catch ME
    fprintf('\n❌ 실패!\n');
    fprintf('  에러: %s\n', ME.message);
    fprintf('  위치: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    
    % 스택 트레이스 출력
    fprintf('\n스택 트레이스:\n');
    for i = 1:min(5, length(ME.stack))
        fprintf('  [%d] %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
    end
    
    % 상세 디버깅
    fprintf('\n상세 에러 정보:\n');
    disp(ME);
end

fprintf('\n');

%% =====================================================================
%  3. RA-RU=1 vs RA-RU=2 비교
%  =====================================================================

fprintf('[2/3] RA-RU=1 vs RA-RU=2 비교\n');
fprintf('----------------------------------------\n');

configs_test = [1, 2];  % RA-RU 값

for ra_ru = configs_test
    fprintf('\n[RA-RU=%d]\n', ra_ru);
    
    cfg_test = config_default();
    cfg_test.L_cell = 0.1;
    cfg_test.rho = 0.3;
    cfg_test.num_STAs = 10;
    cfg_test.numRU_RA = ra_ru;
    
    % ⭐⭐⭐ numRU_SA 자동 계산
    cfg_test.numRU_SA = cfg_test.numRU_total - cfg_test.numRU_RA;
    
    cfg_test.simulation_time = 5.0;
    cfg_test.warmup_time = 0.0;
    cfg_test.verbose = 0;
    
    cfg_test = recompute_pareto_lambda(cfg_test);
    
    fprintf('  numRU_total: %d (고정)\n', cfg_test.numRU_total);
    fprintf('  numRU_SA: %d (= %d - %d)\n', ...
        cfg_test.numRU_SA, cfg_test.numRU_total, cfg_test.numRU_RA);
    
    try
        rng(100);
        [r, ~] = main_sim_v2(cfg_test);
        fprintf('  ✅ 성공: %d 패킷, %.2f ms\n', ...
            r.total_completed_packets, r.summary.mean_delay_ms);
    catch ME
        fprintf('  ❌ 실패: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('     at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

fprintf('\n');

%% =====================================================================
%  4. 기본 설정 확인
%  =====================================================================

fprintf('[3/3] 기본 설정 확인\n');
fprintf('----------------------------------------\n');

cfg_check = config_default();
cfg_check.numRU_RA = 2;

% ⭐⭐⭐ numRU_SA 자동 계산
cfg_check.numRU_SA = cfg_check.numRU_total - cfg_check.numRU_RA;  % = 9 - 2 = 7

fprintf('  numRU_total: %d (고정)\n', cfg_check.numRU_total);
fprintf('  numRU_RA: %d\n', cfg_check.numRU_RA);
fprintf('  numRU_SA: %d (= %d - %d)\n', ...
    cfg_check.numRU_SA, cfg_check.numRU_total, cfg_check.numRU_RA);

% 초기화 함수 확인
AP_test = DEFINE_AP(10);
RUs_test = DEFINE_RUs(cfg_check.numRU_total, cfg_check.numRU_RA);

fprintf('  AP.BSR 크기: %d\n', length(AP_test.BSR));
fprintf('  RUs 개수: %d\n', length(RUs_test));
fprintf('  RA-RU 개수: %d (mode=0)\n', sum([RUs_test.mode] == 0));
fprintf('  SA-RU 개수: %d (mode=1)\n', sum([RUs_test.mode] == 1));

% 검증
expected_sa_ru = cfg_check.numRU_SA;
actual_sa_ru = sum([RUs_test.mode] == 1);

if expected_sa_ru == actual_sa_ru
    fprintf('  ✅ SA-RU 개수 일치: %d = %d\n', expected_sa_ru, actual_sa_ru);
else
    fprintf('  ❌ SA-RU 개수 불일치: 예상=%d, 실제=%d\n', expected_sa_ru, actual_sa_ru);
end

fprintf('\n');

%% =====================================================================
%  5. 결론
%  =====================================================================

fprintf('========================================\n');
fprintf('  디버깅 완료\n');
fprintf('========================================\n\n');

fprintf('💡 문제 원인:\n');
fprintf('  numRU_total=9는 고정, numRU_RA 변경 시 numRU_SA도 재계산 필요!\n\n');

fprintf('✅ 해결 방법:\n');
fprintf('  run_single_config.m에서:\n');
fprintf('    numRU_SA = numRU_total - numRU_RA\n');
fprintf('    (예: numRU_RA=2 → numRU_SA=7)\n\n');

fprintf('다음 단계:\n');
fprintf('  1. 수정된 run_single_config.m 사용\n');
fprintf('  2. exp0_baseline_sweep.m 재실행\n');
fprintf('  3. RA-RU=2 조합에서 정상 동작 확인\n\n');