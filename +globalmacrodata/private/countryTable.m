function t = countryTable()
%COUNTRYTABLE Cached country list, read from helpers/countrylist.dta.
%   Ports the Python _country_df (now that the package can read .dta).

    persistent cached
    if isempty(cached)
        cached = readDtaRemote('helpers/countrylist.dta');
    end
    t = cached;
end
