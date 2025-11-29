function exp_config = get_exp2_01_config()
% GET_EXP2_01_CONFIG: Experiment 2-1 설정 (정책 비교)
%
% 목적:
%   제안 스킴(v1~v3)이 Baseline 대비 얼마나 지연/충돌을 감소시키는가?
%   특히 중부하(Mid) 환경에서 개선 효과가 가장 클 것으로 예상
%
% Research Question:
%   1. 어떤 기법이 T_uora를 가장 효과적으로 줄이는가?
%   2. 평균 지연뿐 아니라 분산(std)도 감소하는가?
%   3. 부하 수준별로 기법 효과가 어떻게 다른가?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp2_01_scheme_comparison';
    exp_config.phase = 2;
    exp_config.description = '정책 비교 - 부하 수준별 성능 (T_uora 감소 효과)';
    
    %% =====================================================================
    %  시나리오 정의 (3개 × 4개 스킴 = 12개 조합)
    %  =====================================================================
    
    % 커스텀 러너 사용 (시나리오 × 스킴 2D 실험)
    exp_config.use_custom_runner = true;
    
    %% =====================================================================
    %  시나리오 파라미터 (Exp 1-00 결과 기반)
    %  =====================================================================
    %
    %  ⭐ 핵심: rho=0.5, mu_on=0.05 고정 (Exp 1-00과 동일)
    %
    %  Exp 1-00 결과:
    %    Low (0.15): Buffer Empty 38.7% → Unsaturated
    %    Mid (0.30): Buffer Empty 27.2% → 경계, Explicit BSR 피크
    %    High (0.50): Buffer Empty 23.7% → Saturated
    
    % Scenario 1: Low-load (Unsaturated)
    exp_config.scenarios(1).name = 'Low';
    exp_config.scenarios(1).L_cell = 0.15;
    exp_config.scenarios(1).rho = 0.5;      % ⭐ 고정
    exp_config.scenarios(1).mu_on = 0.05;   % ⭐ 고정
    exp_config.scenarios(1).alpha = 1.5;
    
    % Scenario 2: Mid-load (핵심 타겟)
    exp_config.scenarios(2).name = 'Mid';
    exp_config.scenarios(2).L_cell = 0.30;
    exp_config.scenarios(2).rho = 0.5;      % ⭐ 고정
    exp_config.scenarios(2).mu_on = 0.05;   % ⭐ 고정
    exp_config.scenarios(2).alpha = 1.5;
    
    % Scenario 3: High-load (Saturated, 비교용)
    exp_config.scenarios(3).name = 'High';
    exp_config.scenarios(3).L_cell = 0.50;
    exp_config.scenarios(3).rho = 0.5;      % ⭐ 고정
    exp_config.scenarios(3).mu_on = 0.05;   % ⭐ 고정
    exp_config.scenarios(3).alpha = 1.5;
    
    %% =====================================================================
    %  비교 스킴
    %  =====================================================================
    
    exp_config.schemes = [0, 1, 2, 3];  % Baseline + 제안 3개
    
    exp_config.scheme_names = {
        'v0: Baseline (R=Q)'
        'v1: Fixed Reduction'
        'v2: Proportional'
        'v3: EMA-based'
    };
    
    %% =====================================================================
    %  고정 파라미터 (모든 시나리오 공통)
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
    
    %% =====================================================================
    %  스킴별 파라미터 (초기값 - 추후 최적화 예정)
    %  =====================================================================
    
    % 공통 파라미터
    exp_config.fixed.burst_threshold = 1000;      % 버스트 감지 임계값
    exp_config.fixed.reduction_threshold = 500;   % 감소 적용 최소 큐 크기
    
    % Scheme 1 (Fixed Reduction) 파라미터
    exp_config.fixed.v1_fixed_reduction_bytes = 500;  % 고정 감소량 [bytes]
    exp_config.fixed.v1_sensitivity = 1.0;
    
    % Scheme 2 (Proportional) 파라미터
    exp_config.fixed.v2_max_reduction = 0.5;      % 최대 감소 비율 (50%)
    exp_config.fixed.v2_sensitivity = 1.0;
    
    % Scheme 3 (EMA-based) 파라미터
    exp_config.fixed.v3_EMA_alpha = 0.3;          % EMA 계수 (0.2~0.5 권장)
    exp_config.fixed.v3_sensitivity = 1.0;
    exp_config.fixed.v3_max_reduction = 0.5;      % 최대 감소 비율 (50%)
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;  % 신뢰구간용
    
    %% =====================================================================
    %  수집할 메트릭 (상세)
    %  =====================================================================
    
    exp_config.metrics_to_collect = {
        % 지연 관련 (핵심!)
        'mean_delay_ms'
        'std_delay_ms'          % ⭐ 분산 감소 확인용
        'p90_delay_ms'
        'p99_delay_ms'
        
        % 지연 분해 (T_uora가 핵심!)
        'mean_uora_delay_ms'    % ⭐ 핵심 타겟
        'mean_sched_delay_ms'
        'mean_overhead_delay_ms'
        'mean_frag_delay_ms'
        
        % BSR 관련
        'explicit_bsr_count'    % ⭐ 감소 목표
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