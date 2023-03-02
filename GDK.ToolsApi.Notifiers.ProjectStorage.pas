unit GDK.ToolsApi.Notifiers.ProjectStorage;

interface

uses
  ToolsApi,
  GDK.ToolsAPI.Notifiers.Base,
  System.SysUtils,
  Xml.XMLIntf;

type
  TToolsApiProjectStorageNotifier = class(TToolsApiNotifier, IOTAProjectFileStorageNotifier)
  private
    FNodeName: string;
    FOnCreatingProject: TProc<IOTAModule>;
    FOnProjectClosing: TProc<IOTAModule>;
    FOnProjectLoaded: TProc<IOTAModule, IXMLNode>;
    FOnProjectSaving: TProc<IOTAModule, IXMLNode>;
  public
    constructor Create(const NodeName: string);
    /// <summary>
    /// This function will return the name of your node in the project file.
    /// </summary>
    function GetName: string;
    /// <summary>
    /// Called when a project is loaded and there is a node that matches the
    /// result of GetName.  You may keep a reference to Node and edit the contents
    /// but you must free the reference when ProjectClosing is called.
    /// </summary>
    procedure ProjectLoaded(const ProjectOrGroup: IOTAModule; const Node: IXMLNode);
    procedure CreatingProject(const ProjectOrGroup: IOTAModule);
    procedure ProjectSaving(const ProjectOrGroup: IOTAModule; const Node: IXMLNode);
    procedure ProjectClosing(const ProjectOrGroup: IOTAModule);

    property Name: string read GetName;
    property OnCreatingProject: TProc<IOTAModule> write FOnCreatingProject;
    property OnProjectClosing: TProc<IOTAModule> write FOnProjectClosing;
    property OnProjectLoaded: TProc<IOTAModule, IXMLNode> write FOnProjectLoaded;
    property OnProjectSaving: TProc<IOTAModule, IXMLNode> write FOnProjectSaving;
  end;

implementation

{ TToolsApiProjectStorageNotifier }

constructor TToolsApiProjectStorageNotifier.Create(const NodeName: string);
begin
  inherited Create;
  FNodeName := NodeName;
end;

function TToolsApiProjectStorageNotifier.GetName: string;
begin
  Result := FNodeName;
end;

procedure TToolsApiProjectStorageNotifier.CreatingProject(const ProjectOrGroup: IOTAModule);
begin
  if Assigned(FOnCreatingProject) then
    FOnCreatingProject(ProjectOrGroup);
end;

procedure TToolsApiProjectStorageNotifier.ProjectClosing(const ProjectOrGroup: IOTAModule);
begin
  if Assigned(FOnProjectClosing) then
    FOnProjectClosing(ProjectOrGroup);
end;

procedure TToolsApiProjectStorageNotifier.ProjectLoaded(const ProjectOrGroup: IOTAModule; const Node: IXMLNode);
begin
  if Assigned(FOnProjectLoaded) then
    FOnProjectLoaded(ProjectOrGroup, Node);
end;

procedure TToolsApiProjectStorageNotifier.ProjectSaving(const ProjectOrGroup: IOTAModule; const Node: IXMLNode);
begin
  if Assigned(FOnProjectSaving) then
    FOnProjectSaving(ProjectOrGroup, Node);
end;

end.
