function raw = fetchFrom(relPath) %#ok<INUSD>
%FETCHFROM Fetch a file from the release bucket (S3 primary, GitHub mirror).
%   Walks the data bases with retry and backoff, skipping retries on 4xx.
%   The GitHub mirror only serves helpers/* tables. Returns the raw bytes or
%   text. Not implemented yet in the MATLAB port. See PLAN.md, section 3.
%
%   Base URLs:
%     https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data
%     (GitHub mirror for helpers/* only)
%
%   Full dataset and raw variables are read from the CSV endpoints
%   (distribute/GMD_<ver>.csv, distribute/<var>_<ver>.csv); see PLAN.md
%   section 2 for the format decision.

    error('GMD:notImplemented', 'fetchFrom is not implemented yet. See PLAN.md.');
end
