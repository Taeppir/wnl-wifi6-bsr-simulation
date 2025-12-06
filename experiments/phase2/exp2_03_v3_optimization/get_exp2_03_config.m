function exp_config = get_exp2_03_config()
% GET_EXP2_03_CONFIG: Experiment 2-03 설정 (v3 핵심 파라미터 최적화)
%
% 목적:
%   v3_EMA_alpha × v3_max_reduction 2D 스윕으로 최적 조합 탐색
%
% Research Question:
%   1. EMA_alpha가 클수록 (최근값 민감) 좋은가, 작을수록 (장기 추세) 좋은가?
%   2. max_reduction이 클수록 공격적 감산이 효과적인가?
%   3. 두 파라미터 간 상호작용이 있는가?
%
% 스윕 변수 (2D):
%   v3_EMA_alpha:     [0.1, 0.2, 0.3, 0.5, 0.7]
%   v3_max_reduction: [0.3, 0.5, 0.7, 0.9]
%
% 고정값 (Exp 2-02 결과):
%   reduction_threshold = 4000 bytes
%   burst_threshold = 12000 bytes
%
% 테스트 환경:
%   Low (L=0.15) - v3가 가장 효과적인 환경
%
% 총 시뮬레이션:
%   5 × 4 × 2(scheme) × 10(runs) = 400회 (~20분)

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp2_03_v3_optimization';
    exp_config.phase = 2;
    exp_config.description = 'v3 핵심 파라미터 최적화 (EMA_alpha × max_reduction)';
    
    %% =====================================================================
    %  커스텀 러너 사용
    %  =====================================================================
    
    exp_config.use_custom_runner = true;
    
    %% =====================================================================
    %  테스트 환경: Low (v3 효과 가장 컸던 환경)
    %  =====================================================================
    
    exp_config.scenario = struct();
    exp_config.scenario.name = 'Mid';
    exp_config.scenario.L_cell = 0.30;
    exp_config.scenario.rho = 0.5;
    exp_config.scenario.mu_on = 0.05;
    exp_config.scenario.alpha = 1.5;
    
    %% =====================================================================
    %  2D 스윕 변수 (핵심 파라미터)
    %  =====================================================================
    
    % 변수 1: EMA_alpha (EMA 계수)
    %   - 작을수록: 장기 추세 반영, 느린 반응
    %   - 클수록: 최근값에 민감, 빠른 반응
    exp_config.sweep_var = 'v3_EMA_alpha';
    exp_config.sweep_range = [0.1, 0.3, 0.5];
    
    % 변수 2: max_reduction (최대 감소 비율)
    %   - 작을수록: 보수적 감산
    %   - 클수록: 공격적 감산
    exp_config.sweep_var2 = 'v3_max_reduction';
    exp_config.sweep_range2 = [0.5, 0.7];
    
    %% =====================================================================
    %  비교 대상: Baseline vs v3
    %  =====================================================================
    
    exp_config.schemes = [0, 3];
    exp_config.scheme_names = {'v0: Baseline', 'v3: EMA-based'};
    
    %% =====================================================================
    %  고정 파라미터
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Network
    exp_config.fixed.num_STAs = 10;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Simulation
    exp_config.fixed.simulation_time = 30.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    % Threshold (Exp 2-02 결과로 고정)
    exp_config.fixed.reduction_threshold = 4000;   % 적극적 감산
    exp_config.fixed.burst_threshold = 30000;      % 버스트 감지 (최대 큐 54000 근처)
    
    % v3 기타 파라미터 고정
    exp_config.fixed.v3_sensitivity = 1.0;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
    %% =====================================================================
    %  수집할 메트릭 (확장됨)
    %  =====================================================================
    
    exp_config.metrics_to_collect = {
        % 지연 관련 (핵심) - p10 추가
        'mean_delay_ms'
        'std_delay_ms'
        'p10_delay_ms'
        'p90_delay_ms'
        'p99_delay_ms'
        
        % 지연 분해 (평균)
        'mean_uora_delay_ms'
        'mean_sched_delay_ms'
        'mean_overhead_delay_ms'
        'mean_frag_delay_ms'
        
        % UORA delay 분포
        'std_uora_delay_ms'
        'p10_uora_delay_ms'
        'p90_uora_delay_ms'
        'p99_uora_delay_ms'
        
        % Sched delay 분포
        'std_sched_delay_ms'
        'p10_sched_delay_ms'
        'p90_sched_delay_ms'
        
        % Overhead delay 분포
        'std_overhead_delay_ms'
        'p10_overhead_delay_ms'
        'p90_overhead_delay_ms'
        
        % Frag delay 분포
        'std_frag_delay_ms'
        
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