unit GDK.ToolsAPI.FormNaming.Tests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFormNamingTests = class
  public
    [Test]
    procedure DottedUnitName_KeepsDotsAndDerivesForm;

    [Test]
    procedure SimpleUnitName_DerivesClassAndVariable;

    [Test]
    procedure FullPath_UsesFileBaseAsUnitName;

    [Test]
    procedure FormName_IsTrimmed;

    [Test]
    procedure EmptyFormName_Raises;

    [Test]
    procedure DottedFormName_Raises;

    [Test]
    procedure UnitNameEqualToFormName_RaisesOnCollision;
  end;

implementation

uses
  GDK.ToolsAPI.FormNaming;

procedure TFormNamingTests.DottedUnitName_KeepsDotsAndDerivesForm;
begin
  const Naming = TFormUnitNaming.Derive('C:\proj\MarkdownPad.Main.pas', 'MarkdownPadForm');

  Assert.AreEqual('MarkdownPad.Main', Naming.UnitName);
  Assert.AreEqual('TMarkdownPadForm', Naming.FormClassName);
  Assert.AreEqual('MarkdownPadForm', Naming.FormVariableName);
end;

procedure TFormNamingTests.SimpleUnitName_DerivesClassAndVariable;
begin
  const Naming = TFormUnitNaming.Derive('C:\proj\MainView.pas', 'MainForm');

  Assert.AreEqual('MainView', Naming.UnitName);
  Assert.AreEqual('TMainForm', Naming.FormClassName);
  Assert.AreEqual('MainForm', Naming.FormVariableName);
end;

procedure TFormNamingTests.FullPath_UsesFileBaseAsUnitName;
begin
  const Naming = TFormUnitNaming.Derive('C:\a\b\c\Sales.Order.Edit.pas', 'OrderEditor');

  Assert.AreEqual('Sales.Order.Edit', Naming.UnitName);
  Assert.AreEqual('TOrderEditor', Naming.FormClassName);
end;

procedure TFormNamingTests.FormName_IsTrimmed;
begin
  const Naming = TFormUnitNaming.Derive('C:\proj\MainView.pas', '  MainForm  ');

  Assert.AreEqual('MainForm', Naming.FormVariableName);
  Assert.AreEqual('TMainForm', Naming.FormClassName);
end;

procedure TFormNamingTests.EmptyFormName_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      TFormUnitNaming.Derive('C:\proj\MainView.pas', '   ');
    end,
    EFormUnitNaming);
end;

procedure TFormNamingTests.DottedFormName_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      TFormUnitNaming.Derive('C:\proj\MainView.pas', 'Main.Form');
    end,
    EFormUnitNaming);
end;

procedure TFormNamingTests.UnitNameEqualToFormName_RaisesOnCollision;
begin
  Assert.WillRaise(
    procedure
    begin
      TFormUnitNaming.Derive('C:\proj\MainForm.pas', 'MainForm');
    end,
    EFormUnitNaming);
end;

end.
