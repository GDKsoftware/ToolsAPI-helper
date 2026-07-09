unit GDK.ToolsAPI.Debugger.Interfaces;

interface

uses
  System.SysUtils;

type
  EToolsApiNoDebuggerServices = class(Exception);
  EToolsApiEvaluateFailed = class(Exception);

  {$SCOPEDENUMS ON}
  TToolsApiProcessState = (Nothing, Running, Stopping, Stopped, Fault,
    ResFault, Terminated, Exception, NoProcess);

  TToolsApiStepMode = (StepOver, StepInto, RunUntilReturn);
  {$SCOPEDENUMS OFF}

  TToolsApiBreakpointInfo = record
    FileName: string;
    LineNumber: Integer;
    Enabled: Boolean;
    Expression: string;
    Valid: Boolean;
  end;

  TToolsApiStackFrame = record
    Index: Integer;
    Header: string;
    FileName: string;
    LineNumber: Integer;
  end;

  IToolsApiDebugger = interface
    ['{A6A8EF47-CEC7-43BB-8F88-A0A6A12F4E47}']

    procedure AddBreakpoint(const FileName: string; const LineNumber: Integer);
    function RemoveBreakpoint(const FileName: string; const LineNumber: Integer): Boolean;
    function RemoveAllBreakpoints: Integer;
    function ListBreakpoints: TArray<TToolsApiBreakpointInfo>;

    function State: TToolsApiProcessState;
    function HasProcess: Boolean;
    procedure Continue;
    procedure Step(const Mode: TToolsApiStepMode);
    procedure Pause;
    procedure Terminate;

    function Evaluate(const Expression: string): string;
    function CallStack: TArray<TToolsApiStackFrame>;
    function TryGetCurrentLocation(out FileName: string; out LineNumber: Integer): Boolean;

    // Pumps pending debug events; required while waiting for a deferred evaluate.
    procedure ProcessDebugEvents;
  end;

implementation

end.
