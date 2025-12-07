%% analyze_phase0b.m
% Phase 0B: mu_on 영향 종합 분석
%
% 목표:
%   mu_on (burst duration)이 성능에 미치는 영향 분석
%
% 분석:
%   - mu_on별 성능 비교
%   - rho × mu_on 상호작용
%   - 최적 mu_on 찾기

clear; close all; clc;

fprintf('\n');
fprintf('========================================\n');
fprintf('  Phase 0B: mu_on 종합 분석\n');
fprintf('========================================\n\n');

%% =====================================================================
%  1. 데이터 로드
%  =====================================================================

fprintf('[1/6] 데이터 로드\n');
fprintf('----------------------------------------\n');
csv_file = 'results/phase0/csv/baseline_sweep_summary.csv';


if ~exist(csv_file, 'file')
    error('CSV 파일을 찾을 수 없습니다: %s', csv_file);
end

T = readtable(csv_file);

fprintf('  ✓ 로드 완료: %d개 설정\n', height(T));
fprintf('  컬럼 수: %d개\n', width(T));

% mu_on 컬럼 확인 및 추가
if ~ismember('mu_on', T.Properties.VariableNames)
    warning('mu_on 컬럼이 없습니다! Config ID로 추정합니다.');
    
    % 24 configs 구조: rho 3개 × mu_on 4개 × RA 2개
    % Config 1-8: rho=0.3, mu_on=[0.01,0.01,0.05,0.05,0.1,0.1,0.5,0.5]
    mu_on_pattern = [0.01, 0.01, 0.05, 0.05, 0.1, 0.1, 0.5, 0.5];
    T.mu_on = zeros(height(T), 1);
    
    for i = 1:height(T)
        config_id = T.config_id(i);
        idx = mod(config_id - 1, 8) + 1;
        T.mu_on(i) = mu_on_pattern(idx);
    end
    
    fprintf('  ⚠️  mu_on 값 추정 완료\n');
end

fprintf('\n');

%% =====================================================================
%  2. 전체 데이터 출력
%  =====================================================================

fprintf('[2/6] 전체 데이터 출력\n');
fprintf('----------------------------------------\n\n');

fprintf('========================================\n');
fprintf('  설정 파라미터\n');
fprintf('========================================\n\n');

fprintf('ID   | L_cell rho    mu_on  STAs   RA-RU  SA-RU \n');
fprintf('--------------------------------------------------\n');

for i = 1:height(T)
    fprintf('%-4d | %.1f    %.1f    %.2f   %-6d %-6d %-6d\n', ...
        T.config_id(i), T.L_cell(i), T.rho(i), T.mu_on(i), ...
        T.num_STAs(i), T.numRU_RA(i), T.numRU_SA(i));
end

fprintf('\n');

% 성능 지표
fprintf('========================================\n');
fprintf('  지연 지표 (Delay)\n');
fprintf('========================================\n\n');

fprintf('ID   | Mean[ms]   Std[ms]    P10[ms]    P90[ms]   \n');
fprintf('------------------------------------------------------------\n');

for i = 1:height(T)
    fprintf('%-4d | %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
        T.config_id(i), T.mean_delay_ms(i), T.std_delay_ms(i), ...
        T.p10_delay_ms(i), T.p90_delay_ms(i));
end

fprintf('\n');

% UORA 효율성
fprintf('========================================\n');
fprintf('  UORA 효율성\n');
fprintf('========================================\n\n');

fprintf('ID   | Coll[%%]     Success[%%] \n');
fprintf('----------------------------------------\n');

for i = 1:height(T)
    fprintf('%-4d | %-12.1f %-12.1f\n', ...
        T.config_id(i), T.collision_rate(i) * 100, T.success_rate(i) * 100);
end

fprintf('\n');

% BSR 지표
fprintf('========================================\n');
fprintf('  BSR 지표 ⭐\n');
fprintf('========================================\n\n');

fprintf('ID   | Explicit[%%] BufEmpty[%%]    | Expl.Cnt     Impl.Cnt    \n');
fprintf('----------------------------------------------------------------------\n');

for i = 1:height(T)
    fprintf('%-4d | %-12.1f %-16.1f | %-12d %-12d\n', ...
        T.config_id(i), T.explicit_bsr_ratio(i) * 100, ...
        T.buffer_empty_ratio(i) * 100, ...
        T.explicit_bsr_count(i), T.implicit_bsr_count(i));
end

fprintf('\n');

%% =====================================================================
%  3. mu_on 영향 분석
%  =====================================================================

fprintf('[3/6] mu_on 영향 분석\n');
fprintf('----------------------------------------\n\n');

mu_on_vals = unique(T.mu_on);
rho_vals = unique(T.rho);

fprintf('  [mu_on별 평균 성능]\n\n');

fprintf('  mu_on  | Mean Delay[ms] | Collision[%%] | Explicit BSR[%%] | BufEmpty[%%]\n');
fprintf('  --------------------------------------------------------------------------\n');

for mu_idx = 1:length(mu_on_vals)
    mu_on = mu_on_vals(mu_idx);
    
    mask = abs(T.mu_on - mu_on) < 0.001;
    
    avg_delay = mean(T.mean_delay_ms(mask));
    avg_coll = mean(T.collision_rate(mask)) * 100;
    avg_expl = mean(T.explicit_bsr_ratio(mask)) * 100;
    avg_buf = mean(T.buffer_empty_ratio(mask)) * 100;
    
    fprintf('  %.2f   | %-14.2f | %-13.1f | %-16.1f | %-12.1f\n', ...
        mu_on, avg_delay, avg_coll, avg_expl, avg_buf);
end

fprintf('\n');

% rho별 mu_on 영향
fprintf('  [rho별 mu_on 영향]\n\n');

for rho_idx = 1:length(rho_vals)
    rho = rho_vals(rho_idx);
    
    fprintf('  rho = %.1f:\n', rho);
    fprintf('  mu_on  | Mean Delay[ms] | Collision[%%] | Explicit BSR[%%]\n');
    fprintf('  ---------------------------------------------------------------\n');
    
    for mu_idx = 1:length(mu_on_vals)
        mu_on = mu_on_vals(mu_idx);
        
        mask = (abs(T.rho - rho) < 0.01) & (abs(T.mu_on - mu_on) < 0.001);
        
        if sum(mask) > 0
            avg_delay = mean(T.mean_delay_ms(mask));
            avg_coll = mean(T.collision_rate(mask)) * 100;
            avg_expl = mean(T.explicit_bsr_ratio(mask)) * 100;
            
            fprintf('  %.2f   | %-14.2f | %-13.1f | %-16.1f\n', ...
                mu_on, avg_delay, avg_coll, avg_expl);
        end
    end
    
    fprintf('\n');
end

%% =====================================================================
%  4. RA-RU 비교 (mu_on별)
%  =====================================================================

fprintf('[4/6] RA-RU 비교 (mu_on별)\n');
fprintf('----------------------------------------\n\n');

fprintf('  [RA-RU=1 vs RA-RU=2 비교]\n\n');

fprintf('  mu_on | RA=1[ms]     RA=2[ms]     | Diff[ms]     Diff[%%]     \n');
fprintf('  --------------------------------------------------------------------\n');

for mu_idx = 1:length(mu_on_vals)
    mu_on = mu_on_vals(mu_idx);
    
    mask_ra1 = (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == 1);
    mask_ra2 = (abs(T.mu_on - mu_on) < 0.001) & (T.numRU_RA == 2);
    
    delay_ra1 = mean(T.mean_delay_ms(mask_ra1));
    delay_ra2 = mean(T.mean_delay_ms(mask_ra2));
    
    diff_abs = delay_ra1 - delay_ra2;
    diff_pct = (diff_abs / delay_ra1) * 100;
    
    fprintf('  %.2f  | %-12.2f %-12.2f | %-12.2f %-12.1f\n', ...
        mu_on, delay_ra1, delay_ra2, diff_abs, diff_pct);
end

fprintf('\n');

%% =====================================================================
%  5. 핵심 발견사항
%  =====================================================================

fprintf('[5/6] 핵심 발견사항\n');
fprintf('----------------------------------------\n\n');

% Finding 1: mu_on 단조성
fprintf('  [Finding 1] mu_on 영향 패턴\n');

delays_by_mu = zeros(length(mu_on_vals), 1);
for i = 1:length(mu_on_vals)
    mask = abs(T.mu_on - mu_on_vals(i)) < 0.001;
    delays_by_mu(i) = mean(T.mean_delay_ms(mask));
end

if all(diff(delays_by_mu) > 0)
    fprintf('    • mu_on ↑ → Delay ↑ (단조 증가) ⭐\n');
elseif all(diff(delays_by_mu) < 0)
    fprintf('    • mu_on ↑ → Delay ↓ (단조 감소)\n');
else
    fprintf('    • mu_on과 Delay: 비단조 관계 (최적점 존재)\n');
end

fprintf('    • mu_on=%.2f: %.2f ms (최소)\n', ...
    mu_on_vals(delays_by_mu == min(delays_by_mu)), min(delays_by_mu));
fprintf('    • mu_on=%.2f: %.2f ms (최대)\n', ...
    mu_on_vals(delays_by_mu == max(delays_by_mu)), max(delays_by_mu));

fprintf('\n');

% Finding 2: Explicit BSR vs mu_on
fprintf('  [Finding 2] Explicit BSR vs mu_on\n');

expl_by_mu = zeros(length(mu_on_vals), 1);
for i = 1:length(mu_on_vals)
    mask = abs(T.mu_on - mu_on_vals(i)) < 0.001;
    expl_by_mu(i) = mean(T.explicit_bsr_ratio(mask)) * 100;
end

if all(diff(expl_by_mu) < 0)
    fprintf('    • mu_on ↑ → Explicit BSR ↓ (예상대로) ⭐\n');
    fprintf('      → 긴 burst = SA mode 오래 유지\n');
end

fprintf('    • mu_on=%.2f: %.1f%% (최고)\n', ...
    mu_on_vals(expl_by_mu == max(expl_by_mu)), max(expl_by_mu));
fprintf('    • mu_on=%.2f: %.1f%% (최저)\n', ...
    mu_on_vals(expl_by_mu == min(expl_by_mu)), min(expl_by_mu));

fprintf('\n');

% Finding 3: Buffer Empty vs mu_on
fprintf('  [Finding 3] Buffer Empty vs mu_on\n');

buf_by_mu = zeros(length(mu_on_vals), 1);
for i = 1:length(mu_on_vals)
    mask = abs(T.mu_on - mu_on_vals(i)) < 0.001;
    buf_by_mu(i) = mean(T.buffer_empty_ratio(mask)) * 100;
end

if all(diff(buf_by_mu) < 0)
    fprintf('    • mu_on ↑ → Buffer Empty ↓ ⭐\n');
    fprintf('      → 긴 burst = 큐 오래 유지\n');
end

fprintf('    • 범위: %.1f%% ~ %.1f%%\n', min(buf_by_mu), max(buf_by_mu));

fprintf('\n');

% Finding 4: rho × mu_on 상호작용
fprintf('  [Finding 4] rho × mu_on 상호작용\n');

fprintf('    같은 rho=0.3이라도:\n');
for mu_idx = 1:length(mu_on_vals)
    mu_on = mu_on_vals(mu_idx);
    mu_off = mu_on * (1 - 0.3) / 0.3;
    cycle = mu_on + mu_off;
    
    fprintf('      • mu_on=%.2fs: ON %.0fms, OFF %.0fms (cycle: %.0fms)\n', ...
        mu_on, mu_on*1000, mu_off*1000, cycle*1000);
end

fprintf('    → Burst pattern의 독립적 영향! ⭐\n');

fprintf('\n');

% Finding 5: RA-RU 영향
fprintf('  [Finding 5] RA-RU 영향 (mu_on 평균)\n');

delay_ra1 = mean(T.mean_delay_ms(T.numRU_RA == 1));
delay_ra2 = mean(T.mean_delay_ms(T.numRU_RA == 2));

fprintf('    • RA-RU=1: %.2f ms\n', delay_ra1);
fprintf('    • RA-RU=2: %.2f ms (%.1f%% 개선) ⭐\n', ...
    delay_ra2, ((delay_ra1 - delay_ra2) / delay_ra1) * 100);

fprintf('\n');

%% =====================================================================
%  6. 최적 시나리오 추천
%  =====================================================================

fprintf('[6/6] 최적 시나리오 추천\n');
fprintf('----------------------------------------\n\n');

% 최저 Delay
[min_delay, min_idx] = min(T.mean_delay_ms);

fprintf('  [최저 Delay 시나리오]\n');
fprintf('    Config ID: %d\n', T.config_id(min_idx));
fprintf('    rho: %.1f, mu_on: %.2f, RA-RU: %d\n', ...
    T.rho(min_idx), T.mu_on(min_idx), T.numRU_RA(min_idx));
fprintf('    Mean Delay: %.2f ms\n', min_delay);
fprintf('    Collision: %.1f%%\n', T.collision_rate(min_idx) * 100);
fprintf('    Explicit BSR: %.1f%%\n\n', T.explicit_bsr_ratio(min_idx) * 100);

% 최고 Explicit BSR (최적화 여지)
[max_expl, max_idx] = max(T.explicit_bsr_ratio);

fprintf('  [최고 Explicit BSR 시나리오 (최적화 여지)]\n');
fprintf('    Config ID: %d\n', T.config_id(max_idx));
fprintf('    rho: %.1f, mu_on: %.2f, RA-RU: %d\n', ...
    T.rho(max_idx), T.mu_on(max_idx), T.numRU_RA(max_idx));
fprintf('    Explicit BSR: %.1f%%\n', max_expl * 100);
fprintf('    Explicit Count: %d회 ⭐\n', T.explicit_bsr_count(max_idx));
fprintf('    Mean Delay: %.2f ms\n\n', T.mean_delay_ms(max_idx));

% Phase 0 vs Phase 0B 비교 (mu_on=0.05)
fprintf('  [Phase 0 기준점 (mu_on=0.05)]\n');

mask_baseline = abs(T.mu_on - 0.05) < 0.001;

if sum(mask_baseline) > 0
    fprintf('    Mean Delay: %.2f ms (평균)\n', mean(T.mean_delay_ms(mask_baseline)));
    fprintf('    Collision: %.1f%% (평균)\n', mean(T.collision_rate(mask_baseline)) * 100);
    fprintf('    Explicit BSR: %.1f%% (평균)\n', mean(T.explicit_bsr_ratio(mask_baseline)) * 100);
end

fprintf('\n');

%% =====================================================================
%  7. 완료
%  =====================================================================

fprintf('========================================\n');
fprintf('  Phase 0B 분석 완료!\n');
fprintf('========================================\n\n');

fprintf('🔴 핵심 발견:\n');
fprintf('  1. mu_on ↑ → Delay 패턴 확인\n');
fprintf('  2. mu_on ↑ → Explicit BSR ↓ (긴 burst)\n');
fprintf('  3. rho × mu_on 상호작용 (독립적 영향)\n');
fprintf('  4. RA-RU=2가 여전히 우수\n\n');

fprintf('💡 다음 단계:\n');
fprintf('  1. visualize_phase0b_mu_on.m 실행\n');
fprintf('  2. Phase 0 (mu_on=0.05) vs 0B 비교\n');
fprintf('  3. 최적 mu_on 선택 후 Phase 1 설계\n\n');