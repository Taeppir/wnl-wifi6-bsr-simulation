function exp_config = get_exp3_02_config()
    %% Phase 3-2: 트래픽 다양성 검증
    % Sweet Spot 조건(L=0.30, RA=2, STAs=5)에서
    % 트래픽 파라미터(rho, mu_on) 변화에 따른 v3 효과 탐색
    
    % Schemes
    exp_config.schemes = [0, 3];
    exp_config.scheme_names = {'Baseline', 'v3-EMA'};
    
    % Sweep 변수 1: rho (ON period 비율)
    exp_config.sweep_var1 = 'rho';
    exp_config.sweep_range1 = [0.3, 0.5, 0.7];
    
    % Sweep 변수 2: mu_on (burst rate)
    exp_config.sweep_var2 = 'mu_on';
    exp_config.sweep_range2 = [0.02, 0.05, 0.10];
    
    % 반복 횟수
    exp_config.num_runs = 5;
    
    % 고정 파라미터 (Sweet Spot 조건)
    exp_config.fixed = struct(...
        'L_cell', 0.30, ...           % Sweet Spot
        'numRU_RA', 1, ...            % Sweet Spot
        'num_STAs', 20, ...            % Sweet Spot
        'numRU_SA', 8, ...
        'alpha', 1.5, ...             % Pareto 형태 고정
        'v3_EMA_alpha', 0.1, ...
        'v3_max_reduction', 0.7, ...
        'v3_sensitivity', 1e-4, ...
        'simulation_time', 10, ...
        'warmup_time', 0, ...
        'verbose', false, ...
        'collect_bsr_trace', false ...
    );
    
    % 메타 정보
    exp_config.total_simulations = length(exp_config.schemes) * ...
        length(exp_config.sweep_range1) * ...
        length(exp_config.sweep_range2) * ...
        exp_config.num_runs;
    
    exp_config.description = '트래픽 다양성 검증 (Sweet Spot 조건)';
end