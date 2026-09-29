function t = varlistTable()
%VARLISTTABLE Cached variable-definition table. Ports Python _varlist_df.

    persistent cached
    if isempty(cached)
        cached = readCsvRemote('helpers/varlist.csv');
    end
    t = cached;
end
