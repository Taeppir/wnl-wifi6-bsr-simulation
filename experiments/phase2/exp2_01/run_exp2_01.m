function results = run_exp2_01(exp_config)
% RUN_EXP2_01: Experiment 2-1 커스텀 러너
%
% 입력:
%   exp_config - get_exp2_01_config()에서 생성된 설정
%
% 출력:
%   results - 3D 결과 구조체 [n_scenarios, n_schemes, n_runs]

    fprintf('\n========================================\n');
    fprintf('  실험 시작: %s\n', exp_config.name);
    fprintf('========================================\n\n');
    
    %% =====================================================================
    %  1. 실험 설정 확인
    %  =====================================================================
    
    n_scenarios = length(exp_config.scenarios);
    n_schemes = length(exp_config.schemes);
    n_runs = exp_config.num_runs;
    
    fprintf('[실험 설정]\n');
    fprintf('  목적: T_uora 감소를 통한 큐잉 지연 개선\n');
    fprintf('  시나리오: %d개\n', n_scenarios);
    for s = 1:n_scenarios
        fprintf('    - %s: L_cell=%.2f (rho=%.1f, mu_on=%.2f)\n', ...
            exp_config.scenarios(s).name, ...
            exp_config.scenarios(s).L_cell, ...
            exp_config.scenarios(s).rho, ...
            exp_config.scenarios(s).mu_on);
    end
    fprintf('  스킴: %d개\n', n_schemes);
    for sc = 1:n_schemes
        fprintf('    - %s\n', exp_config.scheme_names{sc});
    end
    fprintf('  반복 횟수: %d\n', n_runs);
    fprintf('  총 시뮬레이션: %d회\n\n', n_scenarios * n_schemes * n_runs);
    
    %% =====================================================================
    %  2. 결과 저장용 구조체 초기화
    %  =====================================================================
    
    metric_names = exp_config.metrics_to_collect;
    
    % 3D 배열 초기화: [scenario, scheme, run]
    results_grid = struct();
    for i = 1:length(metric_names)
        metric = metric_names{i};
        results_grid.(metric) = nan(n_scenarios, n_schemes, n_runs);
    end
    
    %% =====================================================================
    %  3. 메인 루프 (시나리오 × 스킴 × Run)
    %  =====================================================================
    
    total_sims = n_scenarios * n_schemes * n_runs;
    sim_count = 0;
    tic_total = tic;
    
    % 난수 시드 리스트 (모든 시나리오/스킴에서 동일 시드 사용)
    seed_list = 1:n_runs;
    
    for s = 1:n_scenarios
        scenario = exp_config.scenarios(s);
        
        fprintf('[시나리오 %d/%d: %s (L_cell=%.2f)]\n', ...
            s, n_scenarios, scenario.name, scenario.L_cell);
        
        for scheme_idx = 1:n_schemes
            scheme_id = exp_config.schemes(scheme_idx);
            scheme_name = exp_config.scheme_names{scheme_idx};
            
            fprintf('  [스킴 %d/%d: %s]\n', scheme_idx, n_schemes, scheme_name);
            
            % ─────────────────────────────────────────────────────────
            % 반복 실행
            % ─────────────────────────────────────────────────────────
            
            run_delays = zeros(1, n_runs);  % 진행 상황 출력용
            
            for run = 1:n_runs
                sim_count = sim_count + 1;
                
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
                cfg.rho = scenario.rho;
                cfg.mu_on = scenario.mu_on;
                cfg.alpha = scenario.alpha;
                
                % 스킴 설정
                cfg.scheme_id = scheme_id;
                
                % Lambda 재계산
                cfg = recompute_pareto_lambda(cfg);
                
                % ⭐ 난수 시드 설정 (공정한 비교를 위해 동일 시드 사용)
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
                            results_grid.(metric)(s, scheme_idx, run) = ...
                                sim_results.summary.(metric);
                        end
                    end
                    
                    run_delays(run) = sim_results.summary.mean_delay_ms;
                    
                catch ME
                    fprintf('    💥 Run %d 실패: %s\n', run, ME.message);
                    
                    % NaN으로 채우기
                    for m = 1:length(metric_names)
                        metric = metric_names{m};
                        results_grid.(metric)(s, scheme_idx, run) = NaN;
                    end
                    run_delays(run) = NaN;
                end
                
            end % run loop
            
            % 스킴별 요약 출력
            mean_delay = mean(run_delays, 'omitnan');
            std_delay = std(run_delays, 'omitnan');
            fprintf('    → 평균 지연: %.2f ± %.2f ms\n', mean_delay, std_delay);
            
        end % scheme loop
        
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
        
        % 3차원(runs)에서 평균/표준편차
        results.summary.mean.(metric) = mean(data, 3, 'omitnan');
        results.summary.std.(metric) = std(data, 0, 3, 'omitnan');
    end
    
    % 시나리오/스킴 이름 저장 (분석용)
    results.scenario_names = {exp_config.scenarios.name};
    results.scenario_L_cells = [exp_config.scenarios.L_cell];
    results.scheme_names = exp_config.scheme_names;
    
end