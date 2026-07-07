# ToolsAPI-helper
This library contains several helpers and classes to make working with the ToolsAPI much easier.
It's so much fun to extend the IDE with your own tools and options, but it is sometimes very hard to find out how to do it.
With this library we will contribute to the Delphi community and make it more simple to build your own IDE extensions.

## Content
[Logging / Messages](#Logger)

[Project group and projects](#Projects) (incl. build, environment options, module sync)

[Form creation and designer](#form-creation-and-designer)

[Debugger](#debugger)

[Uses manager](#uses-manager)

## Logger
### Simple messages
With the Logger functionality you can add messages to the message tool window.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var Logger := Helper.Logger;

// Log just a message
Logger.Log('This is an example logging');

// Log a message with formatting
Logger.Log('This is a message for project: %s', [Project.Name]);

```
### Custom message tab / group
Or start the Logger with your own group name. This creates a separate tab in the message tool window with that name.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var Logger := Helper.Logger('MyLogTab');
```
### Custom messages
Use the **custom** option to create message with different colors or referencing to a file. In that case double cliking the message will open the file.

```Pascal
var CustomMessage := Logger.Custom;

// Setup
CustomMessage.TextColor := clGreen;
CustomMessage.SetFileReference(FilePath, LineNumber);

// Show message
CustomMessage.Add('[%s] Error on line %d', [FilePath, LineNumber]);
```

## Project group and projects

### Project Group

Get the loaded project group as follows:

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var ProjectGroup := Helper.ProjectGroup;
```

### Project

For a project the **IToolsApiProject** interface is used. This interface groups a list of project related features.
This interface can be received in two ways: for the active project or for the given project

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;
var ActiveProject: IOTAProject := ProjectHelper.Get;

// Get the interface for a given project
var ProjectHelper := Helper.Project(OTAProject);
```

#### Project options
With the **IToolsApiProject** interface you have access to the project options and the build configurations.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;

// Get the project options to figure out the platforms used, the active platform, etc.
var ProjectOptions: IOTAProjectOptionsConfigurations := ProjectHelper.ProjectConfigurations;
```

#### Build configurations
The build configurations are wrapped in **IToolsApiBuildConfigurations** and **IToolsApiBuildConfiguration**. With a specific build configuration interface it's easy to get and change the search paths for a project.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;

// Get the base build configuration
var BaseBuildConfig: IToolsApiBuildConfiguration := ProjectHelper.BuildConfigurations.Base;

// Get the search paths
var SearchPaths: TArray<string> := BaseBuildConfig.SearchPaths;

// Change the paths
SearchPaths := SearchPaths + [NewFilePath];
BaseBuildConfig.SearchPaths := SearchPaths;
```
#### Building a project
The **Build** function builds the project with the IDE compiler, like *Project > Build*. It returns True when the build succeeded.

By default the IDE shows the compile progress dialog. When a build fails, that dialog stays open as a modal dialog until the user dismisses it, and **Build** only returns after that. For unattended builds (for example builds triggered by an IDE plugin) pass `HideProgressDialog := True`: the "Show compiler progress" option is then disabled during the build and restored afterwards, so a failing build returns immediately. The compiler messages still appear in the message tool window.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Build the active project without blocking on the progress dialog
var Succeeded := Helper.Project.Build(True);
```

#### Environment options
The IDE environment options (*Tools > Options*) are wrapped in **IToolsApiEnvironmentOptions**. Option names can differ between IDE versions, so **TryFindOptionName** looks up the exact registered name first.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var EnvironmentOptions := Helper.EnvironmentOptions;

var ExactName: string;
if EnvironmentOptions.TryFindOptionName('ShowCompilerProgress', ExactName) then
begin
  var Value := EnvironmentOptions.GetOption(ExactName);
  EnvironmentOptions.SetOption(ExactName, False);
end;
```

#### Module buffer/disk sync
A file open in the IDE can be newer in memory than on disk (or vice versa when an external tool edits it). **IToolsApiModule** exposes `IsDirty`, `MatchesDisk` and `SyncWithDisk` to reason about this. `SyncWithDisk` reloads the module from disk when the buffer is unmodified, and raises `EToolsApiModuleOutOfSync` when both sides changed (a real conflict).

```Pascal
var Module: IToolsApiModule := THelper.Module;
if not Module.MatchesDisk then
  Module.SyncWithDisk; // reloads if safe, raises on conflict
```

## Form creation and designer

### Creating a form unit
`IToolsApiProject.CreateFormUnit` creates a new form unit through `IOTAModuleServices.CreateModule`, adds it to the project and opens the designer. The unit and `.dfm` source are generated by the library (not left to the IDE default template, which mangles the class name), so the class is exactly `T<FormName>`. `AncestorName` is without the leading `T` (empty means `TForm`).

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
Helper.Project.CreateFormUnit('C:\proj\FMain.pas', 'MainForm', 'TForm');
```

### Editing components on a form
`IToolsApiModule.FormDesigner` returns an **IToolsApiFormEditor** for component-level access to an open form designer, like the palette and Object Inspector:

```Pascal
var Designer := THelper.Module.FormDesigner;

// Inspect
for var Component in Designer.Components do
  ; // Component.Name, .ClassName, ...
var Events := Designer.AssignedEvents(Designer.Root); // ['OnClick=Button1Click', ...]

// Add a control to a named container (forced to the exact parent, e.g. a TabSheet)
var Edit := Designer.AddComponent('TEdit', 'pnlDetail', 8, 8, 200, 23);

// Set published properties by text, including nested paths, sets, events and
// component references:
Designer.SetComponentProperty('Edit1', 'Text', 'hello');
Designer.SetComponentProperty('Edit1', 'Font.Size', '12');
Designer.SetComponentProperty('Button1', 'OnClick', 'Button1Click'); // binds/creates handler
Designer.SetComponentProperty('PageControl1', 'ActivePage', 'TabSheet1'); // component reference
```

`AddComponent` captures the native container before creating and forces the new control's `Parent`, so it lands on exactly the requested tab/page (not the active one). Any installed component class works (VCL, TMS, DevExpress, ...).

### Rendering a form to an image
`IToolsApiFormEditor.CaptureImage` renders the designed form to a PNG (via `TCustomForm.GetFormImage`), returned as `TBytes`.

## Debugger

`IToolsApiHelper.Debugger` returns an **IToolsApiDebugger** around `IOTADebuggerServices`: source breakpoints, process control (continue/step/pause/terminate), expression evaluation (deferred-aware) and the call stack.

```Pascal
var Debugger := THelper.Debugger;

Debugger.AddBreakpoint('C:\proj\FMain.pas', 42);
// ... run the project ...
if Debugger.State = TToolsApiProcessState.Stopped then
begin
  var Value := Debugger.Evaluate('Customer.Name');
  for var Frame in Debugger.CallStack do
    ; // Frame.Header, .FileName, .LineNumber
end;
```

## Uses manager
The **TToolsApiUsesManager** class is located in `GDK.ToolsAPI.UsesManager.pas` and provides the following methods:

- **`WithSource`**: sets the source code of the unit to be parsed

- **`FindUses`**: searches the source code for the interface and implementation sections, as well as the uses clause, and returns the results as a `TUsesResult` record

- **`FindWord`**: searches the source code for a given word and returns the first match as a `TMatch` object

- **`FindPositionToAdd`**: searches the source code for the position where a new unit should be added to the uses clause, and calls a callback function with the position and a Boolean indicating whether the uses clause is currently empty

The **TToolsApiUsesManager** class also defines some private methods for finding the positions of certain keywords in the source code.

The **IToolsApiUsesManager** interface is used to define the public methods of the **TToolsApiUsesManager** class. The interface includes the same methods as the class.






