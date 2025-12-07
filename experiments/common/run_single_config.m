function [results, cfg_used] = run_single_config(cfg_params, num_runs, rng_seed_base)
% RUN_SINGLE_CONFIG: 단일 설정으로 시뮬레이션 실행
%
% 입력:
%   cfg_params    - 파라미터 구조체 (L_cell, rho, num_STAs, numRU_RA 등)
%   num_runs      - 실행 횟수 (기본값: 10)
%   rng_seed_base - RNG 시드 베이스 (기본값: 1000)
%
% 출력:
%   results  - 결과 구조체 배열 (num_runs개)
%   cfg_used - 실제 사용된 설정 구조체
%
% 예시:
%   cfg_params = struct('L_cell', 0.3, 'rho', 0.5, 'num_STAs', 20);
%   [results, cfg] = run_single_config(cfg_params, 10, 1000);

    %% =====================================================================
    %  1. 입력 검증 및 기본값 설정
    %  =====================================================================
    
    if nargin < 2 || isempty(num_runs)
        num_runs = 10;
    end
    
    if nargin < 3 || isempty(rng_seed_base)
        rng_seed_base = 1000;
    end
    
    %% =====================================================================
    %  2. 설정 생성
    %  =====================================================================
    
    % 기본 설정 로드
    cfg = config_default();
    
    % 사용자 파라미터로 덮어쓰기
    field_names = fieldnames(cfg_params);
    for i = 1:length(field_names)
        field = field_names{i};
        cfg.(field) = cfg_params.(field);
    end
    
    % ⭐ numRU_RA가 변경되면 numRU_SA 자동 재계산
    % (numRU_total=9는 고정, numRU_SA = numRU_total - numRU_RA)
    if isfield(cfg_params, 'numRU_RA')
        cfg.numRU_SA = cfg.numRU_total - cfg.numRU_RA;
    end
    
    % Lambda 재계산 (L_cell, rho, mu_on 변경 시 필요)
    if isfield(cfg_params, 'L_cell') || isfield(cfg_params, 'rho') || isfield(cfg_params, 'mu_on')
        cfg = recompute_pareto_lambda(cfg);
    end
    
    % 출력 최소화 (성능)
    cfg.verbose = 0;
    
    % BSR 트레이스 수집 (Phase 0에서는 필요 없을 수도)
    if ~isfield(cfg_params, 'collect_bsr_trace')
        cfg.collect_bsr_trace = false;
    end
    
    %% =====================================================================
    %  3. 다중 실행 (num_runs회)
    %  =====================================================================
    
    results = cell(num_runs, 1);
    
    fprintf('  실행 중: ');
    
    for run = 1:num_runs
        % RNG 시드 설정 (재현성)
        rng(rng_seed_base + run);
        
        % 시뮬레이션 실행
        try
            [results{run}, ~] = main_sim_v2(cfg);
            
            % 진행 표시
            if mod(run, max(1, floor(num_runs/10))) == 0 || run == num_runs
                fprintf('.');
            end
        catch ME
            warning('Run %d failed: %s', run, ME.message);
            results{run} = struct();  % 빈 구조체
        end
    end
    
    fprintf(' 완료 (%d runs)\n', num_runs);
    
    %% =====================================================================
    %  4. 결과 배열로 변환 (cell → struct array)
    %  =====================================================================
    
    % cell array를 struct array로 변환 (분석 편의성)
    results = [results{:}];
    
    %% =====================================================================
    %  5. 사용된 설정 반환
    %  =====================================================================
    
    cfg_used = cfg;
    
end