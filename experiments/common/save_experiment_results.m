function save_experiment_results(results_grid, exp_config)
% SAVE_EXPERIMENT_RESULTS: 실험 결과를 MAT + CSV 형식으로 저장
%
% [수정]
%   - 2D 스윕 시 meshgrid 대신 명시적 인덱싱으로 변경
%   - CSV 행 순서가 results_grid와 정확히 일치하도록 보장

    fprintf('[결과 저장]\n');
    
    %% =====================================================================
    %  1. 디렉토리 확인
    %  =====================================================================
    
    mat_dir = 'results/mat';
    csv_dir = 'results/csv';
    
    if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end
    if ~exist(csv_dir, 'dir'), mkdir(csv_dir); end
    
    %% =====================================================================
    %  2. 평균 및 표준편차 계산
    %  =====================================================================
    
    summary = struct();
    summary.mean = struct();
    summary.std = struct();
    
    metric_names = fieldnames(results_grid);
    
    for i = 1:length(metric_names)
        metric = metric_names{i};
        data = results_grid.(metric);
        
        % 마지막 차원(runs)에서 평균/표준편차
        summary.mean.(metric) = mean(data, ndims(data), 'omitnan');
        summary.std.(metric) = std(data, 0, ndims(data), 'omitnan');
    end
    
    %% =====================================================================
    %  3. MAT 파일 저장
    %  =====================================================================
    
    results = struct();
    results.config = exp_config;
    results.raw_data = results_grid;
    results.summary = summary;
    
    % 메타데이터
    results.metadata = struct();
    results.metadata.timestamp = datetime('now');
    results.metadata.matlab_version = version;
    results.metadata.hostname = getenv('COMPUTERNAME');
    if isempty(results.metadata.hostname)
        results.metadata.hostname = getenv('HOSTNAME');
    end
    
    % 파일명 생성
    timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
    mat_filename = sprintf('%s/%s_%s.mat', mat_dir, exp_config.name, timestamp_str);
    
    save(mat_filename, 'results', '-v7.3');
    fprintf('  ✓ MAT 저장: %s\n', mat_filename);
    
    %% =====================================================================
    %  4. CSV 파일 저장 (summary만) - 수정
    %  =====================================================================
    
    % 1D 또는 2D?
    is_2d = isfield(exp_config, 'sweep_var2');
    
    if is_2d
        % ─────────────────────────────────────────────────────────
        % [수정] 2D: meshgrid 대신 명시적 인덱싱 사용
        % ─────────────────────────────────────────────────────────
        n1 = length(exp_config.sweep_range);
        n2 = length(exp_config.sweep_range2);
        
        % 테이블 생성
        num_rows = n1 * n2;
        T = table();
        
        % [수정] 스윕 변수 열을 results_grid와 동일한 순서로 생성
        % run_sweep_experiment.m의 for i1 = 1:n1, for i2 = 1:n2 순서와 일치
        var1_values = zeros(num_rows, 1);
        var2_values = zeros(num_rows, 1);
        
        row_idx = 0;
        for i1 = 1:n1
            for i2 = 1:n2
                row_idx = row_idx + 1;
                var1_values(row_idx) = exp_config.sweep_range(i1);
                var2_values(row_idx) = exp_config.sweep_range2(i2);
            end
        end
        
        T.(exp_config.sweep_var) = var1_values;
        T.(exp_config.sweep_var2) = var2_values;
        
        % 메트릭 열 (mean, std)
        for i = 1:length(metric_names)
            metric = metric_names{i};
            mean_data = summary.mean.(metric);  % [n1, n2]
            std_data = summary.std.(metric);    % [n1, n2]
            
            % [수정] Column-major 순서로 변환 (i1, i2 순서와 일치)
            T.([metric '_mean']) = mean_data(:);
            T.([metric '_std']) = std_data(:);
        end
        
    else
        % 1D: 각 행 = (val, metric_mean, metric_std, ...)
        n1 = length(exp_config.sweep_range);
        
        T = table();
        T.(exp_config.sweep_var) = exp_config.sweep_range(:);
        
        for i = 1:length(metric_names)
            metric = metric_names{i};
            mean_data = summary.mean.(metric);
            std_data = summary.std.(metric);
            
            T.([metric '_mean']) = mean_data(:);
            T.([metric '_std']) = std_data(:);
        end
    end
    
    % CSV 저장
    csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);
    writetable(T, csv_filename);
    fprintf('  ✓ CSV 저장: %s\n', csv_filename);
    
    % %% =====================================================================
    % %  5. [추가] CSV 저장 검증 (2D만)
    % %  =====================================================================
    
    % if is_2d
    %     fprintf('\n  [CSV 검증] 첫 3행 샘플:\n');
    %     disp(T(1:min(3, height(T)), :));
        
    %     % 예상 순서 출력
    %     fprintf('  예상 순서: (L_cell, rho) = ');
    %     for i1 = 1:min(3, n1)
    %         for i2 = 1:min(2, n2)
    %             fprintf('(%.1f, %.1f) ', exp_config.sweep_range(i1), exp_config.sweep_range2(i2));
    %         end
    %     end
    %     fprintf('...\n');
    % end
    
    % fprintf('\n');
end