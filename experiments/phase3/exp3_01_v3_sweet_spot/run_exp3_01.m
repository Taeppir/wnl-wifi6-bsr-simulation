%% run_exp3_01.m
% Experiment 3-1: v3 Sweet Spot 탐색 (Baseline vs v3 비교)
%
% 실행:
%   >> cd experiments/phase3/exp3_01_v3_sweet_spot
%   >> run_exp3_01

clear; close all; clc;

%% =====================================================================
%  1. 초기화
%  =====================================================================

fprintf('========================================\n');
fprintf('  Experiment 3-1: v3 Sweet Spot 탐색\n');
fprintf('  Baseline vs v3 비교\n');
fprintf('========================================\n\n');

% 실험 설정 로드
exp_config = get_exp3_01_config();

fprintf('[실험 정보]\n');
fprintf('  Schemes: %s\n', mat2str(exp_config.schemes));
fprintf('  총 실행: %d회\n', exp_config.total_simulations);
fprintf('  설명: %s\n\n', exp_config.description);

% 결과 저장 디렉토리
results_dir = '../../../results/phase3/exp3_01';
subdirs = {'mat', 'figures', 'csv'};
for i = 1:length(subdirs)
    subdir = fullfile(results_dir, subdirs{i});
    if ~exist(subdir, 'dir')
        mkdir(subdir);
    end
end

%% =====================================================================
%  2. 파라미터 추출
%  =====================================================================

schemes = exp_config.schemes;
L_cell_range = exp_config.sweep_range1;
numRU_RA_range = exp_config.sweep_range2;
num_STAs_range = exp_config.sweep_range3;

n_schemes = length(schemes);
n_L = length(L_cell_range);
n_RA = length(numRU_RA_range);
n_STA = length(num_STAs_range);
n_runs = exp_config.num_runs;

fprintf('[스윕 범위]\n');
fprintf('  Schemes: [%s]\n', sprintf('%d ', schemes));
fprintf('  L_cell: [%s]\n', sprintf('%.2f ', L_cell_range));
fprintf('  numRU_RA: [%s]\n', sprintf('%d ', numRU_RA_range));
fprintf('  num_STAs: [%s]\n', sprintf('%d ', num_STAs_range));
fprintf('  반복: %d회\n\n', n_runs);

%% =====================================================================
%  3. 결과 저장 구조체 초기화
%  =====================================================================

metrics_list = {
    'mean_delay_ms'
    'p90_delay_ms'
    'p99_delay_ms'
    'collision_rate'
    'implicit_bsr_ratio'
    'mean_uora_delay_ms'
    'throughput_mbps'
    'completion_rate'
};

% 5D 배열: (scheme, L_cell, numRU_RA, num_STAs, runs)
results_5d = struct();
for m = 1:length(metrics_list)
    metric_name = metrics_list{m};
    results_5d.(metric_name) = nan(n_schemes, n_L, n_RA, n_STA, n_runs);
end

%% =====================================================================
%  4. 메인 실험 루프
%  =====================================================================

total_sims = n_schemes * n_L * n_RA * n_STA * n_runs;
sim_count = 0;
tic_total = tic;

fprintf('========================================\n');
fprintf('  실험 시작\n');
fprintf('========================================\n\n');

for i_scheme = 1:n_schemes
    scheme_id = schemes(i_scheme);
    scheme_name = exp_config.scheme_names{i_scheme};
    
    fprintf('════════════════════════════════════════\n');
    fprintf('  정책: %s (ID=%d)\n', scheme_name, scheme_id);
    fprintf('════════════════════════════════════════\n\n');
    
    for i_L = 1:n_L
        L_cell = L_cell_range(i_L);
        
        for i_RA = 1:n_RA
            numRU_RA = numRU_RA_range(i_RA);
            
            for i_STA = 1:n_STA
                num_STAs = num_STAs_range(i_STA);
                
                fprintf('  [%s] L=%.2f, RA=%d, STAs=%d\n', ...
                    scheme_name, L_cell, numRU_RA, num_STAs);
                
                for run = 1:n_runs
                    sim_count = sim_count + 1;
                    
                    fprintf('    Run %d/%d... ', run, n_runs);
                    tic_run = tic;
                    
                    % ─────────────────────────────────────────
                    % 설정 생성
                    % ─────────────────────────────────────────
                    cfg = config_default();
                    
                    % Scheme
                    cfg.scheme_id = scheme_id;
                    
                    % 스윕 변수
                    cfg.L_cell = L_cell;
                    cfg.numRU_RA = numRU_RA;
                    cfg.num_STAs = num_STAs;
                    cfg.numRU_SA = exp_config.fixed.numRU_SA;
                    cfg.numRU_total = cfg.numRU_RA + cfg.numRU_SA;
                    
                    % 고정 파라미터 (선택적 적용)
                    if isfield(exp_config.fixed, 'alpha')
                        cfg.alpha = exp_config.fixed.alpha;
                    end
                    if isfield(exp_config.fixed, 'rho')
                        cfg.rho = exp_config.fixed.rho;
                    end
                    if isfield(exp_config.fixed, 'mu_on')
                        cfg.mu_on = exp_config.fixed.mu_on;
                    end
                    if isfield(exp_config.fixed, 'v3_EMA_alpha')
                        cfg.v3_EMA_alpha = exp_config.fixed.v3_EMA_alpha;
                    end
                    if isfield(exp_config.fixed, 'v3_max_reduction')
                        cfg.v3_max_reduction = exp_config.fixed.v3_max_reduction;
                    end
                    if isfield(exp_config.fixed, 'v3_sensitivity')
                        cfg.v3_sensitivity = exp_config.fixed.v3_sensitivity;
                    end
                    if isfield(exp_config.fixed, 'simulation_time')
                        cfg.simulation_time = exp_config.fixed.simulation_time;
                    end
                    if isfield(exp_config.fixed, 'warmup_time')
                        cfg.warmup_time = exp_config.fixed.warmup_time;
                    end
                    if isfield(exp_config.fixed, 'verbose')
                        cfg.verbose = exp_config.fixed.verbose;
                    end
                    if isfield(exp_config.fixed, 'collect_bsr_trace')
                        cfg.collect_bsr_trace = exp_config.fixed.collect_bsr_trace;
                    end
                    
                    % Lambda 재계산
                    cfg = recompute_pareto_lambda(cfg);
                    
                    % 난수 시드
                    seed = 1000 + (i_L-1)*100 + (i_RA-1)*10 + i_STA + run*1000;
                    rng(seed);
                    
                    % ─────────────────────────────────────────
                    % 시뮬레이션 실행
                    % ─────────────────────────────────────────
                    try
                        [results, ~] = main_sim_v2(cfg);
                        
                        % 결과 저장
                        for m = 1:length(metrics_list)
                            metric_name = metrics_list{m};
                            
                            if isfield(results.summary, metric_name)
                                value = results.summary.(metric_name);
                            else
                                value = NaN;
                            end
                            
                            results_5d.(metric_name)(i_scheme, i_L, i_RA, i_STA, run) = value;
                        end
                        
                        fprintf('%.1fs\n', toc(tic_run));
                        
                    catch ME
                        fprintf('실패: %s\n', ME.message);
                    end
                end
                
                % 진행률
                progress = sim_count / total_sims * 100;
                elapsed_total = toc(tic_total);
                avg_time = elapsed_total / sim_count;
                remaining_time = avg_time * (total_sims - sim_count);
                
                fprintf('    진행률: %.1f%% (%d/%d), 남은 시간: ~%.1f분\n\n', ...
                    progress, sim_count, total_sims, remaining_time / 60);
            end
        end
    end
end

fprintf('========================================\n');
fprintf('  모든 시뮬레이션 완료!\n');
fprintf('  총 소요 시간: %.1f분\n', toc(tic_total) / 60);
fprintf('========================================\n\n');

%% =====================================================================
%  5. 결과 평균 계산 (run 차원만 평균)
%  =====================================================================

fprintf('결과 평균 계산 중...\n');

results_mean = struct();

for m = 1:length(metrics_list)
    metric_name = metrics_list{m};
    
    % 5번째 차원(run)만 평균 → 결과: (scheme, L, RA, STA)
    data_5d = results_5d.(metric_name);  % (scheme, L, RA, STA, run)
    results_mean.(metric_name) = mean(data_5d, 5, 'omitnan');  % (scheme, L, RA, STA)
end

fprintf('✓ 평균 계산 완료\n');
fprintf('  결과 크기 확인: ');
disp(size(results_mean.mean_delay_ms));  % [2, 3, 3, 3] 이어야 함

%% =====================================================================
%  6. 결과 저장
%  =====================================================================

fprintf('\n결과 저장 중...\n');

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
save_file = sprintf('%s/mat/exp3_01_results_%s.mat', results_dir, timestamp);

save(save_file, ...
    'results_5d', 'results_mean', ...
    'L_cell_range', 'numRU_RA_range', 'num_STAs_range', ...
    'schemes', 'metrics_list', 'exp_config', '-v7.3');

fprintf('✓ 결과 저장: %s\n\n', save_file);

fprintf('========================================\n');
fprintf('  실험 완료!\n');
fprintf('  다음 명령어로 분석:\n');
fprintf('  >> analyze_exp3_01\n');
fprintf('========================================\n');