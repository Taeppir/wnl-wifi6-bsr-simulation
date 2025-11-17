% function save_experiment_results(results_grid, exp_config)
% % SAVE_EXPERIMENT_RESULTS: 실험 결과를 MAT + CSV 형식으로 저장
% %
% % [수정 v4 - 최종]
% %   - 2D 스윕: summary를 무조건 2D matrix로 유지
% %   - num_runs=1이든 10이든 동일하게 처리

%     fprintf('[결과 저장]\n');
    
%     %% =====================================================================
%     %  1. 디렉토리 확인
%     %  =====================================================================
    
%     mat_dir = 'results/mat';
%     csv_dir = 'results/csv';
    
%     if ~exist(mat_dir, 'dir'), mkdir(mat_dir); end
%     if ~exist(csv_dir, 'dir'), mkdir(csv_dir); end
    
%     %% =====================================================================
%     %  2. 평균 및 표준편차 계산
%     %  =====================================================================
    
%     summary = struct();
%     summary.mean = struct();
%     summary.std = struct();
    
%     metric_names = fieldnames(results_grid);
%     is_2d = isfield(exp_config, 'sweep_var2');
    
%     for i = 1:length(metric_names)
%         metric = metric_names{i};
%         data = results_grid.(metric);
        
%         % ⭐ [핵심] 2D 스윕인 경우 무조건 2D 형태 유지
%         if is_2d
%             % data 크기: [n1, n2] 또는 [n1, n2, runs]
%             data_size = size(data);
            
%             if ndims(data) == 3
%                 % 3D: 마지막 차원에서 평균
%                 summary.mean.(metric) = mean(data, 3, 'omitnan');
%                 summary.std.(metric) = std(data, 0, 3, 'omitnan');
%             elseif ndims(data) == 2
%                 % 2D: runs=1인 경우, 그대로 사용
%                 summary.mean.(metric) = data;
%                 summary.std.(metric) = zeros(size(data));
%             else
%                 error('Unexpected data dimension for metric: %s', metric);
%             end
%         else
%             % 1D 스윕
%             if ndims(data) == 2
%                 summary.mean.(metric) = mean(data, 2, 'omitnan');
%                 summary.std.(metric) = std(data, 0, 2, 'omitnan');
%             else
%                 summary.mean.(metric) = data;
%                 summary.std.(metric) = zeros(size(data));
%             end
%         end
%     end
    
%     %% =====================================================================
%     %  3. MAT 파일 저장
%     %  =====================================================================
    
%     results = struct();
%     results.config = exp_config;
%     results.raw_data = results_grid;
%     results.summary = summary;
    
%     % 메타데이터
%     results.metadata = struct();
%     results.metadata.timestamp = datetime('now');
%     results.metadata.matlab_version = version;
%     results.metadata.hostname = getenv('COMPUTERNAME');
%     if isempty(results.metadata.hostname)
%         results.metadata.hostname = getenv('HOSTNAME');
%     end
    
%     % 파일명 생성
%     timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
%     mat_filename = sprintf('%s/%s_%s.mat', mat_dir, exp_config.name, timestamp_str);
    
%     save(mat_filename, 'results', '-v7.3');
%     fprintf('  ✓ MAT 저장: %s\n', mat_filename);
    
%     %% =====================================================================
%     %  4. CSV 파일 저장 (summary만)
%     %  =====================================================================
    
%     if is_2d
%         % ─────────────────────────────────────────────────────────
%         % 2D: summary는 [n1, n2] 형태 보장됨
%         % ─────────────────────────────────────────────────────────
%         n1 = length(exp_config.sweep_range);
%         n2 = length(exp_config.sweep_range2);
%         num_rows = n1 * n2;
        
%         % 테이블 생성
%         T = table();
        
%         % 스윕 변수 열 생성
%         var1_values = zeros(num_rows, 1);
%         var2_values = zeros(num_rows, 1);
        
%         row_idx = 0;
%         for i1 = 1:n1
%             for i2 = 1:n2
%                 row_idx = row_idx + 1;
%                 var1_values(row_idx) = exp_config.sweep_range(i1);
%                 var2_values(row_idx) = exp_config.sweep_range2(i2);
%             end
%         end
        
%         T.(exp_config.sweep_var) = var1_values;
%         T.(exp_config.sweep_var2) = var2_values;
        
%         % ⭐ 메트릭 열 추가 (2D → 1D 변환)
%         for i = 1:length(metric_names)
%             metric = metric_names{i};
%             mean_data = summary.mean.(metric);  % [n1, n2]
%             std_data = summary.std.(metric);    % [n1, n2]
            
%             % 2D를 1D로 변환 (row-by-row)
%             mean_vector = zeros(num_rows, 1);
%             std_vector = zeros(num_rows, 1);
            
%             row_idx = 0;
%             for i1 = 1:n1
%                 for i2 = 1:n2
%                     row_idx = row_idx + 1;
%                     mean_vector(row_idx) = mean_data(i1, i2);
%                     std_vector(row_idx) = std_data(i1, i2);
%                 end
%             end
            
%             T.([metric '_mean']) = mean_vector;
%             T.([metric '_std']) = std_vector;
%         end
        
%     else
%         % 1D 스윕
%         n1 = length(exp_config.sweep_range);
        
%         T = table();
%         T.(exp_config.sweep_var) = exp_config.sweep_range(:);
        
%         for i = 1:length(metric_names)
%             metric = metric_names{i};
%             mean_data = summary.mean.(metric);
%             std_data = summary.std.(metric);
            
%             T.([metric '_mean']) = mean_data(:);
%             T.([metric '_std']) = std_data(:);
%         end
%     end
    
%     % CSV 저장
%     csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);
%     writetable(T, csv_filename);
%     fprintf('  ✓ CSV 저장: %s\n', csv_filename);
    
%     fprintf('\n');
% end

function save_experiment_results(results_grid, exp_config)
% SAVE_EXPERIMENT_RESULTS: 실험 결과를 MAT + CSV 형식으로 저장
%
% [수정사항]
%   - 1D와 2D 스윕 모두 처리 가능
%   - 1D: mean_data가 [n1, 1] 형태
%   - 2D: mean_data가 [n1, n2] 형태

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
    %  4. CSV 파일 저장 (summary만)
    %  =====================================================================
    
    % 1D 또는 2D 판별
    is_2d = isfield(exp_config, 'sweep_var2');
    
    if is_2d
        % 2D 스윕
        n1 = length(exp_config.sweep_range);
        n2 = length(exp_config.sweep_range2);
        
        % 테이블 생성
        num_rows = n1 * n2;
        T = table();
        
        % 스윕 변수 열 (명시적 인덱싱)
        var1_vec = zeros(num_rows, 1);
        var2_vec = zeros(num_rows, 1);
        
        row_idx = 0;
        for i1 = 1:n1
            for i2 = 1:n2
                row_idx = row_idx + 1;
                var1_vec(row_idx) = exp_config.sweep_range(i1);
                var2_vec(row_idx) = exp_config.sweep_range2(i2);
            end
        end
        
        T.(exp_config.sweep_var) = var1_vec;
        T.(exp_config.sweep_var2) = var2_vec;
        
        % 각 지표의 평균/표준편차 열 추가
        for i = 1:length(metric_names)
            metric = metric_names{i};
            
            mean_data = summary.mean.(metric);
            std_data = summary.std.(metric);
            
            % ⭐ 핵심 수정: 1D 벡터로 변환
            mean_vector = zeros(num_rows, 1);
            std_vector = zeros(num_rows, 1);
            
            row_idx = 0;
            for i1 = 1:n1
                for i2 = 1:n2
                    row_idx = row_idx + 1;
                    mean_vector(row_idx) = mean_data(i1, i2);
                    std_vector(row_idx) = std_data(i1, i2);
                end
            end
            
            T.([metric '_mean']) = mean_vector;
            T.([metric '_std']) = std_vector;
        end
        
    else
        % 1D 스윕
        n1 = length(exp_config.sweep_range);
        
        % 테이블 생성
        T = table();
        T.(exp_config.sweep_var) = exp_config.sweep_range(:);
        
        % 각 지표의 평균/표준편차 열 추가
        for i = 1:length(metric_names)
            metric = metric_names{i};
            
            mean_data = summary.mean.(metric);
            std_data = summary.std.(metric);
            
            % ⭐ 1D 스윕: mean_data는 이미 [n1, 1] 형태
            % 만약 [n1] 형태라면 (:)로 열벡터화
            T.([metric '_mean']) = mean_data(:);
            T.([metric '_std']) = std_data(:);
        end
    end
    
    % CSV 저장
    csv_filename = sprintf('%s/%s_summary.csv', csv_dir, exp_config.name);
    writetable(T, csv_filename);
    fprintf('  ✓ CSV 저장: %s\n', csv_filename);
    
    fprintf('  완료!\n\n');
end