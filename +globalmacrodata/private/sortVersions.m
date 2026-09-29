function t = sortVersions(t)
%SORTVERSIONS Sort a versions table newest first by the YYYY_MM string.
%   Ports the Python _sort_versions_df helper.

    v = string(t.versions);
    tok = regexp(v, '(\d{4})_(\d{2})', 'tokens', 'once');
    yr = zeros(numel(v), 1);
    mo = zeros(numel(v), 1);
    for i = 1:numel(v)
        if ~isempty(tok{i})
            yr(i) = str2double(tok{i}{1});
            mo(i) = str2double(tok{i}{2});
        end
    end
    [~, order] = sortrows([yr, mo], [-1, -2]);
    t = t(order, :);
end
