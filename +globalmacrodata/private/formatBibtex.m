function s = formatBibtex(entry)
%FORMATBIBTEX Pretty-print a one-line BibTeX entry onto multiple lines.
%   Ports the Python _format_bibtex_for_print helper.

    s = strtrim(char(entry));
    s = regexprep(s, ',\s*([a-zA-Z0-9_]+\s*=)', sprintf(',\n  $1'));
    s = regexprep(s, '\}\s*$', sprintf('\n}'));
end
