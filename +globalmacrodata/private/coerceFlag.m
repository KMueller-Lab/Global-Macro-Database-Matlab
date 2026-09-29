function b = coerceFlag(value, name)
%COERCEFLAG Coerce a logical or boolean-like string to a logical scalar.
%   Accepts true/false, [], or the strings yes/no/y/n/true/false/on/off/1/0
%   (case-insensitive, surrounding whitespace ignored). Any other value
%   raises a GMD error. Equivalent of the Python _coerce_flag helper.

    if nargin < 2
        name = 'flag';
    end

    if islogical(value) && isscalar(value)
        b = value;
        return;
    end
    if isempty(value)
        b = false;
        return;
    end
    if isnumeric(value) && isscalar(value)
        if value == 1
            b = true; return;
        elseif value == 0
            b = false; return;
        end
        fail(498, sprintf('Invalid value for %s: %g', name, value));
    end
    if ischar(value) || (isstring(value) && isscalar(value))
        token = lower(strtrim(char(value)));
        if ismember(token, {'yes','y','true','t','on','1'})
            b = true; return;
        end
        if ismember(token, {'no','n','false','f','off','0',''})
            b = false; return;
        end
        fail(498, sprintf('Invalid value for %s: %s', name, char(value)));
    end
    fail(498, sprintf('Invalid type for %s', name));
end
