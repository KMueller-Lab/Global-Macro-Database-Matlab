function df = datasetTable(ver, fast)
%DATASETTABLE Load the full dataset for a version, using the local cache.
%   Ports the default (non-raw) load path in Python gmd(). When FAST is true
%   the downloaded CSV is persisted under the cache directory (written to a
%   temp file then moved into place) so later calls reload from disk.

    d = ensureCacheDir();
    localVer = fullfile(d, sprintf('GMD_%s.csv', ver));

    if exist(localVer, 'file')
        df = readCsvFile(localVer);
        return;
    end

    relPath = sprintf('distribute/GMD_%s.csv', ver);

    if fast
        tmp = [tempname, '.csv'];
        fetchFrom(relPath, tmp);
        info = dir(tmp);
        if isempty(info) || info.bytes == 0
            error('GMD:fetch', 'Refusing to cache empty file for %s', localVer);
        end
        movefile(tmp, localVer, 'f');
        copyfile(localVer, fullfile(d, 'GMD.csv'), 'f');
        emit(sprintf('GMD dataset loaded and saved locally in %s.', d));
        df = readCsvFile(localVer);
    else
        df = readCsvRemote(relPath);
    end
end

function t = readCsvFile(f)
    t = readtable(f, 'Delimiter', ',', 'ReadVariableNames', true, ...
        'VariableNamingRule', 'preserve', 'TextType', 'string');
end
