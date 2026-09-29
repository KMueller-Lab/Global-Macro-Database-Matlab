function t = sourceListTable()
%SOURCELISTTABLE Cached source-list table. Ports Python _source_list_df.

    persistent cached
    if isempty(cached)
        cached = readCsvRemote('helpers/source_list.csv');
    end
    t = cached;
end
