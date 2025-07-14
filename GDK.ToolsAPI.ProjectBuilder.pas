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
    function GetProjectBuilder: IOTAProjectBuilder;
    function GetProjectConfigurations: IOTAProjectOptionsConfigurations;
    function SetActiveConfiguration(const ConfigName: string;
      Configurations: IOTAProjectOptionsConfigurations): Boolean;
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
  CompileMode: TOTACompileMode): Boolean;
begin
  Result := Builder.BuildProject(CompileMode, True);
end;

function TToolsApiProjectBuilder.DoBuild(const ConfigName, Platform: string;
  const CompileMode: TOTACompileMode): Boolean;
var
  Builder: IOTAProjectBuilder;
  Configurations: IOTAProjectOptionsConfigurations;
  SavedConfig: string;
begin
  Result := False;

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