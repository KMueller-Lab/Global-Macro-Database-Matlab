function y = coerceYear(value, name)
%COERCEYEAR Coerce a year argument to an integer scalar, or [] when unset.
%   Accepts [], a numeric scalar, or a numeric string. Equivalent of the
%   Python _coerce_year helper.

    if nargin < 2
        name = 'year';
    end

    if isempty(value)
        y = [];
        return;
    end
    if isnumeric(value) && isscalar(value) && isfinite(value)
        y = round(value);
        return;
    end
    if ischar(value) || (isstring(value) && isscalar(value))
        s = strtrim(char(value));
        n = str2double(s);
        if ~isnan(n)
            y = round(n);
            return;
        end
    end
    fail(498, sprintf('%s must be an integer year, got %s', name, char(string(value))));
end
