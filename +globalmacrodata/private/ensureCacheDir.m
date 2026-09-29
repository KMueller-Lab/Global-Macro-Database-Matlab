function d = ensureCacheDir()
%ENSURECACHEDIR Create and return the local cache directory.

    d = cacheDir();
    if ~exist(d, 'dir')
        mkdir(d);
    end
end
