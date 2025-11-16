function exp_config = get_exp1_03_config()
% GET_EXP1_03_CONFIG: Experiment 1-3 설정 (ON-length 스윕)
%
% Research Question: 
%   Burst 길이(μ_on)가 Explicit BSR 발생 패턴과 지연에 미치는 영향은?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp1_3_on_length_sweep';
    exp_config.phase = 1;
    exp_config.description = 'ON-length(μ_on) 스윕 - Burst 길이 영향';
    
    %% =====================================================================
    %  스윕 변수 (2D)
    %  =====================================================================
    
    % 변수 1: μ_on (Burst 길이)
    exp_config.sweep_var = 'mu_on';
    exp_config.sweep_range = [0.01, 0.05, 0.1, 0.3, 0.5];  % 초 단위
    % exp_config.sweep_range = [0.01, 0.1];  % 초 단위

    
    % 변수 2: L_cell (부하 수준)
    exp_config.sweep_var2 = 'L_cell';
    exp_config.sweep_range2 = [0.15, 0.3, 0.5];  % Mid, High-unsat
    
    %% =====================================================================
    %  고정 파라미터
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Scheme
    exp_config.fixed.scheme_id = 0;  % Baseline
    
    % Network
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Traffic (Pareto On-Off)
    exp_config.fixed.alpha = 1.5;      % Pareto shape (고정)
    exp_config.fixed.rho = 0.5;        % Burst ratio (고정)
    % mu_on은 스윕 변수
    % mu_off는 recompute_pareto_lambda에서 자동 계산됨

    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
    %% =====================================================================
    %  메타 정보 (분석용)
    %  =====================================================================
    
    % μ_on별 예상 사이클 수 (참고용, ρ=0.7 기준)
    exp_config.meta.expected_cycles = [
        0.01, 714;   % ~714 cycles in 10s
        0.05, 140;   % ~140 cycles
        0.15, 47;    % ~47 cycles
        0.5,  14     % ~14 cycles
    ];
    
end