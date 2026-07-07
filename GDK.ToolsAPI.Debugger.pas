unit GDK.ToolsAPI.Debugger;

interface

uses
  ToolsAPI,
  GDK.ToolsAPI.Debugger.Interfaces;

type
  TToolsApiDebugger = class(TInterfacedObject, IToolsApiDebugger)
  private
    const EvaluateBufferSize = 8192;
    const DeferredPollCount = 200;

    type TEvaluateBuffer = array[0..EvaluateBufferSize - 1] of Char;

    function DebuggerServices: IOTADebuggerServices;
    function TryDebuggerServices(out Services: IOTADebuggerServices): Boolean;
    function CurrentProcess: IOTAProcess;
    function CurrentThread: IOTAThread;
    function FindSourceBreakpoint(const FileName: string; const LineNumber: Integer): IOTASourceBreakpoint;
    function MapState(const State: TOTAProcessState): TToolsApiProcessState;
    procedure RunProcess(const Mode: TOTARunMode);
    function EvaluateOnce(const Thread: IOTAThread; const Expression: string; out Value: string): TOTAEvaluateResult;
  public
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

    procedure ProcessDebugEvents;
  end;

implementation

uses
  System.SysUtils;

function TToolsApiDebugger.TryDebuggerServices(out Services: IOTADebuggerServices): Boolean;
begin
  Result := Assigned(BorlandIDEServices) and
    Supports(BorlandIDEServices, IOTADebuggerServices, Services);
end;

function TToolsApiDebugger.DebuggerServices: IOTADebuggerServices;
begin
  if not TryDebuggerServices(Result) then
    raise EToolsApiNoDebuggerServices.Create('Debugger services unavailable');
end;

function TToolsApiDebugger.CurrentProcess: IOTAProcess;
begin
  Result := DebuggerServices.CurrentProcess;
end;

function TToolsApiDebugger.CurrentThread: IOTAThread;
begin
  const Process = CurrentProcess;
  if Assigned(Process) then
    Result := Process.CurrentThread
  else
    Result := nil;
end;

function TToolsApiDebugger.FindSourceBreakpoint(const FileName: string; const LineNumber: Integer): IOTASourceBreakpoint;
begin
  Result := nil;

  const Services = DebuggerServices;
  for var Index := 0 to Services.SourceBkptCount - 1 do
  begin
    const Breakpoint = Services.SourceBkpts[Index];
    const Matches = SameFileName(Breakpoint.FileName, FileName) and (Breakpoint.LineNumber = LineNumber);
    if Matches then
      Exit(Breakpoint);
  end;
end;

procedure TToolsApiDebugger.AddBreakpoint(const FileName: string; const LineNumber: Integer);
begin
  const Existing = FindSourceBreakpoint(FileName, LineNumber);
  if Assigned(Existing) then
    Exit;

  DebuggerServices.NewSourceBreakpoint(FileName, LineNumber, nil);
end;

function TToolsApiDebugger.RemoveBreakpoint(const FileName: string; const LineNumber: Integer): Boolean;
begin
  const Existing = FindSourceBreakpoint(FileName, LineNumber);
  Result := Assigned(Existing);
  if Result then
    DebuggerServices.RemoveBreakpoint(Existing);
end;

function TToolsApiDebugger.RemoveAllBreakpoints: Integer;
begin
  const Services = DebuggerServices;

  // Removing shifts the breakpoint list, so iterate backwards.
  Result := Services.SourceBkptCount;
  for var Index := Services.SourceBkptCount - 1 downto 0 do
  begin
    Services.RemoveBreakpoint(Services.SourceBkpts[Index]);
  end;
end;

function TToolsApiDebugger.ListBreakpoints: TArray<TToolsApiBreakpointInfo>;
begin
  const Services = DebuggerServices;

  SetLength(Result, Services.SourceBkptCount);
  for var Index := 0 to Services.SourceBkptCount - 1 do
  begin
    const Breakpoint = Services.SourceBkpts[Index];
    Result[Index].FileName := Breakpoint.FileName;
    Result[Index].LineNumber := Breakpoint.LineNumber;
    Result[Index].Enabled := Breakpoint.Enabled;
    Result[Index].Expression := Breakpoint.Expression;
    Result[Index].Valid := Breakpoint.ValidInCurrentProcess;
  end;
end;

function TToolsApiDebugger.MapState(const State: TOTAProcessState): TToolsApiProcessState;
begin
  case State of
    psNothing: Result := TToolsApiProcessState.Nothing;
    psRunning: Result := TToolsApiProcessState.Running;
    psStopping: Result := TToolsApiProcessState.Stopping;
    psStopped: Result := TToolsApiProcessState.Stopped;
    psFault: Result := TToolsApiProcessState.Fault;
    psResFault: Result := TToolsApiProcessState.ResFault;
    psTerminated: Result := TToolsApiProcessState.Terminated;
    psException: Result := TToolsApiProcessState.Exception;
  else
    Result := TToolsApiProcessState.NoProcess;
  end;
end;

function TToolsApiDebugger.State: TToolsApiProcessState;
begin
  var Services: IOTADebuggerServices;
  if not TryDebuggerServices(Services) then
    Exit(TToolsApiProcessState.NoProcess);

  const Process = Services.CurrentProcess;
  if not Assigned(Process) then
    Exit(TToolsApiProcessState.NoProcess);

  Result := MapState(Process.ProcessState);
end;

function TToolsApiDebugger.HasProcess: Boolean;
begin
  var Services: IOTADebuggerServices;
  Result := TryDebuggerServices(Services) and Assigned(Services.CurrentProcess);
end;

procedure TToolsApiDebugger.RunProcess(const Mode: TOTARunMode);
begin
  const Process = CurrentProcess;
  if not Assigned(Process) then
    Exit;

  Process.Run(Mode);
end;

procedure TToolsApiDebugger.Continue;
begin
  RunProcess(ormRun);
end;

procedure TToolsApiDebugger.Step(const Mode: TToolsApiStepMode);
begin
  case Mode of
    TToolsApiStepMode.StepInto: RunProcess(ormStmtStepInto);
    TToolsApiStepMode.RunUntilReturn: RunProcess(ormRunUntilReturn);
  else
    RunProcess(ormStmtStepOver);
  end;
end;

procedure TToolsApiDebugger.Pause;
begin
  const Process = CurrentProcess;
  if Assigned(Process) then
    Process.Pause;
end;

procedure TToolsApiDebugger.Terminate;
begin
  const Process = CurrentProcess;
  if Assigned(Process) then
    Process.Terminate;
end;

function TToolsApiDebugger.Evaluate(const Expression: string): string;
begin
  const Thread = CurrentThread;
  if not Assigned(Thread) then
    raise EToolsApiEvaluateFailed.Create('No stopped process to evaluate in');

  var Value := '';
  var EvalResult := EvaluateOnce(Thread, Expression, Value);

  // Deferred means the evaluator has to call a function inside the debuggee;
  // pump debug events until the result arrives or the attempt is abandoned.
  var Polls := 0;
  while (EvalResult = erDeferred) and (Polls < DeferredPollCount) do
  begin
    DebuggerServices.ProcessDebugEvents;
    Inc(Polls);
    EvalResult := EvaluateOnce(Thread, Expression, Value);
  end;

  case EvalResult of
    erOK: Result := Value;
    erBusy: raise EToolsApiEvaluateFailed.Create('Evaluator is busy, try again');
    erDeferred: raise EToolsApiEvaluateFailed.Create('Evaluation did not complete in time');
  else
    // On erError the evaluator message is what came back in the buffer.
    raise EToolsApiEvaluateFailed.Create(Value);
  end;
end;

function TToolsApiDebugger.EvaluateOnce(const Thread: IOTAThread; const Expression: string; out Value: string): TOTAEvaluateResult;
begin
  var Buffer: TEvaluateBuffer;
  FillChar(Buffer, SizeOf(Buffer), 0);

  var CanModify := False;
  var ResultAddr: LongWord := 0;
  var ResultSize: LongWord := 0;
  var ResultVal: LongWord := 0;

  Result := Thread.Evaluate(Expression, @Buffer[0], EvaluateBufferSize,
    CanModify, True, nil, ResultAddr, ResultSize, ResultVal);

  Value := Buffer;
end;

function TToolsApiDebugger.CallStack: TArray<TToolsApiStackFrame>;
begin
  Result := nil;

  const Thread = CurrentThread;
  if not Assigned(Thread) then
    Exit;

  // GetCallCount must precede GetCallHeader/GetCallPos; frames are 1-based.
  const Count = Thread.GetCallCount;
  SetLength(Result, Count);

  for var Index := 1 to Count do
  begin
    var FrameFile := '';
    var FrameLine := 0;
    Thread.GetCallPos(Index, FrameFile, FrameLine);

    Result[Index - 1].Index := Index;
    Result[Index - 1].Header := Thread.GetCallHeader(Index);
    Result[Index - 1].FileName := FrameFile;
    Result[Index - 1].LineNumber := FrameLine;
  end;
end;

function TToolsApiDebugger.TryGetCurrentLocation(out FileName: string; out LineNumber: Integer): Boolean;
begin
  FileName := '';
  LineNumber := 0;

  const Thread = CurrentThread;
  if not Assigned(Thread) then
    Exit(False);

  FileName := Thread.GetCurrentFile;
  LineNumber := Integer(Thread.GetCurrentLine);
  Result := (FileName <> '');
end;

procedure TToolsApiDebugger.ProcessDebugEvents;
begin
  DebuggerServices.ProcessDebugEvents;
end;

end.
