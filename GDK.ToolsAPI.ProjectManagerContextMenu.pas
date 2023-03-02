unit GDK.ToolsAPI.ProjectManagerContextMenu;

interface

uses
  ToolsApi,
  GDK.ToolsAPI.Notifiers.Base,
  System.Classes,
  System.SysUtils,
  GDK.ToolsAPI.Helper.Interfaces;

type
  TToolsApiProjectContextMenu = class;
  TToolsApiProjectContextMenuItem = class;

  TToolsApiProjectContextMenu = class(TInterfacedObject, IToolsApiProjectContextMenu)
  public
    procedure Remove(const NotifierIndex: Integer);
  end;

  TToolsApiProjectContextMenuNotifier = class(TToolsApiNotifier, IOTAProjectMenuItemCreatorNotifier)
  private
    FShowFor: string;
    function ShouldShowMenu(const IdentList: TStrings): Boolean;
  protected
    function DoAddMenu: TToolsApiProjectContextMenuItem; virtual; abstract;
  public
    procedure AfterConstruction; override;

    procedure AddMenu(const Project: IOTAProject;
                      const IdentList: TStrings;
                      const ProjectManagerMenuList: IInterfaceList;
                      IsMultiSelect: Boolean);


    function ShowForProjectGroup: TToolsApiProjectContextMenuNotifier;
    function ShowForProject: TToolsApiProjectContextMenuNotifier;
  end;

  TToolsApiProjectContextMenuItem = class(TToolsApiProjectContextMenuNotifier, IOTALocalMenu, IOTAProjectManagerMenu, IToolsApiProjectContextMenuItem)
  private
    FName: string;
    FEnabled: Boolean;
    FIsMultiSelectable: Boolean;
    FVerb: string;
    FParent: string;
    FCaption: string;
    FHelpContext: Integer;
    FChecked: Boolean;
    FPosition: Integer;
    FOnPreExecute: TFunc<IOTAProject, Boolean>;
    FOnExecute: TProc<IOTAProject>;
    FOnPostExecute: TFunc<IOTAProject, Boolean>;
    FNotifierIndex: Integer;

    function GetCaption: string;
    function GetChecked: Boolean;
    function GetEnabled: Boolean;
    function GetHelpContext: Integer;
    function GetIsMultiSelectable: Boolean;
    function GetName: string;
    function GetParent: string;
    function GetPosition: Integer;
    function GetVerb: string;

    procedure SetCaption(const Value: string);
    procedure SetChecked(Value: Boolean);
    procedure SetEnabled(Value: Boolean);
    procedure SetHelpContext(Value: Integer);
    procedure SetIsMultiSelectable(Value: Boolean);
    procedure SetName(const Value: string);
    procedure SetParent(const Value: string);
    procedure SetPosition(Value: Integer);
    procedure SetVerb(const Value: string);

    procedure SetOnPostExecute(const Value: TFunc<IOTAProject, Boolean>);
    procedure SetOnExecute(const Value: TProc<IOTAProject>);
    procedure SetOnPreExecute(const Value: TFunc<IOTAProject, Boolean>);
  protected
    function MenuContext(const MenuContextList: IInterfaceList): IOTAProjectMenuContext;
    function Project(const MenuContextList: IInterfaceList): IOTAProject;
  public
    procedure AfterConstruction; override;

    function PreExecute(const MenuContextList: IInterfaceList): Boolean;
    procedure Execute(const MenuContextList: IInterfaceList); overload;
    function PostExecute(const MenuContextList: IInterfaceList): Boolean;

    function NotifierIndex: Integer;

    property Caption: string read GetCaption write SetCaption;
    property Checked: Boolean read GetChecked write SetChecked;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property HelpContext: Integer read GetHelpContext write SetHelpContext;
    property Name: string read GetName write SetName;
    property Parent: string read GetParent write SetParent;
    property Position: Integer read GetPosition write SetPosition;
    property Verb: string read GetVerb write SetVerb;
    property IsMultiSelectable: Boolean read GetIsMultiSelectable write SetIsMultiSelectable;

    property OnPreExecute: TFunc<IOTAProject, Boolean> write SetOnPreExecute;
    property OnExecute: TProc<IOTAProject> write SetOnExecute;
    property OnPostExecute: TFunc<IOTAProject, Boolean> write SetOnPostExecute;
  end;

implementation

{ TToolsApiProjectContextMenu }

procedure TToolsApiProjectContextMenu.Remove(const NotifierIndex: Integer);
begin
  (BorlandIDEServices as IOTAProjectManager).RemoveMenuItemCreatorNotifier(NotifierIndex);
end;

{ TToolsApiProjectContextMenuNotifier }

procedure TToolsApiProjectContextMenuNotifier.AddMenu(const Project: IOTAProject; const IdentList: TStrings; const ProjectManagerMenuList: IInterfaceList; IsMultiSelect: Boolean);
var
  MenuItem: TToolsApiProjectContextMenuItem;
begin
  if not ShouldShowMenu(IdentList) then
    Exit;

  MenuItem := DoAddMenu;

  ProjectManagerMenuList.Add(MenuItem);
end;

procedure TToolsApiProjectContextMenuNotifier.AfterConstruction;
begin
  inherited;
  FShowFor := sFileContainer;
end;

function TToolsApiProjectContextMenuNotifier.ShouldShowMenu(const IdentList: TStrings): Boolean;
begin
  Result := (IdentList.IndexOf(FShowFor) <> -1);
end;

function TToolsApiProjectContextMenuNotifier.ShowForProjectGroup: TToolsApiProjectContextMenuNotifier;
begin
  FShowFor := sProjectGroupContainer;
  Result := Self;
end;

function TToolsApiProjectContextMenuNotifier.ShowForProject: TToolsApiProjectContextMenuNotifier;
begin
  FShowFor := sProjectContainer;
  Result := Self;
end;

{ TToolsApiProjectContextMenuItem }

procedure TToolsApiProjectContextMenuItem.AfterConstruction;
begin
  inherited;
  FNotifierIndex := -1;
end;

function TToolsApiProjectContextMenuItem.GetCaption: string;
begin
  Result := FCaption;
end;

function TToolsApiProjectContextMenuItem.GetChecked: Boolean;
begin
  Result := FChecked;
end;

function TToolsApiProjectContextMenuItem.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TToolsApiProjectContextMenuItem.GetHelpContext: Integer;
begin
  Result := FHelpContext;
end;

function TToolsApiProjectContextMenuItem.GetIsMultiSelectable: Boolean;
begin
  Result := FIsMultiSelectable;
end;

function TToolsApiProjectContextMenuItem.GetName: string;
begin
  Result := FName;
end;

function TToolsApiProjectContextMenuItem.GetParent: string;
begin
  Result := FParent;
end;

function TToolsApiProjectContextMenuItem.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TToolsApiProjectContextMenuItem.GetVerb: string;
begin
  Result := FVerb;
end;

function TToolsApiProjectContextMenuItem.MenuContext(const MenuContextList: IInterfaceList): IOTAProjectMenuContext;
begin
  Result := MenuContextList.Items[0] as IOTAProjectMenuContext;
end;

function TToolsApiProjectContextMenuItem.NotifierIndex: Integer;
begin
  if FNotifierIndex = -1 then
    FNotifierIndex := (BorlandIDEServices as IOTAProjectManager).AddMenuItemCreatorNotifier(Self);

  Result := FNotifierIndex;
end;

function TToolsApiProjectContextMenuItem.Project(const MenuContextList: IInterfaceList): IOTAProject;
begin
  Result := Self.MenuContext(MenuContextList).Project;
end;

function TToolsApiProjectContextMenuItem.PreExecute(const MenuContextList: IInterfaceList): Boolean;
var
  Project: IOTAProject;
begin
  Result := True;
  if not Assigned(FOnPreExecute) then
    Exit;

  Project := Self.Project(MenuContextList);
  Result := FOnPreExecute(Project);
end;

procedure TToolsApiProjectContextMenuItem.Execute(const MenuContextList: IInterfaceList);
var
  Project: IOTAProject;
begin
  if not Assigned(FOnExecute) then
    Exit;

  Project := Self.Project(MenuContextList);
  FOnExecute(Project);
end;

function TToolsApiProjectContextMenuItem.PostExecute(const MenuContextList: IInterfaceList): Boolean;
var
  Project: IOTAProject;
begin
  Result := True;
  if not Assigned(FOnPostExecute) then
    Exit;

  Project := Self.Project(MenuContextList);
  Result := FOnPostExecute(Project);
end;

procedure TToolsApiProjectContextMenuItem.SetCaption(const Value: string);
begin
  FCaption := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetChecked(Value: Boolean);
begin
  FChecked := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetEnabled(Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetHelpContext(Value: Integer);
begin
  FHelpContext := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetIsMultiSelectable(Value: Boolean);
begin
  FIsMultiSelectable := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetName(const Value: string);
begin
  FName := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetOnPreExecute(const Value: TFunc<IOTAProject, Boolean>);
begin
  FOnPreExecute := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetOnExecute(const Value: TProc<IOTAProject>);
begin
  FOnExecute := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetOnPostExecute(const Value: TFunc<IOTAProject, Boolean>);
begin
  FOnPostExecute := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetParent(const Value: string);
begin
  FParent := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetPosition(Value: Integer);
begin
  FPosition := Value;
end;

procedure TToolsApiProjectContextMenuItem.SetVerb(const Value: string);
begin
  FVerb := Value;
end;

end.
