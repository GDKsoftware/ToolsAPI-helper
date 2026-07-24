unit GDK.ToolsAPI.ProjectMatch.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TProjectMatchTests = class
  private
    function PadProjects: TArray<string>;
  public
    [Test]
    procedure ExactBaseName_ReturnsIndex;

    [Test]
    procedure ExactFullPath_ReturnsIndex;

    [Test]
    procedure UniqueSubstring_ReturnsIndex;

    [Test]
    procedure CaseInsensitiveQuery_Matches;

    [Test]
    procedure AmbiguousSubstring_ReturnsNoMatch;

    [Test]
    procedure UnknownQuery_ReturnsNoMatch;

    [Test]
    procedure EmptyQuery_ReturnsNoMatch;

    [Test]
    procedure ExactBaseName_BeatsAmbiguousSubstring;
  end;

implementation

uses
  GDK.ToolsAPI.ProjectMatch;

const
  NoMatch = -1;

function TProjectMatchTests.PadProjects: TArray<string>;
begin
  Result := ['C:\dev\Pad\MarkdownPadVCL.dproj', 'C:\dev\Pad\MarkdownPadFMX.dproj'];
end;

procedure TProjectMatchTests.ExactBaseName_ReturnsIndex;
begin
  Assert.AreEqual(1, TProjectMatch.IndexOf(PadProjects, 'MarkdownPadFMX'));
end;

procedure TProjectMatchTests.ExactFullPath_ReturnsIndex;
begin
  Assert.AreEqual(0, TProjectMatch.IndexOf(PadProjects, 'C:\dev\Pad\MarkdownPadVCL.dproj'));
end;

procedure TProjectMatchTests.UniqueSubstring_ReturnsIndex;
begin
  Assert.AreEqual(1, TProjectMatch.IndexOf(PadProjects, 'FMX'));
end;

procedure TProjectMatchTests.CaseInsensitiveQuery_Matches;
begin
  Assert.AreEqual(0, TProjectMatch.IndexOf(PadProjects, 'markdownpadvcl'));
end;

procedure TProjectMatchTests.AmbiguousSubstring_ReturnsNoMatch;
begin
  Assert.AreEqual(NoMatch, TProjectMatch.IndexOf(PadProjects, 'MarkdownPad'));
end;

procedure TProjectMatchTests.UnknownQuery_ReturnsNoMatch;
begin
  Assert.AreEqual(NoMatch, TProjectMatch.IndexOf(PadProjects, 'Nope'));
end;

procedure TProjectMatchTests.EmptyQuery_ReturnsNoMatch;
begin
  Assert.AreEqual(NoMatch, TProjectMatch.IndexOf(PadProjects, '   '));
end;

procedure TProjectMatchTests.ExactBaseName_BeatsAmbiguousSubstring;
begin
  const Projects: TArray<string> = ['C:\x\App.dproj', 'C:\x\MyApp.dproj'];

  Assert.AreEqual(0, TProjectMatch.IndexOf(Projects, 'App'));
end;

end.
