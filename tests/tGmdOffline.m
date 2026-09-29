classdef tGmdOffline < matlab.unittest.TestCase
    % Fully offline tests: all fetches are routed to tests/fixtures and the
    % cache is redirected to a temp directory, so no network is used and the
    % real ~/.global_macro_data is never touched. Mirrors the coverage of the
    % Python suite for the modes the MATLAB port supports.

    properties
        FixtureRoot
        CacheDir
    end

    methods (TestClassSetup)
        function setupBackend(tc)
            here = fileparts(mfilename('fullpath'));
            tc.FixtureRoot = fullfile(here, 'fixtures');
            tc.CacheDir = fullfile(tempdir, 'gmd_matlab_test_cache');
            if ~exist(tc.CacheDir, 'dir'); mkdir(tc.CacheDir); end
            tc.addTeardown(@() teardownBackend(tc.CacheDir));
        end
    end

    methods (TestMethodSetup)
        function freshCaches(tc)
            % Reset the session getter caches so each test reads the fixtures
            % cleanly, drop any cached dataset, and (re)point the backend since
            % clear('functions') wipes its persistent state.
            f = fullfile(tc.CacheDir, 'GMD_2025_12.dta');
            if exist(f, 'file'); delete(f); end
            g = fullfile(tc.CacheDir, 'GMD.dta');
            if exist(g, 'file'); delete(g); end
            clear('functions');
            globalmacrodata.useFixtures(tc.FixtureRoot, tc.CacheDir);
        end
    end

    methods (Test)

        % --- versions -------------------------------------------------------
        function currentVersionIsLatest(tc)
            tc.verifyEqual(globalmacrodata.get_current_version(), '2025_12');
        end

        function availableVersionsSortedNewestFirst(tc)
            v = globalmacrodata.get_available_versions();
            tc.verifyEqual(v{1}, '2025_12');
            tc.verifyEqual(numel(v), 3);
        end

        function versionListPrints(tc)
            out = evalc("r = globalmacrodata.gmd('version','list');");
            tc.verifySubstring(out, '2025_12');
        end

        function currentVersionPrints(tc)
            out = evalc("r = globalmacrodata.gmd('version','current');");
            tc.verifySubstring(out, 'Current version: 2025_12');
        end

        function unknownVersionRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('version','1900_01'), 'GMD:e498');
        end

        % --- vars -----------------------------------------------------------
        function varsListPrints(tc)
            out = evalc("globalmacrodata.gmd('vars','list');");
            tc.verifySubstring(out, 'Available variables');
            tc.verifySubstring(out, 'rGDP');
        end

        function varsLoadReturnsTable(tc)
            t = globalmacrodata.gmd('vars','load');
            tc.verifyClass(t, 'table');
            tc.verifyGreaterThan(height(t), 0);
        end

        % --- cite -----------------------------------------------------------
        function citeGmdPrintsBibtex(tc)
            out = evalc("globalmacrodata.gmd('cite','GMD');");
            tc.verifySubstring(out, '@techreport');
        end

        function citeUnknownRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('cite','NOPE'), 'GMD:e498');
        end

        function citeMultipleRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('cite','GMD IMF_WEO'), 'GMD:e498');
        end

        function citeLoadReturnsTable(tc)
            t = globalmacrodata.gmd('cite','load');
            tc.verifyClass(t, 'table');
        end

        % --- sources --------------------------------------------------------
        function sourcesListPrints(tc)
            out = evalc("globalmacrodata.gmd('sources','list');");
            tc.verifySubstring(out, 'IMF_WEO');
        end

        function sourcesLoadReturnsTable(tc)
            t = globalmacrodata.gmd('sources','load');
            tc.verifyClass(t, 'table');
            tc.verifyGreaterThan(height(t), 0);
        end

        function sourceDataLoads(tc)
            df = globalmacrodata.gmd('sources','IMF_IFS');
            tc.verifyClass(df, 'table');
            tc.verifyTrue(all(ismember({'ISO3','year'}, df.Properties.VariableNames)));
        end

        function sourceVariableSelect(tc)
            df = globalmacrodata.gmd('sources','IMF_IFS','variables','CA_USD');
            tc.verifyTrue(ismember('IMF_IFS_CA_USD', df.Properties.VariableNames));
        end

        function sourceCsAliasResolves(tc)
            % CS1_ARG normalizes to source ARG_1 with data columns prefixed CS1_.
            df = globalmacrodata.gmd('sources','CS1_ARG','variables','M3_GDP');
            tc.verifyTrue(ismember('CS1_M3_GDP', df.Properties.VariableNames));
        end

        function invalidSourceRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('sources','NOPE'), 'GMD:e498');
        end

        % --- default load ---------------------------------------------------
        function defaultLoadReturnsAllCountries(tc)
            df = globalmacrodata.gmd();
            tc.verifyClass(df, 'table');
            iso = sort(unique(cellstr(string(df.ISO3))));
            tc.verifyEqual(iso(:)', {'CHN','DEU','USA'});
        end

        function variableSelectionIsCanonical(tc)
            df = globalmacrodata.gmd('variables','rgdp');
            tc.verifyTrue(ismember('rGDP', df.Properties.VariableNames));
            tc.verifyFalse(ismember('rgdp', df.Properties.VariableNames));
            tc.verifyTrue(ismember('ISO3', df.Properties.VariableNames));
        end

        function invalidVariableRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('variables','bogus'), 'GMD:e498');
        end

        function countryFilterSingle(tc)
            df = globalmacrodata.gmd('country','USA','variables','rGDP');
            tc.verifyEqual(unique(cellstr(string(df.ISO3))), {'USA'});
        end

        function countryFilterMultiple(tc)
            df = globalmacrodata.gmd('country',{'USA','DEU'},'variables','rGDP');
            iso = sort(unique(cellstr(string(df.ISO3))));
            tc.verifyEqual(iso(:)', {'DEU','USA'});
        end

        function invalidCountryRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('country','ZZZ','variables','rGDP'), 'GMD:e498');
        end

        function leadingEmptyYearsTrimmed(tc)
            % USA 1999 has no rGDP/infl, so the cumulative trim drops it.
            df = globalmacrodata.gmd('country','USA','variables',{'rGDP','infl'});
            years = double(df.year);
            tc.verifyFalse(any(years == 1999));
            tc.verifyEqual(min(years), 2000);
        end

        function yearRangeFilters(tc)
            df = globalmacrodata.gmd('variables','rGDP','start_year',2001,'end_year',2002);
            years = double(df.year);
            tc.verifyGreaterThanOrEqual(min(years), 2001);
            tc.verifyLessThanOrEqual(max(years), 2002);
        end

        % --- raw ------------------------------------------------------------
        function rawSingleVariable(tc)
            df = globalmacrodata.gmd('variables','rGDP','raw',true);
            tc.verifyClass(df, 'table');
            tc.verifyTrue(ismember('rGDP', df.Properties.VariableNames));
        end

        function rawMultipleRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('variables',{'rGDP','infl'},'raw',true), 'GMD:e498');
        end

        % --- country list/load ---------------------------------------------
        function countryListPrints(tc)
            out = evalc("globalmacrodata.gmd('country','list');");
            tc.verifySubstring(out, 'Available countries');
            tc.verifySubstring(out, 'ARG');
        end

        function countryLoadReturnsTable(tc)
            t = globalmacrodata.gmd('country','load');
            tc.verifyEqual(height(t), 10);
            tc.verifyTrue(all(ismember({'ISO3','countryname'}, t.Properties.VariableNames)));
        end

        function isoAliasPrintsCountries(tc)
            out = evalc("globalmacrodata.gmd('iso',true);");
            tc.verifySubstring(out, 'Available countries');
        end

    end
end

function teardownBackend(cacheDir)
    globalmacrodata.resetBackend();
    if exist(cacheDir, 'dir')
        try
            rmdir(cacheDir, 's');
        catch
        end
    end
    clear('functions');
end
