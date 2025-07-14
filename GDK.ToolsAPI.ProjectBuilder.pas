unit GDK.ToolsAPI.ProjectBuilder;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.Helper.Interfaces,
  System.SysUtils,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.ComCtrls;

type
  // Interface to access IDE's internal TLine object
  ILineAccess = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    function GetLineText: string;
  end;

  TToolsApiProjectBuilder = class(TInterfacedObject, IToolsApiProjectBuilder)
  private
    FProject: IOTAProject;
    function GetProjectBuilder: IOTAProjectBuilder;
    function GetProjectConfigurations: IOTAProjectOptionsConfigurations;
    function SetActiveConfiguration(const ConfigName: string;
      Configurations: IOTAProjectOptionsConfigurations): Boolean;
    function ExecuteBuild(Builder: IOTAProjectBuilder40; CompileMode: TOTACompileMode): TArray<TBuildMessage>;
    function DoBuild(const ConfigName, Platform: string; const CompileMode: TOTACompileMode): TArray<TBuildMessage>;
    function FindClassForm(const ClassName: string): TForm;
    function FindTreeView(Form: TForm): TTreeView;
    function GetNodeText(Node: TTreeNode): string;
    procedure GetCompilerMessages(Messages: TList<TBuildMessage>);
    function ParseMessageLine(const MessageText: string): TBuildMessage;
    function ParseMessageType(const MessageText: string): TBuildMessageType;
  public
    constructor Create(const Project: IOTAProject);
    function Build: TArray<TBuildMessage>;
    function BuildWithConfig(const ConfigName: string): TArray<TBuildMessage>;
    function BuildWithPlatform(const Platform: string): TArray<TBuildMessage>;
    function BuildWithConfigAndPlatform(const ConfigName, Platform: string): TArray<TBuildMessage>;
  end;

implementation

uses
  System.RegularExpressions,
  System.StrUtils;

{ TToolsApiProjectBuilder }

constructor TToolsApiProjectBuilder.Create(const Project: IOTAProject);
begin
  inherited Create;
  FProject := Project;
end;

function TToolsApiProjectBuilder.GetProjectBuilder: IOTAProjectBuilder;
begin
  if not Supports(FProject, IOTAProjectBuilder, Result) then
    Result := nil;
end;

function TToolsApiProjectBuilder.GetProjectConfigurations: IOTAProjectOptionsConfigurations;
begin
  Result := FProject.ProjectOptions as IOTAProjectOptionsConfigurations;
end;

function TToolsApiProjectBuilder.SetActiveConfiguration(const ConfigName: string;
  Configurations: IOTAProjectOptionsConfigurations): Boolean;
begin
  Result := False;

  for var I := 0 to Configurations.ConfigurationCount - 1 do
  begin
    if SameText(Configurations.Configurations[I].Name, ConfigName) then
    begin
      Configurations.ActiveConfiguration := Configurations.Configurations[I];

      Result := True;
      Break;
    end;
  end;
end;

function TToolsApiProjectBuilder.ExecuteBuild(Builder: IOTAProjectBuilder40;
  CompileMode: TOTACompileMode): TArray<TBuildMessage>;
var
  Messages: TList<TBuildMessage>;
begin
  Messages := TList<TBuildMessage>.Create;
  try
    Builder.BuildProject(CompileMode, True);
    GetCompilerMessages(Messages);
    Result := Messages.ToArray;
  finally
    Messages.Free;
  end;
end;

function TToolsApiProjectBuilder.DoBuild(const ConfigName, Platform: string;
  const CompileMode: TOTACompileMode): TArray<TBuildMessage>;
var
  Builder: IOTAProjectBuilder;
  Configurations: IOTAProjectOptionsConfigurations;
  SavedConfig: string;
begin
  SetLength(Result, 0);

  // Guard
  if not Assigned(FProject) then
    Exit;

  Builder := GetProjectBuilder;
  if not Assigned(Builder) then
    Exit;

  Configurations := GetProjectConfigurations;
  if Assigned(Configurations) and (ConfigName <> '') then
    SavedConfig := Configurations.ActiveConfiguration.Name;

  SetActiveConfiguration(ConfigName, Configurations);
  Result := ExecuteBuild(Builder, CompileMode);

  if Assigned(Configurations) and (ConfigName <> '') then
      SetActiveConfiguration(SavedConfig, Configurations);
end;

function TToolsApiProjectBuilder.Build: TArray<TBuildMessage>;
begin
  Result := DoBuild('', '', cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithConfig(const ConfigName: string): TArray<TBuildMessage>;
begin
  Result := DoBuild(ConfigName, '', cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithPlatform(const Platform: string): TArray<TBuildMessage>;
begin
  Result := DoBuild('', Platform, cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithConfigAndPlatform(const ConfigName,
  Platform: string): TArray<TBuildMessage>;
begin
  Result := DoBuild(ConfigName, Platform, cmOTABuild);
end;

function TToolsApiProjectBuilder.FindClassForm(const ClassName: string): TForm;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Screen.FormCount - 1 do
    if Screen.Forms[I].ClassNameIs(ClassName) then
    begin
      Result := Screen.Forms[I];
      Break;
    end;
end;

function TToolsApiProjectBuilder.FindTreeView(Form: TForm): TTreeView;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Form.ControlCount - 1 do
    if Form.Controls[I].ClassNameIs('TTreeMessageView') then
    begin
      Result := Form.Controls[I] as TTreeView;
      Break;
    end;
end;

function TToolsApiProjectBuilder.GetNodeText(Node: TTreeNode): string;
var
  LineAccess: ILineAccess;
begin
  Result := '';
  
  if Assigned(Node.Data) and Supports(TObject(Node.Data), ILineAccess, LineAccess) then
    Result := LineAccess.GetLineText
  else
    Result := Node.Text;
end;

procedure TToolsApiProjectBuilder.GetCompilerMessages(Messages: TList<TBuildMessage>);
var
  MessageViewForm: TForm;
  TreeView: TTreeView;
  Node: TTreeNode;
  MessageLine: string;
  BuildMessage: TBuildMessage;
begin
  MessageViewForm := FindClassForm('TMsgWindow');
  if MessageViewForm = nil then
    MessageViewForm := FindClassForm('TMessageViewForm');

  if not Assigned(MessageViewForm) then
    Exit;

  TreeView := FindTreeView(MessageViewForm);
  if not Assigned(TreeView) then
    Exit;

  Node := TreeView.Items.GetFirstNode;
  while Assigned(Node) do
  begin
    MessageLine := GetNodeText(Node);
    if MessageLine <> '' then
    begin
      BuildMessage := ParseMessageLine(MessageLine);
      Messages.Add(BuildMessage);
    end;
    Node := Node.GetNext;
  end;
end;

function TToolsApiProjectBuilder.ParseMessageLine(const MessageText: string): TBuildMessage;
var
  Match: TMatch;
begin
  Result.MessageText := MessageText;
  Result.FileName := '';
  Result.LineNumber := 0;
  Result.ColumnNumber := 0;
  Result.MessageType := TBuildMessageType.Info;

  // Parse pattern: [Type] FileName(Line): Message or [Type] FileName(Line,Column): Message  
  Match := TRegEx.Match(MessageText, '\[(Error|Warning|Hint|Fatal)\]\s*([^(]+)\((\d+)(?:,(\d+))?\):\s*(.+)', [roIgnoreCase]);
  
  if Match.Success then
  begin
    Result.MessageType := ParseMessageType(Match.Groups[1].Value);
    Result.FileName := Trim(Match.Groups[2].Value);
    Result.LineNumber := StrToIntDef(Match.Groups[3].Value, 0);
    Result.ColumnNumber := StrToIntDef(Match.Groups[4].Value, 0);
    Result.MessageText := Trim(Match.Groups[5].Value);
  end
  else
  begin
    // Try simpler pattern without brackets
    Match := TRegEx.Match(MessageText, '([^(]+)\((\d+)(?:,(\d+))?\):\s*(.+)');
    if Match.Success then
    begin
      Result.FileName := Trim(Match.Groups[1].Value);
      Result.LineNumber := StrToIntDef(Match.Groups[2].Value, 0);
      Result.ColumnNumber := StrToIntDef(Match.Groups[3].Value, 0);
      Result.MessageText := Trim(Match.Groups[4].Value);
      Result.MessageType := ParseMessageType(Result.MessageText);
    end;
  end;
end;

function TToolsApiProjectBuilder.ParseMessageType(const MessageText: string): TBuildMessageType;
begin
  if ContainsText(MessageText, 'error') or ContainsText(MessageText, 'fatal') then
    Result := TBuildMessageType.Error
  else if ContainsText(MessageText, 'warning') then
    Result := TBuildMessageType.Warning
  else if ContainsText(MessageText, 'hint') then
    Result := TBuildMessageType.Hint
  else
    Result := TBuildMessageType.Info;
end;

end.