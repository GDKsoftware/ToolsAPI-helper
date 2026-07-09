unit GDK.ToolsAPI.SourceFile;

interface

uses
  ToolsAPI;

type
  // A file supplied to the IDE for a newly created module (source verbatim).
  TToolsApiSourceFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
  public
    constructor Create(const Source: string);
    function GetSource: string;
    function GetAge: TDateTime;
  end;

implementation

constructor TToolsApiSourceFile.Create(const Source: string);
begin
  inherited Create;
  FSource := Source;
end;

function TToolsApiSourceFile.GetSource: string;
begin
  Result := FSource;
end;

function TToolsApiSourceFile.GetAge: TDateTime;
begin
  Result := -1;
end;

end.
