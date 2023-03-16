unit GDK.ToolsAPI.UsesManager;

interface

uses
  System.RegularExpressions,
  System.SysUtils;

type
  TUsesResult = record
    InterfaceSection: TMatch;
    ImplementationSection: TMatch;
  end;

  TOnPositionFoundProc = reference to procedure(const PositionToAdd: Integer; const IsEmptyUses: Boolean);

  IToolsApiUsesManager = interface
    ['{E5AACAFF-3D39-4F9D-BEAC-4DB6577ADAF8}']

    function WithSource(const Source: string): IToolsApiUsesManager;

    function FindUses: TUsesResult;
    function FindWord(const Word: string): TMatch;

    procedure FindPositionToAdd(const UnitName: string; const InImplementation: Boolean; const OnPositionFound: TOnPositionFoundProc);
  end;

  TToolsApiUsesManager = class(TInterfacedObject, IToolsApiUsesManager)
  const
    REGEX_INTERFACE = '\binterface\b[\h\s\w[.,]';
    REGEX_IMPLEMENTATION = '\bimplementation\b[\h\s\w[.,]';
    REGEX_USES_SECTION = '\buses\b[\h\s\w[.,]*;';
  private
    FSource: string;

    function GetPositionForInterface: Integer;
    function GetPositionForImplementation: Integer;
    function GetEndOfSectionKeyword(const ForImplementation: Boolean): Integer;

    function DoFindWord(const Source: string; const Word: string): TMatch;
    function FindPositionToAdd(const UnitName: string; const UsesMatch: TMatch): Integer; overload;
  public
    function WithSource(const Source: string): IToolsApiUsesManager;

    function FindUses: TUsesResult;
    function FindWord(const Word: string): TMatch;

    procedure FindPositionToAdd(const UnitName: string; const InImplementation: Boolean; const OnPositionFound: TOnPositionFoundProc); overload;

    class function Use: IToolsApiUsesManager;
  end;

  EUnitAlreadyInImplementation = class(Exception)
  private
    FPosition: Integer;
  public
    property Position: Integer read FPosition write FPosition;
  end;

implementation

{ TToolsApiUsesManager }

class function TToolsApiUsesManager.Use: IToolsApiUsesManager;
begin
  Result := TToolsApiUsesManager.Create;
end;

function TToolsApiUsesManager.WithSource(const Source: string): IToolsApiUsesManager;
begin
  FSource := Source;
  Result := Self;
end;

function TToolsApiUsesManager.FindUses: TUsesResult;
begin
  var ImplementationPos := GetPositionForImplementation;
  var Matches := TRegEx.Matches(FSource, REGEX_USES_SECTION, [roIgnoreCase, roMultiLine]);

  for var i := 0 to Matches.Count - 1 do
  begin
    var Match := Matches[i];
    if Match.Success then
    begin
      if (Match.Index < ImplementationPos) then
        Result.InterfaceSection := Match
      else
        Result.ImplementationSection := Match;
    end;
  end;
end;

function TToolsApiUsesManager.FindWord(const Word: string): TMatch;
begin
  Result := DoFindWord(FSource, Word);
end;

function TToolsApiUsesManager.DoFindWord(const Source, Word: string): TMatch;
begin
  var RegExPattern := '\b' + Word.Replace('.', '\.') + '\b';

  Result := TRegEx.Match(Source, RegExPattern, [roIgnoreCase, roMultiLine]);
end;

function TToolsApiUsesManager.GetPositionForInterface: Integer;
begin
  var Match := TRegEx.Match(FSource, REGEX_INTERFACE, [roIgnoreCase, roMultiLine]);
  Result := Match.Index;
end;

function TToolsApiUsesManager.GetPositionForImplementation: Integer;
begin
  var Match := TRegEx.Match(FSource, REGEX_IMPLEMENTATION, [roIgnoreCase, roMultiLine]);
  Result := Match.Index;
end;

function TToolsApiUsesManager.GetEndOfSectionKeyword(const ForImplementation: Boolean): Integer;
begin
  if ForImplementation then
    Result := GetPositionForImplementation + 'implementation'.Length
  else
    Result := GetPositionForInterface + 'interface'.Length;
end;

procedure TToolsApiUsesManager.FindPositionToAdd(const UnitName: string; const InImplementation: Boolean; const OnPositionFound: TOnPositionFoundProc);
begin
  var UsesResult := FindUses;

  var MatchInInterface := DoFindWord(UsesResult.InterfaceSection.Value, UnitName);
  if MatchInInterface.Success then
    Exit;

  var MatchInImplementation := DoFindWord(UsesResult.ImplementationSection.Value, UnitName);
  if MatchInImplementation.Success then
  begin
    if InImplementation then
      Exit;

    var MatchException := EUnitAlreadyInImplementation.CreateFmt('Unit "%s" already in implementation uses', [UnitName]);
    MatchException.Position := MatchInImplementation.Index;

    raise MatchException;
  end;

  var UsesMatch: TMatch;

  if InImplementation then
    UsesMatch := UsesResult.ImplementationSection
  else
    UsesMatch := UsesResult.InterfaceSection;

  var HasUsesSection := UsesMatch.Success;
  var Position: Integer;

  if not HasUsesSection then
  begin
    Position := GetEndOfSectionKeyword(InImplementation);
  end
  else
  begin
    Position := FindPositionToAdd(UnitName, UsesMatch);
  end;

  OnPositionFound(Position, not HasUsesSection);
end;

function TToolsApiUsesManager.FindPositionToAdd(const UnitName: string; const UsesMatch: TMatch): Integer;
begin
  Result := UsesMatch.Index + UsesMatch.Length - 2;
end;

end.
