function results = run_exp2_02(exp_config)
% RUN_EXP2_02: Experiment 2-02 커스텀 러너 (2D Threshold 스윕)
%
% 구조: reduction_threshold(4) × burst_threshold(3) × scheme(2) × runs(10)
%       = 240회 시뮬레이션
%
% 입력:
%   exp_config - get_exp2_02_config()에서 생성된 설정
%
% 출력:
%   results - 4D 결과 구조체 [n_red, n_burst, n_scheme, n_runs]

    fprintf('\n========================================\n');
    fprintf('  실험 시작: %s\n', exp_config.name);
    fprintf('========================================\n\n');
    
    %% =====================================================================
    %  1. 실험 설정 확인
    %  =====================================================================
    
    n_red = length(exp_config.sweep_range);      % reduction_threshold
    n_burst = length(exp_config.sweep_range2);   % burst_threshold
    n_schemes = length(exp_config.schemes);
    n_runs = exp_config.num_runs;
    
    total_sims = n_red * n_burst * n_schemes * n_runs;
    
    fprintf('[실험 설정]\n');
    fprintf('  목적: reduction_threshold × burst_threshold 2D 스윕\n');
    fprintf('  환경: %s (L_cell=%.2f)\n', exp_config.scenario.name, exp_config.scenario.L_cell);
    fprintf('  reduction_threshold: %d개 [', n_red);
    fprintf('%d ', exp_config.sweep_range);
    fprintf('] bytes\n');
    fprintf('  burst_threshold: %d개 [', n_burst);
    fprintf('%d ', exp_config.sweep_range2);
    fprintf('] bytes\n');
    fprintf('  스킴: %d개 (Baseline, v3)\n', n_schemes);
    fprintf('  반복 횟수: %d\n', n_runs);
    fprintf('  총 시뮬레이션: %d회\n', total_sims);
    fprintf('  예상 소요 시간: ~%.0f분\n\n', total_sims * 3 / 60);
    
    %% =====================================================================
    %  2. 결과 저장용 구조체 초기화
    %  =====================================================================
    
    metric_names = exp_config.metrics_to_collect;
    
    % 4D 배열: [reduction_threshold, burst_threshold, scheme, run]
    results_grid = struct();
    for i = 1:length(metric_names)
        metric = metric_names{i};
        results_grid.(metric) = nan(n_red, n_burst, n_schemes, n_runs);
    end
    
    %% =====================================================================
    %  3. 메인 루프
    %  =====================================================================
    
    sim_count = 0;
    tic_total = tic;
    seed_list = 1:n_runs;
    
    scenario = exp_config.scenario;
    
    for r = 1:n_red
        red_val = exp_config.sweep_range(r);
        
        for b = 1:n_burst
            burst_val = exp_config.sweep_range2(b);
            
            fprintf('[Grid %d/%d] red_thresh=%d, burst_thresh=%d\n', ...
                (r-1)*n_burst + b, n_red*n_burst, red_val, burst_val);
            
            for sc = 1:n_schemes
                scheme_id = exp_config.schemes(sc);
                scheme_name = exp_config.scheme_names{sc};
                
                fprintf('  %s: ', scheme_name);
                
                run_delays = zeros(1, n_runs);
                
                for run = 1:n_runs
                    sim_count = sim_count + 1;
                    
                    % ─────────────────────────────────────────────────
                    % 설정 생성
                    % ─────────────────────────────────────────────────
                    
                    cfg = config_default();
                    
                    % 고정 파라미터 적용
                    fixed_fields = fieldnames(exp_config.fixed);
                    for f = 1:length(fixed_fields)
                        field_name = fixed_fields{f};
                        cfg.(field_name) = exp_config.fixed.(field_name);
                    end
                    
                    % 시나리오 파라미터 (Low 환경)
                    cfg.L_cell = scenario.L_cell;
                    cfg.rho = scenario.rho;
                    cfg.mu_on = scenario.mu_on;
                    cfg.alpha = scenario.alpha;
                    
                    % 2D 스윕 변수
                    cfg.reduction_threshold = red_val;
                    cfg.burst_threshold = burst_val;
                    
                    % 스킴 설정
                    cfg.scheme_id = scheme_id;
                    
                    % Lambda 재계산
                    cfg = recompute_pareto_lambda(cfg);
                    
                    % 동일 시드 사용 (공정한 비교)
                    rng(seed_list(run));
                    
                    % ─────────────────────────────────────────────────
                    % 시뮬레이션 실행
                    % ─────────────────────────────────────────────────
                    
                    try
                        [sim_results, ~] = main_sim_v2(cfg);
                        
                        % 결과 저장
                        for m = 1:length(metric_names)
                            metric = metric_names{m};
                            if isfield(sim_results.summary, metric)
                                results_grid.(metric)(r, b, sc, run) = ...
                                    sim_results.summary.(metric);
                            end
                        end
                        
                        run_delays(run) = sim_results.summary.mean_delay_ms;
                        
                    catch ME
                        fprintf('X');
                        for m = 1:length(metric_names)
                            metric = metric_names{m};
                            results_grid.(metric)(r, b, sc, run) = NaN;
                        end
                        run_delays(run) = NaN;
                    end
                    
                end % run loop
                
                % 스킴별 요약
                mean_delay = mean(run_delays, 'omitnan');
                std_delay = std(run_delays, 'omitnan');
                fprintf('%.2f±%.2f ms\n', mean_delay, std_delay);
                
            end % scheme loop
            
        end % burst loop
        
        fprintf('\n');
        
    end % reduction loop
    
    %% =====================================================================
    %  4. 완료
    %  =====================================================================
    
    total_elapsed = toc(tic_total);
    
    fprintf('========================================\n');
    fprintf('  실험 완료\n');
    fprintf('========================================\n');
    fprintf('  총 소요 시간: %.1f분\n', total_elapsed / 60);
    fprintf('  시뮬레이션당 평균: %.2f초\n\n', total_elapsed / sim_count);
    
    %% =====================================================================
    %  5. 결과 패키징
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
        
        % 4차원(runs)에서 평균/표준편차 → 3D [red, burst, scheme]
        results.summary.mean.(metric) = mean(data, 4, 'omitnan');
        results.summary.std.(metric) = std(data, 0, 4, 'omitnan');
    end
    
    % 메타 정보 저장
    results.scenario = exp_config.scenario;
    results.reduction_values = exp_config.sweep_range;
    results.burst_values = exp_config.sweep_range2;
    results.scheme_names = exp_config.scheme_names;
    
end