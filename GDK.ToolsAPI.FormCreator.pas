unit GDK.ToolsAPI.FormCreator;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.FormNaming;

type
  // Creates a new form unit through IOTAModuleServices.CreateModule and adds it
  // to the owning project. The unit and .dfm source are generated here from the
  // derived naming (see TFormUnitNaming) rather than from the identifiers the
  // IDE passes in, so a dotted/namespaced unit name is handled correctly and the
  // form class is exactly T<FormName>.
  TToolsApiFormCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FOwner: IOTAProject;
    FUnitFileName: string;
    FAncestorName: string;
    FNaming: TFormUnitNaming;
  public
    constructor Create(const Owner: IOTAProject;
                       const UnitFileName: string;
                       const FormName: string;
                       const AncestorName: string);

    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;

    // IOTAModuleCreator
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent: string; const AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent: string; const FormIdent: string; const AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent: string; const FormIdent: string; const AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

implementation

uses
  System.SysUtils,
  GDK.ToolsAPI.SourceFile;

constructor TToolsApiFormCreator.Create(const Owner: IOTAProject;
                                        const UnitFileName: string;
                                        const FormName: string;
                                        const AncestorName: string);
begin
  inherited Create;
  FOwner := Owner;
  FUnitFileName := UnitFileName;
  FAncestorName := AncestorName;

  // Validating up front (dotted unit names, colliding identifiers) turns a bad
  // request into a clear exception before the IDE creates anything.
  FNaming := TFormUnitNaming.Derive(UnitFileName, FormName);
end;

function TToolsApiFormCreator.GetCreatorType: string;
begin
  Result := sForm;
end;

function TToolsApiFormCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TToolsApiFormCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TToolsApiFormCreator.GetOwner: IOTAModule;
begin
  Result := FOwner;
end;

function TToolsApiFormCreator.GetUnnamed: Boolean;
begin
  Result := FUnitFileName.IsEmpty;
end;

function TToolsApiFormCreator.GetAncestorName: string;
begin
  // The IDE expects the ancestor identifier without the leading "T".
  Result := FAncestorName;
  if Result.StartsWith('T', True) and (Result.Length > 1) then
    Result := Result.Substring(1);
  if Result.IsEmpty then
    Result := 'Form';
end;

function TToolsApiFormCreator.GetImplFileName: string;
begin
  Result := FUnitFileName;
end;

function TToolsApiFormCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TToolsApiFormCreator.GetFormName: string;
begin
  // The form component name is the plain (dot-free) form variable name.
  Result := FNaming.FormVariableName;
end;

function TToolsApiFormCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TToolsApiFormCreator.GetShowForm: Boolean;
begin
  Result := True;
end;

function TToolsApiFormCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TToolsApiFormCreator.NewFormFile(const FormIdent: string; const AncestorIdent: string): IOTAFile;
const
  DfmTemplate =
    'object %0:s: %1:s'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''%0:s'''#13#10 +
    '  ClientHeight = 480'#13#10 +
    '  ClientWidth = 640'#13#10 +
    '  Color = clBtnFace'#13#10 +
    '  Font.Charset = DEFAULT_CHARSET'#13#10 +
    '  Font.Color = clWindowText'#13#10 +
    '  Font.Height = -12'#13#10 +
    '  Font.Name = ''Segoe UI'''#13#10 +
    '  Font.Style = []'#13#10 +
    '  TextHeight = 15'#13#10 +
    'end'#13#10;
begin
  // Generated from the derived naming so the .dfm object matches the unit's
  // form class regardless of the identifiers the IDE passes in.
  Result := TToolsApiSourceFile.Create(Format(DfmTemplate, [FNaming.FormVariableName, FNaming.FormClassName]));
end;

function TToolsApiFormCreator.NewImplSource(const ModuleIdent: string;
                                            const FormIdent: string;
                                            const AncestorIdent: string): IOTAFile;
const
  UnitTemplate =
    'unit %0:s;'#13#10 +
    ''#13#10 +
    'interface'#13#10 +
    ''#13#10 +
    'uses'#13#10 +
    '  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,'#13#10 +
    '  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;'#13#10 +
    ''#13#10 +
    'type'#13#10 +
    '  %1:s = class(T%3:s)'#13#10 +
    '  private'#13#10 +
    '    { Private declarations }'#13#10 +
    '  public'#13#10 +
    '    { Public declarations }'#13#10 +
    '  end;'#13#10 +
    ''#13#10 +
    'var'#13#10 +
    '  %2:s: %1:s;'#13#10 +
    ''#13#10 +
    'implementation'#13#10 +
    ''#13#10 +
    '{$R *.dfm}'#13#10 +
    ''#13#10 +
    'end.'#13#10;
begin
  // The unit name comes from the file (dotted names supported) and the form
  // class/variable from the form name, so they can never collide (E2004).
  Result := TToolsApiSourceFile.Create(
    Format(UnitTemplate, [FNaming.UnitName, FNaming.FormClassName, FNaming.FormVariableName, AncestorIdent]));
end;

function TToolsApiFormCreator.NewIntfSource(const ModuleIdent: string;
                                            const FormIdent: string;
                                            const AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

procedure TToolsApiFormCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

end.
