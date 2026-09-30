function cfg = gmdConfig()
%GMDCONFIG Shared constants for the GMD package (ports the module constants
%   from the Python gmd.py).

    cfg.PackageVersion = '1.0.0';
    cfg.DataBases = { ...
        'https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data', ...
        'https://raw.githubusercontent.com/KMueller-Lab/Global-Macro-Database/refs/heads/main/data'};
    cfg.Timeout        = 60;
    cfg.MaxRetries     = 3;
    cfg.BackoffBase    = 0.5;
    cfg.UserAgent      = sprintf(['global-macro-data/%s ' ...
        '(+https://github.com/KMueller-Lab/Global-Macro-Database-Matlab)'], cfg.PackageVersion);
    cfg.IdCols         = {'ISO3', 'year', 'id', 'countryname'};
    cfg.IssuesUrl      = 'https://github.com/KMueller-Lab/Global-Macro-Database';
    cfg.NetworkHint    = 'If you have active internet access, specify the option: gmd(''network'',''yes'')';
end
