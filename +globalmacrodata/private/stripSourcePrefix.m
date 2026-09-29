function out = stripSourcePrefix(cols, source)
%STRIPSOURCEPREFIX Drop the "<source>_" prefix from data column names.
%   Skips the ISO3/year identifier columns. Ports _strip_source_prefix_cols.

    pref = sprintf('%s_', source);
    out = {};
    for i = 1:numel(cols)
        c = char(cols{i});
        if any(strcmp(c, {'ISO3', 'year'}))
            continue;
        end
        if startsWith(c, pref)
            out{end+1} = c(numel(pref)+1:end); %#ok<AGROW>
        else
            out{end+1} = c; %#ok<AGROW>
        end
    end
end
