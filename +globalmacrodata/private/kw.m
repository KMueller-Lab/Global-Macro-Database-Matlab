function out = kw(value, words)
%KW Lower-case a char argument only when it is one of the given keywords.
%   Leaves real version numbers, source names, and cite keys unchanged.
%   Equivalent of the inner _kw helper in the Python package.

    out = value;
    if ischar(value) || (isstring(value) && isscalar(value))
        lowered = lower(strtrim(char(value)));
        if ismember(lowered, words)
            out = lowered;
        end
    end
end
