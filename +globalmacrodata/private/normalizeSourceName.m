function [s, csPrefix] = normalizeSourceName(source)
%NORMALIZESOURCENAME Convert a CS alias to its file name.
%   "CS1_ARG" -> "ARG_1", "CS10_ITA" -> "ITA_10". Also returns the column
%   prefix inside the file ("CS1", "CS10"), or '' when the name is not a CS
%   alias. Ports the Python _normalize_source_name helper.

    s = strtrim(char(source));
    csPrefix = '';
    tok = regexp(s, '^CS(\d+)_([A-Za-z]{3})$', 'tokens', 'once', 'ignorecase');
    if ~isempty(tok)
        csPrefix = ['CS', tok{1}];
        s = sprintf('%s_%s', upper(tok{2}), tok{1});
    end
end
