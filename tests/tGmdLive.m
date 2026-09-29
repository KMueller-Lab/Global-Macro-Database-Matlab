classdef tGmdLive < matlab.unittest.TestCase
    % Integration tests that hit the release bucket over the network. These
    % use only the small helper tables (versions, varlist, source list) and
    % avoid downloading the full dataset. They are skipped automatically when
    % the bucket is unreachable.

    methods (TestClassSetup)
        function requireNetwork(tc)
            try
                globalmacrodata.get_current_version();
            catch
                tc.assumeFail('Release bucket is not reachable; skipping live tests.');
            end
            clear('functions');  % reset persistent getter caches
        end
    end

    methods (Test)

        function currentVersionHasExpectedFormat(tc)
            v = globalmacrodata.get_current_version();
            tc.verifyMatches(v, '^\d{4}_\d{2}$');
        end

        function availableVersionsNonEmpty(tc)
            v = globalmacrodata.get_available_versions();
            tc.verifyGreaterThan(numel(v), 0);
        end

        function versionListPrints(tc)
            out = evalc("globalmacrodata.gmd('version','list');");
            tc.verifyMatches(out, '\d{4}_\d{2}');
        end

        function varsListPrints(tc)
            out = evalc("globalmacrodata.gmd('vars','list');");
            tc.verifySubstring(out, 'Available variables');
        end

        function varsLoadReturnsTable(tc)
            t = globalmacrodata.gmd('vars', 'load');
            tc.verifyClass(t, 'table');
            tc.verifyGreaterThan(height(t), 0);
        end

        function sourcesListPrints(tc)
            out = evalc("globalmacrodata.gmd('sources','list');");
            tc.verifyGreaterThan(strlength(strtrim(out)), 0);
        end

        function citeGmdPrintsBibtex(tc)
            out = evalc("globalmacrodata.gmd('cite','GMD');");
            tc.verifySubstring(out, '@');
        end

        function sourceDataUnsupportedInMatlab(tc)
            % Source-level data is Stata-only; the port reports this clearly.
            tc.verifyError(@() globalmacrodata.gmd('sources','IMF_WEO'), 'GMD:e501');
        end

        function unknownVersionRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('version','1900_01'), 'GMD:e498');
        end

    end
end
