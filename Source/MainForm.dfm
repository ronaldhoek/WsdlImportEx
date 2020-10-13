object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Import webservice'
  ClientHeight = 480
  ClientWidth = 619
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  DesignSize = (
    619
    480)
  PixelsPerInch = 96
  TextHeight = 13
  object pgctrlMain: TPageControl
    Left = 0
    Top = 0
    Width = 619
    Height = 480
    ActivePage = tbshtStart
    Align = alClient
    TabOrder = 0
    OnChange = pgctrlMainChange
    OnChanging = pgctrlMainChanging
    object tbshtStart: TTabSheet
      Caption = 'Start'
      DesignSize = (
        611
        452)
      object lblURI: TLabel
        Left = 3
        Top = 8
        Width = 108
        Height = 13
        Caption = 'File or webservice URL'
        FocusControl = edtURI
      end
      object lblOutputfolder: TLabel
        Left = 3
        Top = 166
        Width = 65
        Height = 13
        Caption = 'Output folder'
        FocusControl = edtOutputfolder
      end
      object lblOutputFilename: TLabel
        Left = 3
        Top = 209
        Width = 135
        Height = 13
        Caption = 'Output filename (unit name)'
        FocusControl = edtOutputFilename
      end
      object edtURI: TEdit
        Left = 3
        Top = 24
        Width = 574
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        OnChange = edtURIChange
      end
      object btnSelectFile: TButton
        Left = 583
        Top = 24
        Width = 75
        Height = 22
        Anchors = [akTop, akRight]
        Caption = 'Select file'
        TabOrder = 1
        OnClick = btnSelectFileClick
      end
      object gbAuth: TGroupBox
        Left = 3
        Top = 51
        Width = 655
        Height = 109
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Authentication (URL only)'
        TabOrder = 2
        DesignSize = (
          655
          109)
        object lblAuthUsername: TLabel
          Left = 8
          Top = 24
          Width = 48
          Height = 13
          Caption = 'Username'
          FocusControl = edtAuthUsername
        end
        object lblAuthPassword: TLabel
          Left = 8
          Top = 51
          Width = 46
          Height = 13
          Caption = 'Password'
          FocusControl = edtAuthPassword
        end
        object lblProxy: TLabel
          Left = 8
          Top = 78
          Width = 28
          Height = 13
          Caption = 'Proxy'
          FocusControl = edtProxy
        end
        object edtAuthUsername: TEdit
          Left = 112
          Top = 21
          Width = 531
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
        end
        object edtAuthPassword: TEdit
          Left = 112
          Top = 48
          Width = 531
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
        end
        object edtProxy: TEdit
          Left = 112
          Top = 75
          Width = 531
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
        end
      end
      object edtOutputfolder: TEdit
        Left = 3
        Top = 182
        Width = 574
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
      end
      object btnSelectFolder: TButton
        Left = 583
        Top = 182
        Width = 75
        Height = 22
        Anchors = [akTop, akRight]
        Caption = 'Select folder'
        TabOrder = 4
        OnClick = btnSelectFolderClick
      end
      object gbOptions: TGroupBox
        Left = 4
        Top = 252
        Width = 655
        Height = 42
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Options'
        TabOrder = 5
        object cbFilePerNamespace: TCheckBox
          Left = 11
          Top = 16
          Width = 166
          Height = 17
          Caption = 'Create a file per namespace'
          TabOrder = 0
        end
      end
      object edtOutputFilename: TEdit
        Left = 3
        Top = 225
        Width = 574
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 6
        OnChange = edtOutputFilenameChange
      end
    end
    object tbshtTypeMapping: TTabSheet
      Caption = 'Type mapping'
      ImageIndex = 1
      DesignSize = (
        611
        452)
      object lblTypeMapping: TLabel
        Left = 3
        Top = 5
        Width = 220
        Height = 13
        Caption = 'Specify the actual typenames (in code) to use'
      end
      object vleTypeNameMapping: TValueListEditor
        Left = 3
        Top = 29
        Width = 656
        Height = 267
        Anchors = [akLeft, akTop, akRight, akBottom]
        KeyOptions = [keyUnique]
        TabOrder = 0
        TitleCaptions.Strings = (
          'Fullname'
          'Typename')
        OnGetEditText = vleTypeNameMappingGetEditText
        OnSetEditText = vleTypeNameMappingSetEditText
        ColWidths = (
          244
          406)
      end
      object stsTypeMapping: TStatusBar
        Left = 3
        Top = 294
        Width = 656
        Height = 18
        Align = alNone
        Anchors = [akLeft, akRight, akBottom]
        Panels = <>
        SimplePanel = True
      end
      object btnBatchEdit: TButton
        Left = 3
        Top = 512
        Width = 75
        Height = 25
        Anchors = [akLeft, akBottom]
        Caption = 'Batch edit'
        TabOrder = 3
        OnClick = btnBatchEditClick
      end
      object lbFeedback: TListBox
        Left = 3
        Top = 417
        Width = 656
        Height = 89
        Anchors = [akLeft, akRight, akBottom]
        ItemHeight = 13
        TabOrder = 2
      end
      object btnTypesFindNonEdited: TButton
        Left = 84
        Top = 512
        Width = 75
        Height = 25
        Anchors = [akLeft, akBottom]
        Caption = 'Find not set'
        TabOrder = 4
        OnClick = btnTypesFindNonEditedClick
      end
      object btnCheck: TButton
        Left = 165
        Top = 512
        Width = 75
        Height = 25
        Anchors = [akLeft, akBottom]
        Caption = 'Check'
        TabOrder = 5
        OnClick = btnCheckClick
      end
      object edtFilter: TEdit
        Left = 538
        Top = 2
        Width = 121
        Height = 21
        Anchors = [akTop, akRight]
        TabOrder = 6
        TextHint = '<filter>'
        OnChange = edtFilterChange
      end
      object vleTypeNamespaces: TValueListEditor
        Left = 3
        Top = 312
        Width = 656
        Height = 99
        Anchors = [akLeft, akRight, akBottom]
        KeyOptions = [keyUnique]
        Strings.Strings = (
          '=')
        TabOrder = 7
        TitleCaptions.Strings = (
          'Namespace'
          'Filename')
        OnSetEditText = vleTypeNamespacesSetEditText
        ColWidths = (
          240
          410)
      end
    end
    object tbshtPreview: TTabSheet
      Caption = 'Preview'
      ImageIndex = 2
      DesignSize = (
        611
        452)
      object lbWritePreview: TListBox
        Left = 3
        Top = 3
        Width = 656
        Height = 503
        Anchors = [akLeft, akTop, akRight, akBottom]
        ItemHeight = 13
        TabOrder = 0
      end
    end
  end
  object btnPrev: TButton
    Left = 503
    Top = 536
    Width = 75
    Height = 25
    Action = actnPrev
    Anchors = [akRight, akBottom]
    TabOrder = 1
  end
  object btnNext: TButton
    Left = 584
    Top = 536
    Width = 75
    Height = 25
    Action = actnNext
    Anchors = [akRight, akBottom]
    TabOrder = 2
  end
  object dlgSelectFile: TOpenDialog
    Filter = 'Soap Webservice definition (*.wsdl;*.xml)|*.wsdl;*.xml'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select webservice specification'
    Left = 328
    Top = 8
  end
  object alMain: TActionList
    Left = 232
    Top = 8
    object actnPrev: TAction
      Caption = 'Previous'
      OnExecute = actnPrevExecute
      OnUpdate = actnPrevUpdate
    end
    object actnNext: TAction
      Caption = 'Next/Finish'
      OnExecute = actnNextExecute
      OnUpdate = actnNextUpdate
    end
  end
  object dlgSelectFolder: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders, fdoPathMustExist]
    Title = 'Select output folder'
    Left = 232
    Top = 248
  end
  object tmrUpdateFilter: TTimer
    Enabled = False
    Interval = 250
    OnTimer = tmrUpdateFilterTimer
    Left = 304
    Top = 248
  end
end
