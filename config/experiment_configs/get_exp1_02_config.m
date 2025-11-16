function exp_config = get_exp1_02_config()
% GET_EXP1_02_CONFIG: Experiment 1-2 설정 (L_cell, ρ 2D 맵)
%
% Research Question: 
%   (L_cell, ρ) 평면에서 비포화/임계/초과 부하 영역을 어떻게 구분하는가?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp1_2_2d_map';
    exp_config.phase = 1;
    exp_config.description = '(L_cell, ρ) 2D 맵 - 비포화/임계 부하 경계';
    
    %% =====================================================================
    %  스윕 변수 (2D)
    %  =====================================================================
    
    % 변수 1: L_cell (셀 평균 로드)
    exp_config.sweep_var = 'L_cell';
    exp_config.sweep_range = [0.3, 0.4, 0.5, 0.6, 0.7];
    % exp_config.sweep_range = [0.3, 0.7];

    
    % 변수 2: rho (Burst 비율)
    exp_config.sweep_var2 = 'rho';
    exp_config.sweep_range2 = [0.3, 0.5, 0.7, 0.9];
    % exp_config.sweep_range2 = [0.3, 0.9];
    

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
    exp_config.fixed.mu_on = 0.05;     % 50ms On period (고정)
    % rho는 스윕 변수이므로 여기서 설정하지 않음
    % mu_off는 recompute_pareto_lambda에서 자동 계산됨

    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;  % Exp 1-1과 동일
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
end