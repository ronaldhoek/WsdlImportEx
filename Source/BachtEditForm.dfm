object frmBatchEdit: TfrmBatchEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Batch edit typenames'
  ClientHeight = 238
  ClientWidth = 341
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  DesignSize = (
    341
    238)
  PixelsPerInch = 96
  TextHeight = 13
  object lblSuffix: TLabel
    Left = 207
    Top = 16
    Width = 28
    Height = 13
    Caption = 'Suffix'
    FocusControl = edtSuffix
  end
  object rgActionType: TRadioGroup
    Left = 8
    Top = 8
    Width = 193
    Height = 121
    Caption = 'Action type'
    ItemIndex = 0
    Items.Strings = (
      'None'
      'Append suffix'
      'Remove suffix'
      'Ensure suffix'
      'Set name + suffix')
    TabOrder = 0
  end
  object edtSuffix: TEdit
    Left = 207
    Top = 32
    Width = 118
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
  end
  object gbFilter: TGroupBox
    Left = 8
    Top = 135
    Width = 325
    Height = 66
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Filter'
    TabOrder = 2
    DesignSize = (
      325
      66)
    object lblFilterNamespace: TLabel
      Left = 8
      Top = 15
      Width = 55
      Height = 13
      Caption = 'Namespace'
      FocusControl = edtFilterNamespace
    end
    object edtFilterNamespace: TEdit
      Left = 8
      Top = 31
      Width = 309
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object btnExecute: TButton
    Left = 169
    Top = 207
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Execute'
    Default = True
    TabOrder = 3
    OnClick = btnExecuteClick
  end
  object btnCancel: TButton
    Left = 250
    Top = 207
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
