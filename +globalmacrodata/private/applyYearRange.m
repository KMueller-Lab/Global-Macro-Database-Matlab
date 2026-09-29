function df = applyYearRange(df, startYear, endYear)
%APPLYYEARRANGE Keep rows within [startYear, endYear]. Ports _apply_year_range.

    if (isempty(startYear) && isempty(endYear)) || ~ismember('year', df.Properties.VariableNames)
        return;
    end
    years = double(df.year);
    mask = true(height(df), 1);
    if ~isempty(startYear)
        mask = mask & (years >= startYear);
    end
    if ~isempty(endYear)
        mask = mask & (years <= endYear);
    end
    df = df(mask, :);
end
