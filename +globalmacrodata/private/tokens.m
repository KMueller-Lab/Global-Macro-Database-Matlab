function t = tokens(v)
%TOKENS Normalize an argument into a cell array of string tokens.
%   Accepts [], a char row, a string array, a cellstr, or a numeric array.
%   Splits every element on whitespace and commas, trims, drops empties.
%   Equivalent of the Python _tokens helper.
%
%   tokens([])            -> {}
%   tokens('a b c')       -> {'a','b','c'}
%   tokens('a,b,c')       -> {'a','b','c'}
%   tokens({'a','b c'})   -> {'a','b','c'}
%   tokens([1 2])         -> {'1','2'}

    t = {};
    if isempty(v)
        return;
    end

    if isnumeric(v) || islogical(v)
        parts = arrayfun(@(x) num2str(x), v(:), 'UniformOutput', false);
    elseif ischar(v)
        parts = {v};
    elseif isstring(v)
        parts = cellstr(v(:));
    elseif iscell(v)
        parts = cellfun(@(x) char(string(x)), v(:), 'UniformOutput', false);
    else
        fail(498, 'Unsupported argument type for tokens()');
    end

    out = {};
    for i = 1:numel(parts)
        pieces = regexp(parts{i}, '[\s,]+', 'split');
        for j = 1:numel(pieces)
            p = strtrim(pieces{j});
            if ~isempty(p)
                out{end+1} = p; %#ok<AGROW>
            end
        end
    end
    t = out;
end
