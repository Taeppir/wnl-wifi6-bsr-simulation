%% Phase1_L_cell_vs_rho.m
% Phase 1: 부하(L_cell) vs 버스트 비율(rho) 2D 스윕
%
% 목표: UORA 경쟁이 극대화되는 (L_cell, rho) 조합 탐색
%
% 고정 변수:
%   - alpha = 1.5
%   - mu_on = 0.05 (50ms On-period)
%
% 스윕 변수:
%   - L_cell: [0.3, 0.4, 0.5, 0.6, 0.7, 0.8] (6단계)
%   - rho: [0.3, 0.5, 0.7, 0.9] (4단계)
%
% 측정 지표 (Heatmap 8개):
%   1. UORA 충돌률 [%]
%   2. Explicit BSR 카운트
%   3. Implicit BSR 비율 [%]
%   4. 버퍼 Empty 비율 [%]
%   5. 평균 큐잉 지연 [ms]
%   6. P90 큐잉 지연 [ms]
%   7. 패킷 완료율 [%]
%   8. BSR 대기 지연 평균 [ms]

clear; close all; clc;

%% =====================================================================
%  1. 실험 설정
%  =====================================================================

fprintf('========================================\n');
fprintf('  Phase 1: L_cell vs rho 실험\n');
fprintf('========================================\n\n');

% 경로 설정 (이미 했다면 스킵)
% setup_paths();

% 스윕 범위
L_cell_range = [0.2, 0.4];
rho_range = [0.3, 0.5, 0.7];

% 고정 파라미터
fixed_alpha = 1.5;
fixed_mu_on = 0.05;  % 50ms On-period

% 실험 반복 횟수
num_runs = 1;

% 결과 저장 디렉토리
results_dir = 'results/phase1';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

% Grid 크기
n_L = length(L_cell_range);
n_rho = length(rho_range);

fprintf('[실험 설정]\n');
fprintf('  Grid 크기: %d × %d = %d 조합\n', n_L, n_rho, n_L * n_rho);
fprintf('  반복 횟수: %d회\n', num_runs);
fprintf('  총 시뮬레이션: %d회\n\n', n_L * n_rho * num_runs);
fprintf('  고정 파라미터:\n');
fprintf('    - alpha: %.1f\n', fixed_alpha);
fprintf('    - mu_on: %.3f (%.0f ms)\n', fixed_mu_on, fixed_mu_on * 1000);
fprintf('\n');

% 예상 소요 시간 추정
fprintf('[소요 시간 추정]\n');
fprintf('  시뮬레이션당 예상 시간: ~3초\n');
fprintf('  총 예상 시간: ~%.1f분\n\n', (n_L * n_rho * num_runs * 3) / 60);

% user_input = input('실험을 시작하시겠습니까? (y/n): ', 's');
% if ~strcmpi(user_input, 'y')
%     fprintf('실험을 취소했습니다.\n');
%     return;
% end

%% =====================================================================
%  2. 결과 저장용 구조체 초기화
%  =====================================================================

% 반복 횟수만큼 지표를 저장할 3D 배열 (L_cell × rho × runs)
metrics_grid = struct();

metrics_grid.uora_collision_rate = nan(n_L, n_rho, num_runs);
metrics_grid.explicit_bsr_count = nan(n_L, n_rho, num_runs);
metrics_grid.implicit_bsr_ratio = nan(n_L, n_rho, num_runs);
metrics_grid.buffer_empty_ratio = nan(n_L, n_rho, num_runs);
metrics_grid.mean_delay_ms = nan(n_L, n_rho, num_runs);
metrics_grid.std_delay_ms = nan(n_L, n_rho, num_runs); 
metrics_grid.p90_delay_ms = nan(n_L, n_rho, num_runs);
metrics_grid.completion_rate = nan(n_L, n_rho, num_runs);
metrics_grid.bsr_waiting_delay_ms = nan(n_L, n_rho, num_runs);
metrics_grid.bsr_delay_ratio = nan(n_L, n_rho, num_runs);

% 추가 통계 (선택적)
metrics_grid.throughput_mbps = nan(n_L, n_rho, num_runs);
metrics_grid.jain_index = nan(n_L, n_rho, num_runs);

% 메타데이터
metadata = struct();
metadata.L_cell_range = L_cell_range;
metadata.rho_range = rho_range;
metadata.fixed_alpha = fixed_alpha;
metadata.fixed_mu_on = fixed_mu_on;
metadata.num_runs = num_runs;
metadata.timestamp = datetime('now');

%% =====================================================================
%  3. 2D Grid 스윕 (Main Loop)
%  =====================================================================

fprintf('\n========================================\n');
fprintf('  시뮬레이션 시작\n');
fprintf('========================================\n\n');

seed_list = 1:num_runs;  % [1, 2, 3, ..., 10]
metadata.seed_list = seed_list;

fprintf('[난수 시드 설정]\n');
fprintf('  시드 리스트: [%s]\n', num2str(seed_list));
fprintf('  → 통계적 독립성 + 재현성 보장\n\n');

total_sims = n_L * n_rho * num_runs;
sim_count = 0;
tic;

for L_idx = 1:n_L
    for rho_idx = 1:n_rho
        
        L_cell = L_cell_range(L_idx);
        rho = rho_range(rho_idx);
        
        fprintf('[Grid %d/%d] L_cell=%.1f, rho=%.1f\n', ...
            (L_idx-1)*n_rho + rho_idx, n_L*n_rho, L_cell, rho);
        
        % ─────────────────────────────────────────────────────────
        % 설정 파일 생성
        % ─────────────────────────────────────────────────────────
        
        cfg = config_default();
        
        % 출력 최소화
        cfg.verbose = 0;
        
        % 고정 파라미터
        cfg.alpha = fixed_alpha;
        cfg.mu_on = fixed_mu_on;
        
        % 스윕 변수
        cfg.L_cell = L_cell;
        cfg.rho = rho;
        
        % mu_off 자동 계산 (rho 유지를 위해)
        cfg.mu_off = cfg.mu_on * (1 - cfg.rho) / cfg.rho;
        
        % lambda 재계산
        total_capacity = cfg.numRU_SA * cfg.data_rate_per_RU;
        cfg.lambda_network = cfg.L_cell * total_capacity / (cfg.size_MPDU * 8) / cfg.rho;
        cfg.lambda = cfg.lambda_network / cfg.num_STAs ;
        
        % ⭐ 시뮬레이션 시간 조정 (낮은 부하에서는 더 길게)
        if cfg.L_cell < 0.5
            cfg.simulation_time = 15.0;  % 15초
        else
            cfg.simulation_time = 10.0;  % 10초
        end
        cfg.warmup_time = 2.0;
        
        % Baseline 정책 사용
        cfg.scheme_id = 0;
        
        % ─────────────────────────────────────────────────────────
        % 반복 실행
        % ─────────────────────────────────────────────────────────
        
        for run = 1:num_runs
            
            sim_count = sim_count + 1;

            rng(seed_list(run));
            
            if mod(run, 3) == 1
                fprintf('  Run %2d/%d...', run, num_runs);
            end
            
            % 시뮬레이션 실행
            try
                [results, ~] = main_sim_v2(cfg);
                
                % ─────────────────────────────────────────────────
                % 지표 추출
                % ─────────────────────────────────────────────────
                
                % 1. UORA 충돌률
                metrics_grid.uora_collision_rate(L_idx, rho_idx, run) = ...
                    results.summary.collision_rate;
                
                % 2. Explicit BSR 카운트
                metrics_grid.explicit_bsr_count(L_idx, rho_idx, run) = ...
                    results.bsr.total_explicit;
                
                % 3. Implicit BSR 비율
                metrics_grid.implicit_bsr_ratio(L_idx, rho_idx, run) = ...
                    results.summary.implicit_bsr_ratio;
                
                % 4. 버퍼 Empty 비율
                %    = (Q=0인 BSR 횟수) / (총 BSR 횟수)
                %    ⭐ 이 값은 compute_statistics에서 계산 필요
                %    임시로 Implicit BSR 비율의 역수로 근사
                metrics_grid.buffer_empty_ratio(L_idx, rho_idx, run) = ...
                    results.summary.buffer_empty_ratio;
                
                % 5. 평균 큐잉 지연
                metrics_grid.mean_delay_ms(L_idx, rho_idx, run) = ...
                    results.summary.mean_delay_ms;
                
                % 6. P90 큐잉 지연
                metrics_grid.p90_delay_ms(L_idx, rho_idx, run) = ...
                    results.summary.p90_delay_ms;

                % ⭐ 큐잉 지연 표준편차
                metrics_grid.std_delay_ms(L_idx, rho_idx, run) = ...
                    results.summary.std_delay_ms;
                
                % 7. 패킷 완료율
                metrics_grid.completion_rate(L_idx, rho_idx, run) = ...
                    results.summary.completion_rate;
                
                % 8. BSR 대기 지연 평균 
                if isfield(results.summary, 'bsr_waiting_delay_ms')
                    metrics_grid.bsr_waiting_delay_ms(L_idx, rho_idx, run) = ...
                        results.summary.bsr_waiting_delay_ms;
                else
                    metrics_grid.bsr_waiting_delay_ms(L_idx, rho_idx, run) = NaN;
                end

                %  ⭐⭐⭐ 9. BSR 지연 비율 (핵심!)
                if isfield(results.summary, 'bsr_delay_ratio')
                    metrics_grid.bsr_delay_ratio(L_idx, rho_idx, run) = ...
                        results.summary.bsr_delay_ratio;
                else
                    metrics_grid.bsr_delay_ratio(L_idx, rho_idx, run) = NaN;
                end



                % 추가 통계
                metrics_grid.throughput_mbps(L_idx, rho_idx, run) = ...
                    results.summary.throughput_mbps;
                metrics_grid.jain_index(L_idx, rho_idx, run) = ...
                    results.summary.jain_index;
                
                clear results;
                
                    if mod(run, 3) == 0
                    fprintf(' 완료\n');
                end

                
            catch ME
                % ⭐⭐⭐ 상세한 에러 진단
                fprintf(' 💥 실패!\n');
                fprintf('    조건: L_cell=%.1f, rho=%.1f, run=%d, seed=%d\n', ...
                    L_cell, rho, run, seed_list(run));
                fprintf('    에러: %s\n', ME.message);
                
                % 에러 발생 위치
                if ~isempty(ME.stack)
                    fprintf('    위치: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
                end
                
                % ⭐ 설정값 출력 (디버깅용)
                fprintf('    설정: lambda=%.2f, mu_on=%.3f, mu_off=%.3f\n', ...
                    cfg.lambda, cfg.mu_on, cfg.mu_off);
                
                % ⭐ 모든 지표를 NaN으로 채우기 (누락 방지)
                metrics_grid.uora_collision_rate(L_idx, rho_idx, run) = NaN;
                metrics_grid.explicit_bsr_count(L_idx, rho_idx, run) = NaN;
                metrics_grid.implicit_bsr_ratio(L_idx, rho_idx, run) = NaN;
                metrics_grid.buffer_empty_ratio(L_idx, rho_idx, run) = NaN;
                metrics_grid.mean_delay_ms(L_idx, rho_idx, run) = NaN;
                metrics_grid.p90_delay_ms(L_idx, rho_idx, run) = NaN;
                metrics_grid.std_delay_ms(L_idx, rho_idx, run) = NaN;
                metrics_grid.completion_rate(L_idx, rho_idx, run) = NaN;
                metrics_grid.bsr_waiting_delay_ms(L_idx, rho_idx, run) = NaN;
                metrics_grid.bsr_delay_ratio(L_idx, rho_idx, run) = NaN;
                metrics_grid.throughput_mbps(L_idx, rho_idx, run) = NaN;
                metrics_grid.jain_index(L_idx, rho_idx, run) = NaN;
                
                % ⭐ 메모리 정리 (실패 시에도!)
                clear results;
                
                % ⭐ 심각한 에러면 중단 (선택적)
                if contains(ME.message, 'Out of memory') || contains(ME.message, 'Array exceeds')
                    fprintf('\n⛔ 치명적 에러 발생! 실험 중단.\n');
                    error('메모리 부족으로 실험 중단');
                end
            end
            
            % 진행률 출력
            if mod(sim_count, 10) == 0
                elapsed = toc;
                avg_time = elapsed / sim_count;
                remaining = (total_sims - sim_count) * avg_time;
                fprintf('  [진행률: %d/%d (%.1f%%), 남은 시간: ~%.1f분]\n', ...
                    sim_count, total_sims, 100*sim_count/total_sims, remaining/60);
            end
        end
        
        fprintf('\n');
        
        % ─────────────────────────────────────────────────────────
        % 중간 저장 (메모리 보호)
        % ─────────────────────────────────────────────────────────
        
        if mod((L_idx-1)*n_rho + rho_idx, 6) == 0
            temp_filename = sprintf('%s/phase1_temp_%s.mat', ...
                results_dir, datestr(now, 'yyyymmdd_HHMMSS'));
            save(temp_filename, 'metrics_grid', 'metadata');
            fprintf('  중간 저장: %s\n\n', temp_filename);
        end
    end
end

total_elapsed = toc;

fprintf('\n========================================\n');
fprintf('  시뮬레이션 완료\n');
fprintf('========================================\n');
fprintf('  총 소요 시간: %.1f분\n', total_elapsed / 60);
fprintf('  시뮬레이션당 평균: %.2f초\n\n', total_elapsed / total_sims);

%% =====================================================================
%  4. 결과 집계 (평균 및 표준편차)
%  =====================================================================

fprintf('[결과 집계]\n');

% 평균값 계산 (runs 차원에서 평균)
metrics_mean = struct();
metrics_std = struct();

field_names = fieldnames(metrics_grid);

for i = 1:length(field_names)
    field = field_names{i};
    
    % 3D 배열 (L × rho × runs) → 2D 배열 (L × rho)
    data_3d = metrics_grid.(field);
    
    metrics_mean.(field) = mean(data_3d, 3, 'omitnan');
    metrics_std.(field) = std(data_3d, 0, 3, 'omitnan');
end

fprintf('  평균 및 표준편차 계산 완료\n\n');

%% =====================================================================
%  5. 최종 저장
%  =====================================================================

final_filename = sprintf('%s/phase1_final_%s.mat', ...
    results_dir, datestr(now, 'yyyymmdd_HHMMSS'));

save(final_filename, 'metrics_grid', 'metrics_mean', 'metrics_std', 'metadata');

fprintf('💾 최종 결과 저장: %s\n\n', final_filename);

%% =====================================================================
%  6. Heatmap 시각화 (8개)
%  =====================================================================

fprintf('[Heatmap 생성]\n');

fig = figure('Position', [50, 50, 1600, 1400]);  % 높이 증가

% 9개 서브플롯
subplot_titles = {
    'UORA 충돌률 [%]', ...
    'Explicit BSR 카운트', ...
    'Implicit BSR 비율 [%]', ...
    '버퍼 Empty 비율 [%]', ...
    '평균 큐잉 지연 [ms]', ...
    '큐잉 지연 표준편차 [ms]', ...  % ⭐ 새로
    '패킷 완료율 [%]', ...
    'BSR 대기 지연 [ms]', ...
    'BSR 지연 비율 [%]'  % ⭐⭐⭐ 핵심!
};

subplot_fields = {
    'uora_collision_rate', ...
    'explicit_bsr_count', ...
    'implicit_bsr_ratio', ...
    'buffer_empty_ratio', ...
    'mean_delay_ms', ...
    'std_delay_ms', ...  % ⭐ 새로
    'completion_rate', ...
    'bsr_waiting_delay_ms', ...
    'bsr_delay_ratio'  % ⭐⭐⭐ 핵심!
};

% 백분율 변환이 필요한 필드
percentage_fields = {'uora_collision_rate', 'implicit_bsr_ratio', ...
    'buffer_empty_ratio', 'completion_rate'}; 

for i = 1:9
    subplot(3, 3, i);
    
    % 데이터 추출
    data = metrics_mean.(subplot_fields{i});
    
    % 백분율 변환
    if ismember(subplot_fields{i}, percentage_fields)
        data = data * 100;
    end
    
    % Heatmap 그리기
    imagesc(data');
    colorbar;
    
    % 축 설정
    set(gca, 'XTick', 1:n_L, 'XTickLabel', arrayfun(@num2str, L_cell_range, 'UniformOutput', false));
    set(gca, 'YTick', 1:n_rho, 'YTickLabel', arrayfun(@num2str, rho_range, 'UniformOutput', false));
    
    xlabel('L_{cell}', 'FontSize', 11);
    ylabel('\rho (Burst Ratio)', 'FontSize', 11);
    title(subplot_titles{i}, 'FontSize', 12, 'FontWeight', 'bold');
    
    % 값 표시
    hold on;
    for x = 1:n_L
        for y = 1:n_rho
            val = data(x, y);
            if ~isnan(val)
                text(x, y, sprintf('%.1f', val), ...
                    'HorizontalAlignment', 'center', ...
                    'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
            end
        end
    end
    hold off;
    
    colormap(gca, jet);
end

% 전체 제목
sgtitle(sprintf('Phase 1: L_{cell} vs \\rho | \\alpha=%.1f, \\mu_{on}=%.3f', ...
    fixed_alpha, fixed_mu_on), 'FontSize', 16, 'FontWeight', 'bold');

% 저장
fig_filename = sprintf('%s/phase1_heatmaps_%s.png', ...
    results_dir, datestr(now, 'yyyymmdd_HHMMSS'));
saveas(fig, fig_filename);

fprintf('  📊 Heatmap 저장: %s\n\n', fig_filename);


%% 7. Sweet Spot 후보 선정 - 수정된 기준

fprintf('========================================\n');
fprintf('  Sweet Spot 후보 선정\n');
fprintf('========================================\n\n');

% 기준:
% 1. 패킷 완료율 >= 85%
% 2. ⭐⭐⭐ BSR 지연 비율 >= 50% (핵심!)
% 3. UORA 충돌률이 높을수록 좋음
% 4. Explicit BSR 카운트가 많을수록 좋음

completion_threshold = 0.85;
bsr_ratio_threshold = 50.0;  % ⭐ 새로운 필터

% 점수 계산 (정규화 후 가중합)
normalize = @(x) (x - min(x(:))) / (max(x(:)) - min(x(:)));

% 데이터 추출
collision_rate_norm = normalize(metrics_mean.uora_collision_rate);
explicit_bsr_norm = normalize(metrics_mean.explicit_bsr_count);
bsr_ratio_norm = normalize(metrics_mean.bsr_delay_ratio);  % ⭐ 추가
completion_rate = metrics_mean.completion_rate;
bsr_delay_ratio = metrics_mean.bsr_delay_ratio;

% ⭐ 가중치 조정
w1 = 0.3;  % 충돌률
w2 = 0.2;  % Explicit BSR
w3 = 0.5;  % BSR 지연 비율 (가장 중요!)

% 점수 계산
score = w1 * collision_rate_norm + w2 * explicit_bsr_norm + w3 * bsr_ratio_norm;

% 필터 적용
score(completion_rate < completion_threshold) = NaN;
score(bsr_delay_ratio < bsr_ratio_threshold) = NaN;  % ⭐ 핵심 필터

% 상위 3개 후보 선정
[score_sorted, idx_sorted] = sort(score(:), 'descend', 'MissingPlacement', 'last');
top_k = 3;

fprintf('[상위 %d개 Sweet Spot 후보]\n', top_k);
fprintf('(필터: 완료율 >= %.0f%%, BSR 지연 비율 >= %.0f%%)\n\n', ...
    completion_threshold * 100, bsr_ratio_threshold);

for k = 1:top_k
    if isnan(score_sorted(k))
        break;
    end
    
    idx = idx_sorted(k);
    [L_idx, rho_idx] = ind2sub([n_L, n_rho], idx);
    
    L_opt = L_cell_range(L_idx);
    rho_opt = rho_range(rho_idx);
    
    fprintf('후보 #%d: L_cell=%.1f, rho=%.1f (Score=%.3f)\n', k, L_opt, rho_opt, score_sorted(k));
    fprintf('  - UORA 충돌률: %.1f%%\n', metrics_mean.uora_collision_rate(L_idx, rho_idx) * 100);
    fprintf('  - Explicit BSR: %.0f회\n', metrics_mean.explicit_bsr_count(L_idx, rho_idx));
    fprintf('  - BSR 지연 비율: %.1f%%\n', metrics_mean.bsr_delay_ratio(L_idx, rho_idx));
    fprintf('  - 평균 지연: %.2f ms\n', metrics_mean.mean_delay_ms(L_idx, rho_idx));
    fprintf('  - 완료율: %.1f%%\n', metrics_mean.completion_rate(L_idx, rho_idx) * 100);
    fprintf('\n');
end
