function exp_config = get_exp1_00_config()
% GET_EXP1_00_CONFIG: Experiment 1-00 설정 (Baseline 환경별 성능 분석)
%
% 목적: 
%   기법 비교 실험 전, 저부하/중부하/고부하 환경에서의
%   Baseline(v0) 성능을 상세히 파악
%
% Research Question:
%   세 가지 부하 환경에서 Baseline의 지연, BSR 패턴, 
%   버퍼 상태가 어떻게 다른가?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp1_00_baseline_characterization';
    exp_config.phase = 1;
    exp_config.description = 'Baseline 환경별 성능 분석 (Low/Mid/High)';
    
    %% =====================================================================
    %  시나리오 정의 (3개 부하 환경)
    %  =====================================================================
    
    % 커스텀 러너 사용 (시나리오 기반)
    exp_config.use_custom_runner = true;
    
    % Scenario 1: Low-load (Unsaturated)
    exp_config.scenarios(1).name = 'Low';
    exp_config.scenarios(1).L_cell = 0.15;
    exp_config.scenarios(1).description = 'Unsaturated, Buffer Empty ~50%';
    
    % Scenario 2: Mid-load (경계)
    exp_config.scenarios(2).name = 'Mid';
    exp_config.scenarios(2).L_cell = 0.30;
    exp_config.scenarios(2).description = 'Buffer Empty ~30% 경계';
    
    % Scenario 3: High-load (Saturated)
    exp_config.scenarios(3).name = 'High';
    exp_config.scenarios(3).L_cell = 0.50;
    exp_config.scenarios(3).description = 'Saturated, 비교용';
    
    %% =====================================================================
    %  고정 파라미터 (모든 시나리오 공통)
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Scheme: Baseline only
    exp_config.fixed.scheme_id = 0;
    
    % Network
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Traffic (Pareto On-Off) - 지난 실험과 동일
    exp_config.fixed.alpha = 1.5;      % Pareto shape
    exp_config.fixed.rho = 0.5;        % On-state ratio (고정!)
    exp_config.fixed.mu_on = 0.05;     % 50ms On period (고정!)
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;  % 신뢰구간용
    
    %% =====================================================================
    %  수집할 메트릭 (상세)
    %  =====================================================================
    
    exp_config.metrics_to_collect = {
        % 지연 관련
        'mean_delay_ms'
        'p90_delay_ms'
        'p99_delay_ms'
        'std_delay_ms'
        
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
        'channel_utilization'
        'completion_rate'
        
        % 공평성
        'jain_index'
    };
    
end