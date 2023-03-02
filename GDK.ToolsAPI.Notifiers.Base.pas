unit GDK.ToolsAPI.Notifiers.Base;

interface

uses
  ToolsAPI,
  System.SysUtils;

type
  TToolsApiNotifier = class(TNotifierObject, IOTANotifier)
  private
    FOnAfterSave: TProc;
    FOnBeforeSave: TProc;
    FOnDestroyed: TProc;
    FOnModified: TProc;
  public
    /// <summary>
    /// This procedure is called immediately after the item is successfully saved.
    /// This is not called for IOTAWizards
    /// </summary>
    procedure AfterSave;
    /// <summary>
    /// This function is called immediately before the item is saved. This is not
    /// called for IOTAWizard
    /// </summary>
    procedure BeforeSave;
    /// <summary>
    /// The associated item is being destroyed so all references should be dropped.
    /// Exceptions are ignored.
    /// </summary>
    procedure Destroyed;
    /// <summary>
    /// This associated item was modified in some way. This is not called for
    /// IOTAWizards
    /// </summary>
    procedure Modified;

    property OnAfterSave: TProc write FOnAfterSave;
    property OnBeforeSave: TProc write FOnBeforeSave;
    property OnDestroyed: TProc write FOnDestroyed;
    property OnModified: TProc write FOnModified;
  end;

implementation

{ TToolsApiNotifier }

procedure TToolsApiNotifier.AfterSave;
begin
  if Assigned(FOnAfterSave) then FOnAfterSave;
end;

procedure TToolsApiNotifier.BeforeSave;
begin
  if Assigned(FOnBeforeSave) then FOnBeforeSave;
end;

procedure TToolsApiNotifier.Destroyed;
begin
  if Assigned(FOnDestroyed) then FOnDestroyed;
end;

procedure TToolsApiNotifier.Modified;
begin
  if Assigned(FOnModified) then FOnModified;
end;

end.
