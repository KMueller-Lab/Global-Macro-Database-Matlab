function t = versionsTable()
%VERSIONSTABLE Cached versions table, sorted newest first.
%   Ports the lru_cached Python _versions_df. Cached for the MATLAB session;
%   call clear('functions') to reset.

    persistent cached
    if isempty(cached)
        raw = readCsvRemote('helpers/versions.csv');
        if ~ismember('versions', raw.Properties.VariableNames)
            error('GMD:fetch', 'Malformed versions.csv');
        end
        cached = sortVersions(raw);
    end
    t = cached;
end
