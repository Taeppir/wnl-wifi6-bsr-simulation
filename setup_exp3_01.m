%% setup_exp3_01.m
% Exp 3-1 디렉토리 구조 생성

fprintf('========================================\n');
fprintf('  Exp 3-1 디렉토리 생성\n');
fprintf('========================================\n\n');

dirs = {
    'experiments/phase3'
    'experiments/phase3/exp3_01_v3_sweet_spot'
    'results/phase3'
    'results/phase3/exp3_01'
    'results/phase3/exp3_01/figures'
    'results/phase3/exp3_01/mat'
    'results/phase3/exp3_01/csv'
};

for i = 1:length(dirs)
    if ~exist(dirs{i}, 'dir')
        mkdir(dirs{i});
        fprintf('  ✓ %s\n', dirs{i});
    else
        fprintf('  - %s (이미 존재)\n', dirs{i});
    end
end

fprintf('\n✅ Exp 3-1 디렉토리 생성 완료!\n\n');