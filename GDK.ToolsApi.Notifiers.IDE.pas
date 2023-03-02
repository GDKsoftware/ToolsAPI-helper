unit GDK.ToolsApi.Notifiers.IDE;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.Notifiers.Base,
  System.SysUtils;

type
  TOnAfterCompileProc = reference to procedure(const Succeeded: Boolean; const IsCodeInsight: Boolean; const Project: IOTAProject);
  TOnBeforeCompileProc = reference to procedure(const Project: IOTAProject; var Cancel: Boolean; const IsCodeInsight: Boolean);
  TOnFileNotificationProc = reference to procedure(const NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);

  TToolsApiIDENotifier = class(TToolsApiNotifier, IOTAIDENotifier, IOTAIDENotifier50, IOTAIDENotifier80)
  private
    FOnAfterCompile: TOnAfterCompileProc;
    FOnBeforeCompile: TOnBeforeCompileProc;
    FOnFileNotification: TOnFileNotificationProc;
  public
    { IOTAIDENotifier }

    /// <summary>
    /// This procedure is called for many various file operations within the
    /// IDE
    /// </summary>
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);

    /// <summary>
    /// This function is called immediately before the compiler is invoked.
    /// Set Cancel to True to cancel the compile
    /// </summary>
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); overload;

    /// <summary>
    /// This procedure is called immediately following a compile.  Succeeded
    /// will be true if the compile was successful
    /// </summary>
    procedure AfterCompile(Succeeded: Boolean); overload;

  { IOTAIDENotifier50 }

    /// <summary>
    /// Same as BeforeCompile on IOTAIDENotifier except indicates if the compiler
    /// was invoked due to a CodeInsight compile
    /// </summary>
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var Cancel: Boolean); overload;

    /// <summary>
    /// Same as AfterCompile on IOTAIDENotifier except indicates if the compiler
    /// was invoked due to a CodeInsight compile
    /// </summary>
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;

    { IOTAIDENotifier80 }

    /// <summary>
    /// Same as AfterCompile on IOTAIDENotifier except adds a project, like it
    /// should have done all along.
    /// </summary>
    procedure AfterCompile(const Project: IOTAProject; Succeeded: Boolean; IsCodeInsight: Boolean); overload;

    class function UseSingleton: TToolsApiIDENotifier; 

    property OnAfterCompile: TOnAfterCompileProc write FOnAfterCompile;
    property OnBeforeCompile: TOnBeforeCompileProc write FOnBeforeCompile;
    property OnFileNotification: TOnFileNotificationProc read FOnFileNotification write FOnFileNotification;
  end;

implementation

var
  _IDENotifier: TToolsApiIDENotifier = nil;
  _IDENotifierIndex: Integer = -1;

{ TToolsApiIDENotifier }

procedure TToolsApiIDENotifier.AfterCompile(Succeeded: Boolean);
begin
  if Assigned(FOnAfterCompile) then FOnAfterCompile(Succeeded, False, nil);
end;

procedure TToolsApiIDENotifier.AfterCompile(Succeeded, IsCodeInsight: Boolean);
begin
  if Assigned(FOnAfterCompile) then FOnAfterCompile(Succeeded, IsCodeInsight, nil);
end;

procedure TToolsApiIDENotifier.AfterCompile(const Project: IOTAProject; Succeeded, IsCodeInsight: Boolean);
begin
  if Assigned(FOnAfterCompile) then FOnAfterCompile(Succeeded, IsCodeInsight, Project);
end;

procedure TToolsApiIDENotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
  if Assigned(FOnBeforeCompile) then FOnBeforeCompile(Project, Cancel, False);
end;

procedure TToolsApiIDENotifier.BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean; var Cancel: Boolean);
begin
  if Assigned(FOnBeforeCompile) then FOnBeforeCompile(Project, Cancel, IsCodeInsight);
end;

procedure TToolsApiIDENotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
begin
  if Assigned(FOnFileNotification) then FOnFileNotification(NotifyCode, FileName, Cancel);
end;

class function TToolsApiIDENotifier.UseSingleton: TToolsApiIDENotifier;
begin
  if not Assigned(_IDENotifier) then  
  begin
    _IDENotifier := TToolsApiIDENotifier.Create;

    _IDENotifierIndex := (BorlandIDEServices As IOTAServices).AddNotifier(_IDENotifier);  
  end;

  Result := _IDENotifier;
end;

initialization

finalization
  if (_IDENotifierIndex <> -1) then
    (BorlandIDEServices as IOTAServices).RemoveNotifier(_IDENotifierIndex);  

end.
