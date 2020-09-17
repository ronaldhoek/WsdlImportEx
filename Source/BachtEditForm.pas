unit BachtEditForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TBatchEditAction = (
    baAppendSuffix,
    baRemoveSuffix,
    baEnsureSuffix,
    baSetNameWithSuffix);

  TBatchEditInfo = record
    Action: TBatchEditAction;
    Suffix: string;
    Filter: record
      NameSpace: string;
    end;
  end;

  TfrmBatchEdit = class(TForm)
    btnCancel: TButton;
    btnExecute: TButton;
    edtFilterNamespace: TEdit;
    edtSuffix: TEdit;
    gbFilter: TGroupBox;
    lblFilterNamespace: TLabel;
    lblSuffix: TLabel;
    rgActionType: TRadioGroup;
    procedure btnExecuteClick(Sender: TObject);
  public
    function GetInfo: TBatchEditInfo;
  end;

implementation

{$R *.dfm}

procedure TfrmBatchEdit.btnExecuteClick(Sender: TObject);
begin
  if rgActionType.ItemIndex <= 0 then
  begin
    rgActionType.SetFocus;
    raise Exception.Create('No action specified');
  end;

  if edtSuffix.Text = '' then
  begin
    edtSuffix.SetFocus;
    raise Exception.Create('Specify suffix');
  end;

  if edtFilterNamespace.Text = '' then
  begin
    edtFilterNamespace.SetFocus;
    raise Exception.Create('Namespace filter is required');
  end;

  ModalResult := mrOk;
end;

function TfrmBatchEdit.GetInfo: TBatchEditInfo;
begin
  Result.Action := TBatchEditAction(rgActionType.ItemIndex - 1);
  Result.Suffix := edtSuffix.Text;
  Result.Filter.NameSpace := edtFilterNamespace.Text;
end;

end.
