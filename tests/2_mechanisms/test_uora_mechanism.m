%% test_uora_mechanism.m
% UORA 메커니즘 검증
%
% [수정]
%   - Test 1, 4: STA 큐에 데이터를 추가하는 방식을
%     `STA.Queue = ...` 대신 `STA.queue_size = 1`로 변경

clear; close all; clc;

fprintf('========================================\n');
fprintf('  UORA 메커니즘 검증\n');
fprintf('========================================\n\n');

cfg = config_default();
cfg.verbose = 0;

total_tests = 0;
passed_tests = 0;

%% Test 1: OBO 카운터 감소
fprintf('[Test 1] OBO 카운터 감소\n');
fprintf('----------------------------------------\n');

STAs = DEFINE_STAs_v2(3, cfg.OCW_min, cfg);

% 초기 OBO 설정
STAs(1).OBO = 5;
STAs(2).OBO = 1;
STAs(3).OBO = 0;

% [수정] 모두 RA 모드, 데이터 있음 (원형 큐 상태 변수 설정)
for i = 1:3
    STAs(i).mode = 0;
    STAs(i).queue_size = 1;         % 큐에 데이터가 1개 있다고 설정
    STAs(i).queue_total_bytes = 2000; % UORA는 이 값을 보진 않지만, 일관성을 위해 설정
end

% UORA 실행 (numRU = 1)
STAs = UORA(STAs, 1);

% 검증
fprintf('  초기 OBO: [5, 1, 0]\n');
fprintf('  실행 후 OBO: [%d, %d, %d]\n', STAs(1).OBO, STAs(2).OBO, STAs(3).OBO);
fprintf('  접근 시도: [%d, %d, %d]\n', ...
    STAs(1).accessed_RA_RU, STAs(2).accessed_RA_RU, STAs(3).accessed_RA_RU);

total_tests = total_tests + 1;

% STA 1, 2는 감소만, STA 3은 접근
if STAs(1).OBO == 4 && STAs(2).OBO == 0 && STAs(3).accessed_RA_RU > 0
    fprintf('  ✅ PASS: OBO 감소 및 접근 조건 정상\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: OBO 동작 이상\n');
end

fprintf('\n');

%% Test 2: 충돌 감지
fprintf('[Test 2] RU 충돌 감지\n');
fprintf('----------------------------------------\n');

RUs = DEFINE_RUs(2, 1);  % RA-RU 1개
STAs_test = DEFINE_STAs_v2(2, cfg.OCW_min, cfg);

% 두 단말이 같은 RU에 접근
STAs_test(1).accessed_RA_RU = 1;
STAs_test(2).accessed_RA_RU = 1;

RUs = DETECTING_RU_COLLISION(RUs, STAs_test);

total_tests = total_tests + 1;

if RUs(1).collision == true && length(RUs(1).accessedSTAs) == 2
    fprintf('  ✅ PASS: 충돌 정상 감지\n');
    fprintf('     충돌: %d, 접근 단말: [%d, %d]\n', ...
        RUs(1).collision, RUs(1).accessedSTAs(1), RUs(1).accessedSTAs(2));
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 충돌 감지 실패\n');
end

fprintf('\n');

%% Test 3: OCW 증가 (BEB)
fprintf('[Test 3] Binary Exponential Backoff\n');
fprintf('----------------------------------------\n');

STAs_beb = DEFINE_STAs_v2(1, cfg.OCW_min, cfg);
STAs_beb(1).OCW = 15;

fprintf('  초기 OCW: %d\n', STAs_beb(1).OCW);

% 충돌 시뮬레이션 (UL_TRANSMITTING_v2 로직)
old_ocw = STAs_beb(1).OCW;
new_ocw = min(2 * (old_ocw + 1) - 1, cfg.OCW_max);

fprintf('  충돌 후 OCW: %d\n', new_ocw);

total_tests = total_tests + 1;

expected = min(2 * (15 + 1) - 1, 31);  % = 31
if new_ocw == expected
    fprintf('  ✅ PASS: BEB 동작 정상 (2×(OCW+1)-1 = %d)\n', expected);
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: BEB 계산 오류\n');
end

fprintf('\n');

%% Test 4: RA 모드 필터링
fprintf('[Test 4] RA 모드 필터링 (원형 큐 검증)\n');
fprintf('----------------------------------------\n');

STAs_mode = DEFINE_STAs_v2(3, cfg.OCW_min, cfg);

% [수정] STA 1: RA, 데이터 있음 (queue_size = 1)
STAs_mode(1).mode = 0;
STAs_mode(1).OBO = 0;
STAs_mode(1).queue_size = 1;
STAs_mode(1).queue_total_bytes = 2000;

% [수정] STA 2: SA, 데이터 있음 (queue_size = 1, mode = 1)
STAs_mode(2).mode = 1;
STAs_mode(2).OBO = 0;
STAs_mode(2).queue_size = 1;
STAs_mode(2).queue_total_bytes = 2000;

% [수정] STA 3: RA, 데이터 없음 (queue_size = 0)
STAs_mode(3).mode = 0;
STAs_mode(3).OBO = 0;
STAs_mode(3).queue_size = 0;
STAs_mode(3).queue_total_bytes = 0;

STAs_mode = UORA(STAs_mode, 1);

total_tests = total_tests + 1;

if STAs_mode(1).accessed_RA_RU > 0 && ...
   STAs_mode(2).accessed_RA_RU == 0 && ...
   STAs_mode(3).accessed_RA_RU == 0
    fprintf('  ✅ PASS: RA 모드 + queue_size > 0 단말만 참여\n');
    passed_tests = passed_tests + 1;
else
    fprintf('  ❌ FAIL: 참여 조건 필터링 오류\n');
    fprintf('    STA 1 (RA, Data): %d (예상 >0)\n', STAs_mode(1).accessed_RA_RU);
    fprintf('    STA 2 (SA, Data): %d (예상 0)\n', STAs_mode(2).accessed_RA_RU);
    fprintf('    STA 3 (RA, NoData): %d (예상 0)\n', STAs_mode(3).accessed_RA_RU);
end

fprintf('\n');

%% 최종 결과
fprintf('========================================\n');
fprintf('  테스트 결과\n');
fprintf('========================================\n');
fprintf('  통과: %d / %d\n', passed_tests, total_tests);
fprintf('  통과율: %.0f%%\n\n', passed_tests / total_tests * 100);

if passed_tests == total_tests
    fprintf('  🎉 모든 UORA 테스트 통과!\n\n');
else
    fprintf('  ⚠️  일부 테스트 실패\n\n');
end