function fail(code, varargin)
%FAIL Raise a typed GMD error. Never returns.
%   fail(CODE, MSG1, MSG2, ...) throws an MException with identifier
%   'GMD:e<CODE>' whose message joins the message lines with newlines.
%   Mirrors the single error funnel (_fail) in the Python package.

    lines = cellfun(@(x) char(string(x)), varargin, 'UniformOutput', false);
    msg = strjoin(lines, newline);
    if isempty(msg)
        msg = 'GMD command error';
    end
    err = MException(sprintf('GMD:e%d', code), '%s', msg);
    throwAsCaller(err);
end
