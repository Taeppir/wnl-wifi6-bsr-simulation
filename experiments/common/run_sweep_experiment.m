function results_grid = run_sweep_experiment(exp_config)
% RUN_SWEEP_EXPERIMENT: 범용 스윕 실험 실행기
%
% 입력:
%   exp_config - 실험 설정 구조체
%     .name            : 실험 이름 (예: 'exp1_1_load_sweep')
%     .sweep_var       : 스윕 변수 이름 (예: 'L_cell')
%     .sweep_range     : 스윕 범위 (예: [0.1, 0.2, ..., 0.9])
%     .sweep_var2      : (선택) 2D 스윕 변수 이름
%     .sweep_range2    : (선택) 2D 스윕 범위
%     .fixed           : 고정 파라미터 구조체
%     .num_runs        : 반복 횟수
%
% 출력:
%   results_grid - 결과 구조체
%     .mean_delay_ms      : sweep_dim1 × sweep_dim2 × runs
%     .p90_delay_ms       : ...
%     .collision_rate     : ...
%     ... (모든 summary 지표)

    fprintf('\n========================================\n');
    fprintf('  실험 시작: %s\n', exp_config.name);
    fprintf('========================================\n\n');
    
    %% =====================================================================
    %  1. 실험 설정 확인
    %  =====================================================================
    
    % 1D or 2D 스윕?
    is_2d = isfield(exp_config, 'sweep_var2');
    
    n1 = length(exp_config.sweep_range);
    if is_2d
        n2 = length(exp_config.sweep_range2);
        fprintf('[실험 설정]\n');
        fprintf('  타입: 2D 스윕\n');
        fprintf('  변수 1: %s (%d 값)\n', exp_config.sweep_var, n1);
        fprintf('  변수 2: %s (%d 값)\n', exp_config.sweep_var2, n2);
        fprintf('  Grid 크기: %d × %d\n', n1, n2);
        fprintf('  반복 횟수: %d\n', exp_config.num_runs);
        fprintf('  총 시뮬레이션: %d회\n\n', n1 * n2 * exp_config.num_runs);
    else
        n2 = 1;
        fprintf('[실험 설정]\n');
        fprintf('  타입: 1D 스윕\n');
        fprintf('  변수: %s (%d 값)\n', exp_config.sweep_var, n1);
        fprintf('  반복 횟수: %d\n', exp_config.num_runs);
        fprintf('  총 시뮬레이션: %d회\n\n', n1 * exp_config.num_runs);
    end
    
    %% =====================================================================
    %  2. 결과 저장용 구조체 초기화
    %  =====================================================================
    
    % 측정할 지표 목록 (summary에서 추출)
    metric_names = {
        'mean_delay_ms'
        'p90_delay_ms'
        'p99_delay_ms'
        'std_delay_ms'
        'collision_rate'
        'success_rate'
        'implicit_bsr_ratio'
        'throughput_mbps'
        'channel_utilization'
        'completion_rate'
        'jain_index'
        'mean_uora_delay_ms'
        'mean_sched_delay_ms'
        'mean_overhead_delay_ms'
        'mean_frag_delay_ms'
    };
    
    results_grid = struct();
    
    for i = 1:length(metric_names)
        metric = metric_names{i};
        if is_2d
            results_grid.(metric) = nan(n1, n2, exp_config.num_runs);
        else
            results_grid.(metric) = nan(n1, exp_config.num_runs);
        end
    end
    
    %% =====================================================================
    %  3. 메인 루프 (스윕 실행)
    %  =====================================================================
    
    total_sims = n1 * n2 * exp_config.num_runs;
    sim_count = 0;
    tic_total = tic;
    
    % 난수 시드 리스트
    seed_list = 1:exp_config.num_runs;
    
    for i1 = 1:n1
        val1 = exp_config.sweep_range(i1);
        
        for i2 = 1:n2
            if is_2d
                val2 = exp_config.sweep_range2(i2);
                fprintf('[Grid %d/%d] %s=%.2f, %s=%.2f\n', ...
                    (i1-1)*n2 + i2, n1*n2, ...
                    exp_config.sweep_var, val1, ...
                    exp_config.sweep_var2, val2);
            else
                fprintf('[조건 %d/%d] %s=%.2f\n', i1, n1, exp_config.sweep_var, val1);
            end
            
            % ─────────────────────────────────────────────────────────
            % 반복 실행
            % ─────────────────────────────────────────────────────────
            
            for run = 1:exp_config.num_runs
                sim_count = sim_count + 1;
                
                % 진행률 표시 (간결)
                if mod(run, max(1, floor(exp_config.num_runs/3))) == 1
                    fprintf('  Run %2d/%d... ', run, exp_config.num_runs);
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
                
                % 스윕 변수 적용
                cfg.(exp_config.sweep_var) = val1;
                if is_2d
                    cfg.(exp_config.sweep_var2) = val2;
                end
                
                % Lambda 재계산 (부하 관련 파라미터 변경 시)
                if ismember(exp_config.sweep_var, {'L_cell', 'rho', 'mu_on', 'mu_off'}) || ...
                   (is_2d && ismember(exp_config.sweep_var2, {'L_cell', 'rho', 'mu_on', 'mu_off'}))
                    cfg = recompute_pareto_lambda(cfg);
                end
                
                % 난수 시드 설정
                rng(seed_list(run));
                
                % ─────────────────────────────────────────────────────
                % 시뮬레이션 실행
                % ─────────────────────────────────────────────────────
                
                try
                    [results, ~] = main_sim_v2(cfg);
                    
                    % 결과 저장
                    for m = 1:length(metric_names)
                        metric = metric_names{m};
                        if isfield(results.summary, metric)
                            if is_2d
                                results_grid.(metric)(i1, i2, run) = results.summary.(metric);
                            else
                                results_grid.(metric)(i1, run) = results.summary.(metric);
                            end
                        end
                    end
                    
                    if mod(run, max(1, floor(exp_config.num_runs/3))) == 0
                        fprintf('완료\n');
                    end
                    
                catch ME
                    fprintf('💥 실패!\n');
                    fprintf('    에러: %s\n', ME.message);
                    if ~isempty(ME.stack)
                        fprintf('    위치: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                    end
                    
                    % NaN으로 채우기
                    for m = 1:length(metric_names)
                        metric = metric_names{m};
                        if is_2d
                            results_grid.(metric)(i1, i2, run) = NaN;
                        else
                            results_grid.(metric)(i1, run) = NaN;
                        end
                    end
                end
                
                % ─────────────────────────────────────────────────────
                % 진행률 업데이트
                % ─────────────────────────────────────────────────────
                
                if mod(sim_count, 10) == 0
                    elapsed = toc(tic_total);
                    avg_time = elapsed / sim_count;
                    remaining = (total_sims - sim_count) * avg_time;
                    fprintf('  [진행률: %d/%d (%.1f%%), 남은 시간: ~%.1f분]\n', ...
                        sim_count, total_sims, 100*sim_count/total_sims, remaining/60);
                end
                
            end % run loop
            
            fprintf('\n');
            
        end % i2 loop
    end % i1 loop
    
    %% =====================================================================
    %  4. 완료
    %  =====================================================================
    
    total_elapsed = toc(tic_total);
    
    fprintf('========================================\n');
    fprintf('  실험 완료\n');
    fprintf('========================================\n');
    fprintf('  총 소요 시간: %.1f분\n', total_elapsed / 60);
    fprintf('  시뮬레이션당 평균: %.2f초\n\n', total_elapsed / total_sims);
    
end