unit GDK.ToolsAPI.UiAutomation.Interfaces;

interface

uses
  Winapi.Windows,
  System.SysUtils;

type
  EToolsApiUiAutomation = class(Exception);
  EToolsApiWindowNotFound = class(EToolsApiUiAutomation);
  EToolsApiElementNotFound = class(EToolsApiUiAutomation);
  EToolsApiPatternNotSupported = class(EToolsApiUiAutomation);

  TToolsApiUiElement = record
    Name: string;
    AutomationId: string;
    ControlType: string;
    ClassName: string;
    Value: string;
    HasValue: Boolean;
  end;

  // Drives a running VCL application from the outside through Microsoft UI
  // Automation. Elements are addressed by AutomationId (the VCL control Name in
  // RAD Studio 13+) with a fallback to the Name/caption.
  IToolsApiUiAutomation = interface
    ['{AE8FF869-528F-4DCA-BC49-05982D6B0973}']

    // Top-level window whose title contains WindowTitle; raises when absent.
    function FindWindow(const WindowTitle: string): HWND;

    function ListElements(const Window: HWND): TArray<TToolsApiUiElement>;
    function GetElement(const Window: HWND; const Identifier: string): TToolsApiUiElement;

    procedure Click(const Window: HWND; const Identifier: string);
    procedure SetText(const Window: HWND; const Identifier: string; const Text: string);
    function GetText(const Window: HWND; const Identifier: string): string;
  end;

implementation

end.
