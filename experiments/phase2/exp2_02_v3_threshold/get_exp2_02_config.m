function exp_config = get_exp2_02_config()
% GET_EXP2_02_CONFIG: Experiment 2-02 설정 (v3 Threshold 2D 스윕)
%
% 목적:
%   reduction_threshold와 burst_threshold가 v3 성능에 미치는 영향 확인
%   → 핵심 파라미터 스윕 전 적절한 threshold 조합 결정
%
% Research Question:
%   1. 패킷 크기(2000 bytes) 대비 적절한 threshold 값은?
%   2. reduction_threshold와 burst_threshold의 최적 조합은?
%   3. threshold 설정이 v3 감산 빈도에 미치는 영향은?
%
% 스윕 변수 (2D):
%   reduction_threshold: [2000, 4000, 6000, 8000] bytes
%   burst_threshold:     [4000, 6000, 8000] bytes
%
% 테스트 환경:
%   Low (L=0.15) - v3가 가장 효과적이었던 환경
%
% 총 시뮬레이션:
%   4 × 3 × 2(scheme) × 10(runs) = 240회 (~12분)
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp2_02_v3_threshold';
    exp_config.phase = 2;
    exp_config.description = 'v3 threshold 2D 스윕 (reduction × burst)';
    
    %% =====================================================================
    %  커스텀 러너 사용
    %  =====================================================================
    
    exp_config.use_custom_runner = true;
    
    %% =====================================================================
    %  테스트 환경: Low만 (v3 효과 가장 컸던 환경)
    %  =====================================================================
    
    exp_config.scenario = struct();
    exp_config.scenario.name = 'Low';
    exp_config.scenario.L_cell = 0.15;
    exp_config.scenario.rho = 0.5;
    exp_config.scenario.mu_on = 0.05;
    exp_config.scenario.alpha = 1.5;
    
    %% =====================================================================
    %  2D 스윕 변수
    %  =====================================================================
    %
    %  패킷 크기 = 2000 bytes 기준:
    %  - reduction_threshold: 큐에 패킷 1~4개 수준에서 보호
    %  - burst_threshold: 패킷 2~4개 급증 시 버스트 판정
    
    % 변수 1: reduction_threshold (작은 큐 보호)
    exp_config.sweep_var = 'reduction_threshold';
    exp_config.sweep_range = [4000, 6000, 8000, 10000];  % bytes
    
    % 변수 2: burst_threshold (버스트 감지)
    exp_config.sweep_var2 = 'burst_threshold';
    exp_config.sweep_range2 = [12000, 15000, 20000];  % bytes
    
    %% =====================================================================
    %  비교 대상: Baseline vs v3
    %  =====================================================================
    
    exp_config.schemes = [0, 3];  % Baseline, v3
    exp_config.scheme_names = {'v0: Baseline', 'v3: EMA-based'};
    
    %% =====================================================================
    %  고정 파라미터
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Network
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    % v3 핵심 파라미터 (현재 값으로 고정 - Phase B에서 스윕 예정)
    exp_config.fixed.v3_EMA_alpha = 0.3;
    exp_config.fixed.v3_max_reduction = 0.5;
    exp_config.fixed.v3_sensitivity = 1.0;
    
    % threshold는 스윕 변수이므로 여기서 설정 안 함
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
    %% =====================================================================
    %  수집할 메트릭
    %  =====================================================================
    
    exp_config.metrics_to_collect = {
        % 지연 관련
        'mean_delay_ms'
        'std_delay_ms'
        'p90_delay_ms'
        'p99_delay_ms'
        
        % 지연 분해
        'mean_uora_delay_ms'
        'mean_sched_delay_ms'
        'mean_overhead_delay_ms'
        'mean_frag_delay_ms'
        
        % BSR 관련
        'explicit_bsr_count'
        'implicit_bsr_count'
        'implicit_bsr_ratio'
        'buffer_empty_ratio'
        
        % UORA 관련
        'collision_rate'
        'success_rate'
        
        % 처리량
        'throughput_mbps'
        'completion_rate'
        
        % 공평성
        'jain_index'
    };
    
end