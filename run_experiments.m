%% run_policy_comparison.m (혹은 run_experiments.m)
% BSR 정책(Scheme 0-3) 성능 비교 실험
%
% [수정]
%   - 3. 결과 집계: 'vertcat' 오류를 유발할 수 있는 cellfun 로직을
%     'get_scalar_metric' 헬퍼 함수를 사용하는 방식으로 변경하여 안정성 확보

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================
fprintf('========================================\n');
fprintf('  BSR 정책 성능 비교 실험 시작\n');
fprintf('========================================\n\n');

% --- 실험 파라미터 ---
schemes = [0, 1, 2, 3]; % 비교할 Scheme ID
scheme_names = {'Baseline (v0)', 'v1 (Fixed)', 'v2 (Proportional)', 'v3 (EMA)'};
num_runs = 3; % 통계적 신뢰도를 위한 반복 횟수 (테스트 시 3~5, 실제 10 이상)
% ---------------------

% 기본 설정 로드
base_cfg = config_default();

% --- 공통 시뮬레이션 환경 설정 ---
base_cfg.simulation_time = 10.0;
base_cfg.warmup_time = 0.0;
base_cfg.num_STAs = 20;

base_cfg.verbose = 0; % 0=로그 없음, 1=기본 진행 상황
base_cfg.collect_bsr_trace = true; % BSR 통계 수집

% Lambda 값 재계산
base_cfg = recompute_pareto_lambda(base_cfg);

% 결과 저장 디렉토리
results_dir = 'results/policy_comparison';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

n_schemes = length(schemes);
seed_list = 1:num_runs;

fprintf('[실험 설정]\n');
fprintf('  - 비교 정책: %s\n', strjoin(scheme_names, ', '));
fprintf('  - 반복 횟수: %d회 (Seeds: %d~%d)\n', num_runs, seed_list(1), seed_list(end));
fprintf('  - 시뮬레이션 시간: %.1f초 (Warmup: %.1f초)\n', base_cfg.simulation_time, base_cfg.warmup_time);
fprintf('  - STA 수: %d, 부하(L_cell): %.1f\n', base_cfg.num_STAs, base_cfg.L_cell);
fprintf('  - 총 실행 횟수: %d회\n\n', n_schemes * num_runs);

%% =====================================================================
%  2. 시뮬레이션 실행 (Main Loop)
%  =====================================================================

% 결과를 저장할 셀 배열 (Scheme × Runs)
% results.summary 전체를 저장하여 유연성 확보
all_summaries = cell(n_schemes, num_runs);

total_sims = n_schemes * num_runs;
sim_count = 0;
tic_total = tic;

for s = 1:n_schemes
    scheme_id = schemes(s);
    fprintf('────────────────────────────────────────\n');
    fprintf('  정책 실행: %s (Scheme ID = %d)\n', scheme_names{s}, scheme_id);
    fprintf('────────────────────────────────────────\n');
    
    for r = 1:num_runs
        sim_count = sim_count + 1;
        seed = seed_list(r);
        
        fprintf('  [Run %d/%d, Seed=%d] ... ', r, num_runs, seed);
        tic_run = tic;
        
        % 설정 복사 및 수정
        cfg = base_cfg;
        cfg.scheme_id = scheme_id;
        
        % 난수 시드 설정 (재현성 보장)
        rng(seed);
        
        % 시뮬레이션 실행
        try
            [results, ~] = main_sim_v2(cfg);
            
            % 요약 결과만 저장
            all_summaries{s, r} = results.summary;
            
            elapsed_run = toc(tic_run);
            fprintf('완료 (%.2f초)\n', elapsed_run);
            
        catch ME
            fprintf('💥 실패!\n');
            fprintf('    에러: %s\n', ME.message);
            fprintf('    위치: %s (line %d)\n\n', ME.stack(1).name, ME.stack(1).line);
            all_summaries{s, r} = struct(); % 실패 시 빈 구조체
        end
    end
    
    elapsed_total = toc(tic_total);
    avg_time_per_sim = elapsed_total / sim_count;
    remaining_sims = total_sims - sim_count;
    estimated_remaining_time = remaining_sims * avg_time_per_sim;
    
    fprintf('  정책 [%s] 완료. (남은 예상 시간: %.1f분)\n\n', ...
        scheme_names{s}, estimated_remaining_time / 60);
end

fprintf('========================================\n');
fprintf('  모든 시뮬레이션 완료 (총 %.1f분)\n', toc(tic_total) / 60);
fprintf('========================================\n\n');

%% =====================================================================
%  3. 결과 집계 및 테이블 생성
%  =====================================================================
fprintf('결과 집계 중...\n');

% 분석할 핵심 지표 목록
metrics_to_analyze = { ...
    'mean_delay_ms'; ...
    'p90_delay_ms'; ...
    'mean_uora_delay_ms'; ...
    'mean_sched_delay_ms'; ...
    'mean_frag_delay_ms'; ...
    'collision_rate'; ...
    'implicit_bsr_ratio'; ...
    'completion_rate'; ...
    'throughput_mbps' ...
};

% 평균 및 표준편차 저장을 위한 테이블 초기화
mean_table = array2table(nan(n_schemes, length(metrics_to_analyze)), ...
    'VariableNames', metrics_to_analyze, 'RowNames', scheme_names);
std_table = mean_table; % 구조 복사

% 데이터 추출 및 계산
for s = 1:n_schemes
    for m = 1:length(metrics_to_analyze)
        metric_name = metrics_to_analyze{m};
        
        % [오류 수정]
        % (isfield... * summary...) 방식은 summary.(metric)이 []일 때
        % vertcat 오류를 유발함.
        % 항상 스칼라(NaN 또는 값)를 반환하는 헬퍼 함수로 대체
        data_vector = cellfun(@(summary) get_scalar_metric(summary, metric_name), ...
            all_summaries(s, :), 'UniformOutput', true);
        
        mean_table.(metric_name)(s) = mean(data_vector, 'omitnan');
        std_table.(metric_name)(s) = std(data_vector, 0, 'omitnan'); % 0은 (N-1) 정규화
    end
end

% 백분율(%)로 변환 (가독성)
pct_metrics = {'collision_rate', 'implicit_bsr_ratio', 'completion_rate'};
for m_name_cell = pct_metrics
    m_name = m_name_cell{1};
    mean_table.(m_name) = mean_table.(m_name) * 100;
    std_table.(m_name) = std_table.(m_name) * 100;
end

%% =====================================================================
%  4. 결과 출력
%  =====================================================================

% 평균 결과
fprintf('──────────────────────────────────────────────────────────────────────────────────────────────────\n');
fprintf('                                 평균 결과 (Mean) - %d회 실행 평균\n', num_runs);
fprintf('──────────────────────────────────────────────────────────────────────────────────────────────────\n');
disp(mean_table);

% 표준 편차
fprintf('\n──────────────────────────────────────────────────────────────────────────────────────────────────\n');
fprintf('                               표준 편차 (Std. Dev.) - %d회 실행 기준\n', num_runs);
fprintf('──────────────────────────────────────────────────────────────────────────────────────────────────\n');
disp(std_table);

%% =====================================================================
%  5. 최종 저장
%  =====================================================================

results_filename = sprintf('%s/policy_comp_results_%s.mat', ...
    results_dir, datestr(now, 'yyyymmdd_HHMMSS'));

save(results_filename, ...
    'all_summaries', ...
    'mean_table', ...
    'std_table', ...
    'base_cfg', ...
    'schemes', ...
    'scheme_names', ...
    'num_runs', ...
    'seed_list');

fprintf('\n💾 전체 결과가 다음 파일에 저장되었습니다:\n  %s\n\n', results_filename);
fprintf('🎉 실험 완료!\n\n');


%% =====================================================================
%  헬퍼 함수 (오류 방지용)
%  =====================================================================
function value = get_scalar_metric(summary, metric_name)
    % 이 헬퍼 함수는 summary 구조체에서 metric_name을 안전하게 추출합니다.
    % 필드가 없거나, 비어있거나, 스칼라가 아니면 NaN을 반환하여
    % cellfun이 항상 스칼라 값을 받도록 보장합니다.
    if isstruct(summary) && isfield(summary, metric_name)
        val_temp = summary.(metric_name);
        % 값이 스칼라 숫자(NaN 포함)인지 확인
        if isscalar(val_temp) && isnumeric(val_temp)
            value = val_temp;
            return;
        end
    end
    % 그 외 모든 경우 (필드 없음, 비어있음[], struct 등)
    value = NaN;
end