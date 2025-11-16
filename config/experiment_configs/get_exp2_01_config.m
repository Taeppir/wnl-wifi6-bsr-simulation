function exp_config = get_exp2_01_config()
% GET_EXP2_01_CONFIG: Experiment 2-1 설정 (정책 비교)
%
% Research Question: 
%   제안 스킴(1~3)이 Baseline 대비 Low/Mid/High-unsat 환경에서
%   얼마나 지연/충돌을 감소시키는가?
%
% 출력:
%   exp_config - 실험 설정 구조체

    exp_config = struct();
    
    %% =====================================================================
    %  기본 정보
    %  =====================================================================
    
    exp_config.name = 'exp2_1_scheme_comparison';
    exp_config.phase = 2;
    exp_config.description = '정책 비교 - 부하 수준별 성능';
    
    %% =====================================================================
    %  시나리오 정의 (3개 × 4개 스킴 = 12개 조합)
    %  =====================================================================
    
    % ⭐ 이 실험은 "시나리오"와 "스킴"의 2D 스윕
    % 하지만 run_sweep_experiment는 단일 변수 스윕만 지원하므로
    % 여기서는 "scenario_id"를 스윕 변수로 사용하고
    % 각 scenario_id에서 scheme_id를 내부적으로 변경
    
    exp_config.sweep_var = 'scenario_id';
    exp_config.sweep_range = 1:3;  % Scenario A, B, C
    
    % ⭐ 실제로는 scheme_id도 함께 스윕해야 하므로
    % run_sweep_experiment를 확장하거나
    % 수동으로 이중 루프를 구성해야 함
    
    % 여기서는 커스텀 실험 스크립트를 사용할 예정
    exp_config.use_custom_runner = true;
    
    %% =====================================================================
    %  시나리오 파라미터
    %  =====================================================================
    
    % Scenario A (Low-load)
    exp_config.scenarios(1).name = 'Low';
    exp_config.scenarios(1).L_cell = 0.15;
    exp_config.scenarios(1).rho = 0.7;
    exp_config.scenarios(1).mu_on = 0.05;
    exp_config.scenarios(1).alpha = 1.5;
    
    % Scenario B (Mid-load)
    exp_config.scenarios(2).name = 'Mid';
    exp_config.scenarios(2).L_cell = 0.35;
    exp_config.scenarios(2).rho = 0.7;
    exp_config.scenarios(2).mu_on = 0.05;
    exp_config.scenarios(2).alpha = 1.5;
    
    % Scenario C (High-unsat)
    exp_config.scenarios(3).name = 'High';
    exp_config.scenarios(3).L_cell = 0.5;
    exp_config.scenarios(3).rho = 0.7;
    exp_config.scenarios(3).mu_on = 0.05;
    exp_config.scenarios(3).alpha = 1.5;
    
    %% =====================================================================
    %  비교 스킴
    %  =====================================================================
    
    exp_config.schemes = [0, 1, 2, 3];  % Baseline + 제안 3개
    
    exp_config.scheme_names = {
        'Baseline (R=Q)'
        'Scheme 1 (Fixed Reduction)'
        'Scheme 2 (Proportional)'
        'Scheme 3 (EMA-based)'
    };
    
    %% =====================================================================
    %  고정 파라미터 (모든 시나리오 공통)
    %  =====================================================================
    
    exp_config.fixed = struct();
    
    % Network
    exp_config.fixed.num_STAs = 20;
    exp_config.fixed.numRU_RA = 1;
    exp_config.fixed.numRU_SA = 8;
    
    % Simulation
    exp_config.fixed.simulation_time = 10.0;
    exp_config.fixed.warmup_time = 0.0;
    exp_config.fixed.verbose = 0;
    exp_config.fixed.collect_bsr_trace = true;
    
    %% =====================================================================
    %  반복 횟수
    %  =====================================================================
    
    exp_config.num_runs = 10;
    
    %% =====================================================================
    %  스킴별 파라미터 (초기값)
    %  =====================================================================
    
    % Scheme 1 파라미터
    exp_config.fixed.v1_fixed_reduction_bytes = 500;
    exp_config.fixed.v1_sensitivity = 1.0;
    
    % Scheme 2 파라미터
    exp_config.fixed.v2_max_reduction = 0.7;
    exp_config.fixed.v2_sensitivity = 1.0;
    
    % Scheme 3 파라미터
    exp_config.fixed.v3_EMA_alpha = 0.2;
    exp_config.fixed.v3_sensitivity = 1.0;
    exp_config.fixed.v3_max_reduction = 0.7;
    
end