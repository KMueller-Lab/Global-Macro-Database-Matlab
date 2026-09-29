classdef tGmd < matlab.unittest.TestCase
    % Tests for the parts of gmd() implemented so far (argument validation
    % and the print_option mode). Data-loading tests are added as the
    % corresponding milestones in PLAN.md land.

    methods (Test)

        function printOptionGmd(tc)
            out = evalc("globalmacrodata.gmd('print_option','GMD');");
            tc.verifySubstring(out, 'Global Macro Database');
            tc.verifySubstring(out, '33714');
        end

        function printOptionStata(tc)
            out = evalc("globalmacrodata.gmd('print_option','Stata');");
            tc.verifySubstring(out, 'gmd');
        end

        function printOptionInvalidRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('print_option','bogus'), 'GMD:e198');
        end

        function invalidFlagRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('raw','maybe'), 'GMD:e498');
        end

        function startAfterEndRaises(tc)
            tc.verifyError(@() globalmacrodata.gmd('start_year',2020,'end_year',2000), 'GMD:e498');
        end

    end
end
