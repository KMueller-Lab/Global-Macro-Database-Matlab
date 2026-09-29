function useFixtures(root, cacheOverride)
%USEFIXTURES Test helper: route all fetches to a local fixture directory.
%   globalmacrodata.useFixtures(ROOT) makes the package read data from files
%   under ROOT (mirroring the release-bucket paths) instead of the network.
%   globalmacrodata.useFixtures(ROOT, CACHEDIR) also redirects the local cache
%   to CACHEDIR so tests never touch the real ~/.global_macro_data.
%   Intended for the test suite. Call globalmacrodata.resetBackend() to undo.
%   Reset the session getter caches with clear('functions') before calling
%   this so cached network data is not reused.

    if ~exist(root, 'dir')
        error('GMD:e498', 'Fixture root does not exist: %s', root);
    end
    gmdBackend('set', root);
    if nargin >= 2 && ~isempty(cacheOverride)
        gmdBackend('setcache', cacheOverride);
    end
end
