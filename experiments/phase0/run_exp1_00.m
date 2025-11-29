function results = run_exp1_00(exp_config)
% RUN_EXP1_00: Experiment 1-00 커스텀 러너
%
% 입력:
%   exp_config - get_exp1_00_config()에서 생성된 설정
%
% 출력:
%   results - 결과 구조체 [n_scenarios × n_metrics × n_runs]

    fprintf('\n========================================\n');
    fprintf('  실험 시작: %s\n', exp_config.name);
    fprintf('========================================\n\n');
    
    %% =====================================================================
    %  1. 실험 설정 확인
    %  =====================================================================
    
    n_scenarios = length(exp_config.scenarios);
    n_runs = exp_config.num_runs;
    
    fprintf('[실험 설정]\n');
    fprintf('  목적: Baseline 환경별 상세 성능 분석\n');
    fprintf('  시나리오: %d개\n', n_scenarios);
    for s = 1:n_scenarios
        fprintf('    - %s: L_cell=%.2f (%s)\n', ...
            exp_config.scenarios(s).name, ...
            exp_config.scenarios(s).L_cell, ...
            exp_config.scenarios(s).description);
    end
    fprintf('  반복 횟수: %d\n', n_runs);
    fprintf('  고정 파라미터: rho=%.1f, mu_on=%.2f, alpha=%.1f\n', ...
        exp_config.fixed.rho, exp_config.fixed.mu_on, exp_config.fixed.alpha);
    fprintf('  총 시뮬레이션: %d회\n\n', n_scenarios * n_runs);
    
    %% =====================================================================
    %  2. 결과 저장용 구조체 초기화
    %  =====================================================================
    
    metric_names = exp_config.metrics_to_collect;
    
    % 2D 배열 초기화: [scenario, run]
    results_grid = struct();
    for i = 1:length(metric_names)
        metric = metric_names{i};
        results_grid.(metric) = nan(n_scenarios, n_runs);
    end
    
    %% =====================================================================
    %  3. 메인 루프 (시나리오 × Run)
    %  =====================================================================
    
    total_sims = n_scenarios * n_runs;
    sim_count = 0;
    tic_total = tic;
    
    % 난수 시드 리스트
    seed_list = 1:n_runs;
    
    for s = 1:n_scenarios
        scenario = exp_config.scenarios(s);
        
        fprintf('[시나리오 %d/%d: %s (L_cell=%.2f)]\n', ...
            s, n_scenarios, scenario.name, scenario.L_cell);
        
        % ─────────────────────────────────────────────────────────
        % 반복 실행
        % ─────────────────────────────────────────────────────────
        
        for run = 1:n_runs
            sim_count = sim_count + 1;
            
            if mod(run, max(1, floor(n_runs/5))) == 1 || run == n_runs
                fprintf('  Run %2d/%d... ', run, n_runs);
            end
            
            % ─────────────────────────────────────────────────────
            % 설정 생성
            % ─────────────────────────────────────────────────────
            
            cfg = config_default();
            
            % 고정 파라미터 적용
            fixed_fields = fieldnames(exp_config.fixed);
            for f = 1:length(fixed_fields)
                field_name = fixed_fields{f};
                cfg.(field_name) = exp_config.fixed.(field_name);
            end
            
            % 시나리오 파라미터 적용
            cfg.L_cell = scenario.L_cell;
            
            % Lambda 재계산
            cfg = recompute_pareto_lambda(cfg);
            
            % 난수 시드 설정
            rng(seed_list(run));
            
            % ─────────────────────────────────────────────────────
            % 시뮬레이션 실행
            % ─────────────────────────────────────────────────────
            
            try
                [sim_results, ~] = main_sim_v2(cfg);
                
                % 결과 저장
                for m = 1:length(metric_names)
                    metric = metric_names{m};
                    if isfield(sim_results.summary, metric)
                        results_grid.(metric)(s, run) = sim_results.summary.(metric);
                    end
                end
                
                if mod(run, max(1, floor(n_runs/5))) == 0 || run == n_runs
                    fprintf('완료 (delay=%.1fms)\n', sim_results.summary.mean_delay_ms);
                end
                
            catch ME
                fprintf('💥 실패!\n');
                fprintf('    에러: %s\n', ME.message);
                
                % NaN으로 채우기
                for m = 1:length(metric_names)
                    metric = metric_names{m};
                    results_grid.(metric)(s, run) = NaN;
                end
            end
            
        end % run loop
        
        fprintf('\n');
        
    end % scenario loop
    
    %% =====================================================================
    %  4. 완료
    %  =====================================================================
    
    total_elapsed = toc(tic_total);
    
    fprintf('========================================\n');
    fprintf('  실험 완료\n');
    fprintf('========================================\n');
    fprintf('  총 소요 시간: %.1f분\n', total_elapsed / 60);
    fprintf('  시뮬레이션당 평균: %.2f초\n\n', total_elapsed / total_sims);
    
    %% =====================================================================
    %  5. 결과 패키징
    %  =====================================================================
    
    results = struct();
    results.config = exp_config;
    results.raw_data = results_grid;
    
    % Summary 계산 (runs 차원에서 평균/표준편차)
    results.summary = struct();
    results.summary.mean = struct();
    results.summary.std = struct();
    
    for i = 1:length(metric_names)
        metric = metric_names{i};
        data = results_grid.(metric);
        
        % 2차원(runs)에서 평균/표준편차
        results.summary.mean.(metric) = mean(data, 2, 'omitnan');
        results.summary.std.(metric) = std(data, 0, 2, 'omitnan');
    end
    
    % 시나리오 이름 저장
    results.scenario_names = {exp_config.scenarios.name};
    results.scenario_L_cells = [exp_config.scenarios.L_cell];
    
end