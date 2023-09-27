unit GDK.ToolsAPI.UsesBuilder;

interface

uses
  GDK.ToolsAPI.UsesManager,
  System.SysUtils;

type
  TUsesToWrite = record
    Text: string;
    Position: Integer;
  end;

  IToolsAPIUsesBuilder = interface
    ['{CA44B1AA-BBC0-4C9B-A73C-FEAEC60138B9}']

    function InInterface: IToolsAPIUsesBuilder;
    function InImplementation: IToolsAPIUsesBuilder;
    function WithSource(const Content: string): IToolsAPIUsesBuilder;

    function Build(const UnitNames: TArray<string>): TUsesToWrite;
  end;

  TToolsAPIUsesBuilder = class(TInterfacedObject, IToolsAPIUsesBuilder)
  private
    FInImplementation: Boolean;
    FContent: string;
  public
    class function Use: IToolsAPIUsesBuilder;

    function InInterface: IToolsAPIUsesBuilder;
    function InImplementation: IToolsAPIUsesBuilder;
    function WithSource(const Content: string): IToolsAPIUsesBuilder;

    function Build(const UnitNames: TArray<string>): TUsesToWrite;
  end;

implementation

{ TToolsAPIUsesBuilder }

class function TToolsAPIUsesBuilder.Use: IToolsAPIUsesBuilder;
begin
  Result := TToolsAPIUsesBuilder.Create;
end;

function TToolsAPIUsesBuilder.InImplementation: IToolsAPIUsesBuilder;
begin
  FInImplementation := True;
  Result := Self;
end;

function TToolsAPIUsesBuilder.InInterface: IToolsAPIUsesBuilder;
begin
  FInImplementation := False;
  Result := Self;
end;

function TToolsAPIUsesBuilder.WithSource(const Content: string): IToolsAPIUsesBuilder;
begin
  FContent := Content;
  Result := Self;
end;

function TToolsAPIUsesBuilder.Build(const UnitNames: TArray<string>): TUsesToWrite;
begin
  var ActualPosition: Integer := -1;
  var ActualIsEmptyUses: Boolean := False;

  var UsesManager := TToolsApiUsesManager
                      .Use
                      .WithSource(FContent);

  var UnitsToWrite: TArray<string> := [];

  for var UnitName in UnitNames do
  begin
    UsesManager.FindPositionToAdd(UnitName, FInImplementation,
      procedure(const Position: Integer; const IsEmptyUses: Boolean)
      begin
        ActualIsEmptyUses := ActualIsEmptyUses or IsEmptyUses;
        ActualPosition := Position;

        var CurLength := Length(UnitsToWrite);
        SetLength(UnitsToWrite, CurLength + 1);
        UnitsToWrite[CurLength] := UnitName;
      end);
  end;

  Result.Position := ActualPosition;

  if ActualIsEmptyUses then
  begin
    Result.Text :=  sLineBreak +
                    sLineBreak + 'uses' +
                    sLineBreak + '  ' + string.Join(',', UnitsToWrite) + ';'
  end
  else
  begin
    Result.Text := ', ' + string.Join(',', UnitsToWrite);
  end;
end;

end.
