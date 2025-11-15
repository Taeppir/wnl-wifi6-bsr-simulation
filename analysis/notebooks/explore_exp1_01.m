%% explore_exp1_1.m
% Exp 1-1 빠른 탐색 (Notebook 스타일)

clear; close all; clc;

%% 로드
exp = load_experiment('exp1_1_load_sweep');

%% 데이터 추출
L = exp.config.sweep_range;
delay = exp.summary.mean.mean_delay_ms;
collision = exp.summary.mean.collision_rate;
implicit_bsr = exp.summary.mean.implicit_bsr_ratio;
uora_delay = exp.summary.mean.mean_uora_delay_ms;
completion = exp.summary.mean.completion_rate;

% buffer_empty (있으면 사용, 없으면 implicit_bsr 사용)
if isfield(exp.summary.mean, 'buffer_empty_ratio')
    buffer_empty = exp.summary.mean.buffer_empty_ratio;
    use_buffer = true;
else
    buffer_empty = implicit_bsr;  % 대안
    use_buffer = false;
end

%% 빠른 확인
fprintf('\n========================================\n');
fprintf('  Exp 1-1 빠른 확인\n');
fprintf('========================================\n\n');

fprintf('%-8s | %8s | %8s | %8s | %8s | %8s\n', ...
    'L_cell', 'Delay', 'Coll.', 'BufEmpty', 'Impl.', 'Compl.');
fprintf('%s\n', repmat('-', 1, 65));

for i = 1:length(L)
    fprintf('%-8.1f | %8.2f | %7.1f%% | %7.1f%% | %7.1f%% | %7.1f%%\n', ...
        L(i), delay(i), collision(i)*100, buffer_empty(i)*100, ...
        implicit_bsr(i)*100, completion(i)*100);
end

fprintf('\n');

%% Unsaturated 찾기
fprintf('[Unsaturated 조건]\n');
mask = (buffer_empty >= 0.30) & (completion >= 0.85);

if any(mask)
    fprintf('  L_cell = %.1f ~ %.1f\n', min(L(mask)), max(L(mask)));
    fprintf('  (총 %d개 조건)\n\n', sum(mask));
    
    % 중간값 추천
    mid_idx = find(mask, 1, 'first') + floor(sum(mask)/2);
    fprintf('[추천] L_cell = %.1f\n', L(mid_idx));
    fprintf('  - 버퍼 empty 비율: %.1f%%\n', buffer_empty(mid_idx)*100);
    fprintf('  - UORA 지연: %.2f ms\n', uora_delay(mid_idx));
    fprintf('  - 충돌률: %.1f%%\n\n', collision(mid_idx)*100);
else
    fprintf('  없음! 기준 완화 필요\n\n');
end

%% 간단한 플롯
figure('Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
plot(L, buffer_empty*100, 'b-o', 'LineWidth', 2);
yline(30, 'r--');
grid on;
xlabel('L_{cell}');
ylabel('Buffer Empty [%]');
title('버퍼 비어있음 비율');

subplot(1, 3, 2);
plot(L, uora_delay, 'm-o', 'LineWidth', 2);
grid on;
xlabel('L_{cell}');
ylabel('UORA Delay [ms]');
title('UORA 지연');

subplot(1, 3, 3);
plot(L, implicit_bsr*100, 'c-o', 'LineWidth', 2);
yline(50, 'k--');
grid on;
xlabel('L_{cell}');
ylabel('Implicit BSR [%]');
title('Implicit BSR 비율');

sgtitle('Exp 1-1 빠른 탐색', 'FontSize', 14, 'FontWeight', 'bold');