function t = bibTable()
%BIBTABLE Cached citation table. Ports Python _bib_df.

    persistent cached
    if isempty(cached)
        cached = readCsvRemote('helpers/bib_dataframe.csv');
    end
    t = cached;
end
