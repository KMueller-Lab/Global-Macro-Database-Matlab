function printSummary(df, anything, country, selectedVersion, versionOpt, raw, sources, fast, savedGmd)
%PRINTSUMMARY Print the citation and dataset summary. Ports Python _summary.

    cfg = gmdConfig();
    nVars = width(df);
    for i = 1:numel(cfg.IdCols)
        if ismember(cfg.IdCols{i}, df.Properties.VariableNames)
            nVars = nVars - 1;
        end
    end
    if nVars <= 0
        fail(498, sprintf('The database has no data on %s for %s', anything, country));
    end
    if height(df) <= 0
        return;
    end

    emit('Global Macro Database by Müller, Xu, Lehbib, and Chen (2025)');
    emit('Website: https://www.globalmacrodata.com');
    emit('');
    emit('When using these data, please cite:');
    emit('For BibTeX: gmd(''cite'',''GMD'')  |  For APA: gmd(''print_option'',''GMD'')');
    emit('');
    emit('When using the gmd command, please further cite:');
    emit('For BibTeX: gmd(''cite'',''lehbib2025gmd'')  |  For APA: gmd(''print_option'',''Stata'')');
    emit('');

    hasSources = ~isempty(sources) && ~strcmp(char(string(sources)), '');
    if ~fast && ~savedGmd && ~raw
        emit(sprintf(['To save the data locally for faster reloading, use: ' ...
            'gmd(''version'',''%s'',''fast'',''yes'')'], selectedVersion));
    end

    if raw || hasSources
        emit(sprintf('Final dataset: %d observations of %d variables', height(df), nVars));
    else
        if nVars > 1
            emit(sprintf('Final dataset: %d observations for %d variables', height(df), nVars));
        else
            emit(sprintf('Final dataset: %d observations for %d variable', height(df), nVars));
        end
    end

    if ~isempty(versionOpt) && ~strcmp(char(string(versionOpt)), '')
        emit(sprintf('Version: %s', char(string(versionOpt))));
    else
        emit(sprintf('Version: %s', selectedVersion));
    end
end
