function exp_config = get_exp3_03_config()
    %% Phase 3-3: v3 파라미터 최적화
    % 최적 환경(L=0.15, RA=2, STAs=20, rho=0.3, mu=0.05)에서
    % v3 파라미터 재튜닝
    
    % Schemes
    exp_config.schemes = [0, 3];
    exp_config.scheme_names = {'Baseline', 'v3-EMA'};
    
    % Sweep 변수 1: v3_EMA_alpha (EMA 평활 계수)
    exp_config.sweep_var1 = 'v3_EMA_alpha';
    exp_config.sweep_range1 = [0.05, 0.1, 0.2, 0.3];
    
    % Sweep 변수 2: v3_max_reduction (최대 감소율)
    exp_config.sweep_var2 = 'v3_max_reduction';
    exp_config.sweep_range2 = [0.5, 0.7, 0.9];
    
    % 반복 횟수
    exp_config.num_runs = 5;
    
    % 고정 파라미터 (Phase 3-2-v4 최적 조건)
    exp_config.fixed = struct(...
        'L_cell', 0.30, ...           % 최적 부하
        'numRU_RA', 1, ...            % 중간 경쟁
        'num_STAs', 20, ...           % 현실적 단말 수
        'numRU_SA', 8, ...
        'rho', 0.3, ...               % 최적 트래픽
        'mu_on', 0.02, ...            % 최적 burst
        'alpha', 1.5, ...
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
    
    exp_config.description = 'v3 파라미터 최적화 (EMA_alpha × max_reduction)';
end