function out = gmdBackend(cmd, value)
%GMDBACKEND Test seam: optional fixture root and cache-dir override.
%   When a fixture root is set, fetchFrom serves files from disk instead of
%   the network. When a cache override is set, cacheDir returns it instead of
%   ~/.global_macro_data. This mirrors the monkeypatched backend in the Python
%   tests and keeps the test suite off the network and out of the real cache.
%   Production code never sets either, so behavior is unchanged by default.
%
%   gmdBackend('set', root)        store the fixture root
%   gmdBackend('get')              return the fixture root ('' when unset)
%   gmdBackend('setcache', dir)    store the cache-dir override
%   gmdBackend('getcache')         return the cache override ('' when unset)
%   gmdBackend('clear')            remove both overrides

    persistent root cacheOverride
    if isempty(root); root = ''; end
    if isempty(cacheOverride); cacheOverride = ''; end

    out = '';
    switch cmd
        case 'set'
            root = char(value);
        case 'get'
            out = root;
        case 'setcache'
            cacheOverride = char(value);
        case 'getcache'
            out = cacheOverride;
        case 'clear'
            root = '';
            cacheOverride = '';
        otherwise
            error('GMD:e498', 'Unknown gmdBackend command: %s', cmd);
    end
end
