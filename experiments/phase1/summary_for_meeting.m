%% summary_for_meeting.m
% 랩미팅용 전체 결과 요약
%
% 모든 지표에 대해 Baseline vs v3 비교
% 깔끔한 표 형식으로 출력

clear; close all; clc;

fprintf('\n========================================\n');
fprintf('  v3 Sweep 전체 결과 요약\n');
fprintf('  (랩미팅용)\n');
fprintf('========================================\n\n');

%% 1. 결과 로드

load_file = 'v3_sweep_results.mat';
if ~exist(load_file, 'file')
    error('결과 파일 없음: %s', load_file);
end

fprintf('결과 로드: %s\n', load_file);
load(load_file);

num_scenarios = length(results.scenarios);
num_runs = results.num_runs;

fprintf('  Scenarios: %d\n', num_scenarios);
fprintf('  Runs per scenario: %d\n', num_runs);
fprintf('  v3 alpha: %.2f\n', results.v3_alpha);
fprintf('  v3 max_red: %.2f\n\n', results.v3_max_red);

%% 2. Metric 추출

fprintf('========================================\n');
fprintf('  Metric 추출 중...\n');
fprintf('========================================\n\n');

metrics = struct();

for s = 1:num_scenarios
    
    % Scenario 정보
    metrics(s).scenario_idx = s;
    metrics(s).L_cell = results.scenarios(s).L_cell;
    metrics(s).mu_on = results.scenarios(s).mu_on;
    metrics(s).rho = results.scenarios(s).rho;
    metrics(s).RA_RU = results.scenarios(s).RA_RU;
    
    % Baseline 평균
    base_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.baseline(s, :)));
    base_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.baseline(s, :)));
    base_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.baseline(s, :)));
    base_p99 = mean(cellfun(@(x) x.summary.p99_delay_ms, results.baseline(s, :)));
    base_coll = mean(cellfun(@(x) x.uora.collision_rate, results.baseline(s, :)));
    base_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.baseline(s, :)));
    base_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.baseline(s, :)));
    base_total_bsr = mean(cellfun(@(x) x.bsr.total_bsr, results.baseline(s, :)));
    base_buffer_empty = mean(cellfun(@(x) x.bsr.buffer_empty_ratio, results.baseline(s, :)));
    base_throughput = mean(cellfun(@(x) x.throughput.throughput_mbps, results.baseline(s, :)));
    
    metrics(s).base_delay = base_delay;
    metrics(s).base_p90 = base_p90;
    metrics(s).base_p10 = base_p10;
    metrics(s).base_p99 = base_p99;
    metrics(s).base_coll = base_coll;
    metrics(s).base_expl = base_expl;
    metrics(s).base_impl = base_impl;
    metrics(s).base_total_bsr = base_total_bsr;
    metrics(s).base_expl_ratio = base_expl / base_total_bsr * 100;
    metrics(s).base_buffer_empty = base_buffer_empty;
    metrics(s).base_throughput = base_throughput;
    
    % v3 평균
    v3_delay = mean(cellfun(@(x) x.summary.mean_delay_ms, results.v3(s, :)));
    v3_p90 = mean(cellfun(@(x) x.summary.p90_delay_ms, results.v3(s, :)));
    v3_p10 = mean(cellfun(@(x) x.summary.p10_delay_ms, results.v3(s, :)));
    v3_p99 = mean(cellfun(@(x) x.summary.p99_delay_ms, results.v3(s, :)));
    v3_coll = mean(cellfun(@(x) x.uora.collision_rate, results.v3(s, :)));
    v3_expl = mean(cellfun(@(x) x.bsr.total_explicit, results.v3(s, :)));
    v3_impl = mean(cellfun(@(x) x.bsr.total_implicit, results.v3(s, :)));
    v3_total_bsr = mean(cellfun(@(x) x.bsr.total_bsr, results.v3(s, :)));
    v3_buffer_empty = mean(cellfun(@(x) x.bsr.buffer_empty_ratio, results.v3(s, :)));
    v3_throughput = mean(cellfun(@(x) x.throughput.throughput_mbps, results.v3(s, :)));
    
    metrics(s).v3_delay = v3_delay;
    metrics(s).v3_p90 = v3_p90;
    metrics(s).v3_p10 = v3_p10;
    metrics(s).v3_p99 = v3_p99;
    metrics(s).v3_coll = v3_coll;
    metrics(s).v3_expl = v3_expl;
    metrics(s).v3_impl = v3_impl;
    metrics(s).v3_total_bsr = v3_total_bsr;
    metrics(s).v3_expl_ratio = v3_expl / v3_total_bsr * 100;
    metrics(s).v3_buffer_empty = v3_buffer_empty;
    metrics(s).v3_throughput = v3_throughput;
    
    % Improvement 계산
    metrics(s).improve_delay = (base_delay - v3_delay) / base_delay * 100;
    metrics(s).improve_p90 = (base_p90 - v3_p90) / base_p90 * 100;
    metrics(s).improve_p10 = (base_p10 - v3_p10) / base_p10 * 100;
    metrics(s).improve_p99 = (base_p99 - v3_p99) / base_p99 * 100;
    metrics(s).improve_coll = (base_coll - v3_coll) / base_coll * 100;
    metrics(s).improve_expl = (base_expl - v3_expl) / base_expl * 100;
    metrics(s).improve_throughput = (v3_throughput - base_throughput) / base_throughput * 100;
end

fprintf('Metric 추출 완료!\n\n');

%% 3. 전체 결과 표 출력

fprintf('========================================\n');
fprintf('  전체 결과 상세 (Baseline vs v3)\n');
fprintf('========================================\n\n');

fprintf('%-4s | %-20s | %-12s | %-12s | %-10s\n', ...
    'Idx', 'Scenario', 'Baseline', 'v3', 'Improve');
fprintf('%s\n', repmat('-', 1, 75));

for s = 1:num_scenarios
    m = metrics(s);
    
    fprintf('\n[ Scenario #%d ] L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        s, m.L_cell, m.mu_on, m.rho, m.RA_RU);
    fprintf('%s\n', repmat('-', 1, 75));
    
    % Mean Delay
    fprintf('%-20s | %10.2f ms | %10.2f ms | %8.2f%%\n', ...
        'Mean Delay', m.base_delay, m.v3_delay, m.improve_delay);
    
    % P10 Delay
    fprintf('%-20s | %10.2f ms | %10.2f ms | %8.2f%%\n', ...
        'P10 Delay', m.base_p10, m.v3_p10, m.improve_p10);
    
    % P90 Delay
    fprintf('%-20s | %10.2f ms | %10.2f ms | %8.2f%%\n', ...
        'P90 Delay', m.base_p90, m.v3_p90, m.improve_p90);
    
    % P99 Delay
    fprintf('%-20s | %10.2f ms | %10.2f ms | %8.2f%%\n', ...
        'P99 Delay', m.base_p99, m.v3_p99, m.improve_p99);
    
    % Collision Rate
    fprintf('%-20s | %10.2f %% | %10.2f %% | %8.2f%%\n', ...
        'Collision Rate', m.base_coll*100, m.v3_coll*100, m.improve_coll);
    
    % Throughput
    fprintf('%-20s | %10.2f Mbps | %10.2f Mbps | %8.2f%%\n', ...
        'Throughput', m.base_throughput, m.v3_throughput, m.improve_throughput);
    
    % Explicit BSR
    fprintf('%-20s | %10.0f     | %10.0f     | %8.2f%%\n', ...
        'Explicit BSR', m.base_expl, m.v3_expl, m.improve_expl);
    
    % Explicit BSR Ratio
    fprintf('%-20s | %10.2f %% | %10.2f %% | %8s\n', ...
        'Explicit BSR Ratio', m.base_expl_ratio, m.v3_expl_ratio, '-');
    
    % Implicit BSR
    fprintf('%-20s | %10.0f     | %10.0f     | %8s\n', ...
        'Implicit BSR', m.base_impl, m.v3_impl, '-');
    
    % Total BSR
    fprintf('%-20s | %10.0f     | %10.0f     | %8s\n', ...
        'Total BSR', m.base_total_bsr, m.v3_total_bsr, '-');
    
    % Buffer Empty Ratio
    fprintf('%-20s | %10.2f %% | %10.2f %% | %8s\n', ...
        'Buffer Empty Ratio', m.base_buffer_empty*100, m.v3_buffer_empty*100, '-');
end

fprintf('\n');

%% 4. 전체 평균

fprintf('========================================\n');
fprintf('  전체 평균 (모든 %d scenarios)\n', num_scenarios);
fprintf('========================================\n\n');

avg_improve_delay = mean([metrics.improve_delay]);
avg_improve_p90 = mean([metrics.improve_p90]);
avg_improve_p10 = mean([metrics.improve_p10]);
avg_improve_p99 = mean([metrics.improve_p99]);
avg_improve_coll = mean([metrics.improve_coll]);
avg_improve_expl = mean([metrics.improve_expl]);
avg_improve_throughput = mean([metrics.improve_throughput]);

fprintf('평균 Improvement:\n');
fprintf('  Mean Delay:    %6.2f%%\n', avg_improve_delay);
fprintf('  P10 Delay:     %6.2f%%\n', avg_improve_p10);
fprintf('  P90 Delay:     %6.2f%%\n', avg_improve_p90);
fprintf('  P99 Delay:     %6.2f%%\n', avg_improve_p99);
fprintf('  Collision:     %6.2f%%\n', avg_improve_coll);
fprintf('  Throughput:    %6.2f%%\n', avg_improve_throughput);
fprintf('  Explicit BSR:  %6.2f%%\n\n', avg_improve_expl);

%% 5. Best/Worst Cases

fprintf('========================================\n');
fprintf('  Best Cases (Mean Delay 기준)\n');
fprintf('========================================\n\n');

[~, sorted_idx] = sort([metrics.improve_delay], 'descend');

fprintf('Top 5:\n');
for i = 1:min(5, num_scenarios)
    idx = sorted_idx(i);
    m = metrics(idx);
    fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        idx, m.L_cell, m.mu_on, m.rho, m.RA_RU);
    fprintf('       Mean Delay: %.2f%%, P90: %.2f%%, Coll: %.2f%%\n', ...
        m.improve_delay, m.improve_p90, m.improve_coll);
    fprintf('       ExplR: %.1f%% (Baseline), %.1f%% (v3)\n\n', ...
        m.base_expl_ratio, m.v3_expl_ratio);
end

fprintf('========================================\n');
fprintf('  Worst Cases (Mean Delay 기준)\n');
fprintf('========================================\n\n');

fprintf('Bottom 3:\n');
for i = max(1, num_scenarios-2):num_scenarios
    idx = sorted_idx(i);
    m = metrics(idx);
    fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        idx, m.L_cell, m.mu_on, m.rho, m.RA_RU);
    fprintf('       Mean Delay: %.2f%%, P90: %.2f%%, Coll: %.2f%%\n', ...
        m.improve_delay, m.improve_p90, m.improve_coll);
    fprintf('       ExplR: %.1f%% (Baseline), %.1f%% (v3)\n\n', ...
        m.base_expl_ratio, m.v3_expl_ratio);
end

%% 6. 조건별 분류

fprintf('========================================\n');
fprintf('  조건별 평균 Improvement\n');
fprintf('========================================\n\n');

% L_cell별
L_values = unique([metrics.L_cell]);
fprintf('L_cell별:\n');
for L = L_values
    idx = find([metrics.L_cell] == L);
    avg_delay = mean([metrics(idx).improve_delay]);
    avg_coll = mean([metrics(idx).improve_coll]);
    fprintf('  L=%.1f: Delay %.2f%%, Coll %.2f%% (n=%d)\n', ...
        L, avg_delay, avg_coll, length(idx));
end
fprintf('\n');

% rho별
rho_values = unique([metrics.rho]);
fprintf('rho별:\n');
for rho = rho_values
    idx = find([metrics.rho] == rho);
    avg_delay = mean([metrics(idx).improve_delay]);
    avg_coll = mean([metrics(idx).improve_coll]);
    fprintf('  rho=%.1f: Delay %.2f%%, Coll %.2f%% (n=%d)\n', ...
        rho, avg_delay, avg_coll, length(idx));
end
fprintf('\n');

% RA_RU별
RA_values = unique([metrics.RA_RU]);
fprintf('RA_RU별:\n');
for RA = RA_values
    idx = find([metrics.RA_RU] == RA);
    avg_delay = mean([metrics(idx).improve_delay]);
    avg_coll = mean([metrics(idx).improve_coll]);
    fprintf('  RA=%d: Delay %.2f%%, Coll %.2f%% (n=%d)\n', ...
        RA, avg_delay, avg_coll, length(idx));
end
fprintf('\n');

%% 7. CSV 저장 (선택)

fprintf('========================================\n');
fprintf('  CSV 파일 저장\n');
fprintf('========================================\n\n');

csv_file = 'v3_sweep_summary.csv';
fid = fopen(csv_file, 'w');

% Header
fprintf(fid, 'Scenario,L_cell,mu_on,rho,RA_RU,');
fprintf(fid, 'Base_MeanDelay,v3_MeanDelay,Improve_MeanDelay,');
fprintf(fid, 'Base_P90,v3_P90,Improve_P90,');
fprintf(fid, 'Base_Coll,v3_Coll,Improve_Coll,');
fprintf(fid, 'Base_ExplR,v3_ExplR,Improve_ExplBSR,');
fprintf(fid, 'Base_Throughput,v3_Throughput,Improve_Throughput\n');

% Data
for s = 1:num_scenarios
    m = metrics(s);
    fprintf(fid, '%d,%.1f,%.2f,%.1f,%d,', ...
        s, m.L_cell, m.mu_on, m.rho, m.RA_RU);
    fprintf(fid, '%.2f,%.2f,%.2f,', ...
        m.base_delay, m.v3_delay, m.improve_delay);
    fprintf(fid, '%.2f,%.2f,%.2f,', ...
        m.base_p90, m.v3_p90, m.improve_p90);
    fprintf(fid, '%.4f,%.4f,%.2f,', ...
        m.base_coll, m.v3_coll, m.improve_coll);
    fprintf(fid, '%.2f,%.2f,%.2f,', ...
        m.base_expl_ratio, m.v3_expl_ratio, m.improve_expl);
    fprintf(fid, '%.2f,%.2f,%.2f\n', ...
        m.base_throughput, m.v3_throughput, m.improve_throughput);
end

fclose(fid);

fprintf('CSV 저장: %s\n\n', csv_file);

%% 8. 권장 집중 실험 시나리오

fprintf('========================================\n');
fprintf('  권장 집중 실험 시나리오\n');
fprintf('========================================\n\n');

% Delay improvement > 5% 인 시나리오
good_scenarios = find([metrics.improve_delay] > 5.0);

fprintf('Mean Delay 5%% 이상 개선 시나리오: %d개\n\n', length(good_scenarios));

for i = 1:length(good_scenarios)
    idx = good_scenarios(i);
    m = metrics(idx);
    fprintf('  #%d: L=%.1f, mu=%.2f, rho=%.1f, RA=%d\n', ...
        idx, m.L_cell, m.mu_on, m.rho, m.RA_RU);
    fprintf('       Improve: Delay %.2f%%, P90 %.2f%%, Coll %.2f%%\n', ...
        m.improve_delay, m.improve_p90, m.improve_coll);
    fprintf('       ExplR: %.1f%%\n\n', m.base_expl_ratio);
end

fprintf('이 시나리오들로 집중 실험 추천 (runs 증가)\n');
fprintf('========================================\n\n');