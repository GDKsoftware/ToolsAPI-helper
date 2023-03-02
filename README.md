# ToolsAPI-helper
This library contains several helpers and classes to make working with the ToolsAPI much easier.
It's so much fun to extend the IDE with your own tools and options, but it is sometimes very hard to find out how to do it.
With this library we will contribute to the Delphi community and make it more simple to build your own IDE extensions.

## IToolsApiHelper
In the IToolsApiHelper you can find the following methods:

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



