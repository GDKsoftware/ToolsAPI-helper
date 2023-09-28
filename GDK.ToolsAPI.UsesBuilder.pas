unit GDK.ToolsAPI.UsesBuilder;

interface

uses
  GDK.ToolsAPI.UsesManager,
  System.SysUtils;

type
  IUsesToWriteResult = interface
    ['{270998A3-D930-459D-8926-75C6673D28A5}']

    {$REGION 'Getters and setters'}
    function GetText: string;
    procedure SetText(const Value: string);
    function GetPosition: Integer;
    procedure SetPosition(const Value: Integer);
    {$ENDREGION}

    property Text: string read GetText write SetText;
    property Position: Integer read GetPosition write SetPosition;
  end;

  IToolsAPIUsesBuilder = interface
    ['{CA44B1AA-BBC0-4C9B-A73C-FEAEC60138B9}']

    function InInterface: IToolsAPIUsesBuilder;
    function InImplementation: IToolsAPIUsesBuilder;
    function WithSource(const Source: string): IToolsAPIUsesBuilder;

    function Build(const UnitNames: TArray<string>): IUsesToWriteResult;
  end;

  TToolsAPIUsesBuilder = class(TInterfacedObject, IToolsAPIUsesBuilder)
  private
    FUsesManager: IToolsApiUsesManager;

    FInImplementation: Boolean;

    FUnitNamesToWrite: TArray<string>;
    FPosition: Integer;
    FIsEmptyUses: Boolean;

    procedure DoFindPositionToAdd(const UnitName: string);
    procedure HandleOnPositionFound(const Position: Integer; const IsEmptyUses: Boolean);
    procedure AddUnitNameToWrite(const UnitName: string);

    function ComposeUsesToWrite: IUsesToWriteResult;
    procedure ResetFields;
  public
    class function Use: IToolsAPIUsesBuilder;

    constructor Create(const UsesManager: IToolsApiUsesManager);

    function InInterface: IToolsAPIUsesBuilder;
    function InImplementation: IToolsAPIUsesBuilder;
    function WithSource(const Source: string): IToolsAPIUsesBuilder;

    function Build(const UnitNames: TArray<string>): IUsesToWriteResult;
  end;

  TUsesToWriteResult = class(TInterfacedObject, IUsesToWriteResult)
  strict private
    FPosition: Integer;
    FText: string;
  public
    {$REGION 'Getters and setters'}
    function GetText: string;
    procedure SetText(const Value: string);
    function GetPosition: Integer;
    procedure SetPosition(const Value: Integer);
    {$ENDREGION}

    property Text: string read GetText write SetText;
    property Position: Integer read GetPosition write SetPosition;
  end;

implementation

{ TToolsAPIUsesBuilder }

class function TToolsAPIUsesBuilder.Use: IToolsAPIUsesBuilder;
begin
  Result := TToolsAPIUsesBuilder.Create(TToolsApiUsesManager.Use);
end;

constructor TToolsAPIUsesBuilder.Create(const UsesManager: IToolsApiUsesManager);
begin
  inherited Create;

  FUsesManager := UsesManager;
  ResetFields;
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

function TToolsAPIUsesBuilder.WithSource(const Source: string): IToolsAPIUsesBuilder;
begin
  FUsesManager.WithSource(Source);
  Result := Self;
end;

function TToolsAPIUsesBuilder.Build(const UnitNames: TArray<string>): IUsesToWriteResult;
begin
  try
    for var UnitName in UnitNames do
      DoFindPositionToAdd(UnitName);

    Result := ComposeUsesToWrite;
  finally
    ResetFields;
  end;
end;

procedure TToolsAPIUsesBuilder.DoFindPositionToAdd(const UnitName: string);
begin
  FUsesManager.FindPositionToAdd(UnitName, FInImplementation,
    procedure(const Position: Integer; const IsEmptyUses: Boolean)
    begin
      HandleOnPositionFound(Position, IsEmptyUses);
      AddUnitNameToWrite(UnitName);
    end
  );
end;

procedure TToolsAPIUsesBuilder.HandleOnPositionFound(const Position: Integer; const IsEmptyUses: Boolean);
begin
  FIsEmptyUses := FIsEmptyUses or IsEmptyUses;
  FPosition := Position;
end;

procedure TToolsAPIUsesBuilder.AddUnitNameToWrite(const UnitName: string);
begin
  FUnitNamesToWrite := FUnitNamesToWrite + [UnitName];
end;

function TToolsAPIUsesBuilder.ComposeUsesToWrite: IUsesToWriteResult;
begin
  Result := TUsesToWriteResult.Create;
  Result.Position := FPosition;

  if FIsEmptyUses then
  begin
    Result.Text :=  sLineBreak +
                    sLineBreak + 'uses' +
                    sLineBreak + '  ' + string.Join(',', FUnitNamesToWrite) + ';'
  end
  else
  begin
    Result.Text := ', ' + string.Join(',', FUnitNamesToWrite);
  end;
end;

procedure TToolsAPIUsesBuilder.ResetFields;
begin
  FUnitNamesToWrite := [];
  FIsEmptyUses := False;
  FPosition := -1;
end;

{$REGION 'TUsesToWriteResult'}

function TUsesToWriteResult.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TUsesToWriteResult.GetText: string;
begin
  Result := FText;
end;

procedure TUsesToWriteResult.SetPosition(const Value: Integer);
begin
  FPosition := Value;
end;

procedure TUsesToWriteResult.SetText(const Value: string);
begin
  FText := Value;
end;

{$ENDREGION}

end.
