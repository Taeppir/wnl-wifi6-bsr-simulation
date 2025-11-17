function exp_config = get_exp2_03_config()
% GET_EXP2_03_CONFIG: Experiment 2-3 설정 (Scheme 2 파라미터 최적화)

    exp_config = struct();
    
    exp_config.name = 'exp2_3_scheme2_optimization';
    exp_config.phase = 2;
    exp_config.description = 'Scheme 2 파라미터 최적화';
    
    % 변수 1: max_reduction
    exp_config.sweep_var = 'v2_max_reduction';
    exp_config.sweep_range = [0.3, 0.5, 0.7, 0.9];
    
    % 변수 2: sensitivity
    exp_config.sweep_var2 = 'v2_sensitivity';
    exp_config.sweep_range2 = [0.5, 0.7, 1.0, 1.3, 1.5];
    
    exp_config.fixed = struct();
    exp_config.fixed.scheme_id = 2;  % Scheme 2
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % 대표 시나리오 (Mid-load)
    exp_config.fixed.L_cell = 0.35;
    exp_config.fixed.rho = 0.7;
    exp_config.fixed.mu_on = 0.05;
    exp_config.fixed.alpha = 1.5;
    
    exp_config.fixed.burst_threshold = 1000;
    exp_config.fixed.reduction_threshold = 500;
    
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    exp_config.num_runs = 10;
    exp_config.include_baseline = true;
end