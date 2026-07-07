unit GDK.ToolsAPI.FormCreator;

interface

uses
  ToolsAPI;

type
  // Creates a new form unit through IOTAModuleServices.CreateModule: the IDE
  // generates the default unit source and .dfm, adds the unit to the owning
  // project and opens the designer.
  TToolsApiFormCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FOwner: IOTAProject;
    FUnitFileName: string;
    FFormName: string;
    FAncestorName: string;
  private
    procedure DiagLog(const Text: string);
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
  System.IOUtils;

procedure TToolsApiFormCreator.DiagLog(const Text: string);
begin
  // Tijdelijke diagnose voor de createForm-naamverminking; verwijderen na fix.
  try
    TFile.AppendAllText(TPath.Combine(TPath.GetTempPath, 'claude4d-formcreator.log'),
      Text + sLineBreak, TEncoding.UTF8);
  except
  end;
end;

constructor TToolsApiFormCreator.Create(const Owner: IOTAProject;
                                        const UnitFileName: string;
                                        const FormName: string;
                                        const AncestorName: string);
begin
  inherited Create;
  FOwner := Owner;
  FUnitFileName := UnitFileName;
  FFormName := FormName;
  FAncestorName := AncestorName;

  DiagLog(Format('--- createForm: UnitFileName="%s" FormName="%s" AncestorName="%s"',
    [UnitFileName, FormName, AncestorName]));
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
  DiagLog(Format('GetAncestorName -> "%s"', [Result]));
end;

function TToolsApiFormCreator.GetImplFileName: string;
begin
  Result := FUnitFileName;
  DiagLog(Format('GetImplFileName -> "%s"', [Result]));
end;

function TToolsApiFormCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TToolsApiFormCreator.GetFormName: string;
begin
  Result := FFormName;
  DiagLog(Format('GetFormName -> "%s"', [Result]));
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
begin
  DiagLog(Format('NewFormFile: FormIdent="%s" AncestorIdent="%s"', [FormIdent, AncestorIdent]));

  // nil: the IDE generates the default .dfm for the ancestor.
  Result := nil;
end;

function TToolsApiFormCreator.NewImplSource(const ModuleIdent: string;
                                            const FormIdent: string;
                                            const AncestorIdent: string): IOTAFile;
begin
  DiagLog(Format('NewImplSource: ModuleIdent="%s" FormIdent="%s" AncestorIdent="%s"',
    [ModuleIdent, FormIdent, AncestorIdent]));

  // nil: the IDE generates the default form unit source.
  Result := nil;
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
