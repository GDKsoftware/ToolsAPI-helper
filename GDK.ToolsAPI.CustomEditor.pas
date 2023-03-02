unit GDK.ToolsAPI.CustomEditor;

interface

uses
  ToolsAPI,
  DesignIntf,
  VCL.Forms,
  Vcl.Graphics;

type
  TCustomEditorView = class(TInterfacedObject, INTACustomEditorView)
  strict protected
    function GetCaption: string; virtual; abstract;
    function GetEditorWindowCaption: string; virtual; abstract;
    function GetViewIdentifier: string; virtual; abstract;
    function GetFrameClass: TCustomFrameClass; virtual; abstract;
    procedure FrameCreated(AFrame: TCustomFrame); virtual; abstract;
    function GetImageIndex: Integer; virtual; abstract;
    function GetTabHintText: string; virtual; abstract;

    function GetCanCloneView: Boolean; virtual;
    function CloneEditorView: INTACustomEditorView; virtual;
    function GetEditState: TEditState; virtual;
    function EditAction(Action: TEditAction): Boolean; virtual;
    procedure CloseAllCalled(var ShouldClose: Boolean); virtual;
    procedure Close(var Allowed: Boolean); virtual;
    procedure SelectView; virtual;
    procedure DeselectView; virtual;

    function GetTabColor: TColor; virtual;
  public
    property CanCloneView: Boolean read GetCanCloneView;
    property Caption: string read GetCaption;
    property EditorWindowCaption: string read GetEditorWindowCaption;
    property FrameClass: TCustomFrameClass read GetFrameClass;
    property ViewIdentifier: string read GetViewIdentifier;
  end;

  {$IF CompilerVersion >= 22.0}
  TCustomEditorView150 = class(TCustomEditorView, INTACustomEditorView150);
  {$ENDIF}

  {$IF CompilerVersion >= 35.0}
  TCustomEditorView280 = class(TCustomEditorView150, INTACustomEditorView280);
  {$ENDIF}



implementation

{ TCustomEditorView }

function TCustomEditorView.GetCanCloneView: Boolean;
begin
  Result := False;
end;

function TCustomEditorView.CloneEditorView: INTACustomEditorView;
begin
  Result := nil;
end;

function TCustomEditorView.GetEditState: TEditState;
begin
  Result := [TEditStates.esCanCut, TEditStates.esCanCopy, TEditStates.esCanPaste, TEditStates.esCanDelete];
end;

function TCustomEditorView.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

procedure TCustomEditorView.CloseAllCalled(var ShouldClose: Boolean);
begin
  ShouldClose := True
end;

procedure TCustomEditorView.SelectView;
begin
  // No default implementation
end;

procedure TCustomEditorView.DeselectView;
begin
  // No default implementation
end;

procedure TCustomEditorView.Close(var Allowed: Boolean);
begin
  Allowed := True;
end;

function TCustomEditorView.GetTabColor: TColor;
begin
  Result := clNone;
end;

end.
