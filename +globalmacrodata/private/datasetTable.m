function df = datasetTable(ver, fast)
%DATASETTABLE Load the full dataset for a version, using the local cache.
%   Reads the versioned .dta release (via the built-in readDta) so values
%   match the Stata/Python/R packages exactly; the CSV distribution rounds
%   some values. When FAST is true the downloaded .dta is persisted under the
%   cache directory (written to a temp file then moved into place) so later
%   calls reload from disk.

    d = ensureCacheDir();
    localVer = fullfile(d, sprintf('GMD_%s.dta', ver));

    if exist(localVer, 'file')
        df = readDta(localVer);
        return;
    end

    relPath = sprintf('distribute/GMD_%s.dta', ver);

    if fast
        tmp = [tempname, '.dta'];
        fetchFrom(relPath, tmp);
        info = dir(tmp);
        if isempty(info) || info.bytes == 0
            error('GMD:fetch', 'Refusing to cache empty file for %s', localVer);
        end
        movefile(tmp, localVer, 'f');
        copyfile(localVer, fullfile(d, 'GMD.dta'), 'f');
        emit(sprintf('GMD dataset loaded and saved locally in %s.', d));
        df = readDta(localVer);
    else
        df = readDtaRemote(relPath);
    end
end
