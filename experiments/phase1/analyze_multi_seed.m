%% analyze_multi_seed.m
% Multi-Seed 결과 분석 및 시각화
%
% 출력:
%   1. Seed별, Scenario별 improvement
%   2. Box plot (분포)
%   3. 통계 분석 (평균, std, 범위)
%   4. 최종 결론

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  Multi-Seed 결과 분석\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'multi_seed_validation.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s', load_file);
end

fprintf('결과 로드: %s\n\n', load_file);
load(load_file);

num_seeds = length(results.seeds);
num_scenarios = length(results.scenarios);

%% 2. 데이터 추출

delay_matrix = zeros(num_seeds, num_scenarios);
p90_matrix = zeros(num_seeds, num_scenarios);
coll_matrix = zeros(num_seeds, num_scenarios);

for seed_idx = 1:num_seeds
    for s_idx = 1:num_scenarios
        delay_matrix(seed_idx, s_idx) = results.summary(seed_idx, s_idx).improve_delay;
        p90_matrix(seed_idx, s_idx) = results.summary(seed_idx, s_idx).improve_p90;
        coll_matrix(seed_idx, s_idx) = results.summary(seed_idx, s_idx).improve_coll;
    end
end

%% 3. 상세 테이블

fprintf('========================================\n');
fprintf('  상세 결과 (Seed × Scenario)\n');
fprintf('========================================\n\n');

fprintf('Mean Delay Improvement [%%]:\n');
fprintf('%-6s |', 'Seed');
for s_idx = 1:num_scenarios
    fprintf(' %6s |', results.scenarios(s_idx).name);
end
fprintf(' %6s\n', 'Avg');
fprintf('%s\n', repmat('-', 1, 10 + 9*num_scenarios + 9));

for seed_idx = 1:num_seeds
    fprintf('%5d  |', results.seeds(seed_idx));
    for s_idx = 1:num_scenarios
        fprintf(' %6.2f |', delay_matrix(seed_idx, s_idx));
    end
    fprintf(' %6.2f\n', mean(delay_matrix(seed_idx, :)));
end

fprintf('%s\n', repmat('-', 1, 10 + 9*num_scenarios + 9));
fprintf('%-6s |', 'Avg');
for s_idx = 1:num_scenarios
    fprintf(' %6.2f |', mean(delay_matrix(:, s_idx)));
end
fprintf(' %6.2f\n\n', mean(delay_matrix(:)));

%% 4. 통계 요약

fprintf('========================================\n');
fprintf('  통계 요약\n');
fprintf('========================================\n\n');

all_delay = delay_matrix(:);
all_p90 = p90_matrix(:);
all_coll = coll_matrix(:);

fprintf('Mean Delay Improvement:\n');
fprintf('  평균:     %.2f%%\n', mean(all_delay));
fprintf('  표준편차: %.2f%%\n', std(all_delay));
fprintf('  범위:     %.2f%% ~ %.2f%%\n', min(all_delay), max(all_delay));
fprintf('  중앙값:   %.2f%%\n\n', median(all_delay));

fprintf('P90 Delay Improvement:\n');
fprintf('  평균:     %.2f%%\n', mean(all_p90));
fprintf('  표준편차: %.2f%%\n', std(all_p90));
fprintf('  범위:     %.2f%% ~ %.2f%%\n\n', min(all_p90), max(all_p90));

fprintf('Collision Improvement:\n');
fprintf('  평균:     %.2f%%\n', mean(all_coll));
fprintf('  표준편차: %.2f%%\n', std(all_coll));
fprintf('  범위:     %.2f%% ~ %.2f%%\n\n', min(all_coll), max(all_coll));

%% 5. Bar Plot 시각화 (boxplot 대체)

figure('Position', [100, 100, 1400, 400]);
sgtitle('Multi-Seed Performance Distribution', 'FontSize', 14, 'FontWeight', 'bold');

% 1. Mean Delay
subplot(1, 3, 1);
b = bar(delay_matrix');
set(gca, 'XTickLabel', {results.scenarios.name});
ylabel('Mean Delay Improvement [%]');
title('Mean Delay');
legend(arrayfun(@(x) sprintf('Seed %d', x), results.seeds, 'UniformOutput', false), ...
    'Location', 'best');
grid on;
hold on;
plot(xlim, [mean(all_delay), mean(all_delay)], 'r--', 'LineWidth', 2);
hold off;

% 2. P90 Delay
subplot(1, 3, 2);
b = bar(p90_matrix');
set(gca, 'XTickLabel', {results.scenarios.name});
ylabel('P90 Delay Improvement [%]');
title('P90 Delay');
legend(arrayfun(@(x) sprintf('Seed %d', x), results.seeds, 'UniformOutput', false), ...
    'Location', 'best');
grid on;
hold on;
plot(xlim, [mean(all_p90), mean(all_p90)], 'r--', 'LineWidth', 2);
hold off;

% 3. Collision
subplot(1, 3, 3);
b = bar(coll_matrix');
set(gca, 'XTickLabel', {results.scenarios.name});
ylabel('Collision Improvement [%]');
title('Collision');
legend(arrayfun(@(x) sprintf('Seed %d', x), results.seeds, 'UniformOutput', false), ...
    'Location', 'best');
grid on;
hold on;
plot(xlim, [mean(all_coll), mean(all_coll)], 'r--', 'LineWidth', 2);
hold off;

saveas(gcf, 'multi_seed_boxplot.png');
fprintf('저장: multi_seed_boxplot.png\n\n');

%% 6. Seed별 비교

figure('Position', [100, 100, 1400, 400]);
sgtitle('Improvement by Seed', 'FontSize', 14, 'FontWeight', 'bold');

x = 1:num_seeds;
colors = lines(num_scenarios);

% Mean Delay
subplot(1, 3, 1);
hold on;
for s_idx = 1:num_scenarios
    plot(x, delay_matrix(:, s_idx), '-o', 'LineWidth', 2, ...
        'Color', colors(s_idx, :), 'DisplayName', results.scenarios(s_idx).name);
end
hold off;
set(gca, 'XTick', x, 'XTickLabel', results.seeds);
xlabel('Seed');
ylabel('Mean Delay Improvement [%]');
title('Mean Delay');
legend('Location', 'best');
grid on;

% P90 Delay
subplot(1, 3, 2);
hold on;
for s_idx = 1:num_scenarios
    plot(x, p90_matrix(:, s_idx), '-o', 'LineWidth', 2, ...
        'Color', colors(s_idx, :), 'DisplayName', results.scenarios(s_idx).name);
end
hold off;
set(gca, 'XTick', x, 'XTickLabel', results.seeds);
xlabel('Seed');
ylabel('P90 Delay Improvement [%]');
title('P90 Delay');
legend('Location', 'best');
grid on;

% Collision
subplot(1, 3, 3);
hold on;
for s_idx = 1:num_scenarios
    plot(x, coll_matrix(:, s_idx), '-o', 'LineWidth', 2, ...
        'Color', colors(s_idx, :), 'DisplayName', results.scenarios(s_idx).name);
end
hold off;
set(gca, 'XTick', x, 'XTickLabel', results.seeds);
xlabel('Seed');
ylabel('Collision Improvement [%]');
title('Collision');
legend('Location', 'best');
grid on;

saveas(gcf, 'multi_seed_trends.png');
fprintf('저장: multi_seed_trends.png\n\n');

%% 7. 최종 결론

fprintf('========================================\n');
fprintf('  최종 결론\n');
fprintf('========================================\n\n');

fprintf('v3 BSR Reduction 성능 (5 seeds, 3 scenarios):\n\n');

fprintf('✅ 평균 Improvement:\n');
fprintf('   Mean Delay:  %.2f%% (std: %.2f%%)\n', mean(all_delay), std(all_delay));
fprintf('   P90 Delay:   %.2f%% (std: %.2f%%)\n', mean(all_p90), std(all_p90));
fprintf('   Collision:   %.2f%% (std: %.2f%%)\n\n', mean(all_coll), std(all_coll));

fprintf('📊 Performance Range:\n');
fprintf('   Mean Delay:  %.2f%% ~ %.2f%%\n', min(all_delay), max(all_delay));
fprintf('   P90 Delay:   %.2f%% ~ %.2f%%\n', min(all_p90), max(all_p90));
fprintf('   Collision:   %.2f%% ~ %.2f%%\n\n', min(all_coll), max(all_coll));

% 논문용 표현
if mean(all_delay) >= 5.0
    fprintf('🎯 결론: v3는 평균 5%%+ 개선 달성! ✅\n');
    fprintf('   논문에 "significant improvement" 주장 가능\n');
elseif mean(all_delay) >= 3.0
    fprintf('⚠️  결론: v3는 평균 3-5%% 개선 달성\n');
    fprintf('   논문에 "moderate improvement" 표현 적절\n');
else
    fprintf('❌ 결론: v3는 평균 3%% 미만 개선\n');
    fprintf('   효과가 제한적, 추가 연구 필요\n');
end

fprintf('\n');

%% 8. Seed Dependency 평가

seed_means = mean(delay_matrix, 2);
seed_std = std(seed_means);

fprintf('========================================\n');
fprintf('  Seed Dependency 평가\n');
fprintf('========================================\n\n');

fprintf('Seed별 평균 (3 scenarios):\n');
for seed_idx = 1:num_seeds
    fprintf('  Seed %d: %.2f%%\n', results.seeds(seed_idx), seed_means(seed_idx));
end
fprintf('\n');

fprintf('Seed 간 표준편차: %.2f%%\n', seed_std);

if seed_std < 1.0
    fprintf('→ Seed dependency 낮음 (robust) ✅\n\n');
elseif seed_std < 2.0
    fprintf('→ Seed dependency 중간 (acceptable) ⚠️\n\n');
else
    fprintf('→ Seed dependency 높음 (concerning) ❌\n\n');
end

fprintf('========================================\n');
fprintf('  분석 완료!\n');
fprintf('========================================\n\n');

fprintf('생성된 파일:\n');
fprintf('  - multi_seed_boxplot.png\n');
fprintf('  - multi_seed_trends.png\n\n');