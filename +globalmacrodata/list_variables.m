function list_variables()
%LIST_VARIABLES Print the variable table.
%   Thin wrapper over gmd('vars','list'). Not implemented yet. See PLAN.md.

    globalmacrodata.gmd('vars', 'list');
end
