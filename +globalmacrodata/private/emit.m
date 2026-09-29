function emit(varargin)
%EMIT Print each argument on its own line (ports the Python _emit helper).

    for i = 1:nargin
        fprintf('%s\n', char(string(varargin{i})));
    end
end
