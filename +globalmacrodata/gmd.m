function df = gmd(opts)
%GMD Fetch macroeconomic data from the Global Macro Database.
%   DF = GMD() downloads the full latest dataset and returns it as a table.
%   Name-value arguments narrow the data down or switch GMD into one of its
%   helper and metadata modes. This is the MATLAB port of the Python and R
%   packages; see README.md for usage.
%
%   Name-value arguments:
%     'variables'   Variable code(s) to keep: 'rGDP' or {'rGDP','infl'}.
%     'country'     ISO3 code(s): 'USA' or {'USA','CHN'}. 'list'/'load' print
%                   or return the country table.
%     'version'     Data vintage 'YYYY_MM'. 'current' reports the latest,
%                   'list' prints every available version.
%     'raw'         If true, load raw source-level data for one variable.
%     'iso'         If true, alias for 'country','list'.
%     'vars'        'list' prints the variable table, 'load' returns it.
%     'sources'     A source name, or 'list'/'load'.
%     'cite'        A source key to print its BibTeX, or 'load'.
%     'print_option' 'GMD' or 'Stata' to print an APA-style citation.
%     'network'     Pass 'yes' to force the fetch when detection failed.
%     'fast'        If true, cache the dataset locally for faster reloads.
%     'start_year'  Keep rows with year >= start_year.
%     'end_year'    Keep rows with year <= end_year.
%
%   Returns a table (or the metadata table for the 'load' modes), or [] for
%   the print-only modes.
%
%   Example:
%     df = globalmacrodata.gmd('version','2025_12', ...
%              'country',{'USA','CHN'}, 'variables',{'rGDP','infl'});

    arguments
        opts.variables    = []
        opts.country      = []
        opts.version      = []
        opts.raw          = []
        opts.iso          = []
        opts.vars         = []
        opts.sources      = []
        opts.cite         = []
        opts.print_option = []
        opts.network      = []
        opts.fast         = []
        opts.start_year   = []
        opts.end_year     = []
    end

    cfg = gmdConfig();
    APA_GMD = ['Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). ' ...
        'The Global Macro Database: A New International Macroeconomic ' ...
        'Dataset (NBER Working Paper No. 33714).'];
    APA_PACKAGE = ['Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to ' ...
        'Access the World''s Most Comprehensive Macroeconomic Database. ' ...
        'Working Paper.'];
    VARS_HINTS = {'To print the list of variables: gmd(''vars'',''list'')', ...
                  'To load the list of variables: gmd(''vars'',''load'')'};
    COUNTRY_HINTS = {'To print the list of countries: gmd(''country'',''list'')', ...
                     'To load the list of countries: gmd(''country'',''load'')'};

    df = [];

    % --- flag and year coercion (front matter, matches Python order) -------
    raw  = coerceFlag(opts.raw,  'raw');
    iso  = coerceFlag(opts.iso,  'iso');
    fast = coerceFlag(opts.fast, 'fast');

    startYear = coerceYear(opts.start_year, 'start_year');
    endYear   = coerceYear(opts.end_year,   'end_year');
    if ~isempty(startYear) && ~isempty(endYear) && startYear > endYear
        fail(498, sprintf('start_year (%d) cannot be greater than end_year (%d)', ...
            startYear, endYear));
    end

    country = opts.country;
    if iso
        country = 'list';
    end

    vers = opts.version;
    if ischar(vers) || (isstring(vers) && isscalar(vers))
        vers = strtrim(char(vers));
    end
    vers    = kw(vers,        {'list', 'current'});
    sources = kw(opts.sources, {'load', 'list'});
    cite    = kw(opts.cite,    {'load'});
    vars    = kw(opts.vars,    {'load', 'list'});

    anythingTokens = tokens(opts.variables);
    anything = strjoin(anythingTokens, ' ');
    wordCount = numel(anythingTokens);

    if ischar(country) || (isstring(country) && isscalar(country))
        countryArg = char(country);
    elseif isempty(country)
        countryArg = '';
    else
        countryArg = strjoin(tokens(country), ' ');
    end

    % --- print_option mode --------------------------------------------------
    if ~isempty(opts.print_option)
        option = lower(strtrim(char(opts.print_option)));
        switch option
            case 'gmd',   emit(APA_GMD);     return;
            case 'stata', emit(APA_PACKAGE); return;
            otherwise
                fail(198, 'Invalid option for print(). valid arguments are ''GMD'' or ''Stata''.');
        end
    end

    % --- version resolution (with offline fallback) ------------------------
    selectedVersion = '';
    availableVersions = strings(0);
    hasInternet = true;
    gmdLocalPath = '';
    savedGmd = false;

    try
        vt = versionsTable();
        selectedVersion = char(string(vt.versions(1)));
        availableVersions = sort(unique(string(vt.versions)));

        if ischar(vers) && strcmp(vers, 'list')
            for i = 1:numel(availableVersions)
                emit(char(availableVersions(i)));
            end
            return;
        end

        if ~isempty(vers) && ~strcmp(char(string(vers)), '')
            req = char(string(vers));
            if numel(tokens(req)) ~= 1
                emit(sprintf('Version must either be one specific version (%s) or current.', selectedVersion));
                return;
            end
            if ismember(string(req), availableVersions)
                selectedVersion = req;
            elseif strcmp(req, 'current')
                emit(sprintf('Current version: %s', selectedVersion));
            else
                fail(498, sprintf('Error: Version %s does not exist', req), ...
                    sprintf('Available versions: %s', strjoin(cellstr(availableVersions'), ' ')));
            end
        end
    catch ME
        if startsWith(ME.identifier, 'GMD:e')
            rethrow(ME);
        end
        hasInternet = ~isempty(opts.network) && ~strcmp(char(string(opts.network)), '');
        emit('Error: Unable to access version information. Check internet connection.');
        emit('Loading local version');
        localDefault = fullfile(cacheDir(), 'GMD.dta');
        if ~exist(localDefault, 'file')
            fail(498, 'Local version not found');
        end
        gmdLocalPath = localDefault;
        savedGmd = true;
        selectedVersion = '';
    end

    % --- internet guards for modes that must fetch -------------------------
    if ~hasInternet
        if any(strcmp(sources, {'load', 'list'}))
            failNeedsInternet('fetch the sources list');
        elseif ~isempty(sources) && ~strcmp(char(string(sources)), '')
            failNeedsInternet(sprintf('fetch the %s data', char(string(sources))));
        end
        if raw
            failNeedsInternet('fetch the raw data');
        end
        if strcmp(cite, 'load')
            failNeedsInternet('load the sources to cite');
        elseif ~isempty(cite) && ~strcmp(char(string(cite)), '')
            failNeedsInternet(sprintf('cite %s', char(string(cite))));
        end
    end

    % --- cite mode ----------------------------------------------------------
    if strcmp(cite, 'load')
        try
            df = bibTable();
        catch
            failWithIssue('the list of sources to cite');
        end
        return;
    end
    if ~isempty(cite) && ~strcmp(char(string(cite)), '')
        citeTokens = tokens(cite);
        if numel(citeTokens) ~= 1
            fail(498, 'Only one citation can be retrieved at a time');
        end
        key = citeTokens{1};
        bib = bibTable();
        keyCol = firstMember({'source_name', 'source'}, bib.Properties.VariableNames);
        if isempty(keyCol)
            fail(111, 'source_name not found');
        end
        if ~ismember('citation', bib.Properties.VariableNames)
            fail(111, 'citation not found');
        end
        mask = lower(string(bib.(keyCol))) == lower(string(key));
        if ~any(mask)
            fail(498, sprintf('Source ''%s'' does not exist.', key), ...
                'To load the list of sources to cite: gmd(''cite'',''load'')');
        end
        cites = string(bib.citation(mask));
        emit(formatBibtex(cites(1)));
        return;
    end

    % --- sources mode -------------------------------------------------------
    hasSources = ~isempty(sources) && ~strcmp(char(string(sources)), '');
    if hasSources && raw
        emit('Note: raw option is specified, but this is implicit when using the sources option.');
    end
    if any(strcmp(sources, {'load', 'list'}))
        try
            srcList = sourceListTable();
        catch
            failWithIssue('source list');
        end
        if strcmp(sources, 'load')
            emit('Imported the list of sources.');
            df = srcList;
            return;
        end
        for s = sort(unique(string(srcList.source_name)))'
            emit(char(s));
        end
        return;
    end
    if hasSources
        df = loadSourceData(char(string(sources)), anything, countryArg);
        return;
    end

    % --- vars mode ----------------------------------------------------------
    if strcmp(vars, 'load')
        try
            df = varlistTable();
        catch
            failWithIssue('variable list');
        end
        return;
    end
    if strcmp(vars, 'list')
        try
            vt2 = varlistTable();
        catch
            failWithIssue('variable list');
        end
        printVarTable(vt2);
        return;
    end

    % --- raw single-variable mode ------------------------------------------
    if raw
        if wordCount ~= 1
            fail(498, 'Warning: Please specify exactly one variable.');
        end
        try
            df = readCsvRemote(sprintf('distribute/%s_%s.csv', anything, selectedVersion));
        catch
            isValid = false;
            try
                vl = varlistTable();
                vcol = firstMember({'variable', 'variables'}, vl.Properties.VariableNames);
                isValid = ~isempty(vcol) && any(string(vl.(vcol)) == string(anything));
            catch
            end
            if ~isValid
                fail(498, 'Specified variable is not valid.');
            end
            fail(498, 'Variable does not have raw data.');
        end
        emit(sprintf('Loaded raw data on %s', anything));
    end

    % --- country list/load mode --------------------------------------------
    if (ischar(country) || (isstring(country) && isscalar(country))) ...
            && any(strcmpi(char(country), {'load', 'list'}))
        mode = lower(char(country));
        try
            ct = countryTable();
        catch
            failWithIssue('country list');
        end
        if strcmp(mode, 'load')
            df = ct;
        else
            printCountryTable(ct);
        end
        return;
    end

    % --- reject identifier variables ---------------------------------------
    if ismember(lower(anything), lower(cfg.IdCols))
        fail(498, sprintf(['%s is an identifying variable loaded in the dataset, ' ...
            'specify common variables'], anything), VARS_HINTS{:});
    end

    % --- default dataset load ----------------------------------------------
    if ~raw
        if isempty(gmdLocalPath)
            df = datasetTable(selectedVersion, fast);
        else
            df = readDta(gmdLocalPath);
        end
    end
    if isempty(df)
        error('GMD:e498', 'No data loaded');
    end

    % --- variable selection (case-insensitive, canonical casing) -----------
    if ~strcmp(anything, '') && ~raw
        colNames = df.Properties.VariableNames;
        lowerToActual = containers.Map('KeyType', 'char', 'ValueType', 'char');
        for i = 1:numel(colNames)
            lowerToActual(lower(colNames{i})) = colNames{i};
        end
        canonical = {};
        invalidVars = {};
        for i = 1:numel(anythingTokens)
            key = lower(anythingTokens{i});
            if isKey(lowerToActual, key)
                canonical{end+1} = lowerToActual(key); %#ok<AGROW>
            else
                invalidVars{end+1} = anythingTokens{i}; %#ok<AGROW>
            end
        end
        if ~isempty(invalidVars)
            if numel(invalidVars) == 1
                emit(sprintf('%s is not a valid variable code', invalidVars{1}));
            else
                emit(sprintf('%s are not valid variable codes', strjoin(invalidVars, ' ')));
            end
            fail(498, VARS_HINTS{:});
        end
        anythingTokens = canonical;

        keep = {};
        ordered = [cfg.IdCols, canonical];
        for i = 1:numel(ordered)
            if ismember(ordered{i}, df.Properties.VariableNames) && ~ismember(ordered{i}, keep)
                keep{end+1} = ordered{i}; %#ok<AGROW>
            end
        end
        df = df(:, keep);

        if all(ismember({'ISO3', 'year'}, df.Properties.VariableNames))
            sel = df(:, canonical);
            validCount = sum(~ismissing(sel), 2);
            [df, order] = sortrows(df, {'ISO3', 'year'});
            vc = validCount(order);
            [~, ~, g] = unique(string(df.ISO3), 'stable');
            mask = false(height(df), 1);
            for gi = 1:max(g)
                idx = find(g == gi);
                mask(idx) = cumsum(vc(idx)) > 0;
            end
            df = df(mask, :);
        end
    end

    % --- country filtering --------------------------------------------------
    if ~strcmp(countryArg, '')
        cTokens = tokens(upper(countryArg));
        if ~ismember('ISO3', df.Properties.VariableNames)
            fail(498, 'Country code is invalid or no data for this country in source.', ...
                COUNTRY_HINTS{:});
        end
        isoSeries = upper(string(df.ISO3));
        if numel(cTokens) == 1
            code = cTokens{1};
            if ~any(isoSeries == string(code))
                fail(498, 'Country code is invalid or no data for this country in source.', ...
                    COUNTRY_HINTS{:});
            end
            df = df(isoSeries == string(code), :);
        elseif numel(cTokens) > 1
            keepMask = false(height(df), 1);
            invalid = {};
            for i = 1:numel(cTokens)
                one = isoSeries == string(cTokens{i});
                if any(one)
                    keepMask = keepMask | one;
                else
                    invalid{end+1} = cTokens{i}; %#ok<AGROW>
                end
            end
            if ~isempty(invalid)
                inv = strjoin(invalid, ' ');
                if numel(invalid) == 1
                    emit(sprintf('%s is not a valid ISO3 code', inv));
                else
                    emit(sprintf('%s are not valid ISO3 codes', inv));
                end
                emit(COUNTRY_HINTS{:});
                fail(498, 'Invalid ISO3 code');
            end
            df = df(keepMask, :);
        end
    end

    % --- year range and cleanup --------------------------------------------
    df = applyYearRange(df, startYear, endYear);
    df = dropAllMissingColumns(df);

    printSummary(df, anything, countryArg, selectedVersion, opts.version, ...
        raw, sources, fast, savedGmd);
end

% -------------------------------------------------------------------------
% Local helper functions
% -------------------------------------------------------------------------

function out = firstMember(candidates, names)
    out = '';
    for i = 1:numel(candidates)
        if ismember(candidates{i}, names)
            out = candidates{i};
            return;
        end
    end
end

function df = dropAllMissingColumns(df)
    names = df.Properties.VariableNames;
    drop = false(1, numel(names));
    for i = 1:numel(names)
        drop(i) = all(ismissing(df.(names{i})));
    end
    df = df(:, ~drop);
end

function out = loadSourceData(srcName, anything, countryArg)
    csColPrefix = '';
    name = strtrim(srcName);
    if numel(name) == 7 && startsWith(name, 'CS')
        parts = strsplit(name, '_');
        csColPrefix = parts{1};
        name = normalizeSourceName(name);
    end
    srcTokens = tokens(name);
    if numel(srcTokens) > 1
        fail(498, 'Warning: Please specify exactly one source.');
    end
    name = srcTokens{1};

    try
        srcDf = readDtaRemote(sprintf('clean/combined/%s.dta', name));
    catch
        try
            srcList = sourceListTable();
        catch
            failWithIssue('source list');
        end
        mask = lower(string(srcList.source_name)) == lower(string(name));
        if ~any(mask)
            fail(498, 'Invalid source name', 'To load the list of sources: gmd(''sources'',''load'')');
        end
        matched = string(srcList.source_name(mask));
        name = char(matched(1));
        try
            srcDf = readDtaRemote(sprintf('clean/combined/%s.dta', name));
        catch
            fail(498, sprintf('Unable to load data for source ''%s''.', name), ...
                'Please check your internet connection or report this issue.');
        end
    end

    prefix = name;
    if ~isempty(csColPrefix)
        prefix = csColPrefix;
    end

    if ~strcmp(anything, '')
        srcCol = sprintf('%s_%s', prefix, anything);
        if ismember(srcCol, srcDf.Properties.VariableNames)
            keep = {};
            for c = {'ISO3', 'year', srcCol}
                if ismember(c{1}, srcDf.Properties.VariableNames)
                    keep{end+1} = c{1}; %#ok<AGROW>
                end
            end
            if ismember('countryname', srcDf.Properties.VariableNames)
                keep{end+1} = 'countryname';
            end
            if ismember('id', srcDf.Properties.VariableNames)
                keep{end+1} = 'id';
            end
            out = srcDf(:, keep);
            if ~strcmp(countryArg, '')
                target = upper(countryArg);
                out = out(upper(string(out.ISO3)) == string(target), :);
            end
            return;
        end
        avail = stripSourcePrefix(srcDf.Properties.VariableNames, prefix);
        fail(498, sprintf('This source doesn''t have data on %s. It has data on %s.', ...
            anything, strjoin(avail, ' ')));
    end

    out = srcDf;
end
