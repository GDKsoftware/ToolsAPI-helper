unit GDK.ToolsAPI.FormEditor;

interface

uses
  System.Classes,
  ToolsAPI,
  GDK.ToolsAPI.Helper.Interfaces;

type
  TToolsApiFormEditor = class(TInterfacedObject, IToolsApiFormEditor)
  private
    FEditor: IOTAFormEditor;

    function NativeComponent(const Component: IOTAComponent): TComponent;
    procedure SetPropertyValue(const Instance: TObject; const PropertyPath: string; const Value: string);
  public
    constructor Create(const Editor: IOTAFormEditor);

    function Get: IOTAFormEditor;

    function Root: TComponent;
    function Find(const ComponentName: string): TComponent;
    function Components: TArray<TComponent>;

    function AddComponent(const TypeName: string;
                          const ContainerName: string;
                          const Left: Integer;
                          const Top: Integer;
                          const Width: Integer;
                          const Height: Integer): TComponent;
    procedure SetComponentProperty(const ComponentName: string;
                                   const PropertyPath: string;
                                   const Value: string);

    procedure ShowDesigner;
    procedure MarkModified;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Vcl.Graphics;

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

  const Created = FEditor.CreateComponent(Container, TypeName, Left, Top, Width, Height);
  if not Assigned(Created) then
    raise EToolsApiComponentNotCreated.CreateFmt(
      'Component of type "%s" could not be created - is the component class installed and registered?', [TypeName]);

  Result := NativeComponent(Created);
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
  else
    raise EToolsApiPropertyNotSupported.CreateFmt('Property "%s" has an unsupported type', [PropertyName]);
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
