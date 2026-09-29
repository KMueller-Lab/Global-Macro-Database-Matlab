function v = cacheVersions()
%CACHEVERSIONS List versions cached locally as GMD_<ver>.csv (newest first).
%   Ports the Python _cache_versions helper (CSV instead of DTA).

    v = {};
    d = cacheDir();
    if ~exist(d, 'dir')
        return;
    end
    files = dir(fullfile(d, 'GMD_*.csv'));
    found = {};
    for i = 1:numel(files)
        tok = regexp(files(i).name, '^GMD_(\d{4}_\d{2})\.csv$', 'tokens', 'once');
        if ~isempty(tok)
            found{end+1} = tok{1}; %#ok<AGROW>
        end
    end
    v = sort(unique(found), 'descend');
end
