# ToolsAPI-helper
This library contains several helpers and classes to make working with the ToolsAPI much easier.
It's so much fun to extend the IDE with your own tools and options, but it is sometimes very hard to find out how to do it.
With this library we will contribute to the Delphi community and make it more simple to build your own IDE extensions.

## Content
[Logging / Messages](#Logger)

[Project group and projects](#Projects)

## Logger
With the Logger functionality you can add messages to the message tool window.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var Logger := Helper.Logger;

// Log just a message
Logger.Log('This is an example logging');

// Log a message with formatting
Logger.Log('This is a message for project: %s', [Project.Name]);

```

Or start the Logger with your own group name. This creates a separate tab in the message tool window with that name.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;
var Logger := Helper.Logger('MyLogTab');
```

Use the <mark>custom</mark> option to create message with different colors or referencing to a file. In that case double cliking the message will open the file.

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

For a project the <mark>IToolsApiProject</mark> interface is used. This interface groups a list of project related features.
This interface can be received in two ways: for the active project or for the given project

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;
var ActiveProject: IOTAProject := ProjectHelper.Get;

// Get the interface for a given project
var ProjectHelper := Helper.Project(OTAProject);
```

With the <mark>IToolsApiProject</mark> interface you have access to the project options and the build configurations.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;

// Get the project options to figure out the platforms used, the active platform, etc.
var ProjectOptions: IOTAProjectOptionsConfigurations := Helper.ProjectConfigurations;
```

The build configurations are wrapped in <mark>IToolsApiBuildConfigurations</mark> and <mark>IToolsApiBuildConfiguration</mark>. With a specific build configuration interface it's easy to get and change the search paths for a project.

```Pascal
var Helper: IToolsApiHelper := TToolsApiHelper.Create;

// Get the active project
var ProjectHelper := Helper.Project;

// Get the base build configuration
var BaseBuildConfig: IToolsApiBuildConfiguration := Helper.BuildConfigurations.Base;

// Get the search paths
var SearchPaths: TArray<string> := BaseBuildConfig.SearchPaths;

// Change the paths
SearchPaths := SearchPaths + [NewFilePath];
BaseBuildConfig.SearchPaths := SearchPaths;
```







