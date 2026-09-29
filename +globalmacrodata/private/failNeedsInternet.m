function failNeedsInternet(action)
%FAILNEEDSINTERNET Raise a GMD error when a mode requires internet access.
%   Ports the Python _fail_needs_internet helper.

    cfg = gmdConfig();
    fail(498, sprintf('You need access to the internet in order to %s', action), ...
        cfg.NetworkHint);
end
