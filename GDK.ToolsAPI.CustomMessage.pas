unit GDK.ToolsAPI.CustomMessage;

interface

uses
  ToolsAPI,
  Vcl.Graphics,
  Winapi.Windows;

type
  TCustomMessage = class(TInterfacedObject, IOTACustomMessage, INTACustomDrawMessage)
  private
    FGroup: IOTAMessageGroup;

    FFontName: string;
    FStyle: TFontStyles;

    FTextColor: TColor;
    FBackColor: TColor;

    FFileName: string;
    FLineNumber: Integer;
    FColumnNumber: Integer;
    FLineText: string;

    procedure InitFields;
  public
    constructor Create; overload;
    constructor Create(const Group: IOTAMessageGroup); overload;
    constructor Create(const GroupName: string); overload;

    property FontName: string write FFontName;
    property FontStyle: TFontStyles write FStyle;

    property TextColor: TColor write FTextColor;
    property BackColor: TColor write FBackColor;

    function GetColumnNumber: Integer;
    function GetFileName: string;
    function GetLineNumber: Integer;
    function GetLineText: string;

    procedure ShowHelp; virtual;

    procedure SetFileReference(const FileName: string); overload;
    procedure SetFileReference(const FileName: string; const LineNumber: Integer); overload;
    procedure SetFileReference(const FileName: string; const LineNumber: Integer; const ColumnNumber: Integer); overload;

    function CalcRect(Canvas: TCanvas; MaxWidth: Integer; Wrap: Boolean): TRect;
    procedure Draw(Canvas: TCanvas; Const Rect: TRect; Wrap: Boolean);

    procedure Add(const Msg: string); overload;
    procedure Add(const Msg: string; const TextColor: TColor); overload;
  end;

implementation

uses
  System.SysUtils;

{ TCustomMessage }

constructor TCustomMessage.Create;
begin
  inherited Create;
  InitFields;
end;

constructor TCustomMessage.Create(const Group: IOTAMessageGroup);
begin
  inherited Create;
  InitFields;
  FGroup := Group;
end;

constructor TCustomMessage.Create(const GroupName: string);
begin
  inherited Create;
  InitFields;

  FGroup := (BorlandIDEServices As IOTAMessageServices).GetGroup(GroupName);
  if not Assigned(FGroup) then
    FGroup := (BorlandIDEServices As IOTAMessageServices).AddMessageGroup(GroupName);
end;

procedure TCustomMessage.InitFields;
begin
  FTextColor := clBlack;
  FBackColor := clWindow;
  FStyle := [];
  FGroup := nil;
end;

procedure TCustomMessage.Add(const Msg: string);
begin
  Add(Msg, FTextColor);
end;

procedure TCustomMessage.Add(const Msg: string; const TextColor: TColor);
begin
  FLineText := Msg;
  FTextColor := TextColor;

  (BorlandIDEServices As IOTAMessageServices).AddCustomMessage(Self As IOTACustomMessage, FGroup);
end;

function TCustomMessage.CalcRect(Canvas: TCanvas; MaxWidth: Integer; Wrap: Boolean): TRect;
begin
  if not FFontName.IsEmpty then
  begin
    Canvas.Font.Name := FFontName;
    Canvas.Font.Style := FStyle;
  end;

  Result := Canvas.ClipRect;
  Result.Bottom := Result.Top + Canvas.TextHeight('Wp');
  Result.Right := Result.Left + Canvas.TextWidth(FLineText);
end;

procedure TCustomMessage.Draw(Canvas: TCanvas; const Rect: TRect; Wrap: Boolean);
begin
  Canvas.Font.Color := FTextColor;
  Canvas.Brush.Color := FBackColor;
  Canvas.FillRect(Rect);

  if not FFontName.IsEmpty then
  begin
    Canvas.Font.Name := FFontName;
    Canvas.Font.Style := FStyle;
  end;

  Canvas.TextOut(Rect.Left, Rect.Top, FLineText);
end;

function TCustomMessage.GetColumnNumber: Integer;
begin
  Result := FColumnNumber;
end;

function TCustomMessage.GetFileName: string;
begin
  Result := FFileName;
end;

function TCustomMessage.GetLineNumber: Integer;
begin
  Result := FLineNumber;
end;

function TCustomMessage.GetLineText: string;
begin
  Result := FLineText;
end;

procedure TCustomMessage.SetFileReference(const FileName: string);
begin
  Self.SetFileReference(FileName, 0);
end;

procedure TCustomMessage.SetFileReference(const FileName: string; const LineNumber: Integer);
begin
  Self.SetFileReference(FileName, LineNumber, 0);
end;

procedure TCustomMessage.SetFileReference(const FileName: string; const LineNumber, ColumnNumber: Integer);
begin
  FFileName := FileName;
  FLineNumber := LineNumber;
  FColumnNumber := ColumnNumber;
end;

procedure TCustomMessage.ShowHelp;
begin
  // Not implemented
end;

end.
