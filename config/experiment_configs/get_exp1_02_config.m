function exp_config = get_exp1_02_config()
% GET_EXP1_02_CONFIG: Experiment 1-2 설정 (버스트 강도 스윕)
%
% Research Question: 트래픽 burstiness(rho, alpha)가 UORA 경쟁에 미치는 영향
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% 1. 기본 정보
    exp_config.name = 'exp1_2_burst_sweep';
    exp_config.phase = 1;
    exp_config.description = '트래픽 버스트 강도(rho, alpha) 2D 스윕';
    
    %% 2. 스윕 변수 (2D)
    
    % 스윕 변수 1 (Y축)
    exp_config.sweep_var = 'rho';
    exp_config.sweep_range = [0.3, 0.5, 0.7, 0.9];
    
    % 스윕 변수 2 (X축)
    exp_config.sweep_var2 = 'alpha';
    exp_config.sweep_range2 = [1.2, 1.5, 1.8, 2.1];
    
    %% 3. 고정 파라미터
    exp_config.fixed = struct();
    
    exp_config.fixed.scheme_id = 0;  % Baseline
    exp_config.fixed.num_STAs = 20;
    
    % ⭐ [핵심] 부하(L_cell)는 0.3로 고정
    exp_config.fixed.L_cell = 0.3;
    
    % On-period는 50ms로 고정 (mu_off는 rho에 따라 자동 계산됨)
    exp_config.fixed.mu_on = 0.05;
    
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% 4. 반복 횟수
    exp_config.num_runs = 10;
    
end