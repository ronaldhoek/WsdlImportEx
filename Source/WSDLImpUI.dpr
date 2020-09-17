program WSDLImpUI;

uses
  Vcl.Forms,
  WSDLImpWriter in 'WSDLImpWriter.pas',
  XMLSchemaHelper in 'XMLSchemaHelper.pas',
  WSDLPasWriter in 'WSDLPasWriter.pas',
  WSDLModelIntf in 'WSDLModelIntf.pas',
  WSDLImpConst in 'WSDLImpConst.pas',
  WSDLCppWriter in 'WSDLCppWriter.pas',
  UDDIHlprDesign in 'UDDIHlprDesign.pas',
  MessageDigest_5 in 'MessageDigest_5.pas',
  MainForm in 'MainForm.pas' {frmMain},
  BachtEditForm in 'BachtEditForm.pas' {frmBatchEdit};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
