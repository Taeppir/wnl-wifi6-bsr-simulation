function exp_config = get_exp2_02_config()
% GET_EXP2_02_CONFIG: Experiment 2-2 설정 (Scheme 1 파라미터 최적화)
%
% Research Question:
%   Scheme 1(Fixed Reduction)의 최적 파라미터는?
%   - fixed_reduction_bytes
%   - sensitivity
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp2_2_scheme1_optimization';
    exp_config.phase = 2;
    exp_config.description = 'Scheme 1 파라미터 최적화';
    
    %% =====================================================================
    %  스윕 변수 (2D)
    %  =====================================================================
    
    % 변수 1: fixed_reduction_bytes
    exp_config.sweep_var = 'v1_fixed_reduction_bytes';
    exp_config.sweep_range = [100, 500, 1000];
    
    % 변수 2: sensitivity
    exp_config.sweep_var2 = 'v1_sensitivity';
    exp_config.sweep_range2 = [0.5, 1.0, 1.5];
    
    %% =====================================================================
    %  고정 파라미터
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Scheme 선택
    exp_config.fixed.scheme_id = 1;  % Scheme 1
    
    % Network
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % 대표 시나리오 (Mid-load)
    exp_config.fixed.L_cell = 0.35;
    exp_config.fixed.rho = 0.7;
    exp_config.fixed.mu_on = 0.05;
    exp_config.fixed.alpha = 1.5;
    
    % 공통 파라미터
    exp_config.fixed.burst_threshold = 1000;
    exp_config.fixed.reduction_threshold = 500;
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 2;
    
    %% =====================================================================
    %  비교 대상 (Baseline)
    %  =====================================================================
    
    exp_config.include_baseline = true;
    
end