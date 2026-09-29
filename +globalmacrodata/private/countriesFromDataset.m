function ct = countriesFromDataset(ver, fast)
%COUNTRIESFROMDATASET Derive the country table (ISO3, countryname) from the
%   dataset. MATLAB-port deviation: the release bucket serves the country list
%   only as a Stata .dta file (helpers/countrylist.csv is absent), which
%   MATLAB cannot read, so the list is derived from the distinct ISO3 and
%   country names in the dataset. See PLAN.md.

    df = datasetTable(ver, fast);
    if ~all(ismember({'ISO3', 'countryname'}, df.Properties.VariableNames))
        failWithIssue('country list');
    end
    sub = df(:, {'ISO3', 'countryname'});
    [~, ia] = unique(string(sub.ISO3), 'stable');
    ct = sub(ia, :);
    ct = sortrows(ct, 'ISO3');
end
