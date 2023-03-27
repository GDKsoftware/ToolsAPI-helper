unit GDK.ToolsAPI.Helper;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.Helper.Interfaces,
  System.SysUtils,
  GDK.ToolsAPI.CustomMessage;

type
  TToolsApiHelper = class(TInterfacedObject, IToolsApiHelper)
  private
    FEditView: IToolsApiEditView;
  public
    function Logger: IToolsApiLogger; overload;
    function Logger(const GroupName: string): IToolsApiLogger; overload;

    function ProjectGroup: IOTAProjectGroup;

    function Project: IToolsApiProject; overload;
    function Project(const Project: IOTAProject): IToolsApiProject; overload;

    function ProjectContextMenu: IToolsApiProjectContextMenu;

    function BuildConfigurations: IToolsApiBuildConfigurations;

    function Module: IToolsApiModule; overload;
    function Module(const Module: IOTAModule): IToolsApiModule; overload;

    function SourceEditor: IToolsApiSourceEditor;
    function EditorReader: IToolsApiEditReader;
    function EditorWriter: IToolsApiEditWriter;

    procedure EditorInsertText(const Text: TArray<string>; const Position: TOTAEditPos); overload;
    procedure EditorInsertText(const Text: TArray<string>; const AtLine: Integer); overload;

    function  EditorPosition: TOTAEditPos;
    function  EditorContent: string;

    function EditView: IToolsApiEditView;
  end;

  TToolsApiLogger = class(TInterfacedObject, IToolsApiLogger)
  private
    FGroupName: string;
  public
    constructor Create(const GroupName: string);

    function UsesCustomGroup: Boolean;
    function GetGroup: IOTAMessageGroup;

    procedure Clear;

    procedure Log(const Text: string); overload;
    procedure Log(const Text: string; const Params: array of const); overload;

    function Custom: TCustomMessage;
  end;

  TToolsApiProject = class(TInterfacedObject, IToolsApiProject)
  private
    FProject: IOTAProject;
    procedure Guard;
  public
    constructor Create; overload;
    constructor Create(const Project: IOTAProject); overload;

    function Get: IOTAProject;

    function ProjectConfigurations: IOTAProjectOptionsConfigurations;
    function BuildConfigurations: IToolsApiBuildConfigurations;
  end;

  TToolsApiModule = class(TInterfacedObject, IToolsApiModule)
  private
    FModule: IOTAModule;
    procedure Guard;
  public
    constructor Create; overload;
    constructor Create(const Module: IOTAModule); overload;

    function Get: IOTAModule;
    function FileCount: Integer;

    function Editor(const Predicate: TFunc<IOTAEditor, Boolean>): IOTAEditor;
    function SourceEditor(const Predicate: TFunc<IOTASourceEditor, Boolean> = nil): IToolsApiSourceEditor;
    function FormEditor(const Predicate: TFunc<IOTAFormEditor, Boolean> = nil): IOTAFormEditor;
  end;

  TToolsApiEditView = class(TInterfacedObject, IToolsApiEditView)
  private
    FEditorServices: IOTAEditorServices;
  public
    constructor Create;

    function TopView: IOTAEditView;
    function CursorPosition: TOTAEditPos;

    procedure InsertText(const Text: TArray<string>; const Position: TOTAEditPos);
  end;

  TToolsApiSourceEditor = class(TInterfacedObject, IToolsApiSourceEditor)
  private
    FEditor: IOTASourceEditor;
    procedure AddToUses(const UnitName: string; const AddToImplementation: Boolean);
  public
    constructor Create(const Editor: IOTASourceEditor);

    function Get: IOTASourceEditor;
    function Reader: IToolsApiEditReader;
    function Writer: IToolsApiEditWriter;
    function UndoableWriter: IToolsApiEditWriter;

    procedure AddToInterfaceUses(const UnitName: string);
    procedure AddToImplementationUses(const UnitName: string);
  end;

  TToolsApiEditReader = class(TInterfacedObject, IToolsApiEditReader)
  private
    FReader: IOTAEditReader;
  public
    constructor Create(const Reader: IOTAEditReader);

    function Get: IOTAEditReader;
    function Content: string;
  end;

  TToolsApiEditWriter = class(TInterfacedObject, IToolsApiEditWriter)
  private
    FWriter: IOTAEditWriter;
  public
    constructor Create(const Writer: IOTAEditWriter);
    function Get: IOTAEditWriter;

    procedure InsertText(const Text: string; const Position: Integer); overload;
    procedure InsertText(const Text: string; const Position: TOTAEditPos); overload;
  end;

  TToolsApiBuildConfigurations = class(TInterfacedObject, IToolsApiBuildConfigurations)
  private
    FProject: IOTAProject;
    FConfigurations: IOTAProjectOptionsConfigurations;
  public
    constructor Create(const Project: IOTAProject);

    function Base: IToolsApiBuildConfiguration;
    function Active: IToolsApiBuildConfiguration;
  end;

  TToolsApiBuildConfiguration = class(TInterfacedObject, IToolsApiBuildConfiguration)
  private
    FConfiguration: IOTABuildConfiguration;

    function  GetSearchPaths: TArray<string>;
    procedure SetSearchPaths(const Paths: TArray<string>);
  public
    constructor Create(const Configuration: IOTABuildConfiguration);
    function Get: IOTABuildConfiguration;

    property SearchPaths: TArray<string> read GetSearchPaths write SetSearchPaths;
  end;

implementation

uses
  System.Classes,
  DCCStrs,
  GDK.ToolsAPI.ProjectManagerContextMenu,
  GDK.ToolsAPI.UsesManager;

{ TToolsApiHelper }

function TToolsApiHelper.Project: IToolsApiProject;
begin
  Result := TToolsApiProject.Create;
end;

function TToolsApiHelper.Project(const Project: IOTAProject): IToolsApiProject;
begin
  Result := TToolsApiProject.Create(Project);
end;

function TToolsApiHelper.ProjectContextMenu: IToolsApiProjectContextMenu;
begin
  Result := TToolsApiProjectContextMenu.Create;
end;

function TToolsApiHelper.ProjectGroup: IOTAProjectGroup;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  ProjectGroup: IOTAProjectGroup;
  i: Integer;
Begin
  ProjectGroup := nil;

  ModuleServices := (BorlandIDEServices as IOTAModuleServices);
  for i := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Module := ModuleServices.Modules[i];
    if (Module.QueryInterface(IOTAProjectGroup, ProjectGroup) = S_OK) Then
      Break;
  end;

  Result := ProjectGroup;
end;

function TToolsApiHelper.Module: IToolsApiModule;
begin
  Result := TToolsApiModule.Create;
end;

function TToolsApiHelper.Module(const Module: IOTAModule): IToolsApiModule;
begin
  Result := TToolsApiModule.Create(Module);
end;

function TToolsApiHelper.SourceEditor: IToolsApiSourceEditor;
begin
  Result := Self.Module.SourceEditor;
end;

function TToolsApiHelper.BuildConfigurations: IToolsApiBuildConfigurations;
var
  ActiveProject: IOTAProject;
begin
  ActiveProject := Self.Project.Get;
  Result := TToolsApiBuildConfigurations.Create(ActiveProject);
end;

function TToolsApiHelper.EditorReader: IToolsApiEditReader;
begin
  Result := Self.SourceEditor.Reader;
end;

function TToolsApiHelper.EditorWriter: IToolsApiEditWriter;
begin
  Self.SourceEditor.Writer;
end;

function TToolsApiHelper.EditView: IToolsApiEditView;
begin
  if not Assigned(FEditView) then
    FEditView := TToolsApiEditView.Create;

  Result := FEditView;
end;

function TToolsApiHelper.Logger: IToolsApiLogger;
begin
  Result := Self.Logger('');
end;

function TToolsApiHelper.Logger(const GroupName: string): IToolsApiLogger;
begin
  Result := TToolsApiLogger.Create(GroupName);
end;

procedure TToolsApiHelper.EditorInsertText(const Text: TArray<string>; const Position: TOTAEditPos);
begin
  Self.EditView.InsertText(Text, Position);
end;

procedure TToolsApiHelper.EditorInsertText(const Text: TArray<string>; const AtLine: Integer);
begin
  var Lines := string.Join(sLineBreak, Text);
  Self.EditorWriter.InsertText(Lines, AtLine);
end;

function TToolsApiHelper.EditorPosition: TOTAEditPos;
begin
  Result := Self.EditView.CursorPosition;
end;

function TToolsApiHelper.EditorContent: string;
begin
  Result := EditorReader.Content;
end;

{ TToolsApiProject }

constructor TToolsApiProject.Create;
begin
  inherited Create;
  FProject := GetActiveProject;
  Guard;
end;

constructor TToolsApiProject.Create(const Project: IOTAProject);
begin
  inherited Create;
  FProject := Project;
  Guard;
end;

function TToolsApiProject.Get: IOTAProject;
begin
  Result := FProject;
end;

function TToolsApiProject.ProjectConfigurations: IOTAProjectOptionsConfigurations;
begin
  Result :=  FProject.ProjectOptions as IOTAProjectOptionsConfigurations;
end;

function TToolsApiProject.BuildConfigurations: IToolsApiBuildConfigurations;
begin
  Result := TToolsApiBuildConfigurations.Create(FProject);
end;

procedure TToolsApiProject.Guard;
begin
  if not Assigned(FProject) then
    raise EToolsApiNoProjectFound.Create('No active project found');
end;

{ TToolsApiModule }

constructor TToolsApiModule.Create;
begin
  inherited Create;
  FModule := (BorlandIDEServices as IOTAModuleServices).CurrentModule;
  Guard;
end;

constructor TToolsApiModule.Create(const Module: IOTAModule);
begin
  inherited Create;
  FModule := Module;
  Guard;
end;

function TToolsApiModule.Get: IOTAModule;
begin
  Result := FModule;
end;

function TToolsApiModule.FileCount: Integer;
begin
  Result := FModule.GetModuleFileCount;
end;

function TToolsApiModule.Editor(const Predicate: TFunc<IOTAEditor, Boolean>): IOTAEditor;
var
  i: Integer;
  Editor: IOTAEditor;
begin
  Result := nil;

  for i := 0 to FileCount - 1 do
  begin
    Editor := FModule.GetModuleFileEditor(i);
    if Assigned(Predicate) and not Predicate(Editor) then
      Continue;

    Result := Editor;
    Break;
  end;

  if not Assigned(Result) then
    raise EToolsApiNoEditorFound.Create('No editor found.');
end;

function TToolsApiModule.SourceEditor(const Predicate: TFunc<IOTASourceEditor, Boolean>): IToolsApiSourceEditor;
var
  Found: IOTAEditor;
  SourceEditor: IOTASourceEditor;
begin
  Found := Editor(
                function(Editor: IOTAEditor): Boolean
                begin
                  Result := Supports(Editor, IOTASourceEditor);
                end);

  SourceEditor := Found as IOTASourceEditor;
  Result := TToolsApiSourceEditor.Create(SourceEditor);
end;

function TToolsApiModule.FormEditor(const Predicate: TFunc<IOTAFormEditor, Boolean>): IOTAFormEditor;
var
  Found: IOTAEditor;
begin
  Found := Editor(
                function(Editor: IOTAEditor): Boolean
                begin
                  Result := Supports(Editor, IOTAFormEditor);
                end);

  Result := Found as IOTAFormEditor;
end;

procedure TToolsApiModule.Guard;
begin
  if not Assigned(FModule) then
    raise EToolsApiNoModuleFound.Create('No active module found.');
end;

{ TToolsApiSourceEditor }

constructor TToolsApiSourceEditor.Create(const Editor: IOTASourceEditor);
begin
  inherited Create;
  FEditor := Editor;
end;

function TToolsApiSourceEditor.Get: IOTASourceEditor;
begin
  Result := FEditor;
end;

function TToolsApiSourceEditor.Reader: IToolsApiEditReader;
var
  Reader: IOTAEditReader;
begin
  Reader := FEditor.CreateReader;
  Result := TToolsApiEditReader.Create(Reader);
end;

function TToolsApiSourceEditor.Writer: IToolsApiEditWriter;
begin
  var Writer := FEditor.CreateWriter;
  Result := TToolsApiEditWriter.Create(Writer);
end;

function TToolsApiSourceEditor.UndoableWriter: IToolsApiEditWriter;
begin
  var Writer := FEditor.CreateUndoableWriter;
  Result := TToolsApiEditWriter.Create(Writer);
end;

procedure TToolsApiSourceEditor.AddToInterfaceUses(const UnitName: string);
begin
  AddToUses(UnitName, False);
end;

procedure TToolsApiSourceEditor.AddToImplementationUses(const UnitName: string);
begin
  AddToUses(UnitName, True);
end;

procedure TToolsApiSourceEditor.AddToUses(const UnitName: string; const AddToImplementation: Boolean);
begin
  var EditorContent := Self.Reader.Content;

  TToolsApiUsesManager
    .Use
    .WithSource(EditorContent)
    .FindPositionToAdd(UnitName, AddToImplementation,
      procedure(const Position: Integer; const IsEmptyUses: Boolean)
      begin
        var UsesText := '';
        if IsEmptyUses then
          UsesText := sLineBreak +
                       sLineBreak + 'uses' +
                       sLineBreak + '  ' + UnitName + ';'
        else
          UsesText := ', ' + UnitName;

        Self.Writer.InsertText(UsesText, Position);
      end);
end;

{ TToolsApiEditReader }

constructor TToolsApiEditReader.Create(const Reader: IOTAEditReader);
begin
  inherited Create;
  FReader := Reader;
end;

function TToolsApiEditReader.Get: IOTAEditReader;
begin
  Result := FReader;
end;

function TToolsApiEditReader.Content: string;
const
  BufferSize: Integer = 1024;
var
  Read: Integer;
  Position: Integer;
  Buffer: AnsiString;
begin
  Result := '';

  Position := 0;
  repeat
    SetLength(Buffer, BufferSize);

    Read := FReader.GetText(Position, PAnsiChar(Buffer), BufferSize);
    SetLength(Buffer, Read);

    Result := Result + string(Buffer);
    Inc(Position, Read);

  until (Read < BufferSize);
end;

{ TToolsApiBuildConfiguration }

constructor TToolsApiBuildConfiguration.Create(const Configuration: IOTABuildConfiguration);
begin
  inherited Create;
  FConfiguration := Configuration;
end;

function TToolsApiBuildConfiguration.Get: IOTABuildConfiguration;
begin
  Result := FConfiguration;
end;

function TToolsApiBuildConfiguration.GetSearchPaths: TArray<string>;
var
  Paths: TStringList;
begin
  Paths := TStringList.Create;
  try
    FConfiguration.GetValues(DCCStrs.sUnitSearchPath, Paths, True);

    Result := Paths.ToStringArray;
  finally
    Paths.Free;
  end;
end;

procedure TToolsApiBuildConfiguration.SetSearchPaths(const Paths: TArray<string>);
var
  SearchPaths: TStringList;
begin
  SearchPaths := TStringList.Create;
  try
    SearchPaths.AddStrings(Paths);
    FConfiguration.SetValues(sUnitSearchPath, SearchPaths);
  finally
    SearchPaths.Free;
  end;
end;

{ TToolsApiEditWriter }

constructor TToolsApiEditWriter.Create(const Writer: IOTAEditWriter);
begin
  inherited Create;
  FWriter := Writer;
end;

function TToolsApiEditWriter.Get: IOTAEditWriter;
begin
  Result := FWriter;
end;

procedure TToolsApiEditWriter.InsertText(const Text: string; const Position: Integer);
begin
  FWriter.CopyTo(Position);
  FWriter.Insert(PAnsiChar(AnsiString(Text)));
end;

procedure TToolsApiEditWriter.InsertText(const Text: string; const Position: TOTAEditPos);
var
  EditView: IToolsApiEditView;
begin
  EditView := TToolsApiEditView.Create;
  EditView.InsertText([Text], Position);
end;

{ TToolsApiEditView }

constructor TToolsApiEditView.Create;
begin
  inherited Create;
  FEditorServices := (BorlandIDEServices as IOTAEditorServices);
end;

function TToolsApiEditView.TopView: IOTAEditView;
begin
  Result := FEditorServices.TopView;
  if not Assigned(Result) then
    raise EToolsApiNoEditViewFound.Create('No edit view found.');
end;

function TToolsApiEditView.CursorPosition: TOTAEditPos;
begin
  Result := TopView.CursorPos;
end;

procedure TToolsApiEditView.InsertText(const Text: TArray<string>; const Position: TOTAEditPos);
var
  Line: string;
  EditView: IOTAEditView;
  LineNumber, Col: Integer;
begin
  EditView := TopView;

  LineNumber := Position.Line;
  Col := Position.Col;

  for Line in Text do
  begin
    EditView.Buffer.EditPosition.Move(LineNumber, Col);
    EditView.Buffer.EditPosition.InsertText(Line + sLineBreak);

    Inc(LineNumber);
  end;
end;

{ TToolsApiBuildConfigurations }

constructor TToolsApiBuildConfigurations.Create(const Project: IOTAProject);
begin
  inherited Create;
  FProject := Project;
  FConfigurations := FProject.ProjectOptions as IOTAProjectOptionsConfigurations;
end;

function TToolsApiBuildConfigurations.Active: IToolsApiBuildConfiguration;
var
  Config: IOTABuildConfiguration;
begin
  Config := FConfigurations.ActiveConfiguration;
  Result := TToolsApiBuildConfiguration.Create(Config);
end;

function TToolsApiBuildConfigurations.Base: IToolsApiBuildConfiguration;
var
  Config: IOTABuildConfiguration;
begin
  Config := FConfigurations.BaseConfiguration;
  Result := TToolsApiBuildConfiguration.Create(Config);
end;

{ TToolsApiLogger }

constructor TToolsApiLogger.Create(const GroupName: string);
begin
  inherited Create;
  FGroupName := GroupName;
end;

function TToolsApiLogger.Custom: TCustomMessage;
var
  CustomGroup: IOTAMessageGroup;
begin
  CustomGroup := GetGroup;
  Result := TCustomMessage.Create(CustomGroup);
end;

function TToolsApiLogger.UsesCustomGroup: Boolean;
begin
  Result := (not FGroupName.IsEmpty);
end;

function TToolsApiLogger.GetGroup: IOTAMessageGroup;
begin
  if not Self.UsesCustomGroup then
    raise EToolsApiNoCustomLogGroupUsed.Create('No custom logging group is used');

  Result := (BorlandIDEServices As IOTAMessageServices).AddMessageGroup(FGroupName);
end;

procedure TToolsApiLogger.Clear;
var
  CustomGroup: IOTAMessageGroup;
begin
  if not Self.UsesCustomGroup then
    Exit;

  CustomGroup := (BorlandIDEServices As IOTAMessageServices).GetGroup(FGroupName);
  (BorlandIDEServices As IOTAMessageServices).ClearMessageGroup(CustomGroup);
end;

procedure TToolsApiLogger.Log(const Text: string; const Params: array of const);
var
  FormattedText: string;
begin
  FormattedText := Format(Text, Params);
  Log(FormattedText);
end;

procedure TToolsApiLogger.Log(const Text: string);
var
  LineRef: Pointer;
  CustomGroup: IOTAMessageGroup;
begin
  if Self.UsesCustomGroup then
    CustomGroup := GetGroup
  else
    CustomGroup := nil;

  (BorlandIDEServices As IOTAMessageServices).AddToolMessage('', Text, '', 1, 1, nil, LineRef, CustomGroup);
end;

end.
