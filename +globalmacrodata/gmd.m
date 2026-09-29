function df = gmd(opts)
%GMD Fetch macroeconomic data from the Global Macro Database.
%   DF = GMD() downloads the full latest dataset and returns it as a table.
%   Name-value arguments narrow the data down or switch GMD into one of its
%   helper and metadata modes. This is the MATLAB port of the Python and R
%   packages; see README.md for usage and PLAN.md for the implementation plan.
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
%   the print-only modes ('version','list'; 'vars','list'; 'country','list';
%   'sources','list'; a cite lookup; and 'print_option').
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

    APA_GMD = ['Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). ' ...
        'The Global Macro Database: A New International Macroeconomic ' ...
        'Dataset (NBER Working Paper No. 33714).'];
    APA_PACKAGE = ['Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to ' ...
        'Access the World''s Most Comprehensive Macroeconomic Database. ' ...
        'Working Paper.'];

    df = [];

    % --- flag and year coercion (front matter, matches Python order) -------
    raw  = coerceFlag(opts.raw,  'raw');
    iso  = coerceFlag(opts.iso,  'iso');
    fast = coerceFlag(opts.fast, 'fast'); %#ok<NASGU>

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

    vers    = opts.version;
    if ischar(vers) || (isstring(vers) && isscalar(vers))
        vers = strtrim(char(vers));
    end
    vers    = kw(vers,        {'list','current'});
    sources = kw(opts.sources, {'load','list'});
    cite    = kw(opts.cite,    {'load'});
    vars    = kw(opts.vars,    {'load','list'});

    % --- print_option mode --------------------------------------------------
    if ~isempty(opts.print_option)
        option = lower(strtrim(char(opts.print_option)));
        switch option
            case 'gmd'
                fprintf('%s\n', APA_GMD); return;
            case 'stata'
                fprintf('%s\n', APA_PACKAGE); return;
            otherwise
                fail(198, 'Invalid option for print(). valid arguments are ''GMD'' or ''Stata''.');
        end
    end

    % ----------------------------------------------------------------------
    % Remaining modes (version listing, cite, sources, vars, country, and the
    % default variable/country load) are being ported. See PLAN.md, section 8.
    % ----------------------------------------------------------------------
    error('GMD:notImplemented', ...
        ['Data loading is not implemented yet in the MATLAB port.\n' ...
         'Implemented so far: argument validation and print_option.\n' ...
         'See PLAN.md for the remaining milestones.']);
end
