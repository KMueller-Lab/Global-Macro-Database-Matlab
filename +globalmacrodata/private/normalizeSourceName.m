function s = normalizeSourceName(source)
%NORMALIZESOURCENAME Convert a 7-char CS alias (e.g. "CS1_ARG") to "ARG_1".
%   Ports the Python _normalize_source_name helper.

    s = strtrim(char(source));
    if numel(s) == 7 && startsWith(s, 'CS')
        s = sprintf('%s_%s', s(end-2:end), s(3));
    end
end
