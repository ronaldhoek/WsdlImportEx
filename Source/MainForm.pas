unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ActnList, WSDLModelIntf, Vcl.Grids, Vcl.ValEdit;

type
  // Hack to override 'AdjustColWidths'
  TValueListEditor = class(Vcl.ValEdit.TValueListEditor)
  private
    FAdjustByColWidthChange: Boolean;
    FAdjustingColWidths: Boolean;
  protected
    procedure AdjustColWidths; override;
    procedure ColWidthsChanged; override;
  end;

  TfrmMain = class(TForm)
    actnNext: TAction;
    actnPrev: TAction;
    alMain: TActionList;
    btnBatchEdit: TButton;
    btnNext: TButton;
    btnPrev: TButton;
    btnSelectFile: TButton;
    btnSelectFolder: TButton;
    dlgSelectFile: TOpenDialog;
    dlgSelectFolder: TFileOpenDialog;
    edtAuthPassword: TEdit;
    edtAuthUsername: TEdit;
    edtOutputfolder: TEdit;
    edtProxy: TEdit;
    edtURI: TEdit;
    gbAuth: TGroupBox;
    lbFeedback: TListBox;
    lblAuthPassword: TLabel;
    lblAuthUsername: TLabel;
    lblOutputfolder: TLabel;
    lblProxy: TLabel;
    lblTypeMapping: TLabel;
    lblURI: TLabel;
    pgctrlMain: TPageControl;
    stsTypeMapping: TStatusBar;
    tbshtPreview: TTabSheet;
    tbshtStart: TTabSheet;
    tbshtTypeMapping: TTabSheet;
    vleTypeNameMapping: TValueListEditor;
    lbWritePreview: TListBox;
    gbOptions: TGroupBox;
    cbFilePerNamespace: TCheckBox;
    procedure actnNextExecute(Sender: TObject);
    procedure actnNextUpdate(Sender: TObject);
    procedure actnPrevExecute(Sender: TObject);
    procedure actnPrevUpdate(Sender: TObject);
    procedure btnBatchEditClick(Sender: TObject);
    procedure btnSelectFileClick(Sender: TObject);
    procedure btnSelectFolderClick(Sender: TObject);
    procedure edtURIChange(Sender: TObject);
    procedure ExecuteWriter(aPreview: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure pgctrlMainChange(Sender: TObject);
    procedure pgctrlMainChanging(Sender: TObject; var AllowChange: Boolean);
    procedure vleTypeNameMappingGetEditText(Sender: TObject; ACol, ARow: Integer;
        var Value: string);
    procedure vleTypeNameMappingSetEditText(Sender: TObject; ACol, ARow: Integer;
        const Value: string);
  private
    FImporter: IWSDLImporter;
    FPreviewOK: Boolean;
    FSettingLoaded: Boolean;
    FTypeMappingDefaults: TStrings;
    FWSDLImportInfo: TWSDLImportInfo;
    FWSDLTypes: IWSDLTypeArray;
    procedure CheckStartPage;
    procedure CheckTypeMapping;
    function GetDirectory: string;
    function GetIniFilename: string;
    function GetRelHdrDir: string;
    function GetWSDLType(aIndex: Integer): IWSDLType;
    procedure InitPreview;
    procedure InitTypeMapping;
    procedure LoadPreviousSettings;
    procedure SaveCurrentSettings;
  protected
    procedure Loaded; override;
    procedure WriteFeedback(const Message: String; const Args: array of const);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses WSDLImpWriter, WSDLPasWriter, System.IniFiles, BachtEditForm,
  System.StrUtils, Winapi.ShellAPI;

const
  sIdentHeight = 'Height';
  sIdentWidth = 'Width';
  sIdentPosLeft = 'PosLeft';
  sIdentPosTop = 'PosTop';
  sIdentTypeNameColWidth = 'TypeNameColWidth';
  sIdentFilePerNamespace = 'FilePerNamespace';
  sNamespaceTypeSeparator = '$';


  sSectionFormState = 'FormState';

  sSectionStart = 'Start';
  sIdentURI = 'URI';
  sIdentOutputfolder = 'Outputfolder';

  sSectionTypeMappingDefaults = 'TypeMappingDefaults';

function isHTTP(const Name: string): boolean;
const
  sHTTPPrefix = 'http://';
  sHTTPsPrefix= 'https://';
begin
  Result := SameText(Copy(Name, 1, Length(sHTTPPrefix)), sHTTPPrefix) or
            SameText(Copy(Name, 1, Length(sHTTPsPrefix)),sHTTPsPrefix);
end;

function ExtractNameSpace(const aFullname: string): string;
var
  iPos: Integer;
begin
  iPos := Pos(sNamespaceTypeSeparator, aFullname);
  if iPos > 1 then
    Result := Copy(aFullname, 1, iPos - 1)
  else
    Result := '';
end;

{ TValueListEditor }

procedure WriteFeedbackProc(const Message: String; const Args: array of const);
begin
  if Assigned(frmMain) then
    frmMain.WriteFeedback(Message, Args);
end;

procedure TValueListEditor.AdjustColWidths;
begin
  // We don't want to adjust the rigth column width, but left
  if not FAdjustingColWidths and HandleAllocated and Showing then
  begin
    FAdjustingColWidths := True;
    try
      if (ColWidths[0] + ColWidths[1]) <> (ClientWidth - 2) then
      begin
        if FAdjustByColWidthChange then
          ColWidths[1] := ClientWidth - ColWidths[0] - 2
        else
          ColWidths[0] := ClientWidth - ColWidths[1] - 2
      end;
    finally
      FAdjustingColWidths := False;
    end;
  end;
end;

procedure TValueListEditor.ColWidthsChanged;
begin
  FAdjustByColWidthChange := True;
  try
    inherited;
  finally
    FAdjustByColWidthChange := False;
  end;
end;

{ TfrmMain }

procedure TfrmMain.actnNextExecute(Sender: TObject);
begin
  if pgctrlMain.ActivePageIndex = pgctrlMain.PageCount - 1 then
  begin
    ExecuteWriter(False);
    if MessageDlg('Files(s) have been created. Open containing folder?', mtConfirmation, mbYesNo, 0) = IDYES then
      ShellExecute(GetDesktopWindow, 'open', PChar(GetDirectory), nil, nil, SW_SHOWNORMAL);
  end else
    pgctrlMain.SelectNextPage(True);
end;

procedure TfrmMain.actnNextUpdate(Sender: TObject);
begin
  if pgctrlMain.ActivePageIndex = pgctrlMain.PageCount - 1 then
  begin
    (Sender as TCustomAction).Caption := 'Finish';
    (Sender as TCustomAction).Enabled := FPreviewOK;
  end else
  begin
    (Sender as TCustomAction).Caption := 'Next';
    (Sender as TCustomAction).Enabled := True;
  end;
end;

procedure TfrmMain.actnPrevExecute(Sender: TObject);
begin
  pgctrlMain.SelectNextPage(False);
end;

procedure TfrmMain.actnPrevUpdate(Sender: TObject);
begin
  (Sender as TCustomAction).Enabled := pgctrlMain.ActivePageIndex > 0;
end;

procedure TfrmMain.btnBatchEditClick(Sender: TObject);
var
  sTypename: String;
  list: TStrings;
  I: Integer;
  _Info: TBatchEditInfo;
begin
  with TfrmBatchEdit.Create(Self) do
  try
    if vleTypeNameMapping.Strings.Count >= vleTypeNameMapping.Row then
      edtFilterNamespace.Text := ExtractNameSpace(vleTypeNameMapping.Strings.Names[vleTypeNameMapping.Row - 1]);

    if ShowModal <> mrOk then
      Exit;

    _Info := GetInfo;
  finally
    Free;
  end;

  list := vleTypeNameMapping.Strings;
  list.BeginUpdate;
  try
    for I := 0 to list.Count - 1 do
      if SameStr(ExtractNameSpace(list.Names[I]), _Info.Filter.NameSpace) then
    begin
      case _Info.Action of
        baAppendSuffix:
          list.ValueFromIndex[I] := list.ValueFromIndex[I] + _Info.Suffix;
        baRemoveSuffix:
          begin
            sTypename := list.ValueFromIndex[I];
            if SameStr(RightStr(sTypename, Length(_Info.Suffix)), _Info.Suffix) then
              list.ValueFromIndex[I] := Copy(sTypename, 1, Length(sTypename) - Length(_Info.Suffix));
          end;
        baEnsureSuffix:
          begin
            sTypename := list.ValueFromIndex[I];
            if not SameStr(RightStr(sTypename, Length(_Info.Suffix)), _Info.Suffix) then
              list.ValueFromIndex[I] := sTypename + _Info.Suffix;
          end;
        baSetNameWithSuffix:
          list.ValueFromIndex[I] := GetWSDLType(I).Name + _Info.Suffix;
      else
        raise Exception.Create('Unknown action');
      end;

      // Deze ook gelijk bijwerken!
      GetWSDLType(I).LangName := list.ValueFromIndex[I];
    end;
  finally
    list.EndUpdate;
  end;
end;

procedure TfrmMain.btnSelectFileClick(Sender: TObject);
begin
  if dlgSelectFile.Execute then
    edtURI.Text := dlgSelectFile.FileName;
end;

procedure TfrmMain.btnSelectFolderClick(Sender: TObject);
begin
  if dlgSelectFolder.Execute then
    edtOutputfolder.Text := dlgSelectFolder.FileName;
end;

procedure TfrmMain.CheckStartPage;
begin
  if not (FileExists(edtURI.Text) or isHTTP(edtURI.Text)) then
  begin
    edtURI.SetFocus;
    raise Exception.Create('Invalid file');
  end;

  if not DirectoryExists(edtOutputfolder.Text) then
  begin
    edtOutputfolder.SetFocus;
    raise Exception.Create('Invalid output folder');
  end;
end;

procedure TfrmMain.CheckTypeMapping;
begin
  // TODO -cMM: TfrmMain.CheckTypeMapping default body inserted
end;

constructor TfrmMain.Create(AOwner: TComponent);
begin
  FTypeMappingDefaults := TStringList.Create;
  inherited;
end;

destructor TfrmMain.Destroy;
begin
  FreeAndNil(FTypeMappingDefaults);
  inherited;
end;

procedure TfrmMain.edtURIChange(Sender: TObject);
begin
  FImporter := nil;
end;

procedure TfrmMain.ExecuteWriter(aPreview: Boolean);
const
  bDirectWrite: Boolean = False;
  AWriteSettings: boolean = False;
var
  WriterClass: TWSDLWriterClass;
  Writer: TWSDLWriter;
begin
  if aPreview then
    FPreviewOK := False;

  if FImporter = nil then
    InitTypeMapping; // Just in case ;)

  { Here we determine the writer }
//  if (LangGen = CppGen) then
//    WriterClass := TWSDLCppWriter
//  else
    WriterClass := TWSDLPasWriter;

  { Direct writing to file? }
  if bDirectWrite then
    Writer := WriterClass.CreateDirect(FImporter, GetDirectory + GetRelHdrDir)
  else
    Writer := WriterClass.Create(FImporter);

  try
    { Give writer output directory }
    Writer.SetDirectory(GetDirectory);
    if Writer.HasSource then
      Writer.SetRelHeaderDir(GetRelHdrDir);

    { Create a file per namespace }
    Writer.SetFilePerNamespace(cbFilePerNamespace.Checked);

    { Write interface to stream}
    Writer.WriteIntf;

     { Write stream to disk }
    if aPreview then
    begin
      Writer.WritePreview(AWriteSettings, lbWritePreview.Items);
      FPreviewOK := True // No errors?
    end else
      Writer.WriteToDisk(AWriteSettings);

  finally
    Writer.Free;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveCurrentSettings;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not FSettingLoaded then
    LoadPreviousSettings;
end;

function TfrmMain.GetDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(edtOutputfolder.Text);
end;

function TfrmMain.GetIniFilename: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

function TfrmMain.GetRelHdrDir: string;
begin
  Result := '';
end;

function TfrmMain.GetWSDLType(aIndex: Integer): IWSDLType;
var
  p: Pointer;
begin
  p := Pointer(vleTypeNameMapping.Strings.Objects[aIndex]);
  Result := IInterface(p) as IWSDLType;
end;

procedure TfrmMain.InitPreview;
begin
  lbWritePreview.Items.Clear;
  ExecuteWriter(True);
end;

procedure TfrmMain.InitTypeMapping;
var
  Flag: TImporterFlags;
  list: TStringList;
  OutFile: string;
  sTypeName: String;
  sFullTypename: String;
  wdsltype: IWSDLType;
  WriterClass: TWSDLWriterClass;
begin
  if FImporter = nil then
  try
    vleTypeNameMapping.Strings.Clear;

    OutFile := '';
//    { Default to Pascal }
//    LangGen := PasGen;

    { Flag }
    Flag := [];
//    if LangGen = CppGen then
//      { C++ }
//      Flag := [ifWriterHasWeakAliases]
//    else
      { Delphi }
      Flag := [ifWriterHasOutParams];

    {TODO -oRH -cOtions : Set schema option}
    if XMLSchemaFile then
      Flag := Flag + [ifImportXMLSchema];

    FImporter := ImportWSDL(edtURI.Text, nil{Stream},
                           WriteFeedbackProc,
                           Flag,
                           OutFile,
                           edtProxy.Text, edtAuthUsername.Text, edtAuthPassword.Text,
                           (30 * 1000), { 30 Secs. timeout }
                           @FWSDLImportInfo);

//    if (LangGen = CppGen) then
//      WriterClass := TWSDLCppWriter
//    else
      WriterClass := TWSDLPasWriter;

    // Init typenames
    WriterClass.Create(FImporter).Free;

    // Gets 'all' types (require reference to ensure interface lifetime)
    FWSDLTypes := FImporter.GetTypes;

    list := vleTypeNameMapping.Strings as TStringList;
    list.BeginUpdate;
    try
      for wdsltype in FWSDLTypes do
        if wdsltype.DataKind <> wtNotDefined then
      begin
        sFullTypename := wdsltype.Namespace + sNamespaceTypeSeparator + wdsltype.Name;
        sTypeName := FTypeMappingDefaults.Values[sFullTypename];
        if sTypeName = '' then
          sTypeName := wdsltype.LangName
        else
          wdsltype.LangName := sTypeName;

        list.AddObject(sFullTypename + list.NameValueSeparator + sTypeName, Pointer(wdsltype) );
      end;

      list.Sort;
    finally
      list.EndUpdate;
    end;

    stsTypeMapping.SimpleText := 'Type count: ' + IntToStr(vleTypeNameMapping.Strings.Count);
  except
    FImporter := nil;
    vleTypeNameMapping.Strings.Clear;
    Raise;
  end;
end;

procedure TfrmMain.Loaded;
begin
  inherited;
  pgctrlMain.ActivePageIndex := 0;
end;

procedure TfrmMain.LoadPreviousSettings;
begin
  FSettingLoaded := True;

  with TIniFile.Create(GetIniFilename) do
  try
    // Mainform placement
    Self.Top    := ReadInteger(sSectionFormState, sIdentPosTop , Self.Top);
    Self.Left   := ReadInteger(sSectionFormState, sIdentPosLeft, Self.Left);
    Self.Width  := ReadInteger(sSectionFormState, sIdentWidth  , Self.Width);
    Self.Height := ReadInteger(sSectionFormState, sIdentHeight , Self.Height);

    vleTypeNameMapping.ColWidths[1] := ReadInteger(sSectionFormState, sIdentTypeNameColWidth, vleTypeNameMapping.ColWidths[1]);

    // Start
    edtURI.Text := ReadString(sSectionStart, sIdentURI, '');
    edtOutputfolder.Text := ReadString(sSectionStart, sIdentOutputfolder, '');

    cbFilePerNamespace.Checked := ReadBool(sSectionStart, sIdentFilePerNamespace, True);

    // Type mappings
    ReadSectionValues(sSectionTypeMappingDefaults, FTypeMappingDefaults);
  finally
    Free;
  end;
end;

procedure TfrmMain.pgctrlMainChange(Sender: TObject);
begin
  if pgctrlMain.ActivePage = tbshtTypeMapping then
    InitTypeMapping
  else if pgctrlMain.ActivePage = tbshtPreview then
    InitPreview;
end;

procedure TfrmMain.pgctrlMainChanging(Sender: TObject; var AllowChange:
    Boolean);
begin
  // Check current page
  try
    if pgctrlMain.ActivePage = tbshtStart then
      CheckStartPage
    else if pgctrlMain.ActivePage = tbshtTypeMapping then
      CheckTypeMapping
  except
    AllowChange := False;
    Application.HandleException(Self);
  end;
end;

procedure TfrmMain.SaveCurrentSettings;
var
  list: TStrings;
  I: Integer;
begin
  with TMemIniFile.Create(GetIniFilename) do
  try
    // Mainform placement
    WriteInteger(sSectionFormState, sIdentPosTop , Self.Top);
    WriteInteger(sSectionFormState, sIdentPosLeft, Self.Left);
    WriteInteger(sSectionFormState, sIdentWidth  , Self.Width);
    WriteInteger(sSectionFormState, sIdentHeight , Self.Height);

    WriteInteger(sSectionFormState, sIdentTypeNameColWidth, vleTypeNameMapping.ColWidths[1]);

    // Start
    WriteString(sSectionStart, sIdentURI, edtURI.Text);
    WriteString(sSectionStart, sIdentOutputfolder, edtOutputfolder.Text);

    WriteBool(sSectionStart, sIdentFilePerNamespace, cbFilePerNamespace.Checked);

    // Update 'default' typemapping info
    list := vleTypeNameMapping.Strings;
    for I := 0 to list.Count - 1 do
      WriteString(sSectionTypeMappingDefaults, list.Names[I], list.ValueFromIndex[I]);

    UpdateFile; // Don't forget this...
  finally
    Free;
  end;
end;

procedure TfrmMain.vleTypeNameMappingGetEditText(Sender: TObject; ACol, ARow:
    Integer; var Value: string);
begin
  if (Value = '') and (ACol = 1) and (vleTypeNameMapping.Strings.Count >= ARow) then
    Value := GetWSDLType(ARow -1).LangName;
end;

procedure TfrmMain.vleTypeNameMappingSetEditText(Sender: TObject; ACol, ARow:
    Integer; const Value: string);
begin
  if (ACol = 1) and (vleTypeNameMapping.Strings.Count >= ARow) then
    GetWSDLType(ARow - 1).LangName := Value;
end;

procedure TfrmMain.WriteFeedback(const Message: String;
  const Args: array of const);
begin
  lbFeedback.Items.Add(Format(Message, Args));
end;

end.
