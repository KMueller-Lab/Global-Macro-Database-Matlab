function t = readDtaRemote(relPath, bases)
%READDTAREMOTE Download a .dta endpoint from the release bucket and read it.
%   Wraps fetchFrom + readDta. Used for the country list and source-level
%   tables, which are published only as Stata format-114 .dta files.

    if nargin < 2
        bases = [];
    end
    tmp = [tempname, '.dta'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    fetchFrom(relPath, tmp, bases);
    t = readDta(tmp);
end

function deleteIfExists(f)
    if exist(f, 'file')
        try
            delete(f);
        catch
        end
    end
end
