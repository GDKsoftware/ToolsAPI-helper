unit GDK.ToolsAPI.ProjectMatch;

// Pure project-selection logic, kept free of any ToolsAPI dependency so it can
// be unit-tested. TToolsApiHelper.FindProject feeds it the project-group file
// names and a user-supplied query (a project name, base name or path fragment).

interface

type
  TProjectMatch = record
    // Returns the index in FileNames of the project that best matches Query, or
    // -1 when nothing matches or a substring match is ambiguous. Precedence:
    // exact full path, then exact base name (no extension), then a unique
    // case-insensitive substring of the file name. All comparisons ignore case.
    class function IndexOf(const FileNames: TArray<string>; const Query: string): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

class function TProjectMatch.IndexOf(const FileNames: TArray<string>; const Query: string): Integer;
begin
  Result := -1;

  const Trimmed = Query.Trim;
  if Trimmed = '' then
    Exit;

  const NormQuery = Trimmed.ToLower;
  const QueryBase = TPath.GetFileNameWithoutExtension(Trimmed).ToLower;

  // 1. Exact full-path match.
  for var Index := 0 to High(FileNames) do
    if FileNames[Index].ToLower = NormQuery then
      Exit(Index);

  // 2. Exact project name (base file name without extension).
  for var Index := 0 to High(FileNames) do
    if TPath.GetFileNameWithoutExtension(FileNames[Index]).ToLower = QueryBase then
      Exit(Index);

  // 3. Unique case-insensitive substring of the file name.
  var Match := -1;
  for var Index := 0 to High(FileNames) do
    if FileNames[Index].ToLower.Contains(NormQuery) then
    begin
      if Match <> -1 then
        Exit(-1);

      Match := Index;
    end;

  Result := Match;
end;

end.
