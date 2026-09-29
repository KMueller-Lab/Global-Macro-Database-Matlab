function v = cacheVersions()
%CACHEVERSIONS List versions cached locally as GMD_<ver>.dta (newest first).
%   Ports the Python _cache_versions helper.

    v = {};
    d = cacheDir();
    if ~exist(d, 'dir')
        return;
    end
    files = dir(fullfile(d, 'GMD_*.dta'));
    found = {};
    for i = 1:numel(files)
        tok = regexp(files(i).name, '^GMD_(\d{4}_\d{2})\.dta$', 'tokens', 'once');
        if ~isempty(tok)
            found{end+1} = tok{1}; %#ok<AGROW>
        end
    end
    v = sort(unique(found), 'descend');
end
