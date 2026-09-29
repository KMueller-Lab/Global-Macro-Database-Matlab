function list_countries()
%LIST_COUNTRIES Print the country table.
%   Thin wrapper over gmd('country','list'). Not implemented yet. See PLAN.md.

    globalmacrodata.gmd('country', 'list');
end
