unit GDK.ToolsAPI.ProjectBuilder;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.Helper.Interfaces,
  System.SysUtils;

type
  TToolsApiProjectBuilder = class(TInterfacedObject, IToolsApiProjectBuilder)
  private
    FProject: IOTAProject;
    function GetProjectBuilder40: IOTAProjectBuilder40;
    function GetProjectConfigurations: IOTAProjectOptionsConfigurations;
    function SetActiveConfiguration(const ConfigName: string;
      Configurations: IOTAProjectOptionsConfigurations): Boolean;
    procedure LogMessage(const Message: string);
    procedure HandlePlatformRequest(const Platform: string);
    function ExecuteBuild(Builder: IOTAProjectBuilder40; CompileMode: TOTACompileMode): Boolean;
    function DoBuild(const ConfigName, Platform: string; const CompileMode: TOTACompileMode): Boolean;
  public
    constructor Create(const Project: IOTAProject);
    function Build: Boolean;
    function BuildWithConfig(const ConfigName: string): Boolean;
    function BuildWithPlatform(const Platform: string): Boolean;
    function BuildWithConfigAndPlatform(const ConfigName, Platform: string): Boolean;
  end;

implementation

uses
  System.StrUtils;

{ TToolsApiProjectBuilder }

constructor TToolsApiProjectBuilder.Create(const Project: IOTAProject);
begin
  inherited Create;
  FProject := Project;
end;

function TToolsApiProjectBuilder.GetProjectBuilder40: IOTAProjectBuilder40;
begin
  if not Supports(FProject, IOTAProjectBuilder40, Result) then
    Result := nil;
end;

function TToolsApiProjectBuilder.GetProjectConfigurations: IOTAProjectOptionsConfigurations;
begin
  Result := FProject.ProjectOptions as IOTAProjectOptionsConfigurations;
end;

procedure TToolsApiProjectBuilder.LogMessage(const Message: string);
begin
  if Assigned(BorlandIDEServices) then
    (BorlandIDEServices as IOTAMessageServices).AddToolMessage('', Message, '', 0, 0);
end;

function TToolsApiProjectBuilder.SetActiveConfiguration(const ConfigName: string;
  Configurations: IOTAProjectOptionsConfigurations): Boolean;
var
  I: Integer;
begin
  Result := False;
  if ConfigName = '' then
    Exit(True);

  for I := 0 to Configurations.ConfigurationCount - 1 do
  begin
    if SameText(Configurations.Configurations[I].Name, ConfigName) then
    begin
      Configurations.ActiveConfiguration := Configurations.Configurations[I];
      Exit(True);
    end;
  end;
end;

procedure TToolsApiProjectBuilder.HandlePlatformRequest(const Platform: string);
begin
  if Platform <> '' then
    LogMessage('Platform selection via ToolsAPI is limited. Please set platform in IDE.');
end;

function TToolsApiProjectBuilder.ExecuteBuild(Builder: IOTAProjectBuilder40;
  CompileMode: TOTACompileMode): Boolean;
begin
  Result := Builder.BuildProject(CompileMode, True);
end;

function TToolsApiProjectBuilder.DoBuild(const ConfigName, Platform: string;
  const CompileMode: TOTACompileMode): Boolean;
var
  Builder: IOTAProjectBuilder40;
  Configurations: IOTAProjectOptionsConfigurations;
  SavedConfig: string;
begin
  Result := False;

  if not Assigned(FProject) then
    Exit;

  Builder := GetProjectBuilder40;
  if not Assigned(Builder) then
  begin
    LogMessage('Project does not support building. IOTAProjectBuilder40 interface required.');
    Exit;
  end;

  Configurations := GetProjectConfigurations;
  if Assigned(Configurations) and (ConfigName <> '') then
  begin
    SavedConfig := Configurations.ActiveConfiguration.Name;
    try
      SetActiveConfiguration(ConfigName, Configurations);
      HandlePlatformRequest(Platform);
      Result := ExecuteBuild(Builder, CompileMode);
    finally
      SetActiveConfiguration(SavedConfig, Configurations);
    end;
  end
  else
  begin
    HandlePlatformRequest(Platform);
    Result := ExecuteBuild(Builder, CompileMode);
  end;
end;

function TToolsApiProjectBuilder.Build: Boolean;
begin
  Result := DoBuild('', '', cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithConfig(const ConfigName: string): Boolean;
begin
  Result := DoBuild(ConfigName, '', cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithPlatform(const Platform: string): Boolean;
begin
  Result := DoBuild('', Platform, cmOTABuild);
end;

function TToolsApiProjectBuilder.BuildWithConfigAndPlatform(const ConfigName,
  Platform: string): Boolean;
begin
  Result := DoBuild(ConfigName, Platform, cmOTABuild);
end;

end.