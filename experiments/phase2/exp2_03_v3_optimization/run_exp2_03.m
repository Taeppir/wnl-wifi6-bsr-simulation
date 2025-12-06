function results = run_exp2_03(exp_config)
% RUN_EXP2_03: Experiment 2-03 커스텀 러너 (v3 핵심 파라미터 2D 스윕)
%
% [최적화] Baseline은 파라미터 무관하므로 1번만 실행
%
% 구조: 
%   - Baseline: 1 × runs (파라미터 무관)
%   - v3: EMA_alpha × max_reduction × runs
%
% 입력:
%   exp_config - get_exp2_03_config()에서 생성된 설정
%
% 출력:
%   results - 결과 구조체 [n_alpha, n_maxred, n_scheme, n_runs]

    fprintf('\n========================================\n');
    fprintf('  실험 시작: %s\n', exp_config.name);
    fprintf('========================================\n\n');
    
    %% =====================================================================
    %  1. 실험 설정 확인
    %  =====================================================================
    
    n_alpha = length(exp_config.sweep_range);       % EMA_alpha
    n_maxred = length(exp_config.sweep_range2);     % max_reduction
    n_schemes = length(exp_config.schemes);
    n_runs = exp_config.num_runs;
    
    % [최적화] 실제 시뮬레이션 횟수 계산
    % Baseline: n_runs (1번만)
    % v3: n_alpha × n_maxred × n_runs
    baseline_sims = n_runs;
    v3_sims = n_alpha * n_maxred * n_runs;
    total_sims = baseline_sims + v3_sims;
    
    % 기존 방식 대비 절감
    old_total = n_alpha * n_maxred * n_schemes * n_runs;
    savings = old_total - total_sims;
    
    fprintf('[실험 설정]\n');
    fprintf('  목적: v3 핵심 파라미터 최적화\n');
    fprintf('  환경: %s (L_cell=%.2f)\n', exp_config.scenario.name, exp_config.scenario.L_cell);
    fprintf('  EMA_alpha: %d개 [', n_alpha);
    fprintf('%.1f ', exp_config.sweep_range);
    fprintf(']\n');
    fprintf('  max_reduction: %d개 [', n_maxred);
    fprintf('%.1f ', exp_config.sweep_range2);
    fprintf(']\n');
    fprintf('  고정값: reduction_thresh=%d, burst_thresh=%d\n', ...
        exp_config.fixed.reduction_threshold, exp_config.fixed.burst_threshold);
    fprintf('  반복 횟수: %d\n', n_runs);
    fprintf('  [최적화] Baseline %d회 + v3 %d회 = 총 %d회\n', baseline_sims, v3_sims, total_sims);
    fprintf('  [최적화] 기존 대비 %d회 절감 (%.0f%% 감소)\n', savings, savings/old_total*100);
    fprintf('  예상 소요 시간: ~%.1f분\n\n', total_sims * 2 / 60);
    
    %% =====================================================================
    %  2. 결과 저장용 구조체 초기화
    %  =====================================================================
    
    metric_names = exp_config.metrics_to_collect;
    
    % 4D 배열: [alpha, maxred, scheme, run]
    % scheme 1 = Baseline, scheme 2 = v3
    results_grid = struct();
    for i = 1:length(metric_names)
        metric = metric_names{i};
        results_grid.(metric) = nan(n_alpha, n_maxred, n_schemes, n_runs);
    end
    
    %% =====================================================================
    %  3. Baseline 실행 (1번만!)
    %  =====================================================================
    
    fprintf('[Step 1/2] Baseline 실행 (%d회)\n', n_runs);
    
    sim_count = 0;
    tic_total = tic;
    seed_list = 1:n_runs;
    scenario = exp_config.scenario;
    
    % Baseline 결과 저장용
    baseline_results = struct();
    for i = 1:length(metric_names)
        metric = metric_names{i};
        baseline_results.(metric) = nan(1, n_runs);
    end
    
    baseline_delays = zeros(1, n_runs);
    
    fprintf('  v0: Baseline: ');
    
    for run = 1:n_runs
        sim_count = sim_count + 1;
        
        % 설정 생성
        cfg = config_default();
        
        % 고정 파라미터 적용
        fixed_fields = fieldnames(exp_config.fixed);
        for f = 1:length(fixed_fields)
            field_name = fixed_fields{f};
            cfg.(field_name) = exp_config.fixed.(field_name);
        end
        
        % 시나리오 파라미터
        cfg.L_cell = scenario.L_cell;
        cfg.rho = scenario.rho;
        cfg.mu_on = scenario.mu_on;
        cfg.alpha = scenario.alpha;
        
        % Baseline (scheme_id = 0)
        cfg.scheme_id = 0;
        
        % Lambda 재계산
        cfg = recompute_pareto_lambda(cfg);
        
        % 동일 시드 사용
        rng(seed_list(run));
        
        try
            [sim_results, ~] = main_sim_v2(cfg);
            
            % Baseline 결과 저장
            for mi = 1:length(metric_names)
                metric = metric_names{mi};
                if isfield(sim_results.summary, metric)
                    baseline_results.(metric)(run) = sim_results.summary.(metric);
                end
            end
            
            baseline_delays(run) = sim_results.summary.mean_delay_ms;
            fprintf('.');
            
        catch ME
            fprintf('X');
            baseline_delays(run) = NaN;
        end
        
        % [메모리 정리]
        clear sim_results cfg;
        java.lang.System.gc();  % Java 가비지 컬렉션
    end
    
    mean_baseline = mean(baseline_delays, 'omitnan');
    std_baseline = std(baseline_delays, 'omitnan');
    fprintf(' %.2f±%.2f ms\n\n', mean_baseline, std_baseline);
    
    % Baseline 결과를 모든 (alpha, maxred) 조합에 복사
    for a = 1:n_alpha
        for m = 1:n_maxred
            for mi = 1:length(metric_names)
                metric = metric_names{mi};
                results_grid.(metric)(a, m, 1, :) = baseline_results.(metric);
            end
        end
    end
    
    %% =====================================================================
    %  4. v3 실행 (파라미터 스윕)
    %  =====================================================================
    
    fprintf('[Step 2/2] v3 파라미터 스윕 (%d회)\n', v3_sims);
    
    for a = 1:n_alpha
        alpha_val = exp_config.sweep_range(a);
        
        for m = 1:n_maxred
            maxred_val = exp_config.sweep_range2(m);
            
            fprintf('  [%d/%d] alpha=%.1f, max_red=%.1f: ', ...
                (a-1)*n_maxred + m, n_alpha*n_maxred, alpha_val, maxred_val);
            
            run_delays = zeros(1, n_runs);
            
            for run = 1:n_runs
                sim_count = sim_count + 1;
                
                % 설정 생성
                cfg = config_default();
                
                % 고정 파라미터 적용
                fixed_fields = fieldnames(exp_config.fixed);
                for f = 1:length(fixed_fields)
                    field_name = fixed_fields{f};
                    cfg.(field_name) = exp_config.fixed.(field_name);
                end
                
                % 시나리오 파라미터
                cfg.L_cell = scenario.L_cell;
                cfg.rho = scenario.rho;
                cfg.mu_on = scenario.mu_on;
                cfg.alpha = scenario.alpha;
                
                % v3 파라미터
                cfg.v3_EMA_alpha = alpha_val;
                cfg.v3_max_reduction = maxred_val;
                
                % v3 (scheme_id = 3)
                cfg.scheme_id = 3;
                
                % Lambda 재계산
                cfg = recompute_pareto_lambda(cfg);
                
                % 동일 시드 사용 (Baseline과 동일 조건)
                rng(seed_list(run));
                
                try
                    [sim_results, ~] = main_sim_v2(cfg);
                    
                    % v3 결과 저장 (scheme index = 2)
                    for mi = 1:length(metric_names)
                        metric = metric_names{mi};
                        if isfield(sim_results.summary, metric)
                            results_grid.(metric)(a, m, 2, run) = ...
                                sim_results.summary.(metric);
                        end
                    end
                    
                    run_delays(run) = sim_results.summary.mean_delay_ms;
                    
                catch ME
                    fprintf('X');
                    run_delays(run) = NaN;
                end
                
                % [메모리 정리]
                clear sim_results cfg;
                
            end
            
            % v3 요약
            mean_v3 = mean(run_delays, 'omitnan');
            std_v3 = std(run_delays, 'omitnan');
            improvement = (1 - mean_v3 / mean_baseline) * 100;
            fprintf('%.2f±%.2f ms (%+.1f%%)\n', mean_v3, std_v3, improvement);
            
            % [체크포인트 저장] - 매 그리드 완료 시
            checkpoint_file = 'results/checkpoint_exp2_03.mat';
            save(checkpoint_file, 'results_grid', 'a', 'm', 'baseline_results', '-v7.3');
            
        end % maxred loop
        
        % [메모리 정리] - 매 alpha 완료 시
        java.lang.System.gc();
        pause(0.1);  % GC 시간 확보
        
    end % alpha loop
    
    %% =====================================================================
    %  5. 완료
    %  =====================================================================
    
    total_elapsed = toc(tic_total);
    
    fprintf('\n========================================\n');
    fprintf('  실험 완료\n');
    fprintf('========================================\n');
    fprintf('  총 소요 시간: %.1f분\n', total_elapsed / 60);
    fprintf('  시뮬레이션당 평균: %.2f초\n', total_elapsed / sim_count);
    fprintf('  [최적화] %d회 절감으로 %.1f분 단축!\n\n', savings, savings * 2 / 60);
    
    %% =====================================================================
    %  6. 결과 패키징
    %  =====================================================================
    
    results = struct();
    results.config = exp_config;
    results.raw_data = results_grid;
    
    % Summary: runs 차원에서 평균/표준편차
    results.summary = struct();
    results.summary.mean = struct();
    results.summary.std = struct();
    
    for i = 1:length(metric_names)
        metric = metric_names{i};
        data = results_grid.(metric);
        
        % 4차원(runs)에서 평균/표준편차 → 3D [alpha, maxred, scheme]
        results.summary.mean.(metric) = mean(data, 4, 'omitnan');
        results.summary.std.(metric) = std(data, 0, 4, 'omitnan');
    end
    
    % 메타 정보 저장
    results.scenario = exp_config.scenario;
    results.alpha_values = exp_config.sweep_range;
    results.maxred_values = exp_config.sweep_range2;
    results.scheme_names = exp_config.scheme_names;
    
    % Baseline 정보 추가
    results.baseline = struct();
    results.baseline.mean_delay = mean_baseline;
    results.baseline.std_delay = std_baseline;
    
end