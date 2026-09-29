function resetBackend()
%RESETBACKEND Test helper: stop routing fetches to local fixtures.
%   Undoes globalmacrodata.useFixtures, so the package fetches from the
%   network again.

    gmdBackend('clear');
end
