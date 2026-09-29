function v = get_current_version()
%GET_CURRENT_VERSION Get the latest version string.
%   Ports the Python get_current_version.

    all = globalmacrodata.get_available_versions();
    v = all{1};
end
