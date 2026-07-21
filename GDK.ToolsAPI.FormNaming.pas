unit GDK.ToolsAPI.FormNaming;

interface

uses
  System.SysUtils;

type
  EFormUnitNaming = class(Exception);

  // Derives the identifiers a new form unit needs from the requested unit file
  // name and form name. The unit name (which may be dotted/namespaced, e.g.
  // MarkdownPad.Main) is kept separate from the form class and the global form
  // variable so the generated source never redeclares an identifier.
  TFormUnitNaming = record
  strict private
    FUnitName: string;
    FFormClassName: string;
    FFormVariableName: string;
  public
    class function Derive(const UnitFileName: string; const FormName: string): TFormUnitNaming; static;

    property UnitName: string read FUnitName;
    property FormClassName: string read FFormClassName;
    property FormVariableName: string read FFormVariableName;
  end;

implementation

uses
  System.IOUtils;

class function TFormUnitNaming.Derive(const UnitFileName: string; const FormName: string): TFormUnitNaming;
begin
  const UnitName = TPath.GetFileNameWithoutExtension(UnitFileName);
  const TrimmedFormName = FormName.Trim;

  if UnitName.IsEmpty then
    raise EFormUnitNaming.Create('The unit file name is empty');

  // A dotted unit name (MarkdownPad.Main) is valid; a form component name is a
  // plain identifier and may not contain dots.
  if not IsValidIdent(UnitName, True) then
    raise EFormUnitNaming.CreateFmt('"%s" is not a valid unit name', [UnitName]);

  if TrimmedFormName.IsEmpty then
    raise EFormUnitNaming.Create('A form name is required');

  if not IsValidIdent(TrimmedFormName) then
    raise EFormUnitNaming.CreateFmt('"%s" is not a valid form name (an identifier without dots, without the leading T)', [TrimmedFormName]);

  Result.FUnitName := UnitName;
  Result.FFormClassName := 'T' + TrimmedFormName;
  Result.FFormVariableName := TrimmedFormName;

  // Delphi forbids a global variable named after its own unit (E2004); the unit
  // name and the form variable must differ.
  if SameText(Result.FUnitName, Result.FFormVariableName) then
    raise EFormUnitNaming.CreateFmt(
      'The unit name and the form name are both "%s", so the unit clause and the form variable would collide. ' +
      'Give the unit file a different (for example namespaced) name or choose another form name.',
      [Result.FUnitName]);
end;

end.
