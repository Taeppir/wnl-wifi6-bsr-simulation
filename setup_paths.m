function setup_paths()
% 모든 하위 디렉토리를 MATLAB 경로에 추가
% 사용법:
%   시뮬레이션 실행 전 반드시 한 번 실행
%   >> setup_paths

% 현재 스크립트 디렉토리: root
root_dir = fileparts(mfilename('fullpath'));

% 추가할 폴더 목록
folders = {
    'analysis'
    'analysis/notebooks'
    'analysis/scripts'
    'analysis/toolkit'
    'config'
    'config/experiment_configs'
    'experiments'
    'experiments/common'
    'experiments/phase0'
    'experiments/phase1'
    'experiments/phase2'
    'initialization'
    'metrics'
    'policies'
    'results'
    'results/csv'
    'results/mat'
    'results/publication'
    'results/quick_plots'
    'tests'
    'tests/1_core'
    'tests/2_mechanisms'
    'tests/3_integration'
    'traffic'
    'traffic/experiments'
    'core'
    'utils'
    
};

% 경로 추가
for i = 1:length(folders)
    folder_path = fullfile(root_dir, folders{i});
    if exist(folder_path, 'dir')
        addpath(folder_path);
        fprintf('Added to path: %s\n', folders{i});
    else
        warning('Folder not found: %s', folders{i});
    end
end

% results 폴더 생성
results_dir = fullfile(root_dir, 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
    fprintf('Created results directory\n');
end

fprintf('\nPath setup complete!\n');
fprintf('You can now run simulations.\n\n');

end