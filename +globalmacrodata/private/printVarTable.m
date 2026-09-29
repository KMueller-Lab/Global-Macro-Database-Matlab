function printVarTable(t)
%PRINTVARTABLE Print the variable-definition table. Ports _print_var_table.

    names = t.Properties.VariableNames;
    if ~ismember('variable', names) && ismember('variables', names)
        t.Properties.VariableNames{strcmp(names, 'variables')} = 'variable';
        names = t.Properties.VariableNames;
    end
    if ~all(ismember({'variable', 'definition', 'units'}, names))
        failWithIssue('variable list');
    end

    vname = fillmissing(string(t.variable), 'constant', "");
    vdef  = fillmissing(string(t.definition), 'constant', "");
    vunit = fillmissing(string(t.units), 'constant', "");

    varlen = max(strlength(vname)) + 2;
    deflen = max(strlength(vdef)) + varlen + 2;

    emit('', 'Available variables:', '');
    emit(repmat('-', 1, 90));
    header = [pad('Variable', varlen), pad('Definition', deflen - varlen), 'Units'];
    emit(header);
    emit(repmat('-', 1, 90));
    for i = 1:numel(vname)
        left = pad(char(vname(i)), varlen);
        row = [left, pad(char(vdef(i)), max(deflen - numel(left), 1)), char(vunit(i))];
        emit(row);
    end
    emit(repmat('-', 1, 90));
end
