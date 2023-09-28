unit GDK.ToolsAPI.UsesManager.Tests;

interface

uses
  DUnitX.TestFramework,
  GDK.ToolsAPI.UsesBuilder;

type
  [TestFixture]
  TGdkToolsApiUsesManagerTests = class
  const
    MY_TEST_UNIT = 'My.Test.Unit';
  private
    function GetEmptyUnit: string;
    function GetUnitWithInterfaceUses: string;
    function GetUnitWithImplementationUses: string;
    function GetUnitWithBothUses: string;

    procedure AssertUsesFound(const Source: string; const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
  public
    [Test]
    [TestCase('Add to interface', 'False,27,True')]
    [TestCase('Add to implementation', 'True,45,True')]
    procedure AddUnitToNonExistingUsesSection(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);

    [Test]
    [TestCase('Add to interface', 'False,71,False')]
    [TestCase('Add to implementation', 'True,91,True')]
    procedure AddUnitToExistingInterfaceUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);

    [Test]
    [TestCase('Add to interface', 'False,27,True')]
    [TestCase('Add to implementation', 'True,108,False')]
    procedure AddUnitToExistingImplementationUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);

    [Test]
    [TestCase('Add to interface', 'False,100,False')]
    [TestCase('Add to implementation', 'True,142,False')]
    procedure AddUnitToExistingBothUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);

    [Test]
    procedure TestUsesBuilder;
  end;

implementation

uses
  GDK.ToolsAPI.UsesManager,
  System.SysUtils;

{ TGdkToolsApiUsesManagerTests }

procedure TGdkToolsApiUsesManagerTests.AddUnitToNonExistingUsesSection(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
begin
  var Source := GetEmptyUnit;
  AssertUsesFound(Source, AddToImplementation, ExpectedPosition, ExpectEmptyUses);
end;

procedure TGdkToolsApiUsesManagerTests.AddUnitToExistingInterfaceUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
begin
  var Source := GetUnitWithInterfaceUses;
  AssertUsesFound(Source, AddToImplementation, ExpectedPosition, ExpectEmptyUses);
end;

procedure TGdkToolsApiUsesManagerTests.AddUnitToExistingImplementationUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
begin
  var Source := GetUnitWithImplementationUses;
  AssertUsesFound(Source, AddToImplementation, ExpectedPosition, ExpectEmptyUses);
end;

procedure TGdkToolsApiUsesManagerTests.AddUnitToExistingBothUses(const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
begin
  var Source := GetUnitWithBothUses;
  AssertUsesFound(Source, AddToImplementation, ExpectedPosition, ExpectEmptyUses);
end;

procedure TGdkToolsApiUsesManagerTests.AssertUsesFound(const Source: string; const AddToImplementation: Boolean; const ExpectedPosition: Integer; const ExpectEmptyUses: Boolean);
begin
  var UsesManager := TToolsApiUsesManager
                        .Use
                        .WithSource(Source);

  var PositionFound: Integer := -1;
  var IsEmptyUsesFound: Boolean;

  UsesManager.FindPositionToAdd(MY_TEST_UNIT, AddToImplementation,
    procedure(const PositionToAdd: Integer; const IsEmptyUses: Boolean)
    begin
      PositionFound := PositionToAdd;
      IsEmptyUsesFound := IsEmptyUses;
    end);

  var ErrorInfo := '';
  if AddToImplementation then
    ErrorInfo := ' (add to implementation)'
  else
    ErrorInfo := ' (add to interface)';

  Assert.AreEqual(ExpectedPosition, PositionFound, 'Wrong position found' + ErrorInfo);
  Assert.AreEqual(ExpectEmptyUses, IsEmptyUsesFound, 'Uses empty or not' + ErrorInfo);

end;

procedure TGdkToolsApiUsesManagerTests.TestUsesBuilder;
const
  Uses_Separator = ', ';
begin
  var UsesBuilder: IToolsAPIUsesBuilder := TToolsAPIUsesBuilder.Use;
  UsesBuilder.InImplementation;
  var ExpectedPosition := 45;
  var ExpectedText :=  sLineBreak +
                       sLineBreak + 'uses' +
                       sLineBreak + '  ' + MY_TEST_UNIT + ';';

  var EmptySource := GetEmptyUnit;
  UsesBuilder.WithSource(EmptySource);

  var UnitNames: TArray<string> := [MY_TEST_UNIT];
  var Actual := UsesBuilder.Build(UnitNames);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '1 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '1 - Text is not correct');

  UnitNames := [MY_TEST_UNIT, 'System.SysUtils'];
  ExpectedText := sLineBreak +
                  sLineBreak + 'uses' +
                  sLineBreak + '  ' + string.Join(Uses_Separator, UnitNames) + ';';

  Actual := UsesBuilder.Build(UnitNames);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '2 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '2 - Text is not correct');

  var SourceWithInterfaceUses := GetUnitWithInterfaceUses;
  UsesBuilder.WithSource(SourceWithInterfaceUses);

  ExpectedPosition := 91;

  UnitNames := [MY_TEST_UNIT];
  ExpectedText := sLineBreak +
                  sLineBreak + 'uses' +
                  sLineBreak + '  ' + string.Join(Uses_Separator, UnitNames) + ';';
  Actual := UsesBuilder.Build(UnitNames);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '3 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '3 - Text is not correct');

  UnitNames := [MY_TEST_UNIT];
  ExpectedText := sLineBreak +
                  sLineBreak + 'uses' +
                  sLineBreak + '  ' + string.Join(Uses_Separator, UnitNames) + ';';

  // System.SysUtils already used in interface uses
  Actual := UsesBuilder.Build(UnitNames + ['System.SysUtils']);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '4 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '4 - Text is not correct');

  var SourceWithImplementationUses := GetUnitWithImplementationUses;
  UsesBuilder.WithSource(SourceWithImplementationUses);

  ExpectedPosition := 108;

  UnitNames := [MY_TEST_UNIT];
  ExpectedText := Uses_Separator + string.Join(Uses_Separator, UnitNames);
  Actual := UsesBuilder.Build(UnitNames);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '5 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '5 - Text is not correct');

  UnitNames := [MY_TEST_UNIT];
  ExpectedText := Uses_Separator + string.Join(Uses_Separator, UnitNames);

  // System.SysUtils already used in implementation uses
  Actual := UsesBuilder.Build(UnitNames + ['System.SysUtils']);

  Assert.AreEqual(ExpectedPosition, Actual.Position, '6 - Position is not correct');
  Assert.AreEqual(ExpectedText, Actual.Text, '6 - Text is not correct');
end;

function TGdkToolsApiUsesManagerTests.GetEmptyUnit: string;
begin
  var UnitSource := [
    'unit TestUnit',
    '',
    'interface',
    '',
    'implementation',
    '',
    'end.'
  ];

  Result := string.Join(sLineBreak, UnitSource);
end;

function TGdkToolsApiUsesManagerTests.GetUnitWithInterfaceUses: string;
begin
  var UnitSource := [
    'unit TestUnit',
    '',
    'interface',
    '',
    'uses System.SysUtils,',
    '        Tests.Base;',
    '',
    'implementation',
    '',
    'end.'
  ];

  Result := string.Join(sLineBreak, UnitSource);
end;

function TGdkToolsApiUsesManagerTests.GetUnitWithImplementationUses: string;
begin
  var UnitSource := [
    'unit TestUnit',
    '',
    'interface',
    '',
    'implementation',
    '',
    'uses System.SysUtils, DataModel.Customer',
    '        Tests.Base;',
    '',
    'end.'
  ];

  Result := string.Join(sLineBreak, UnitSource);
end;

function TGdkToolsApiUsesManagerTests.GetUnitWithBothUses: string;
begin
  var UnitSource := [
    'unit TestUnit',
    '',
    'interface',
    '',
    'uses System.SysUtils,',
    '        Tests.Base,',
    '        DataModel.Customer;',
    '',
    'implementation',
    '',
    'uses System.IOUtils;',
    '',
    'end.'
  ];

  Result := string.Join(sLineBreak, UnitSource);
end;

end.
