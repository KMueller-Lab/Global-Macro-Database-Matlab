function ok = fetchFrom(relPath, destFile, bases)
%FETCHFROM Download a file from the release bucket to a local file.
%   Walks BASES in order (S3 primary, then the GitHub mirror), retrying with
%   exponential backoff and skipping retries on clear 4xx client errors.
%   Ports the Python _fetch_from behavior. Throws GMD:fetch if every base and
%   attempt fails. The GitHub mirror only serves helpers/* tables.

    % Test seam: when a fixture root is set, serve files from disk instead of
    % the network (mirrors the Python monkeypatched _fetch_* backend).
    root = gmdBackend('get');
    if ~isempty(root)
        src = fullfile(root, strrep(relPath, '/', filesep));
        if ~exist(src, 'file')
            error('GMD:fetch', 'Local test resource not found: %s', src);
        end
        copyfile(src, destFile);
        ok = true;
        return;
    end

    cfg = gmdConfig();
    if nargin < 3 || isempty(bases)
        bases = cfg.DataBases;
    end

    opts = weboptions('Timeout', cfg.Timeout, ...
        'HeaderFields', {'User-Agent', cfg.UserAgent}, ...
        'ContentType', 'binary');

    errors = {};
    for b = 1:numel(bases)
        url = sprintf('%s/%s', bases{b}, relPath);
        for attempt = 1:cfg.MaxRetries
            try
                websave(destFile, url, opts);
                ok = true;
                return;
            catch ME
                is4xx = contains(ME.identifier, 'HTTP4') || ...
                        ~isempty(regexp(ME.message, '\<4\d\d\>', 'once'));
                errors{end+1} = sprintf('%s: %s', url, ME.message); %#ok<AGROW>
                if is4xx
                    break;  % client error will not recover; try next base
                end
                if attempt < cfg.MaxRetries
                    pause(cfg.BackoffBase * 2^(attempt - 1));
                end
            end
        end
    end

    error('GMD:fetch', 'Unable to load ''%s''. %s', relPath, strjoin(errors, '; '));
end
