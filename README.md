# ToolsAPI-helper
This library contains several helpers and classes to make working with the ToolsAPI much easier.
It's so much fun to extend the IDE with your own tools and options, but it is sometimes very hard to find out how to do it.
With this library we will contribute to the Delphi community and make it more simple to build your own IDE extensions.

## Content
[Logging / Messages](#Logger)

[Project group and projects](#Projects)

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
## Uses manager
The **TToolsApiUsesManager** class is located in `GDK.ToolsAPI.UsesManager.pas` and provides the following methods:

- **`WithSource`**: sets the source code of the unit to be parsed

- **`FindUses`**: searches the source code for the interface and implementation sections, as well as the uses clause, and returns the results as a `TUsesResult` record

- **`FindWord`**: searches the source code for a given word and returns the first match as a `TMatch` object

- **`FindPositionToAdd`**: searches the source code for the position where a new unit should be added to the uses clause, and calls a callback function with the position and a Boolean indicating whether the uses clause is currently empty

The **TToolsApiUsesManager** class also defines some private methods for finding the positions of certain keywords in the source code.

The **IToolsApiUsesManager** interface is used to define the public methods of the **TToolsApiUsesManager** class. The interface includes the same methods as the class.






