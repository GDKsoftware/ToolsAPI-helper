unit GDK.ToolsAPI.Helper.Interfaces;

interface

uses
  ToolsAPI,
  System.SysUtils,
  GDK.ToolsAPI.CustomMessage;

type
  IToolsApiHelper = interface;
  IToolsApiLogger = interface;
  IToolsApiProject = interface;
  IToolsApiModule = interface;
  IToolsApiEditView = interface;
  IToolsApiSourceEditor = interface;
  IToolsApiEditReader = interface;
  IToolsApiEditWriter = interface;
  IToolsApiBuildConfigurations = interface;
  IToolsApiBuildConfiguration = interface;
  IToolsApiProjectContextMenu = interface;
  IToolsApiProjectContextMenuItem = interface;

  EToolsApiNoProjectFound = class(Exception);
  EToolsApiNoModuleFound = class(Exception);
  EToolsApiNoEditorFound = class(Exception);
  EToolsApiNoEditViewFound = class(Exception);
  EToolsApiNoCustomLogGroupUsed = class(Exception);

  IToolsApiHelper = interface
    ['{3D85AEBD-3FE0-43A0-9C30-F30F0A820C45}']

    function Logger: IToolsApiLogger; overload;
    function Logger(const GroupName: string): IToolsApiLogger; overload;

    function ProjectGroup: IOTAProjectGroup;

    function Project: IToolsApiProject; overload;
    function Project(const Project: IOTAProject): IToolsApiProject; overload;

    function ProjectContextMenu: IToolsApiProjectContextMenu;

    function Module: IToolsApiModule; overload;
    function Module(const Module: IOTAModule): IToolsApiModule; overload;

    function SourceEditor: IToolsApiSourceEditor;
    function EditorReader: IToolsApiEditReader;
    function EditorWriter: IToolsApiEditWriter;

    procedure EditorInsertText(const Text: TArray<string>; const Position: TOTAEditPos); overload;
    procedure EditorInsertText(const Text: TArray<string>; const AtLine: Integer); overload;
    function  EditorPosition: TOTAEditPos;
    function  EditorContent: string;

    function BuildConfigurations: IToolsApiBuildConfigurations;

    function EditView: IToolsApiEditView;
  end;

  IToolsApiLogger = interface
    ['{D8FF6783-45A9-4D15-A239-7D5B3EC19D7C}']

    function UsesCustomGroup: Boolean;
    function GetGroup: IOTAMessageGroup;

    procedure Clear;

    procedure Log(const Text: string); overload;
    procedure Log(const Text: string; const Params: array of const); overload;

    function Custom: TCustomMessage;
  end;

  IToolsApiProject = interface
    ['{F78C515E-354A-4341-8073-E45B091847B2}']

    function Get: IOTAProject;
    function ProjectConfigurations: IOTAProjectOptionsConfigurations;

    function BuildConfigurations: IToolsApiBuildConfigurations;
  end;

  IToolsApiModule = interface
    ['{6370BA7A-2A5C-468F-BA8F-93B090837B90}']

    function Get: IOTAModule;
    function FileCount: Integer;

    function Editor(const Predicate: TFunc<IOTAEditor, Boolean>): IOTAEditor;
    function SourceEditor(const Predicate: TFunc<IOTASourceEditor, Boolean> = nil): IToolsApiSourceEditor;
    function FormEditor(const Predicate: TFunc<IOTAFormEditor, Boolean> = nil): IOTAFormEditor;
  end;

  IToolsApiEditView = interface
    ['{5E080CEF-0D18-453E-8AF4-F7CF9BBCE45C}']

    function TopView: IOTAEditView;
    function CursorPosition: TOTAEditPos;

    procedure InsertText(const Text: TArray<string>; const Position: TOTAEditPos);
  end;

  IToolsApiSourceEditor = interface
    ['{1A2D29C0-A6B2-4B21-B17D-781F89A54A14}']

    function Get: IOTASourceEditor;
    function Reader: IToolsApiEditReader;
    function Writer: IToolsApiEditWriter;
    function UndoableWriter: IToolsApiEditWriter;
  end;

  IToolsApiEditReader = interface
    ['{81675E71-2231-4165-B5CF-EC898D204DEC}']

    function Get: IOTAEditReader;
    function Content: string;
  end;

  IToolsApiEditWriter = interface
    ['{27079628-B140-4E0E-959C-40879C213D52}']

    function Get: IOTAEditWriter;

    procedure InsertText(const Text: string; const Position: Integer); overload;
    procedure InsertText(const Text: string; const Position: TOTAEditPos); overload;
  end;

  IToolsApiBuildConfigurations = interface
    ['{CF2A696D-B493-491F-9E2F-C82D7B69CEFE}']

    function Base: IToolsApiBuildConfiguration;
    function Active: IToolsApiBuildConfiguration;
  end;

  IToolsApiBuildConfiguration = interface
    ['{B1FF2C33-0F59-4FD1-822E-327FA78216D2}']
    function  GetSearchPaths: TArray<string>;
    procedure SetSearchPaths(const Paths: TArray<string>);

    function Get: IOTABuildConfiguration;

    property SearchPaths: TArray<string> read GetSearchPaths write SetSearchPaths;
  end;

  IToolsApiProjectContextMenu = interface
    ['{B8BBB29F-A521-4ED1-9443-8BFA3DEE6E29}']

    procedure Remove(const NotifierIndex: Integer);
  end;

  IToolsApiProjectContextMenuItem = interface(IOTAProjectManagerMenu)
    ['{32307ABE-6BFD-41D7-A47C-DEBC11F9B217}']
    procedure SetOnPostExecute(const Value: TFunc<IOTAProject, Boolean>);
    procedure SetOnExecute(const Value: TProc<IOTAProject>);
    procedure SetOnPreExecute(const Value: TFunc<IOTAProject, Boolean>);

    function NotifierIndex: Integer;

    property OnPreExecute: TFunc<IOTAProject, Boolean> write SetOnPreExecute;
    property OnExecute: TProc<IOTAProject> write SetOnExecute;
    property OnPostExecute: TFunc<IOTAProject, Boolean> write SetOnPostExecute;
  end;

implementation

end.
