# Implementation plan: MATLAB port of the GMD package

Goal: a MATLAB package with the **same public API and behavior** as the Python
and R packages, and the **same README, license, and layout**.

## 1. Reference contract (from the Python `gmd.py`)

The port must reproduce this observable behavior:

- Single entry point `gmd(...)` returning a `table` (equivalent of a pandas
  DataFrame), or nothing for the print-only modes.
- Modes dispatched in a fixed order: `print_option` -> version list/current ->
  `cite` -> `sources` -> `vars` -> country list/load -> default variable and
  country load.
- Data sources: S3 primary, GitHub mirror secondary (the mirror only serves
  `helpers/*` tables, not the versioned releases).
- Local cache under `~/.global_macro_data`; `fast` persists the dataset.
- Errors funnel through one helper that raises a typed error with a numeric
  code (MATLAB `MException`, identifier `GMD:e<code>`).
- Boolean-like string coercion (`yes`/`no`/`true`/`false`/`on`/`off`/`1`/`0`);
  any other value raises an error.
- Case-insensitive matching of variable, country, and keyword arguments, with
  results returned in the dataset's canonical casing.

## 2. Data format decision (RESOLVED)

MATLAB has no built-in Stata `.dta` reader, so the release bucket was probed
for alternatives:

| Endpoint | Result |
|----------|--------|
| `distribute/GMD_<ver>.csv` | **Available** (HTTP 206 on range request) |
| `distribute/GMD_<ver>.parquet` | Not found (404) |
| `distribute/GMD_<ver>.dta` | Available |
| `distribute/<var>_<ver>.csv` (raw) | Available |
| `helpers/varlist.csv`, `helpers/source_list.csv`, `helpers/versions.csv` | Available |

**Decision:** use the CSV endpoints throughout via `webread` + `readtable`.
No `.dta` reader is needed and the package has **no external dependencies**.
The full-dataset CSV header was confirmed to carry the expected columns
(`countryname, ISO3, id, year, nGDP, ...`).

## 3. Repository layout

```
Global-Macro-Database-Matlab/
  +globalmacrodata/            % package namespace (call as globalmacrodata.gmd)
    gmd.m                      % public entry point, name-value API
    get_available_versions.m
    get_current_version.m
    list_variables.m
    list_countries.m
    private/                   % internal helpers, not user-visible
      fetchFrom.m              % S3 -> mirror retry/backoff, skip retry on 4xx
      readCsvRemote.m          % webread + readtable
      coerceFlag.m
      coerceYear.m
      tokens.m                 % split char/cellstr on spaces and commas
      kw.m                     % case-insensitive keyword normalization
      fail.m                   % build and throw MException GMD:e<code>
      cacheDir.m / atomicSave.m
      versionsTable.m varlistTable.m sourceListTable.m bibTable.m countriesTable.m
  Contents.m                   % package banner and version
  gmd.prj                      % toolbox packaging definition -> .mltbx
  tests/
    tGmd.m ...                 % matlab.unittest classes, one per feature area
    fixtures/{clean,final,helpers}/   % copied from the Python test fixtures
  README.md  LICENSE  PLAN.md  .gitignore
  .github/workflows/test.yml   % CI: setup-matlab + run-tests
```

## 4. Construct mapping (Python -> MATLAB)

| Python | MATLAB |
|--------|--------|
| `def gmd(**kwargs)` | `arguments` block with name-value pairs |
| pandas DataFrame | `table` |
| `requests.get` + retry/backoff | `webread`/`websave` with `weboptions`, manual retry loop, skip retry on 4xx |
| `@lru_cache(maxsize=1)` | `persistent` variable in each getter (or `memoize`) |
| `GMDCommandError(code)` | `MException('GMD:e%d', ...)` |
| `os.replace` atomic write | write `.tmp` then `movefile` |
| `str.lower()` keyword match | `lower`, `matches`, `ismember` |
| list `['USA','CHN']` | cellstr or string array; also accept space/comma split |
| `read_stata` / `read_csv` | `readtable` over the CSV endpoints (section 2) |

## 5. Public API shape

```matlab
df = globalmacrodata.gmd();                                  % latest
df = globalmacrodata.gmd('version','2025_12', ...
        'country',{'USA','CHN'}, 'variables',{'rGDP','infl'});
globalmacrodata.gmd('version','list');                       % prints, returns []
df = globalmacrodata.gmd('variables','rGDP','raw',true);
```

Name-value pairs replace Python keyword arguments; every mode and result is
otherwise identical.

## 6. Testing

- `matlab.unittest`, one class per Python `Test*` area (target parity with the
  ~130 Python cases).
- Reuse the **same fixtures** as Python (`tests/fixtures/{clean,final,helpers}`).
- Network is mocked by making `fetchFrom` swappable: tests inject a
  local-file fetcher through a function handle seam, mirroring the Python
  `responses`/monkeypatch approach. No live network calls in the suite.
- CI via GitHub Actions using `matlab-actions/setup-matlab` and `run-tests`.

## 7. README, license, metadata

- README uses the **shared skeleton** (Features, Installation, Usage,
  Parameters, Citation, Documentation, Authors, License) with the same website
  call-to-action and badge row (MATLAB badge in place of the PyPI badge).
- LICENSE is the identical **Global Macro Database Non-Commercial License**.
- `Contents.m` version banner and the `.prj` license field state Non-Commercial.
- Repo description (needs admin rights to set):
  `MATLAB package to access the Global Macro Database. 79 macro variables across 243 countries, from 1086 to 2030.`

## 8. Milestones

1. [x] Probe bucket for a CSV or Parquet full-dataset endpoint. **CSV confirmed.**
2. [x] Scaffold repository: layout, README, LICENSE, PLAN, stubs, CI.
3. [x] Core plumbing: `fetchFrom`, `readCsvRemote`, cache, `fail`, flag/year coercion.
4. [x] Cached getters: versions, varlist, sources, bib.
5. [x] `gmd.m` dispatcher, modes in the Python order (see limitations below).
6. [x] Offline mocked tests for parity. A fixture backend seam (`useFixtures`,
       routing every fetch and the cache dir to local files) drives `tGmdOffline`
       (27 cases) fully offline; `tGmd` (validation) and `tGmdLive` (network)
       round it out. 41 tests, all green on R2026b.
7. [x] Toolbox packaging: `package_toolbox.m` builds `Global-Macro-Database.mltbx`
       via ToolboxOptions. Verified install/run/uninstall on R2026b.
8. [ ] Set the repo description (needs admin) and announce.

## Implemented modes

Working end to end: default variable/country load with case-insensitive
matching and canonical casing, year range, `version` list/current/specific,
`vars` list/load, `sources` list/load and individual source data (including
CS aliases), `cite` load and single-key BibTeX, `country` list/load,
`print_option`, `fast` local caching and reload, and the offline version
fallback. Verified live against the release bucket on R2026b.

## Stata .dta support (resolved)

The country list and source-level tables are published only as Stata `.dta`.
A focused reader (`readDta`) now handles both the old binary format 114/115
and the modern tagged formats 117/118/119 (no external dependency): it reads
variable names, numeric types with Stata missing values mapped to NaN, and
fixed-length strings. Value labels are ignored (unlabeled read, matching the
Python `convert_categoricals=False`); strL long strings are not supported and
raise a clear error if ever encountered. This unlocks `gmd('sources','<name>')`
(including CS aliases) and `gmd('country','list'|'load')`, verified live
against the format-118 bucket files.

## 9. Open decisions

1. **Minimum MATLAB version.** The `arguments` block needs R2019b; propose
   R2020b or newer as the baseline.
2. **Distribution.** Ship as a plain package folder (the repository) and also
   attach a packaged toolbox (`.mltbx`) to each release.
