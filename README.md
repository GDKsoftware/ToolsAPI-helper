# ToolsAPI-helper
This library contains several helpers and classes to make working with the ToolsAPI much easier.
It's so much fun to extend the IDE with your own tools and options, but it is sometimes very hard to find out how to do it.
With this library we will contribute to the Delphi community and make it more simple to build your own IDE extensions.

## Content
[Logger](#Logger)

### Logger
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






