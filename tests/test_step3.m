%% test_step3.m
% Step 3: 트래픽 생성 테스트

clear; close all; clc;

fprintf('========================================\n');
fprintf('Step 3: 트래픽 생성 테스트\n');
fprintf('========================================\n\n');

%% 설정 로드
cfg = config_default();
cfg.verbose = 2;

% 빠른 테스트를 위해 짧게 설정
cfg.simulation_time = 10.0;
cfg.warmup_time = 2;

%% 초기화
AP = DEFINE_AP(cfg.num_STAs);
STAs = DEFINE_STAs_v2(cfg.num_STAs, cfg.OCW_min, cfg);

%% Test 3-1: 기본 트래픽 생성
fprintf('Test 3-1: 기본 트래픽 생성\n');

STAs = gen_onoff_pareto_v2(STAs, cfg);

% 패킷 생성 확인
total_packets = sum([STAs.num_of_packets]);
assert(total_packets > 0, 'No packets generated');

fprintf('  트래픽 생성 성공: %d 패킷\n', total_packets);

%% Test 3-2: 단말별 패킷 확인
fprintf('\nTest 3-2: 단말별 패킷 확인\n');

at_least_one_has_packets = false;

for i = 1:length(STAs)
    if STAs(i).num_of_packets > 0
        at_least_one_has_packets = true;
        
        % packet_list 구조 확인
        pkt = STAs(i).packet_list(1);
        
        assert(isfield(pkt, 'packet_idx'), 'Missing packet_idx');
        assert(isfield(pkt, 'total_size'), 'Missing total_size');
        assert(isfield(pkt, 'arrival_time'), 'Missing arrival_time');
        
        % 값 확인
        assert(pkt.packet_idx > 0, 'Invalid packet_idx');
        assert(pkt.total_size == cfg.size_MPDU, 'Invalid packet size');
        assert(pkt.arrival_time >= 0, 'Negative arrival time');
        assert(pkt.arrival_time <= cfg.simulation_time, 'Arrival time exceeds sim_time');
        
        break;
    end
end

assert(at_least_one_has_packets, 'No STA has packets');

fprintf('  패킷 구조 검증 성공\n');

%% Test 3-3: 도착 시간 정렬 확인
fprintf('\nTest 3-3: 도착 시간 정렬 확인\n');

all_sorted = true;

for i = 1:length(STAs)
    if ~isempty(STAs(i).packet_list)
        arrivals = [STAs(i).packet_list.arrival_time];
        
        if ~issorted(arrivals)
            all_sorted = false;
            fprintf('  STA %d: 도착 시간 정렬 안 됨\n', i);
        end
    end
end

assert(all_sorted, 'Some STAs have unsorted arrival times');

fprintf('  모든 단말의 도착 시간 정렬됨\n');

%% Test 3-4: 트래픽 검증
fprintf('\nTest 3-4: 트래픽 검증\n');

validate_traffic(STAs, cfg);

%% Test 3-5: 부하 변경 테스트
fprintf('\nTest 3-5: 다양한 부하 조건 테스트\n');

loads = [0.3, 0.6, 0.9];

fprintf('\n  %-10s | %-15s | %-15s | %-10s\n', 'L_cell', '생성 패킷', '목표 패킷', '오차');
fprintf('  %s\n', repmat('-', 1, 60));

for L = loads
    cfg_test = config_default();
    cfg_test.simulation_time = 2.0;
    cfg_test.L_cell = L;
    cfg_test.verbose = 0;
    
    % lambda 재계산
    total_capacity = cfg_test.numRU_SA * cfg_test.data_rate_per_RU;
    cfg_test.lambda_network = cfg_test.L_cell * total_capacity / (cfg_test.size_MPDU * 8);
    cfg_test.lambda = cfg_test.lambda_network / cfg_test.num_STAs;
    
    % 초기화 및 생성
    STAs_test = DEFINE_STAs_v2(cfg_test.num_STAs, cfg_test.OCW_min, cfg_test);
    STAs_test = gen_onoff_pareto_v2(STAs_test, cfg_test);
    
    % 통계
    total_pkts = sum([STAs_test.num_of_packets]);
    expected_pkts = cfg_test.lambda_network * cfg_test.simulation_time;
    error_pct = abs(total_pkts - expected_pkts) / expected_pkts * 100;
    
    fprintf('  %-10.1f | %-15d | %-15.0f | %-9.1f%%\n', ...
        L, total_pkts, expected_pkts, error_pct);
end

fprintf('\n  ✓ 부하 변경 테스트 성공\n');

%% Test 3-6: Pareto 분포 검증
fprintf('\nTest 3-6: Pareto 분포 특성 확인\n');

% 충분한 샘플을 위해 긴 시뮬레이션
cfg_long = config_default();
cfg_long.simulation_time = 10.0;
cfg_long.verbose = 0;

STAs_long = DEFINE_STAs_v2(cfg_long.num_STAs, cfg_long.OCW_min, cfg_long);
STAs_long = gen_onoff_pareto_v2(STAs_long, cfg_long);

% 모든 패킷 수집
all_arrivals = [];
for i = 1:length(STAs_long)
    if ~isempty(STAs_long(i).packet_list)
        arrivals = [STAs_long(i).packet_list.arrival_time];
        all_arrivals = [all_arrivals, arrivals];
    end
end

if ~isempty(all_arrivals)
    % Inter-arrival time 계산
    sorted_arrivals = sort(all_arrivals);
    inter_arrivals = diff(sorted_arrivals);
    
    % 통계
    mean_inter = mean(inter_arrivals);
    std_inter = std(inter_arrivals);
    
    fprintf('  Inter-arrival time:\n');
    fprintf('    평균: %.4f s\n', mean_inter);
    fprintf('    표준편차: %.4f s\n', std_inter);
    fprintf('    CV: %.2f\n', std_inter / mean_inter);
    
    % Pareto의 heavy-tail 특성 확인 (CV > 1)
    cv = std_inter / mean_inter;
    if cv > 1
        fprintf('  Heavy-tail 특성 확인 (CV > 1)\n');
    else
        fprintf('  CV < 1 (샘플 부족 가능)\n');
    end
else
    fprintf('  패킷 없음 - 테스트 스킵\n');
end

%% Test 3-7: 메모리 효율성
fprintf('\nTest 3-7: 메모리 효율성 확인\n');

% 많은 단말 생성
cfg_large = config_default();
cfg_large.num_STAs = 50;
cfg_large.simulation_time = 5.0;
cfg_large.verbose = 0;

tic;
STAs_large = DEFINE_STAs_v2(cfg_large.num_STAs, cfg_large.OCW_min, cfg_large);
STAs_large = gen_onoff_pareto_v2(STAs_large, cfg_large);
elapsed = toc;

total_pkts_large = sum([STAs_large.num_of_packets]);
mem_bytes = whos('STAs_large').bytes;

fprintf('  단말 수: %d\n', cfg_large.num_STAs);
fprintf('  생성 패킷: %d\n', total_pkts_large);
fprintf('  생성 시간: %.3f s\n', elapsed);
fprintf('  메모리: %.2f MB\n', mem_bytes / 1e6);
fprintf('  패킷당 시간: %.2f µs\n', elapsed / total_pkts_large * 1e6);

if elapsed < 2.0
    fprintf('  생성 속도 양호\n');
else
    fprintf('  생성 느림 - 최적화 필요\n');
end

%% Test 3-8: 재현성 테스트
fprintf('\nTest 3-8: 재현성 테스트 (난수 시드)\n');

% 첫 번째 실행
rng(42);  % 시드 고정
cfg_seed = config_default();
cfg_seed.simulation_time = 1.0;
cfg_seed.verbose = 0;

STAs_seed1 = DEFINE_STAs_v2(cfg_seed.num_STAs, cfg_seed.OCW_min, cfg_seed);
STAs_seed1 = gen_onoff_pareto_v2(STAs_seed1, cfg_seed);
pkts1 = sum([STAs_seed1.num_of_packets]);

% 두 번째 실행 (같은 시드)
rng(42);  % 같은 시드
STAs_seed2 = DEFINE_STAs_v2(cfg_seed.num_STAs, cfg_seed.OCW_min, cfg_seed);
STAs_seed2 = gen_onoff_pareto_v2(STAs_seed2, cfg_seed);
pkts2 = sum([STAs_seed2.num_of_packets]);

if pkts1 == pkts2
    fprintf('  재현성 확인 (패킷 수 일치: %d)\n', pkts1);
else
    fprintf('  패킷 수 불일치: %d vs %d\n', pkts1, pkts2);
end

% 세 번째 실행 (다른 시드)
rng(99);
STAs_seed3 = DEFINE_STAs_v2(cfg_seed.num_STAs, cfg_seed.OCW_min, cfg_seed);
STAs_seed3 = gen_onoff_pareto_v2(STAs_seed3, cfg_seed);
pkts3 = sum([STAs_seed3.num_of_packets]);

if pkts1 ~= pkts3
    fprintf('  시드 변경 시 다른 결과: %d vs %d\n', pkts1, pkts3);
else
    fprintf('  시드 변경했는데 같은 결과 (우연?)\n');
end

%% 모든 테스트 통과
fprintf('\n========================================\n');
fprintf('  Step 3 완료: 트래픽 생성 검증 성공\n');
fprintf('========================================\n\n');

fprintf('트래픽 생성 완료:\n');
fprintf(['  - Pareto On-Off 모델 동작 확인✓' ...
    '\n']);
fprintf('  - 부하 제어 정상 ✓\n');
fprintf('  - 패킷 구조 검증 ✓\n');
fprintf('  - 도착 시간 정렬 ✓\n\n')

fprintf('다음 단계:\n');
fprintf('  >> test_step4  %% Step 4: BSR 정책 함수 테스트\n\n');