function save_experiment_results(all_results, all_configs, experiment_name, phase_num)
% SAVE_EXPERIMENT_RESULTS: 실험 결과를 MAT 및 CSV 형식으로 저장 (FIXED)
%
% 수정 내역:
%   [FIX] BSR Count 추가 (explicit_bsr_count, implicit_bsr_count, total_bsr_count)
%
% 입력:
%   all_results     - 결과 구조체 배열 (N개 설정 × M개 runs)
%   all_configs     - 설정 구조체 배열 (N개)
%   experiment_name - 실험 이름 (예: 'baseline_sweep')
%   phase_num       - Phase 번호 (0, 1, 2, 3, 4)
%
% 저장 위치:
%   results/phaseX/raw/experiment_name_YYYYMMDD_HHMMSS.mat
%   results/phaseX/csv/experiment_name_summary.csv

    %% =====================================================================
    %  1. 디렉토리 생성
    %  =====================================================================
    
    phase_dir = sprintf('results/phase%d', phase_num);
    raw_dir = fullfile(phase_dir, 'raw');
    csv_dir = fullfile(phase_dir, 'csv');
    
    if ~exist(raw_dir, 'dir')
        mkdir(raw_dir);
    end
    
    if ~exist(csv_dir, 'dir')
        mkdir(csv_dir);
    end
    
    %% =====================================================================
    %  2. MAT 파일 저장 (전체 결과)
    %  =====================================================================
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    mat_filename = sprintf('%s/%s_%s.mat', raw_dir, experiment_name, timestamp);
    
    % 저장할 데이터
    experiment_data = struct();
    experiment_data.all_results = all_results;
    experiment_data.all_configs = all_configs;
    experiment_data.timestamp = timestamp;
    experiment_data.phase_num = phase_num;
    experiment_data.experiment_name = experiment_name;
    
    save(mat_filename, '-struct', 'experiment_data', '-v7.3');
    
    fprintf('  ✓ MAT 파일 저장: %s\n', mat_filename);

    %% =====================================================================
    %  3. 요약 테이블 생성
    %  =====================================================================

    num_configs = length(all_configs);
    num_results = length(all_results);
    
    if num_configs == 0
        warning('No configs provided');
        return;
    end

    % 테이블 초기화
    T = table();
    
    % ⭐ 각 result가 몇 번째 config인지 자동 판별
    % 순서: config 1의 run 1~N, config 2의 run 1~N, ...
    num_runs_per_config = num_results / num_configs;

    for i = 1:num_configs
        row = struct();

        % 설정 파라미터
        row.config_id = i;
        row.L_cell = all_configs(i).L_cell;
        row.rho = all_configs(i).rho;
        row.mu_on = all_configs(i).mu_on;
        row.num_STAs = all_configs(i).num_STAs;
        row.numRU_RA = all_configs(i).numRU_RA;
        row.numRU_SA = all_configs(i).numRU_SA;
        row.scheme_id = all_configs(i).scheme_id;

        % ⭐ i번째 config에 해당하는 결과 인덱스 계산
        start_idx = (i - 1) * num_runs_per_config + 1;
        end_idx = i * num_runs_per_config;
        
        % ⭐ all_results는 이미 struct array! (exp0에서 변환됨)
        results_subset = all_results(start_idx:end_idx);
        
        if isempty(results_subset)
            warning('No results found for config %d', i);
            continue;
        end

        % ⭐ nested struct 접근은 arrayfun 사용!
        % 평균 지연
        mean_delays = arrayfun(@(x) x.packet_level.mean_delay, results_subset);
        row.mean_delay_ms = mean(mean_delays, 'omitnan') * 1000;

        std_delays = arrayfun(@(x) x.packet_level.std_delay, results_subset);
        row.std_delay_ms = mean(std_delays, 'omitnan') * 1000;

        % 백분위수
        p90_delays = arrayfun(@(x) x.packet_level.p90_delay, results_subset);
        row.p90_delay_ms = mean(p90_delays, 'omitnan') * 1000;

        p10_delays = arrayfun(@(x) x.packet_level.p10_delay, results_subset);
        row.p10_delay_ms = mean(p10_delays, 'omitnan') * 1000;

        % UORA
        collision_rates = arrayfun(@(x) x.uora.collision_rate, results_subset);
        row.collision_rate = mean(collision_rates, 'omitnan');

        success_rates = arrayfun(@(x) x.uora.success_rate, results_subset);
        row.success_rate = mean(success_rates, 'omitnan');

        % BSR Ratio
        explicit_ratios = arrayfun(@(x) x.bsr.explicit_ratio, results_subset);
        row.explicit_bsr_ratio = mean(explicit_ratios, 'omitnan');

        % ⭐⭐⭐ [FIX] BSR Count 추가
        explicit_counts = arrayfun(@(x) x.bsr.total_explicit, results_subset);
        row.explicit_bsr_count = mean(explicit_counts, 'omitnan');

        implicit_counts = arrayfun(@(x) x.bsr.total_implicit, results_subset);
        row.implicit_bsr_count = mean(implicit_counts, 'omitnan');

        total_bsr_counts = arrayfun(@(x) x.bsr.total_bsr, results_subset);
        row.total_bsr_count = mean(total_bsr_counts, 'omitnan');

        % 큐 상태
        buffer_empty_ratios = arrayfun(@(x) x.bsr.buffer_empty_ratio, results_subset);
        row.buffer_empty_ratio = mean(buffer_empty_ratios, 'omitnan');

        % 지연 분해
        mean_uora_delays = arrayfun(@(x) x.bsr.mean_uora_delay, results_subset);
        row.mean_uora_delay_ms = mean(mean_uora_delays, 'omitnan') * 1000;

        mean_sched_delays = arrayfun(@(x) x.bsr.mean_sched_delay, results_subset);
        row.mean_sched_delay_ms = mean(mean_sched_delays, 'omitnan') * 1000;

        mean_frag_delays = arrayfun(@(x) x.packet_level.mean_frag_delay, results_subset);
        row.mean_frag_delay_ms = mean(mean_frag_delays, 'omitnan') * 1000;

        % 처리율
        throughputs = arrayfun(@(x) x.throughput.throughput_mbps, results_subset);
        row.throughput_mbps = mean(throughputs, 'omitnan');

        % 완료율
        completion_rates = arrayfun(@(x) x.summary.completion_rate, results_subset);
        row.completion_rate = mean(completion_rates, 'omitnan');
        
        % 성공 run 수 추가
        row.successful_runs = length(results_subset);

        % 테이블에 행 추가
        T = [T; struct2table(row)]; %#ok<AGROW>
    end

    %% =====================================================================
    %  4. CSV 저장
    %  =====================================================================

    csv_filename = sprintf('%s/%s_summary.csv', csv_dir, experiment_name);

    writetable(T, csv_filename);

    fprintf('  ✓ CSV 파일 저장: %s\n', csv_filename);
    fprintf('  설정 수: %d개\n', height(T));
    fprintf('  컬럼 수: %d개 (BSR Count 포함)\n', width(T));
    fprintf('\n');
end