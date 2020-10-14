unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ActnList, WSDLModelIntf, Vcl.Grids, Vcl.ValEdit, Vcl.ExtCtrls;

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
    btnCheck: TButton;
    btnNext: TButton;
    btnPrev: TButton;
    btnSelectFile: TButton;
    btnSelectFolder: TButton;
    btnTypesFindNonEdited: TButton;
    cbFilePerNamespace: TCheckBox;
    dlgSelectFile: TOpenDialog;
    dlgSelectFolder: TFileOpenDialog;
    edtAuthPassword: TEdit;
    edtAuthUsername: TEdit;
    edtFilter: TEdit;
    edtOutputFilename: TEdit;
    edtOutputfolder: TEdit;
    edtProxy: TEdit;
    edtURI: TEdit;
    gbAuth: TGroupBox;
    gbOptions: TGroupBox;
    lbFeedback: TListBox;
    lblAuthPassword: TLabel;
    lblAuthUsername: TLabel;
    lblOutputFilename: TLabel;
    lblOutputfolder: TLabel;
    lblProxy: TLabel;
    lblTypeMapping: TLabel;
    lblURI: TLabel;
    lbWritePreview: TListBox;
    pgctrlMain: TPageControl;
    stsTypeMapping: TStatusBar;
    tbshtPreview: TTabSheet;
    tbshtStart: TTabSheet;
    tbshtTypeMapping: TTabSheet;
    tmrUpdateFilter: TTimer;
    vleTypeNameMapping: TValueListEditor;
    vleTypeNamespaces: TValueListEditor;
    procedure actnNextExecute(Sender: TObject);
    procedure actnNextUpdate(Sender: TObject);
    procedure actnPrevExecute(Sender: TObject);
    procedure actnPrevUpdate(Sender: TObject);
    procedure btnBatchEditClick(Sender: TObject);
    procedure btnCheckClick(Sender: TObject);
    procedure btnSelectFileClick(Sender: TObject);
    procedure btnSelectFolderClick(Sender: TObject);
    procedure btnTypesFindNonEditedClick(Sender: TObject);
    procedure edtFilterChange(Sender: TObject);
    procedure edtOutputFilenameChange(Sender: TObject);
    procedure edtURIChange(Sender: TObject);
    procedure ExecuteWriter(aPreview: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure pgctrlMainChange(Sender: TObject);
    procedure pgctrlMainChanging(Sender: TObject; var AllowChange: Boolean);
    procedure tmrUpdateFilterTimer(Sender: TObject);
    procedure vleTypeNameMappingGetEditText(Sender: TObject; ACol, ARow: Integer;
        var Value: string);
    procedure vleTypeNameMappingSetEditText(Sender: TObject; ACol, ARow: Integer;
        const Value: string);
    procedure vleTypeNamespacesSetEditText(Sender: TObject; ACol, ARow: Integer;
        const Value: string);
  private
    FImporter: IWSDLImporter;
    FNamespaceFilemappings: TStrings;
    FOutputFilenames: TStrings;
    FPreviewOK: Boolean;
    FSettingsLoaded: Boolean;
    FTypeMappingDefaults: TStrings;
    FWSDLImportInfo: TWSDLImportInfo;
    FWSDLTypes: IWSDLTypeArray;
    procedure CheckDuplicatedTypeNames;
    procedure CheckStartPage;
    function GetDirectory: string;
    function GetIniFilename: string;
    function GetMappingInfoFilename: string;
    function GetRelHdrDir: string;
    function GetWSDLType(aIndex: Integer): IWSDLType;
    procedure InitPreview;
    procedure InitTypeMapping;
    procedure LoadPreviousSettings;
    procedure SaveCurrentSettings;
    procedure UpdateTypeEditor(aInit: boolean);
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
  sNamespaceTypeSeparator = '$';

  // Form state/position etc.
  sSectionFormState = 'FormState';
  sIdentHeight = 'Height';
  sIdentWidth = 'Width';
  sIdentPosLeft = 'PosLeft';
  sIdentPosTop = 'PosTop';
  sIdentTypeNameColWidth = 'TypeNameColWidth';
  sIdentFilenameColWidth = 'FilenameColWidth';
  sIdentFilePerNamespace = 'FilePerNamespace';

  // Form user inputs
  sSectionStart = 'Start';
  sIdentURI = 'URI';
  sIdentOutputfolder = 'Outputfolder';

  // Mapping info
  sSectionOutputfilenames = 'Outputfilenames';
  sSectionTypes = 'Types';
  sSectionNamespaces = 'Namespaces';

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

procedure TfrmMain.btnCheckClick(Sender: TObject);
begin
  CheckDuplicatedTypeNames;
end;

procedure TfrmMain.btnSelectFileClick(Sender: TObject);
begin
  if FileExists(edtURI.Text) then
    dlgSelectFile.FileName := edtURI.Text;
  if DirectoryExists(ExtractFilePath(edtURI.Text)) then
    dlgSelectFile.InitialDir := ExtractFilePath(edtURI.Text);

  if dlgSelectFile.Execute then
    edtURI.Text := dlgSelectFile.FileName;
end;

procedure TfrmMain.btnSelectFolderClick(Sender: TObject);
begin
  if DirectoryExists(edtOutputfolder.Text) then
    dlgSelectFolder.FileName := edtOutputfolder.Text;
  if DirectoryExists(ExtractFilePath(edtOutputfolder.Text)) then
    dlgSelectFolder.FileName := ExtractFilePath(edtOutputfolder.Text);

  if dlgSelectFolder.Execute then
    edtOutputfolder.Text := dlgSelectFolder.FileName;
end;

procedure TfrmMain.btnTypesFindNonEditedClick(Sender: TObject);
var
  curtype: IWSDLType;
  iCurRow: Integer;
  iStartRow: Integer;
begin
  iStartRow := vleTypeNameMapping.Row;
  iCurRow := iStartRow;
  while iCurRow < vleTypeNameMapping.RowCount do
  begin
    curtype := GetWSDLType(iCurRow - 1);
    if curtype.Name = curtype.LangName then
    begin
      vleTypeNameMapping.Row := iCurRow;
      vleTypeNameMapping.SetFocus;
      Exit;
    end;
    Inc(iCurRow);
  end;

  ShowMessage('No more items found');
end;

procedure TfrmMain.CheckDuplicatedTypeNames;
var
  I: Integer;
  iItem: Integer;
  sl: TStringList;
  wdsltype: IWSDLType;
begin
  // Check duplicate typenames
  sl := TStringList.Create;
  try
    sl.Sorted := True;
    sl.Duplicates := dupIgnore;

    // Check all types - ignore filter!
    for wdsltype in FWSDLTypes do
      if wdsltype.DataKind <> wtNotDefined then
    begin
      // Count typenames
      iItem := sl.Add(wdsltype.LangName);
      sl.Objects[iItem] := Pointer(NativeInt(sl.Objects[iItem]) + 1);
    end;

    sl.Sorted := False;
    for I := sl.Count - 1 downto 0 do
      if NativeInt(sl.Objects[I]) = 1 then
        sl.Delete(I)
      else
        sl[I] := '- ' + sl[I];

    if sl.Count > 0 then
      Raise Exception.Create('Duplicate typenames found:' + sLineBreak + sl.Text);
  finally
    sl.Free;
  end;
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

constructor TfrmMain.Create(AOwner: TComponent);
begin
  FOutputFilenames := TStringList.Create;
  FTypeMappingDefaults := TStringList.Create;
  FNamespaceFilemappings := TStringList.Create;
  inherited;
end;

destructor TfrmMain.Destroy;
begin
  FreeAndNil(FOutputFilenames);
  FreeAndNil(FTypeMappingDefaults);
  FreeAndNil(FNamespaceFilemappings);
  inherited;
end;

procedure TfrmMain.edtFilterChange(Sender: TObject);
begin
  tmrUpdateFilter.Enabled := False;
  tmrUpdateFilter.Enabled := True;
end;

procedure TfrmMain.edtOutputFilenameChange(Sender: TObject);
begin
  FImporter := nil;
end;

procedure TfrmMain.edtURIChange(Sender: TObject);
var
  s: string;
begin
  FImporter := nil;
  s := FOutputFilenames.Values[ExtractFilename((Sender as TEdit).Text)];
  if s > '' then
    edtOutputFilename.Text := s;
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
    if cbFilePerNamespace.Checked then
      Writer.SetNamespaceFilenames(vleTypeNamespaces.Strings);

    { Write interface to stream}
    Writer.WriteIntf;

     { Write stream to disk }
    if aPreview then
    try
      CheckDuplicatedTypeNames;
      Writer.WritePreview(AWriteSettings, lbWritePreview.Items);
      FPreviewOK := True // No errors?
    except
      on E: Exception do
      begin
        lbWritePreview.Items.Add('ERROR: ' + E.Message);
        raise;
      end;
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
  if not FSettingsLoaded then
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

function TfrmMain.GetMappingInfoFilename: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'Mappings.ini';
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
  OutFile: string;
begin
  if FImporter = nil then
  try
    vleTypeNameMapping.Strings.Clear;
    vleTypeNamespaces.Strings.Clear;
    edtFilter.Clear;
    tmrUpdateFilter.Enabled := False;

    OutFile := edtOutputFilename.Text;
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
//      WriterClass := TWSDLPasWriter;

    // Gets 'all' types (require reference to ensure interface lifetime)
    FWSDLTypes := FImporter.GetTypes;
    UpdateTypeEditor(True);
  except
    FImporter := nil;
    vleTypeNameMapping.Strings.Clear;
    vleTypeNamespaces.Strings.Clear;
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
  FSettingsLoaded := True;

  // Basic settings
  with TIniFile.Create(GetIniFilename) do
  try
    // Mainform placement
    Self.Top    := ReadInteger(sSectionFormState, sIdentPosTop , Self.Top);
    Self.Left   := ReadInteger(sSectionFormState, sIdentPosLeft, Self.Left);
    Self.Width  := ReadInteger(sSectionFormState, sIdentWidth  , Self.Width);
    Self.Height := ReadInteger(sSectionFormState, sIdentHeight , Self.Height);

    vleTypeNameMapping.ColWidths[1] := ReadInteger(sSectionFormState, sIdentTypeNameColWidth, vleTypeNameMapping.ColWidths[1]);
    vleTypeNamespaces.ColWidths[1] := ReadInteger(sSectionFormState, sIdentFilenameColWidth, vleTypeNamespaces.ColWidths[1]);

    // Start
    edtURI.Text := ReadString(sSectionStart, sIdentURI, '');
    edtOutputfolder.Text := ReadString(sSectionStart, sIdentOutputfolder, '');

    cbFilePerNamespace.Checked := ReadBool(sSectionStart, sIdentFilePerNamespace, True);
  finally
    Free;
  end;

  // Mapping information
  with TIniFile.Create(GetMappingInfoFilename) do
  try
    // Output filenames
    ReadSectionValues(sSectionOutputfilenames, FOutputFilenames);
    edtURIChange(edtURI);

    // Type mappings
    ReadSectionValues(sSectionTypes, FTypeMappingDefaults);

    // Namespace mappings
    ReadSectionValues(sSectionNamespaces, FNamespaceFilemappings);
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
  with TIniFile.Create(GetIniFilename) do
  try
    // Mainform placement
    WriteInteger(sSectionFormState, sIdentPosTop , Self.Top);
    WriteInteger(sSectionFormState, sIdentPosLeft, Self.Left);
    WriteInteger(sSectionFormState, sIdentWidth  , Self.Width);
    WriteInteger(sSectionFormState, sIdentHeight , Self.Height);

    WriteInteger(sSectionFormState, sIdentTypeNameColWidth, vleTypeNameMapping.ColWidths[1]);
    WriteInteger(sSectionFormState, sIdentFilenameColWidth, vleTypeNamespaces.ColWidths[1]);

    // Start
    WriteString(sSectionStart, sIdentURI, edtURI.Text);
    WriteString(sSectionStart, sIdentOutputfolder, edtOutputfolder.Text);

    WriteBool(sSectionStart, sIdentFilePerNamespace, cbFilePerNamespace.Checked);

    UpdateFile; // Just in case...
  finally
    Free;
  end;

  // Mapping information
  with TMemIniFile.Create(GetMappingInfoFilename) do
  try
    // Store webservice outputfilename based on source filename
    if (edtOutputFilename.Text > '') and (edtURI.Text > '') then
      WriteString(sSectionOutputfilenames, ExtractFileName(edtURI.Text), edtOutputFilename.Text);

    // Store typemapping info
    list := vleTypeNameMapping.Strings;
    for I := 0 to list.Count - 1 do
      if (list.Names[I] > '') and (list.ValueFromIndex[I] > '') then
        WriteString(sSectionTypes, list.Names[I], list.ValueFromIndex[I]);

    // Stroe namespace mappings
    list := vleTypeNamespaces.Strings;
    for I := 0 to list.Count - 1 do
      if (list.Names[I] > '') and (list.ValueFromIndex[I] > '') then
        WriteString(sSectionNamespaces, list.Names[I], list.ValueFromIndex[I]);

    UpdateFile; // Don't forget this...
  finally
    Free;
  end;
end;

procedure TfrmMain.tmrUpdateFilterTimer(Sender: TObject);
begin
  (Sender as TTimer).Enabled := False;
  UpdateTypeEditor(False);
end;

procedure TfrmMain.UpdateTypeEditor(aInit: boolean);
var
  list, listNS: TStringList;
  sFilter: String;
  s: String;
  sFullTypename: String;
  wdsltype: IWSDLType;
begin
  sFilter := edtFilter.Text;
  try
    list := vleTypeNameMapping.Strings as TStringList;
    listNS := vleTypeNamespaces.Strings as TStringList;
    list.BeginUpdate;
    listNS.BeginUpdate;
    try
      list.Clear;
      for wdsltype in FWSDLTypes do
        if (wdsltype.DataKind <> wtNotDefined) then
      begin
        if (sFilter = '') or ContainsText(wdsltype.LangName, sFilter) then
        begin
          sFullTypename := wdsltype.Namespace + sNamespaceTypeSeparator + wdsltype.Name;

          if aInit then
          begin
            s := FTypeMappingDefaults.Values[sFullTypename];
            if s > '' then
              wdsltype.LangName := s;
          end;

          list.AddObject(sFullTypename + list.NameValueSeparator + wdsltype.LangName, Pointer(wdsltype) );
        end;

        // Namespaces
        if aInit and (listNS.IndexOfName(wdsltype.Namespace) = -1) then
        begin
          s := FNamespaceFilemappings.Values[wdsltype.Namespace];
          if s = '' then s := GetValidFilenameByNamespace(wdsltype.Namespace);
          listNS.Add(wdsltype.Namespace + list.NameValueSeparator + s);
        end;
      end;

      list.Sort;
      listNS.Sort;
    finally
      list.EndUpdate;
      listNS.EndUpdate;
    end;

    stsTypeMapping.SimpleText := 'Type count: ' + IntToStr(vleTypeNameMapping.Strings.Count);
  except
    vleTypeNameMapping.Strings.Clear;
    raise;
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

procedure TfrmMain.vleTypeNamespacesSetEditText(Sender: TObject; ACol, ARow:
    Integer; const Value: string);
begin
  if (ACol = 1) and (vleTypeNamespaces.Strings.Count >= ARow) then
    FNamespaceFilemappings.Values[vleTypeNamespaces.Keys[ARow]] := Value;
end;

procedure TfrmMain.WriteFeedback(const Message: String;
  const Args: array of const);
begin
  lbFeedback.Items.Add(Format(Message, Args));
end;

end.
