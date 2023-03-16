unit GDK.ToolsAPI.UsesManager.Tests;

interface

uses
  DUnitX.TestFramework;

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
