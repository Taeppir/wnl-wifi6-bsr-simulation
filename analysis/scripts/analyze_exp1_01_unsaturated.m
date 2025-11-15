%% analyze_exp1_1_unsaturated.m
% Experiment 1-1 분석: Unsaturated 환경 찾기
%
% 분석 목표:
%   1. 버퍼 비어있음 비율 확인
%   2. UORA 지연 확인
%   3. Explicit/Implicit BSR 비율 확인
%   4. 적정 L_cell 범위 도출

clear; close all; clc;

%% =====================================================================
%  1. 실험 결과 로드
%  =====================================================================

fprintf('========================================\n');
fprintf('  Exp 1-1: Unsaturated 환경 분석\n');
fprintf('========================================\n\n');

exp = load_experiment('exp1_1_load_sweep');

% 데이터 추출
L_cell = exp.config.sweep_range;
n_points = length(L_cell);

% Summary 데이터
mean_delay = exp.summary.mean.mean_delay_ms;
std_delay = exp.summary.std.mean_delay_ms;

mean_collision = exp.summary.mean.collision_rate;
mean_completion = exp.summary.mean.completion_rate;

mean_uora_delay = exp.summary.mean.mean_uora_delay_ms;
mean_sched_delay = exp.summary.mean.mean_sched_delay_ms;

% Fragmentation delay 추가
if isfield(exp.summary.mean, 'mean_frag_delay_ms')
    mean_frag_delay = exp.summary.mean.mean_frag_delay_ms;
else
    mean_frag_delay = nan(size(L_cell));
    warning('mean_frag_delay_ms가 결과에 없습니다.');
end

% BSR 관련
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio;
    has_buffer_empty = true;
else
    % ⭐ 대안: Implicit BSR 비율을 버퍼 비율의 proxy로 사용
    % (Implicit BSR이 높다 = 버퍼가 자주 비워진다 = Unsaturated)
    warning('buffer_empty_ratio가 없습니다. implicit_bsr_ratio를 대안으로 사용합니다.');
    buffer_empty = nan(size(L_cell));
    has_buffer_empty = false;
end

if isfield(exp.summary.mean, 'implicit_bsr_ratio')
    implicit_bsr = exp.summary.mean.implicit_bsr_ratio;
else
    implicit_bsr = nan(size(L_cell));
    warning('implicit_bsr_ratio가 결과에 없습니다.');
end

%% =====================================================================
%  2. Unsaturated 조건 판단
%  =====================================================================

fprintf('[Unsaturated 환경 기준]\n');
if has_buffer_empty
    fprintf('  1. 버퍼 비어있음 비율 >= 30%% (적당히 비어야 함)\n');
    fprintf('  2. UORA 지연 > 0 (경쟁이 있어야 함)\n');
    fprintf('  3. 완료율 >= 85%% (신뢰성)\n');
    fprintf('  4. Implicit BSR 비율 >= 50%% (unsaturated 특징)\n\n');
    
    % 조건 체크
    condition1 = buffer_empty >= 0.30;  % 버퍼 30% 이상 비어있음
else
    fprintf('  ⚠️  buffer_empty_ratio 없음 → 대안 기준 사용\n');
    fprintf('  1. Implicit BSR 비율 >= 60%% (unsaturated proxy)\n');
    fprintf('  2. UORA 지연 > 0 (경쟁이 있어야 함)\n');
    fprintf('  3. 완료율 >= 85%% (신뢰성)\n');
    fprintf('  4. 충돌률 < 40%% (과부하 아님)\n\n');
    
    % 대안 조건
    condition1 = implicit_bsr >= 0.60;  % Implicit BSR 60% 이상
end

condition2 = mean_uora_delay > 0;   % UORA 지연 존재
condition3 = mean_completion >= 0.85; % 완료율 85% 이상

if has_buffer_empty
    condition4 = implicit_bsr >= 0.50;  % Implicit BSR 50% 이상
else
    condition4 = mean_collision < 0.40;  % 충돌률 40% 미만
end

% 모든 조건 만족하는 L_cell 찾기
unsaturated_mask = condition1 & condition2 & condition3 & condition4;

fprintf('[조건별 분석]\n');
if has_buffer_empty
    fprintf('%-10s | %10s | %10s | %10s | %10s | %s\n', ...
        'L_cell', 'Buf.Empty', 'UORA>0', 'Compl>=85', 'Impl>=50', 'Result');
    fprintf('%s\n', repmat('-', 1, 75));
    
    for i = 1:n_points
        fprintf('%-10.1f | %10s | %10s | %10s | %10s | %s\n', ...
            L_cell(i), ...
            sprintf('%.1f%%', buffer_empty(i)*100), ...
            sprintf('%s', ternary(mean_uora_delay(i) > 0, 'YES', 'NO')), ...
            sprintf('%.1f%%', mean_completion(i)*100), ...
            sprintf('%.1f%%', implicit_bsr(i)*100), ...
            ternary(unsaturated_mask(i), '✓ Unsaturated', '✗ Saturated'));
    end
else
    fprintf('%-10s | %10s | %10s | %10s | %10s | %s\n', ...
        'L_cell', 'Impl>=60', 'UORA>0', 'Compl>=85', 'Coll<40', 'Result');
    fprintf('%s\n', repmat('-', 1, 75));
    
    for i = 1:n_points
        fprintf('%-10.1f | %10s | %10s | %10s | %10s | %s\n', ...
            L_cell(i), ...
            sprintf('%.1f%%', implicit_bsr(i)*100), ...
            sprintf('%s', ternary(mean_uora_delay(i) > 0, 'YES', 'NO')), ...
            sprintf('%.1f%%', mean_completion(i)*100), ...
            sprintf('%.1f%%', mean_collision(i)*100), ...
            ternary(unsaturated_mask(i), '✓ Unsaturated', '✗ Saturated'));
    end
end

fprintf('\n');

%% =====================================================================
%  3. 최적 범위 도출
%  =====================================================================

if any(unsaturated_mask)
    optimal_L_cell = L_cell(unsaturated_mask);
    fprintf('[결과] Unsaturated 조건을 만족하는 L_cell:\n');
    fprintf('  → %.1f ~ %.1f (총 %d개 조건)\n', ...
        min(optimal_L_cell), max(optimal_L_cell), sum(unsaturated_mask));
    
    % 가장 균형잡힌 조건 찾기
    idx_unsaturated = find(unsaturated_mask);
    
    if has_buffer_empty
        % Score: 버퍼 비율 × UORA 지연 (둘 다 클수록 좋음)
        score = buffer_empty(idx_unsaturated) .* mean_uora_delay(idx_unsaturated);
    else
        % 대안: Implicit BSR × UORA 지연
        score = implicit_bsr(idx_unsaturated) .* mean_uora_delay(idx_unsaturated);
    end
    
    [~, best_idx] = max(score);
    best_L_cell = L_cell(idx_unsaturated(best_idx));
    
    fprintf('\n[추천] 가장 균형잡힌 조건:\n');
    fprintf('  L_cell = %.1f\n', best_L_cell);
    if has_buffer_empty
        fprintf('  - 버퍼 비어있음: %.1f%%\n', buffer_empty(idx_unsaturated(best_idx))*100);
    end
    fprintf('  - Implicit BSR: %.1f%%\n', implicit_bsr(idx_unsaturated(best_idx))*100);
    fprintf('  - UORA 지연: %.2f ms\n', mean_uora_delay(idx_unsaturated(best_idx)));
    fprintf('  - 평균 지연: %.2f ms\n', mean_delay(idx_unsaturated(best_idx)));
    fprintf('  - 충돌률: %.1f%%\n\n', mean_collision(idx_unsaturated(best_idx))*100);
else
    fprintf('[결과] ⚠️  Unsaturated 조건을 만족하는 L_cell이 없습니다!\n');
    fprintf('  → 기준을 완화하거나 실험 범위를 조정하세요.\n\n');
end

%% =====================================================================
%  4. 시각화
%  =====================================================================

fprintf('[시각화 생성 중...]\n');

fig = figure('Position', [100, 100, 1400, 1000]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 1: 평균 지연
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 1);
errorbar(L_cell, mean_delay, std_delay, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
xlabel('L_{cell}');
ylabel('Mean Delay [ms]');
title('평균 큐잉 지연');

% ─────────────────────────────────────────────────────────────────────
% Subplot 2: UORA 지연
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 2);
plot(L_cell, mean_uora_delay, 'm-o', 'LineWidth', 2, 'MarkerFaceColor', 'm');
grid on;
xlabel('L_{cell}');
ylabel('UORA Delay [ms]');
title('UORA 지연 (경쟁 강도)');

% ─────────────────────────────────────────────────────────────────────
% Subplot 3: Explicit vs Implicit BSR
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 3);
plot(L_cell, implicit_bsr * 100, 'c-o', 'LineWidth', 2, 'MarkerFaceColor', 'c');
hold on;
plot(L_cell, (1 - implicit_bsr) * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on;
xlabel('L_{cell}');
ylabel('BSR Ratio [%]');
title('Explicit vs Implicit BSR');
legend({'Implicit BSR', 'Explicit BSR'}, 'Location', 'best');
ylim([0, 100]);

% ─────────────────────────────────────────────────────────────────────
% Subplot 4: 완료율 & 충돌률
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 4);
yyaxis left;
plot(L_cell, mean_completion * 100, 'g-o', 'LineWidth', 2, 'MarkerFaceColor', 'g');
ylabel('Completion Rate [%]');
ylim([0, 105]);
hold on;

yyaxis right;
plot(L_cell, mean_collision * 100, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
ylabel('Collision Rate [%]');
grid on;
xlabel('L_{cell}');
title('완료율 & 충돌률');
legend({'Completion Rate', 'Collision Rate'}, 'Location', 'best');

% ─────────────────────────────────────────────────────────────────────
% Subplot 5: 지연 분해 (UORA vs Frag)
% ─────────────────────────────────────────────────────────────────────
subplot(3, 2, 5);
bar(L_cell, [mean_uora_delay, mean_frag_delay], 'stacked');
grid on;
xlabel('L_{cell}');
ylabel('Delay [ms]');
title('지연 분해 (UORA vs Fragmentation)');
legend({'UORA Delay', 'Fragmentation Delay'}, 'Location', 'northwest');

% ─────────────────────────────────────────────────────────────────────
% 전체 제목
% ─────────────────────────────────────────────────────────────────────
sgtitle('Exp 1-1: Unsaturated 환경 분석', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% =====================================================================
%  5. 저장
%  =====================================================================

fig_dir = 'results/publication/figures';
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fig_filename = sprintf('%s/exp1_1_unsaturated_analysis.png', fig_dir);
saveas(fig, fig_filename);
fprintf('  ✓ Figure 저장: %s\n', fig_filename);

% PDF도 저장 (고품질)
fig_filename_pdf = sprintf('%s/exp1_1_unsaturated_analysis.pdf', fig_dir);
exportgraphics(fig, fig_filename_pdf, 'ContentType', 'vector');
fprintf('  ✓ PDF 저장: %s\n', fig_filename_pdf);

fprintf('\n🎉 분석 완료!\n\n');

%% =====================================================================
%  Helper Functions
%  =====================================================================

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end