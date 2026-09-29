function v = get_available_versions()
%GET_AVAILABLE_VERSIONS List all data vintages (newest first).
%   Falls back to locally cached versions when the network is unavailable.
%   Ports the Python get_available_versions.

    try
        vt = versionsTable();
        v = cellstr(string(vt.versions));
    catch ME
        if startsWith(ME.identifier, 'GMD:e')
            rethrow(ME);
        end
        cached = cacheVersions();
        if ~isempty(cached)
            v = cached;
            return;
        end
        if exist(fullfile(cacheDir(), 'GMD.csv'), 'file')
            v = {'local'};
            return;
        end
        cfg = gmdConfig();
        error('GMD:e498', ['Unable to load version information. Check your internet ' ...
            'connection or report this issue at %s'], cfg.IssuesUrl);
    end
end
