function failWithIssue(resource)
%FAILWITHISSUE Raise a GMD error pointing at the issue tracker.
%   Ports the Python _fail_with_issue helper.

    cfg = gmdConfig();
    fail(498, sprintf('Unable to access %s. Please raise an issue at %s', ...
        resource, cfg.IssuesUrl));
end
