function printCountryTable(t)
%PRINTCOUNTRYTABLE Print the country table. Ports _print_country_table.

    if ~all(ismember({'countryname', 'ISO3'}, t.Properties.VariableNames))
        failWithIssue('country list');
    end
    emit('', 'Available countries:', '');
    emit(repmat('-', 1, 90));
    emit('ISO3 code  Country name');
    emit(repmat('-', 1, 90));
    iso = fillmissing(string(t.ISO3), 'constant', "");
    name = fillmissing(string(t.countryname), 'constant', "");
    for i = 1:numel(iso)
        emit([pad(char(iso(i)), 10), char(name(i))]);
    end
    emit(repmat('-', 1, 90));
end
