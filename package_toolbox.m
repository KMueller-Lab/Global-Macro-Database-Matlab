function outFile = package_toolbox()
%PACKAGE_TOOLBOX Build the Global Macro Database toolbox (.mltbx).
%   Run from the repository root:
%       outFile = package_toolbox();
%   Produces Global-Macro-Database.mltbx, which installs the globalmacrodata
%   package as a MATLAB Add-On. The .mltbx is a build artifact and is not
%   checked in (see .gitignore).

    here = fileparts(mfilename('fullpath'));

    % Stable identifier for the toolbox (do not change across releases).
    identifier = '3f9a1c72-8b4e-4d5a-9c21-7e6b0a2f1d34';

    opts = matlab.addons.toolbox.ToolboxOptions(here, identifier);
    opts.ToolboxName    = 'Global Macro Database';
    opts.ToolboxVersion = '2.0.0';
    opts.Summary        = 'MATLAB access to the Global Macro Database.';
    opts.Description    = [ ...
        'A single function, globalmacrodata.gmd, fetches macroeconomic data ', ...
        'from the Global Macro Database (79 variables across 243 countries, ', ...
        '1086 to 2030). Supports variable, country, and year filters, data ', ...
        'vintages, source-level data, citations, and local caching. ', ...
        'See https://www.globalmacrodata.com.'];
    opts.AuthorName    = 'Mohamed Lehbib';
    opts.AuthorEmail   = 'lehbib@u.nus.edu';
    opts.AuthorCompany = 'National University of Singapore';

    % Ship only the package and its docs, not tests or the build script.
    opts.ToolboxFiles = { ...
        fullfile(here, '+globalmacrodata'), ...
        fullfile(here, 'Contents.m'), ...
        fullfile(here, 'README.md'), ...
        fullfile(here, 'LICENSE')};

    try
        opts.MinimumMatlabRelease = 'R2020b';
    catch
        % Older releases may not expose this property; ignore.
    end

    opts.OutputFile = fullfile(here, 'Global-Macro-Database.mltbx');

    matlab.addons.toolbox.packageToolbox(opts);
    outFile = opts.OutputFile;
    fprintf('Built %s\n', outFile);
end
