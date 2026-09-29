function d = cacheDir()
%CACHEDIR Path to the local cache directory (~/.global_macro_data).
%   Mirrors the Python _CACHE_DIR location. Honors a test-set cache override.

    override = gmdBackend('getcache');
    if ~isempty(override)
        d = override;
        return;
    end

    if ispc
        home = getenv('USERPROFILE');
    else
        home = getenv('HOME');
    end
    if isempty(home)
        home = char(java.lang.System.getProperty('user.home'));
    end
    d = fullfile(home, '.global_macro_data');
end
