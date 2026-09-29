function t = readDta(path)
%READDTA Read a Stata .dta file into a table.
%   Supports the old binary format 114/115 and the modern tagged formats
%   117/118/119. Value labels are ignored (data read unlabeled, like the
%   Python package's convert_categoricals=False), strL long strings are not
%   supported, and numeric Stata missing values become NaN.

    fid = fopen(path, 'r');
    if fid < 0
        error('GMD:e498', 'Cannot open .dta file: %s', path);
    end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    raw = fread(fid, inf, '*uint8')';

    if numel(raw) >= 11 && isequal(char(raw(1:11)), '<stata_dta>')
        t = parseTagged(raw);
    elseif raw(1) == 114 || raw(1) == 115
        t = parseOld(raw);
    else
        error('GMD:e501', 'Unrecognized .dta format (first byte %d).', raw(1));
    end
end

% =========================================================================
% Modern tagged format (117/118/119)
% =========================================================================
function t = parseTagged(raw)
    s = char(raw);

    rel = regexp(s(1:min(numel(s), 400)), '<release>(\d+)</release>', 'tokens', 'once');
    release = str2double(rel{1});
    bo = regexp(s(1:min(numel(s), 400)), '<byteorder>(LSF|MSF)</byteorder>', 'tokens', 'once');
    big = strcmp(bo{1}, 'MSF');

    iK = strfind(s, '<K>') + 3;
    nvar = double(rdInt(raw(iK:iK + 1), 'uint16', big));

    iN = strfind(s, '<N>') + 3;
    if release >= 118
        nobs = double(rdInt(raw(iN:iN + 7), 'uint64', big));
    else
        nobs = double(rdInt(raw(iN:iN + 3), 'uint32', big));
    end

    iMap = strfind(s, '<map>') + numel('<map>');
    mapvals = double(typecast(uint8(raw(iMap:iMap + 14 * 8 - 1)), 'uint64'));
    if big
        mapvals = double(swapbytes(uint64(mapvals)));
    end
    % mapvals (1-based): 3=variable_types, 4=varnames, 10=data (0-based file offsets)
    typesOff = mapvals(3) + numel('<variable_types>');
    namesOff = mapvals(4) + numel('<varnames>');
    dataOff  = mapvals(10) + numel('<data>');

    typlist = double(rdInt(raw(typesOff + 1 : typesOff + 2 * nvar), 'uint16', big));

    if release >= 118
        fieldLen = 129;   % 128 chars + null
    else
        fieldLen = 33;    % 32 chars + null
    end
    varnames = readFixedStrings(raw, namesOff + 1, fieldLen, nvar);

    t = readData(raw, dataOff + 1, typlist, varnames, nvar, nobs, big);
end

% =========================================================================
% Old binary format (114/115)
% =========================================================================
function t = parseOld(raw)
    big = (raw(2) == 1);   % 1 = HILO (big), 2 = LOHI (little)
    nvar = double(rdInt(raw(5:6), 'int16', big));
    nobs = double(rdInt(raw(7:10), 'int32', big));

    pos = 110;   % header is 109 bytes
    typlist = double(raw(pos:pos + nvar - 1));  pos = pos + nvar;
    varnames = readFixedStrings(raw, pos, 33, nvar);  pos = pos + 33 * nvar;
    pos = pos + 2 * (nvar + 1);   % srtlist
    pos = pos + 49 * nvar;        % fmtlist
    pos = pos + 33 * nvar;        % value-label names
    pos = pos + 81 * nvar;        % variable labels
    while true                    % expansion fields
        dtype = raw(pos); pos = pos + 1;
        pos = pos + 4;            % (int32 length, ignored for terminator)
        if dtype == 0
            break;
        end
        pos = pos + double(rdInt(raw(pos - 4:pos - 1), 'int32', big));
    end
    t = readData(raw, pos, typlist, varnames, nvar, nobs, big);
end

% =========================================================================
% Shared data-block decoder
% =========================================================================
function t = readData(raw, dataStart, typlist, varnames, nvar, nobs, big)
    sizes = zeros(1, nvar);
    for i = 1:nvar
        sizes(i) = typeSize(typlist(i));
    end
    rowSize = sum(sizes);

    block = raw(dataStart:dataStart + rowSize * nobs - 1);
    block = reshape(block, rowSize, nobs);   % column j = observation j

    cols = cell(1, nvar);
    offset = 0;
    for i = 1:nvar
        s = sizes(i);
        fieldBytes = block(offset + 1:offset + s, :);
        offset = offset + s;
        if isStringCode(typlist(i))
            chars = char(fieldBytes');   % nobs x s
            strs = strings(nobs, 1);
            for r = 1:nobs
                row = chars(r, :);
                nul = find(row == char(0), 1);
                if ~isempty(nul)
                    row = row(1:nul - 1);
                end
                strs(r) = string(strtrim(row));
            end
            cols{i} = strs;
        else
            cols{i} = decodeNumeric(fieldBytes, typlist(i), big);
        end
    end

    t = table(cols{:});
    t.Properties.VariableNames = varnames;
end

% =========================================================================
% Type helpers (handle both the 114 and 117/118 code schemes)
% =========================================================================
function tf = isStringCode(code)
    % str<n>: 1..244 (format 114) or 1..2045 (117/118). The old-format numeric
    % codes 251..255 fall in that range but are not strings.
    tf = code >= 1 && code <= 2045 && ~ismember(code, [251 252 253 254 255]);
end

function s = typeSize(code)
    switch code
        case {251, 65530}, s = 1;   % byte
        case {252, 65529}, s = 2;   % int
        case {253, 65528}, s = 4;   % long
        case {254, 65527}, s = 4;   % float
        case {255, 65526}, s = 8;   % double
        case 32768
            error('GMD:e501', 'strL (long string) columns are not supported.');
        otherwise
            if code >= 1 && code <= 2045
                s = code;   % str<code>
            else
                error('GMD:e501', 'Unsupported .dta variable type code %d', code);
            end
    end
end

function out = decodeNumeric(fieldBytes, code, big)
    switch code
        case {251, 65530}, cls = 'int8';   maxv = 100;         minv = -127;
        case {252, 65529}, cls = 'int16';  maxv = 32740;       minv = -32767;
        case {253, 65528}, cls = 'int32';  maxv = 2147483620;  minv = -2147483647;
        case {254, 65527}, cls = 'single'; maxv = 1.701e38;    minv = -Inf;
        case {255, 65526}, cls = 'double'; maxv = 8.988e307;   minv = -Inf;
    end
    vals = typecast(reshape(fieldBytes, 1, []), cls);
    if big
        vals = swapbytes(vals);
    end
    out = double(vals(:));
    out(out > maxv | out < minv) = NaN;
end

function v = rdInt(bytes, cls, big)
    v = typecast(uint8(bytes), cls);
    if big
        v = swapbytes(v);
    end
end

function names = readFixedStrings(raw, pos, fieldLen, count)
    names = cell(1, count);
    for i = 1:count
        seg = raw(pos + (i - 1) * fieldLen : pos + i * fieldLen - 1);
        row = char(seg);
        nul = find(row == char(0), 1);
        if ~isempty(nul)
            row = row(1:nul - 1);
        end
        names{i} = strtrim(row);
    end
end
