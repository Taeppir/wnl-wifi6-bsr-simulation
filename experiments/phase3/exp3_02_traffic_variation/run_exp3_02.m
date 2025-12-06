%% run_exp3_02.m
% Experiment 3-2: 트래픽 다양성 검증
% Sweet Spot 조건에서 rho, mu_on 변화에 따른 v3 효과
%
% 실행:
%   >> cd experiments/phase3/exp3_02_traffic_variations
%   >> run_exp3_02

clear; close all; clc;

%% =====================================================================
%  1. 초기화
%  =====================================================================

fprintf('========================================\n');
fprintf('  Experiment 3-2: 트래픽 다양성 검증\n');
fprintf('========================================\n\n');

% 실험 설정 로드
exp_config = get_exp3_02_config();

fprintf('[실험 정보]\n');
fprintf('  고정 조건: L=%.2f, RA=%d, STAs=%d (Sweet Spot)\n', ...
    exp_config.fixed.L_cell, exp_config.fixed.numRU_RA, exp_config.fixed.num_STAs);
fprintf('  총 실행: %d회\n', exp_config.total_simulations);
fprintf('  설명: %s\n\n', exp_config.description);

% 결과 저장 디렉토리
results_dir = '../../../results/phase3/exp3_02';
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
rho_range = exp_config.sweep_range1;
mu_on_range = exp_config.sweep_range2;

n_schemes = length(schemes);
n_rho = length(rho_range);
n_mu = length(mu_on_range);
n_runs = exp_config.num_runs;

fprintf('[스윕 범위]\n');
fprintf('  Schemes: [%s]\n', sprintf('%d ', schemes));
fprintf('  rho: [%s]\n', sprintf('%.2f ', rho_range));
fprintf('  mu_on: [%s]\n', sprintf('%.2f ', mu_on_range));
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

% 4D 배열: (scheme, rho, mu_on, runs)
results_4d = struct();
for m = 1:length(metrics_list)
    metric_name = metrics_list{m};
    results_4d.(metric_name) = nan(n_schemes, n_rho, n_mu, n_runs);
end

%% =====================================================================
%  4. 메인 실험 루프
%  =====================================================================

total_sims = n_schemes * n_rho * n_mu * n_runs;
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
    
    for i_rho = 1:n_rho
        rho = rho_range(i_rho);
        
        for i_mu = 1:n_mu
            mu_on = mu_on_range(i_mu);
            
            fprintf('  [%s] rho=%.2f, mu_on=%.2f\n', scheme_name, rho, mu_on);
            
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
                
                % 고정 파라미터 적용
                cfg.L_cell = exp_config.fixed.L_cell;
                cfg.numRU_RA = exp_config.fixed.numRU_RA;
                cfg.num_STAs = exp_config.fixed.num_STAs;
                cfg.numRU_SA = exp_config.fixed.numRU_SA;
                cfg.numRU_total = cfg.numRU_RA + cfg.numRU_SA;
                cfg.alpha = exp_config.fixed.alpha;
                
                % 스윕 변수 적용
                cfg.rho = rho;
                cfg.mu_on = mu_on;
                
                % v3 파라미터
                if isfield(exp_config.fixed, 'v3_EMA_alpha')
                    cfg.v3_EMA_alpha = exp_config.fixed.v3_EMA_alpha;
                end
                if isfield(exp_config.fixed, 'v3_max_reduction')
                    cfg.v3_max_reduction = exp_config.fixed.v3_max_reduction;
                end
                if isfield(exp_config.fixed, 'v3_sensitivity')
                    cfg.v3_sensitivity = exp_config.fixed.v3_sensitivity;
                end
                
                % 시뮬레이션 설정
                cfg.simulation_time = exp_config.fixed.simulation_time;
                cfg.warmup_time = exp_config.fixed.warmup_time;
                cfg.verbose = exp_config.fixed.verbose;
                cfg.collect_bsr_trace = exp_config.fixed.collect_bsr_trace;
                
                % Lambda 재계산
                cfg = recompute_pareto_lambda(cfg);
                
                % 난수 시드
                seed = 2000 + i_scheme*1000 + (i_rho-1)*100 + (i_mu-1)*10 + run;
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
                        
                        results_4d.(metric_name)(i_scheme, i_rho, i_mu, run) = value;
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
    
    % 4번째 차원(run)만 평균 → 결과: (scheme, rho, mu_on)
    data_4d = results_4d.(metric_name);
    results_mean.(metric_name) = mean(data_4d, 4, 'omitnan');
end

fprintf('✓ 평균 계산 완료\n');
fprintf('  결과 크기: ');
disp(size(results_mean.mean_delay_ms));  % [2, 3, 3] 이어야 함

%% =====================================================================
%  6. 결과 저장
%  =====================================================================

fprintf('\n결과 저장 중...\n');

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
save_file = sprintf('%s/mat/exp3_02_results_%s.mat', results_dir, timestamp);

save(save_file, ...
    'results_4d', 'results_mean', ...
    'rho_range', 'mu_on_range', ...
    'schemes', 'metrics_list', 'exp_config', '-v7.3');

fprintf('✓ 결과 저장: %s\n\n', save_file);

fprintf('========================================\n');
fprintf('  실험 완료!\n');
fprintf('  다음 명령어로 분석:\n');
fprintf('  >> analyze_exp3_02\n');
fprintf('========================================\n');