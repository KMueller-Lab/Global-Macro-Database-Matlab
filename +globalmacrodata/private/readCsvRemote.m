function t = readCsvRemote(relPath, bases)
%READCSVREMOTE Read a CSV endpoint from the release bucket into a table.
%   Downloads to a temporary file (fetchFrom) then reads it with readtable,
%   preserving the original column names. Ports _read_csv_primary; the full
%   dataset and raw variables are served as CSV (see PLAN.md section 2).

    if nargin < 2
        bases = [];
    end
    tmp = [tempname, '.csv'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    fetchFrom(relPath, tmp, bases);
    t = readtable(tmp, 'Delimiter', ',', 'ReadVariableNames', true, ...
        'VariableNamingRule', 'preserve', 'TextType', 'string');
end

function deleteIfExists(f)
    if exist(f, 'file')
        try
            delete(f);
        catch
        end
    end
end
