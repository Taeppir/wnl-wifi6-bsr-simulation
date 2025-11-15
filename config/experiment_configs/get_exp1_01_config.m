function exp_config = get_exp1_01_config()
% GET_EXP1_1_CONFIG: Experiment 1-1 설정 (트래픽 부하 스윕)
%
% Research Question: 네트워크 부하가 증가하면 UORA 경쟁과 큐잉 지연이 어떻게 변하는가?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp1_1_load_sweep';
    exp_config.phase = 1;
    exp_config.description = '트래픽 부하(L_cell) 스윕';
    
    %% =====================================================================
    %  스윕 변수
    %  =====================================================================
    
    exp_config.sweep_var = 'L_cell';
    exp_config.sweep_range = [0.1, 0.15,  0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5];
    
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
    exp_config.fixed.alpha = 1.5;      % Pareto shape
    exp_config.fixed.rho = 0.7;        % On-state ratio
    exp_config.fixed.mu_on = 0.05;     % 50ms On period

    exp_config.fixed.mu_off = exp_config.fixed.mu_on * (1 - exp_config.fixed.rho) / exp_config.fixed.rho;
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
end