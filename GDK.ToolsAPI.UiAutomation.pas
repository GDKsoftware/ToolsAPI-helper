unit GDK.ToolsAPI.UiAutomation;

interface

uses
  Winapi.Windows,
  Winapi.UIAutomation,
  GDK.ToolsAPI.UiAutomation.Interfaces;

type
  TToolsApiUiAutomation = class(TInterfacedObject, IToolsApiUiAutomation)
  private
    FAutomation: IUIAutomation;

    function Automation: IUIAutomation;
    function RootElement(const Window: HWND): IUIAutomationElement;
    function DescribeElement(const Element: IUIAutomationElement): TToolsApiUiElement;
    function FindByIdentifier(const Window: HWND; const Identifier: string): IUIAutomationElement;
    function StringProperty(const Element: IUIAutomationElement; const PropertyId: Integer): string;
    function ControlTypeName(const ControlTypeId: Integer): string;
    function TryValuePattern(const Element: IUIAutomationElement; out Pattern: IUIAutomationValuePattern): Boolean;
    function TryInvokePattern(const Element: IUIAutomationElement; out Pattern: IUIAutomationInvokePattern): Boolean;
  public
    function FindWindow(const WindowTitle: string): HWND;
    function ListElements(const Window: HWND): TArray<TToolsApiUiElement>;
    function GetElement(const Window: HWND; const Identifier: string): TToolsApiUiElement;
    procedure Click(const Window: HWND; const Identifier: string);
    procedure SetText(const Window: HWND; const Identifier: string; const Text: string);
    function GetText(const Window: HWND; const Identifier: string): string;
  end;

implementation

uses
  System.SysUtils,
  System.Variants,
  Winapi.ActiveX;

type
  TWindowSearch = record
    TitlePart: string;
    Found: HWND;
  end;
  PWindowSearch = ^TWindowSearch;

function EnumWindowsProc(Handle: HWND; Param: LPARAM): BOOL; stdcall;
var
  Search: PWindowSearch;
  Buffer: array[0..511] of Char;
  Title: string;
begin
  Result := True;

  if not IsWindowVisible(Handle) then
    Exit;

  const Length = GetWindowText(Handle, Buffer, System.Length(Buffer));
  if Length <= 0 then
    Exit;

  SetString(Title, Buffer, Length);

  Search := PWindowSearch(Param);
  if Title.ToLower.Contains(Search.TitlePart.ToLower) then
  begin
    Search.Found := Handle;
    Result := False;
  end;
end;

function TToolsApiUiAutomation.Automation: IUIAutomation;
begin
  if not Assigned(FAutomation) then
  begin
    const HResult = CoCreateInstance(CLSID_CUIAutomation, nil, CLSCTX_INPROC_SERVER,
      IUIAutomation, FAutomation);
    if Failed(HResult) then
      raise EToolsApiUiAutomation.CreateFmt('Could not create the UI Automation client (0x%x)', [HResult]);
  end;

  Result := FAutomation;
end;

function TToolsApiUiAutomation.FindWindow(const WindowTitle: string): HWND;
var
  Search: TWindowSearch;
begin
  Search.TitlePart := WindowTitle;
  Search.Found := 0;

  EnumWindows(@EnumWindowsProc, LPARAM(@Search));

  if Search.Found = 0 then
    raise EToolsApiWindowNotFound.CreateFmt('No visible window with a title containing "%s"', [WindowTitle]);

  Result := Search.Found;
end;

function TToolsApiUiAutomation.RootElement(const Window: HWND): IUIAutomationElement;
begin
  const HResult = Automation.ElementFromHandle(Window, Result);
  if Failed(HResult) or (not Assigned(Result)) then
    raise EToolsApiWindowNotFound.Create('The window is not accessible through UI Automation');
end;

function TToolsApiUiAutomation.StringProperty(const Element: IUIAutomationElement; const PropertyId: Integer): string;
var
  Value: OleVariant;
begin
  Result := '';
  if Succeeded(Element.GetCurrentPropertyValue(PropertyId, Value)) and (not VarIsNull(Value)) and (not VarIsEmpty(Value)) then
    Result := VarToStr(Value);
end;

function TToolsApiUiAutomation.ControlTypeName(const ControlTypeId: Integer): string;
begin
  // Alleen de gangbare typen; overige worden als het numerieke id getoond.
  case ControlTypeId of
    UIA_ButtonControlTypeId: Result := 'Button';
    UIA_EditControlTypeId: Result := 'Edit';
    UIA_TextControlTypeId: Result := 'Text';
    UIA_CheckBoxControlTypeId: Result := 'CheckBox';
    UIA_ComboBoxControlTypeId: Result := 'ComboBox';
    UIA_ListControlTypeId: Result := 'List';
    UIA_ListItemControlTypeId: Result := 'ListItem';
    UIA_TabControlTypeId: Result := 'Tab';
    UIA_TabItemControlTypeId: Result := 'TabItem';
    UIA_TreeControlTypeId: Result := 'Tree';
    UIA_DataGridControlTypeId: Result := 'DataGrid';
    UIA_TableControlTypeId: Result := 'Table';
    UIA_PaneControlTypeId: Result := 'Pane';
    UIA_WindowControlTypeId: Result := 'Window';
    UIA_GroupControlTypeId: Result := 'Group';
    UIA_MenuItemControlTypeId: Result := 'MenuItem';
    UIA_RadioButtonControlTypeId: Result := 'RadioButton';
  else
    Result := IntToStr(ControlTypeId);
  end;
end;

function TToolsApiUiAutomation.TryValuePattern(const Element: IUIAutomationElement; out Pattern: IUIAutomationValuePattern): Boolean;
var
  Unknown: IInterface;
begin
  Pattern := nil;
  Result := Succeeded(Element.GetCurrentPattern(UIA_ValuePatternId, Unknown)) and
    Assigned(Unknown) and Supports(Unknown, IUIAutomationValuePattern, Pattern);
end;

function TToolsApiUiAutomation.TryInvokePattern(const Element: IUIAutomationElement; out Pattern: IUIAutomationInvokePattern): Boolean;
var
  Unknown: IInterface;
begin
  Pattern := nil;
  Result := Succeeded(Element.GetCurrentPattern(UIA_InvokePatternId, Unknown)) and
    Assigned(Unknown) and Supports(Unknown, IUIAutomationInvokePattern, Pattern);
end;

function TToolsApiUiAutomation.DescribeElement(const Element: IUIAutomationElement): TToolsApiUiElement;
var
  ControlType: OleVariant;
  ValuePattern: IUIAutomationValuePattern;
  CurrentValue: PChar;
begin
  Result := Default(TToolsApiUiElement);
  Result.Name := StringProperty(Element, UIA_NamePropertyId);
  Result.AutomationId := StringProperty(Element, UIA_AutomationIdPropertyId);
  Result.ClassName := StringProperty(Element, UIA_ClassNamePropertyId);

  if Succeeded(Element.GetCurrentPropertyValue(UIA_ControlTypePropertyId, ControlType)) and (not VarIsNull(ControlType)) then
    Result.ControlType := ControlTypeName(ControlType);

  if TryValuePattern(Element, ValuePattern) and Succeeded(ValuePattern.get_CurrentValue(CurrentValue)) then
  begin
    Result.Value := CurrentValue;
    Result.HasValue := True;
  end;
end;

function TToolsApiUiAutomation.ListElements(const Window: HWND): TArray<TToolsApiUiElement>;
var
  Condition: IUIAutomationCondition;
  Elements: IUIAutomationElementArray;
  Element: IUIAutomationElement;
  Count: Integer;
begin
  Result := nil;

  const Root = RootElement(Window);

  if Failed(Automation.CreateTrueCondition(Condition)) then
    Exit;

  if Failed(Root.FindAll(TreeScope_Descendants, Condition, Elements)) or (not Assigned(Elements)) then
    Exit;

  if Failed(Elements.get_Length(Count)) then
    Exit;

  for var Index := 0 to Count - 1 do
  begin
    if Failed(Elements.GetElement(Index, Element)) or (not Assigned(Element)) then
      Continue;

    const Described = DescribeElement(Element);

    // Elementen zonder naam en zonder automation-id zijn voor besturing
    // onbruikbaar; laat ze weg om de lijst leesbaar te houden.
    const IsAddressable = (Described.AutomationId <> '') or (Described.Name <> '');
    if IsAddressable then
      Result := Result + [Described];
  end;
end;

function TToolsApiUiAutomation.FindByIdentifier(const Window: HWND; const Identifier: string): IUIAutomationElement;
var
  Condition: IUIAutomationCondition;
begin
  const Root = RootElement(Window);

  // Eerst op AutomationId (de VCL-control-Name), dan op Name/caption.
  if Succeeded(Automation.CreatePropertyCondition(UIA_AutomationIdPropertyId, Identifier, Condition)) and
     Succeeded(Root.FindFirst(TreeScope_Descendants, Condition, Result)) and Assigned(Result) then
    Exit;

  if Succeeded(Automation.CreatePropertyCondition(UIA_NamePropertyId, Identifier, Condition)) and
     Succeeded(Root.FindFirst(TreeScope_Descendants, Condition, Result)) and Assigned(Result) then
    Exit;

  raise EToolsApiElementNotFound.CreateFmt('No control with AutomationId or Name "%s" in the window', [Identifier]);
end;

function TToolsApiUiAutomation.GetElement(const Window: HWND; const Identifier: string): TToolsApiUiElement;
begin
  Result := DescribeElement(FindByIdentifier(Window, Identifier));
end;

procedure TToolsApiUiAutomation.Click(const Window: HWND; const Identifier: string);
var
  InvokePattern: IUIAutomationInvokePattern;
begin
  const Element = FindByIdentifier(Window, Identifier);

  if not TryInvokePattern(Element, InvokePattern) then
    raise EToolsApiPatternNotSupported.CreateFmt('"%s" cannot be invoked (no Invoke pattern)', [Identifier]);

  Element.SetFocus;
  if Failed(InvokePattern.Invoke) then
    raise EToolsApiUiAutomation.CreateFmt('Invoke on "%s" failed', [Identifier]);
end;

procedure TToolsApiUiAutomation.SetText(const Window: HWND; const Identifier: string; const Text: string);
var
  ValuePattern: IUIAutomationValuePattern;
begin
  const Element = FindByIdentifier(Window, Identifier);

  if not TryValuePattern(Element, ValuePattern) then
    raise EToolsApiPatternNotSupported.CreateFmt('"%s" does not support text input (no Value pattern)', [Identifier]);

  Element.SetFocus;
  if Failed(ValuePattern.SetValue(PChar(Text))) then
    raise EToolsApiUiAutomation.CreateFmt('Setting the value of "%s" failed', [Identifier]);
end;

function TToolsApiUiAutomation.GetText(const Window: HWND; const Identifier: string): string;
var
  ValuePattern: IUIAutomationValuePattern;
  CurrentValue: PChar;
begin
  const Element = FindByIdentifier(Window, Identifier);

  if TryValuePattern(Element, ValuePattern) and Succeeded(ValuePattern.get_CurrentValue(CurrentValue)) then
    Exit(CurrentValue);

  // Geen Value-pattern: val terug op de Name/caption (bv. voor labels/knoppen).
  Result := StringProperty(Element, UIA_NamePropertyId);
end;

end.
