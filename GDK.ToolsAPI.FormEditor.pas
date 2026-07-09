unit GDK.ToolsAPI.FormEditor;

interface

uses
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  ToolsAPI,
  GDK.ToolsAPI.Helper.Interfaces;

type
  TToolsApiFormEditor = class(TInterfacedObject, IToolsApiFormEditor)
  private
    FEditor: IOTAFormEditor;

    function NativeComponent(const Component: IOTAComponent): TComponent;
    procedure SetPropertyValue(const Instance: TObject; const PropertyPath: string; const Value: string);
    procedure SetEventHandler(const Instance: TObject; const Info: PPropInfo; const MethodName: string);
    procedure SetComponentReference(const Instance: TObject; const Info: PPropInfo; const ComponentName: string);
  public
    constructor Create(const Editor: IOTAFormEditor);

    function Get: IOTAFormEditor;

    function Root: TComponent;
    function Find(const ComponentName: string): TComponent;
    function Components: TArray<TComponent>;
    function AssignedEvents(const Component: TComponent): TArray<string>;

    function AddComponent(const TypeName: string;
                          const ContainerName: string;
                          const Left: Integer;
                          const Top: Integer;
                          const Width: Integer;
                          const Height: Integer): TComponent;
    procedure SetComponentProperty(const ComponentName: string;
                                   const PropertyPath: string;
                                   const Value: string);

    function CaptureImage: TBytes;

    procedure ShowDesigner;
    procedure MarkModified;
  end;

implementation

uses
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  DesignIntf;

constructor TToolsApiFormEditor.Create(const Editor: IOTAFormEditor);
begin
  inherited Create;
  FEditor := Editor;
end;

function TToolsApiFormEditor.Get: IOTAFormEditor;
begin
  Result := FEditor;
end;

function TToolsApiFormEditor.NativeComponent(const Component: IOTAComponent): TComponent;
var
  Native: INTAComponent;
begin
  Result := nil;

  if Assigned(Component) and Supports(Component, INTAComponent, Native) then
    Result := Native.GetComponent;
end;

function TToolsApiFormEditor.Root: TComponent;
begin
  Result := NativeComponent(FEditor.GetRootComponent);
  if not Assigned(Result) then
    raise EToolsApiComponentNotFound.Create('Form has no root component');
end;

function TToolsApiFormEditor.Find(const ComponentName: string): TComponent;
begin
  const RootComponent = Root;
  if ComponentName.IsEmpty or SameText(ComponentName, RootComponent.Name) then
    Exit(RootComponent);

  Result := NativeComponent(FEditor.FindComponent(ComponentName));
  if not Assigned(Result) then
    raise EToolsApiComponentNotFound.CreateFmt('Component "%s" not found on %s', [ComponentName, RootComponent.Name]);
end;

function TToolsApiFormEditor.Components: TArray<TComponent>;
begin
  const RootComponent = Root;

  SetLength(Result, RootComponent.ComponentCount);
  for var Index := 0 to RootComponent.ComponentCount - 1 do
    Result[Index] := RootComponent.Components[Index];
end;

function TToolsApiFormEditor.AddComponent(const TypeName: string;
                                          const ContainerName: string;
                                          const Left: Integer;
                                          const Top: Integer;
                                          const Width: Integer;
                                          const Height: Integer): TComponent;
begin
  var Container := FEditor.GetRootComponent;
  if not ContainerName.IsEmpty then
  begin
    Container := FEditor.FindComponent(ContainerName);
    if not Assigned(Container) then
      raise EToolsApiComponentNotFound.CreateFmt('Container "%s" not found', [ContainerName]);
  end;

  // Capture the native container BEFORE creating: the ToolsAPI warns that an
  // IOTAComponent handle may become invalid after the form is mutated, so
  // resolving it afterwards can yield a stale/wrong parent (RSP-quirk that
  // lands controls on the active page instead of the requested container).
  const NativeContainer = NativeComponent(Container);
  const RequestedNamedContainer = (not ContainerName.IsEmpty);
  if RequestedNamedContainer and (not (NativeContainer is TWinControl)) then
    raise EToolsApiComponentNotFound.CreateFmt(
      'Container "%s" (%s) cannot host controls; a parent must be a TWinControl (form, panel, tab sheet, group box)',
      [ContainerName, NativeContainer.ClassName]);

  const Created = FEditor.CreateComponent(Container, TypeName, Left, Top, Width, Height);
  if not Assigned(Created) then
    raise EToolsApiComponentNotCreated.CreateFmt(
      'Component of type "%s" could not be created - is the component class installed and registered?', [TypeName]);

  Result := NativeComponent(Created);

  if Result is TControl then
  begin
    const Control = TControl(Result);

    // Force the parent to the exact named container (using the reference we
    // captured before creating), so the control lands on the right tab/page
    // rather than the currently active one.
    if (NativeContainer is TWinControl) and (Control.Parent <> NativeContainer) then
      Control.Parent := TWinControl(NativeContainer);

    // Setting Parent resets the position, so apply the bounds afterwards.
    Control.Left := Left;
    Control.Top := Top;
    if Width > 0 then
      Control.Width := Width;
    if Height > 0 then
      Control.Height := Height;
  end
  else if Assigned(Result) then
    Result.DesignInfo := (Top shl 16) or (Left and $FFFF);

  MarkModified;
end;

procedure TToolsApiFormEditor.SetComponentProperty(const ComponentName: string;
                                                   const PropertyPath: string;
                                                   const Value: string);
begin
  const Target = Find(ComponentName);
  SetPropertyValue(Target, PropertyPath, Value);
  MarkModified;
end;

procedure TToolsApiFormEditor.SetPropertyValue(const Instance: TObject;
                                               const PropertyPath: string;
                                               const Value: string);
begin
  var Current := Instance;
  const Parts = PropertyPath.Split(['.']);

  // Intermediate segments (like Font in Font.Size) must be object properties.
  for var Index := 0 to Length(Parts) - 2 do
  begin
    const Info = GetPropInfo(Current, Parts[Index]);
    const IsObjectProperty = Assigned(Info) and (Info^.PropType^.Kind = tkClass);
    if not IsObjectProperty then
      raise EToolsApiPropertyNotSupported.CreateFmt('"%s" is not an object property of %s',
        [Parts[Index], Current.ClassName]);

    Current := GetObjectProp(Current, Parts[Index]);
    if not Assigned(Current) then
      raise EToolsApiPropertyNotSupported.CreateFmt('Property "%s" of %s is nil',
        [Parts[Index], PropertyPath]);
  end;

  const PropertyName = Parts[High(Parts)];
  const Info = GetPropInfo(Current, PropertyName);
  if not Assigned(Info) then
    raise EToolsApiPropertyNotSupported.CreateFmt('Property "%s" not found on %s',
      [PropertyName, Current.ClassName]);

  case Info^.PropType^.Kind of
    tkInteger:
      if SameText(string(Info^.PropType^.Name), 'TColor') then
        SetOrdProp(Current, Info, StringToColor(Value))
      else
        SetOrdProp(Current, Info, StrToInt(Value));
    tkInt64:
      SetInt64Prop(Current, Info, StrToInt64(Value));
    tkEnumeration:
      SetEnumProp(Current, Info, Value);
    tkFloat:
      SetFloatProp(Current, Info, StrToFloat(Value, TFormatSettings.Invariant));
    tkString, tkLString, tkWString, tkUString:
      SetStrProp(Current, Info, Value);
    tkSet:
      SetSetProp(Current, Info, Value);
    tkMethod:
      SetEventHandler(Current, Info, Value);
    tkClass:
      SetComponentReference(Current, Info, Value);
  else
    raise EToolsApiPropertyNotSupported.CreateFmt('Property "%s" has an unsupported type', [PropertyName]);
  end;
end;

procedure TToolsApiFormEditor.SetComponentReference(const Instance: TObject;
                                                    const Info: PPropInfo;
                                                    const ComponentName: string);
begin
  // Component-reference properties (ActivePage, DataSource, Images, PopupMenu,
  // ...) are set by the referenced component NAME; empty means nil.
  if ComponentName.IsEmpty then
  begin
    SetObjectProp(Instance, Info, nil);
    Exit;
  end;

  const Referenced = NativeComponent(FEditor.FindComponent(ComponentName));
  if not Assigned(Referenced) then
    raise EToolsApiComponentNotFound.CreateFmt('Referenced component "%s" not found on the form', [ComponentName]);

  SetObjectProp(Instance, Info, Referenced);
end;

procedure TToolsApiFormEditor.SetEventHandler(const Instance: TObject;
                                              const Info: PPropInfo;
                                              const MethodName: string);
var
  NativeEditor: INTAFormEditor;
begin
  if MethodName.IsEmpty then
  begin
    var Cleared: TMethod;
    Cleared.Code := nil;
    Cleared.Data := nil;
    SetMethodProp(Instance, Info, Cleared);
    Exit;
  end;

  const HasDesigner = Supports(FEditor, INTAFormEditor, NativeEditor) and
    Assigned(NativeEditor.FormDesigner);
  if not HasDesigner then
    raise EToolsApiPropertyNotSupported.Create('No form designer available to bind the event handler');

  // Mirrors DesignEditors.TMethodProperty.SetValue: rename the current handler
  // when the new name does not exist yet, otherwise bind through CreateMethod
  // (which resolves an existing handler by name or generates a new empty one).
  const FormDesigner = NativeEditor.FormDesigner;
  const CurrentMethod = GetMethodProp(Instance, Info);
  const CurrentName = FormDesigner.GetMethodName(CurrentMethod);

  const CanRename = (CurrentName <> '') and
    (SameText(CurrentName, MethodName) or (not FormDesigner.MethodExists(MethodName))) and
    (not FormDesigner.MethodFromAncestor(CurrentMethod));

  if CanRename then
  begin
    FormDesigner.RenameMethod(CurrentName, MethodName);
    FormDesigner.Modified;
    Exit;
  end;

  const IsNewMethod = (not FormDesigner.MethodExists(MethodName));
  const Handler = FormDesigner.CreateMethod(MethodName, GetTypeData(Info^.PropType^));
  SetMethodProp(Instance, Info, Handler);
  FormDesigner.Modified;

  // CreateMethod only registers the handler; ShowMethod writes the empty method
  // body to the source unit, as the Object Inspector does for a new event handler.
  if IsNewMethod then
    FormDesigner.ShowMethod(MethodName);
end;

function TToolsApiFormEditor.AssignedEvents(const Component: TComponent): TArray<string>;
var
  NativeEditor: INTAFormEditor;
begin
  Result := nil;

  const HasDesigner = Supports(FEditor, INTAFormEditor, NativeEditor) and
    Assigned(NativeEditor.FormDesigner);
  if not HasDesigner then
    Exit;

  const Count = GetPropList(Component.ClassInfo, [tkMethod], nil);
  if Count <= 0 then
    Exit;

  var Props: PPropList;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(Component.ClassInfo, [tkMethod], Props);

    for var Index := 0 to Count - 1 do
    begin
      const Info = Props^[Index];
      const HandlerName = NativeEditor.FormDesigner.GetMethodName(GetMethodProp(Component, Info));
      if HandlerName <> '' then
        Result := Result + [Format('%s=%s', [string(Info^.Name), HandlerName])];
    end;
  finally
    FreeMem(Props);
  end;
end;

function TToolsApiFormEditor.CaptureImage: TBytes;
begin
  const RootComponent = Root;
  if not (RootComponent is TCustomForm) then
    raise EToolsApiComponentNotFound.CreateFmt('%s is not a form and cannot be captured', [RootComponent.ClassName]);

  const Bitmap = TCustomForm(RootComponent).GetFormImage;
  try
    const Png = TPngImage.Create;
    try
      Png.Assign(Bitmap);

      const Stream = TBytesStream.Create;
      try
        Png.SaveToStream(Stream);
        Result := Copy(Stream.Bytes, 0, Stream.Size);
      finally
        Stream.Free;
      end;
    finally
      Png.Free;
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TToolsApiFormEditor.ShowDesigner;
begin
  FEditor.Show;
end;

procedure TToolsApiFormEditor.MarkModified;
begin
  FEditor.MarkModified;
end;

end.
