%% tests/test_policy_traces_all.m
% BSR v0, v1, v2, v3 정책의 (Q, R) 트레이스를 시각적으로 비교 검증
%
% [사전 조건]
%   1. BSR 정책 (v1, v2, v3)이 설계안대로 수정되었어야 함.
%   2. BSR 트레이스 로깅 기능이 구현되었어야 함 (init_metrics, compute_bsr_policy 등)
%
% [검증 내용]
%   - 동일한 트래픽(동일한 난수 시드) 하에서 각 정책이 어떻게 반응하는지 비교
%   - v0: R=Q 인가?
%   - v1/v2/v3: 상승/버스트 시 R=Q로 복귀하는가?
%   - v1/v2/v3: 하락 시에만 R < Q (감산)가 적용되는가?

clear; close all; clc;

fprintf('========================================\n');
fprintf('  BSR 정책 (v0-v3) 통합 트레이스 검증\n');
fprintf('========================================\n\n');

%% 1. 통합 설정
% setup_paths(); % (MATLAB 경로가 안 잡혀있을 경우 주석 해제)

schemes_to_test = [0, 1, 2, 3];
scheme_names = {'v0 (Baseline)', 'v1 (Fixed)', 'v2 (Proportional)', 'v3 (Trend-based)'};
num_schemes = length(schemes_to_test);

% --- 테스트 환경 설정 ---
cfg_base = config_default();
cfg_base.num_STAs = 20;           % STA 1개에 집중
cfg_base.simulation_time = 10; % 10초
cfg_base.verbose = 0;            % (로그 최소화)
cfg_base.collect_bsr_trace = true; % (트레이스 활성화)
cfg_base.L_cell = 0.3;
% -------------------------

% 동일한 트래픽/경쟁을 위한 난수 시드 고정
RNG_SEED = 42; 

% 결과를 저장할 셀 배열
results_all = cell(num_schemes, 1);
metrics_all = cell(num_schemes, 1);

%% 2. 시뮬레이션 루프 (정책별 실행)
fprintf('  STA=1, SimTime=10s, Seed=%d로 정책별 시뮬레이션 실행...\n', RNG_SEED);

for i = 1:num_schemes
    cfg = cfg_base; % 기본 설정 복사
    cfg.scheme_id = schemes_to_test(i);
    
    fprintf('  Running: %s...\n', scheme_names{i});
    
    % [중요] 매번 동일한 난수 시드 적용
    % (동일한 트래픽 및 UORA 동작 보장)
    rng(RNG_SEED); 
    
    % (가정) main_sim_v2가 results에 metrics 구조체를 포함하여 반환
    % (만약 results에 metrics가 없다면, main_sim_v2 내부에서 metrics를 반환하도록 수정 필요)
    [results, metrics] = main_sim_v2(cfg);
    results_all{i} = results;
    
    % (가정) results.metrics에 트레이스 로그가 저장되어 있음
    % (ANALYZE_RESULTS_v2.m가 metrics를 results에 포함시키도록 수정 필요할 수 있음)
    metrics_all{i} = metrics; 
end

fprintf('  모든 시뮬레이션 완료. 트레이스 플로팅 시작...\n');

%% 3. 시각화 (서브플롯으로 비교)
fig = figure('Position', [100, 100, 1400, 900]);
sgtitle(sprintf('BSR Policy Trace Comparison (STA 1, Seed=%d)', RNG_SEED), 'FontSize', 16, 'FontWeight', 'bold');

for i = 1:num_schemes
    subplot(num_schemes, 1, i); % (v0, v1, v2, v3 순서대로 세로로 4개)
    hold on; grid on;
    
    % 트레이스 로그 추출
    try
        trace = metrics_all{i}.policy_level.trace;
        idx = 1:metrics_all{i}.policy_level.trace_idx;
        
        % STA 1의 로그만 필터링 (cfg.num_STAs = 1이므로 사실상 전체)
        sta_mask = (trace.sta_id(idx) == 1);
        t = trace.time(idx(sta_mask));
        Q = trace.Q(idx(sta_mask));
        R = trace.R(idx(sta_mask));
    catch ME
        title(sprintf('%s - TRACE LOGGING FAILED', scheme_names{i}));
        fprintf('Error plotting %s: %s\n', scheme_names{i}, ME.message);
        continue;
    end

   % --- [시각화 수정 1] ---
    % Q (실제 큐)를 연한 파란색 '면(Area)'으로 그립니다.
    area(t, Q, ...
        'FaceColor', [0.8 0.9 1.0], ...  % 면 색상 (연한 하늘색)
        'EdgeColor', [0.3 0.5 0.9], ...  % 테두리 색상 (진한 파란색)
        'LineWidth', 1, ...
        'DisplayName', 'Q (Actual)');

    % --- [시각화 수정 2] ---
    % R (보고된 BSR)을 굵은 빨간색 '선(Line)'으로 그립니다.
    plot(t, R, 'r-', 'LineWidth', 2.0, 'DisplayName', 'R (Reported)');

    % v3인 경우 Q_ema도 플로팅 (스타일 유지)
    if schemes_to_test(i) == 3
        Q_ema = trace.Q_ema(idx(sta_mask));
        plot(t, Q_ema, 'g:', 'LineWidth', 2, 'DisplayName', 'Q_{ema} (Trend)');
    end

    % 감산이 적용된 순간(R < Q) 표시 (스타일 유지)
    % (R이 Q 면적 안으로 파고드는 지점에 검은색 원으로 강조)
    reduction_mask = (R < Q);
    plot(t(reduction_mask), R(reduction_mask), 'ko', 'MarkerSize', 6, ...
        'MarkerFaceColor', 'red', 'DisplayName', 'Reduction Applied');

    legend('Location', 'best');
    ylabel('Buffer Size (bytes)');
    title(scheme_names{i});
    hold off; % 서브플롯마다 hold off
end
xlabel('Time (s)'); % 마지막 플롯에만 X축 레이블 추가

%% 4. 수치적 검증 (Numerical Validation)
fprintf('\n========================================\n');
fprintf('  BSR 정책 수치적 검증 (STA 1)\n');
fprintf('========================================\n');
fprintf('%-18s | %10s | %10s | %12s | %15s\n', ...
    'Policy', 'Total BSRs', 'Reductions', 'Freq. (%)', 'Mean Error (Bytes)');
fprintf(repmat('-', 1, 70));
fprintf('\n');

for i = 1:num_schemes
    try
        % (이전과 동일) 트레이스 로그 추출
        trace = metrics_all{i}.policy_level.trace;
        idx = 1:metrics_all{i}.policy_level.trace_idx;
        sta_mask = (trace.sta_id(idx) == 1);
        
        Q = trace.Q(idx(sta_mask));
        R = trace.R(idx(sta_mask));

        if isempty(Q)
            fprintf('%-18s | %10d | %10s | %12s | %15s\n', ...
                scheme_names{i}, 0, 'N/A', 'N/A', 'N/A');
            continue;
        end

        % --- 수치 계산 ---
        total_bsrs = length(Q);
        reduction_mask = (R < Q);
        reduction_count = sum(reduction_mask);
        
        % 0으로 나누기 방지
        if total_bsrs > 0
            reduction_freq = (reduction_count / total_bsrs) * 100;
        else
            reduction_freq = 0;
        end
        
        % 감산이 적용됐을 때의 평균 오차 (Q - R)
        if reduction_count > 0
            % (Q - R)의 평균값 계산
            mean_error_when_reduced = mean(Q(reduction_mask) - R(reduction_mask));
        else
            mean_error_when_reduced = 0;
        end
        % ---

        fprintf('%-18s | %10d | %10d | %12.1f%% | %15.0f\n', ...
            scheme_names{i}, total_bsrs, reduction_count, reduction_freq, mean_error_when_reduced);
            
    catch ME
        fprintf('%-18s | Error reading metrics: %s\n', scheme_names{i}, ME.message);
    end
end
fprintf('\n');


%% 5. 수치적 검증 (버퍼 크기 통계)
fprintf('\n========================================\n');
fprintf('  BSR 정책 수치적 검증 (버퍼 크기 통계, STA 1)\n');
fprintf('========================================\n');
fprintf('%-18s | %15s | %10s | %10s | %10s | %15s\n', ...
    'Policy', 'Avg. Buffer (B)', 'p10 (B)', 'p50 (B)', 'p90 (B)', 'Empty BSRs (#)');
fprintf(repmat('-', 1, 85));
fprintf('\n');

for i = 1:num_schemes
    try
        % (이전과 동일) 트레이스 로그 추출
        trace = metrics_all{i}.policy_level.trace;
        idx = 1:metrics_all{i}.policy_level.trace_idx;
        sta_mask = (trace.sta_id(idx) == 1);
        
        Q = trace.Q(idx(sta_mask)); % STA 1의 모든 Q 값 추출

        if isempty(Q)
            fprintf('%-18s | %15s | %10s | %10s | %10s | %15s\n', ...
                scheme_names{i}, 'N/A', 'N/A', 'N/A', 'N/A', 'N/A');
            continue;
        end

        % --- 요청하신 통계 수치 계산 ---
        avg_q = mean(Q);
        p10_q = prctile(Q, 10);
        p50_q = prctile(Q, 50); % Median (중앙값)
        p90_q = prctile(Q, 90);
        
        % Q=0인 BSR의 횟수 (SA -> RA 모드 전환 시점)
        empty_bsr_count = sum(Q == 0); 
        % ---
        
        fprintf('%-18s | %15.0f | %10.0f | %10.0f | %10.0f | %15d\n', ...
            scheme_names{i}, avg_q, p10_q, p50_q, p90_q, empty_bsr_count);
            
    catch ME
        fprintf('%-18s | Error reading metrics: %s\n', scheme_names{i}, ME.message);
    end
end
fprintf('\n');

%% 6. 검증 가이드
fprintf('\n========================================\n');
fprintf('  시각적 검증 가이드 (그래프 확인):\n');
fprintf('========================================\n');
fprintf('  - v0 (Baseline): 파란색(Q)과 빨간색(R) 선이 항상 겹쳐야 함 (R=Q).\n');
fprintf('  - v1, v2, v3: 파란색(Q)이 [상승]할 때 빨간색(R)이 즉시 겹쳐야 함 (R=Q).\n');
fprintf('  - v1, v2, v3: 파란색(Q)이 [하락]할 때만 빨간색(R)이 아래로 떨어져야 함 (R < Q).\n');
fprintf('  - v3: (녹색 점선) Q_ema가 파란색(Q) 위에 있을 때만 빨간 동그라미가 찍혀야 함.\n');
fprintf('\n');