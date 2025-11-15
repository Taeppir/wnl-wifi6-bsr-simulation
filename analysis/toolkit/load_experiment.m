function exp = load_experiment(exp_name)
% LOAD_EXPERIMENT: 실험 결과 MAT 파일 로드
%
% 입력:
%   exp_name - 실험 이름 (예: 'exp1_1_load_sweep')
%
% 출력:
%   exp - 실험 결과 구조체
%     .config      : 실험 설정
%     .raw_data    : 원본 데이터 (모든 runs)
%     .summary     : 평균/표준편차
%     .metadata    : 메타데이터
%
% 사용 예:
%   exp = load_experiment('exp1_1_load_sweep');
%   plot(exp.config.sweep_range, exp.summary.mean.mean_delay_ms);

    %% =====================================================================
    %  1. MAT 파일 찾기
    %  =====================================================================
    
    mat_dir = 'results/mat';
    
    % 해당 실험의 모든 MAT 파일 검색
    pattern = sprintf('%s/%s_*.mat', mat_dir, exp_name);
    files = dir(pattern);
    
    if isempty(files)
        error('load_experiment: ''%s'' 실험 결과를 찾을 수 없습니다.\n경로: %s', exp_name, pattern);
    end
    
    %% =====================================================================
    %  2. 가장 최신 파일 선택
    %  =====================================================================
    
    if length(files) > 1
        fprintf('[load_experiment] 여러 결과 파일이 있습니다:\n');
        for i = 1:length(files)
            fprintf('  %d. %s (%s)\n', i, files(i).name, datestr(files(i).datenum));
        end
        [~, latest_idx] = max([files.datenum]);
        fprintf('  → 가장 최신 파일 선택: %s\n\n', files(latest_idx).name);
    else
        latest_idx = 1;
        fprintf('[load_experiment] 로드: %s\n', files(latest_idx).name);
    end
    
    %% =====================================================================
    %  3. 로드
    %  =====================================================================
    
    filepath = fullfile(mat_dir, files(latest_idx).name);
    loaded = load(filepath);
    
    if isfield(loaded, 'results')
        exp = loaded.results;
    else
        error('load_experiment: MAT 파일에 ''results'' 필드가 없습니다.');
    end
    
    fprintf('  ✓ 로드 완료\n\n');
    
end