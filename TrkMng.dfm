object TrMng: TTrMng
  Left = 612
  Top = 278
  BorderStyle = bsToolWindow
  Caption = 'Tracks manager'
  ClientHeight = 209
  ClientWidth = 226
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 72
    Top = 22
    Width = 80
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = '<--Pattern-->'
  end
  object Label2: TLabel
    Left = 72
    Top = 46
    Width = 80
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = '<--Line-->'
  end
  object Label3: TLabel
    Left = 72
    Top = 70
    Width = 80
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = '<--Channel-->'
  end
  object GroupBox1: TGroupBox
    Left = 4
    Top = 0
    Width = 65
    Height = 97
    Caption = 'Location 1'
    TabOrder = 0
    object Edit2: TEdit
      Left = 8
      Top = 18
      Width = 33
      Height = 21
      Hint = 'Pattern number'
      TabOrder = 0
      Text = '0'
    end
    object UpDown1: TUpDown
      Left = 41
      Top = 18
      Width = 15
      Height = 21
      Hint = 'Pattern number'
      Associate = Edit2
      Max = 84
      TabOrder = 1
    end
    object Edit1: TEdit
      Left = 8
      Top = 42
      Width = 33
      Height = 21
      Hint = 'Start pattern line'
      TabOrder = 2
      Text = '0'
    end
    object UpDown2: TUpDown
      Left = 41
      Top = 42
      Width = 15
      Height = 21
      Hint = 'Start pattern line'
      Associate = Edit1
      Max = 99
      TabOrder = 3
    end
    object Edit6: TEdit
      Left = 8
      Top = 66
      Width = 33
      Height = 21
      Hint = 'Channel number: 0 - A; 1 - B; 2 - C'
      TabOrder = 4
      Text = 'A'
      OnKeyDown = Edit6_7KeyDown
      OnKeyPress = Edit6_7KeyPress
    end
    object UpDown6: TUpDown
      Left = 41
      Top = 66
      Width = 15
      Height = 21
      Hint = 'Channel number: 0 - A; 1 - B; 2 - C'
      Max = 2
      TabOrder = 5
      OnChangingEx = UpDown6_7ChangingEx
    end
  end
  object GroupBox2: TGroupBox
    Left = 156
    Top = 0
    Width = 65
    Height = 97
    Caption = 'Location 2'
    TabOrder = 1
    object Edit3: TEdit
      Left = 8
      Top = 18
      Width = 33
      Height = 21
      Hint = 'Pattern number'
      TabOrder = 0
      Text = '0'
    end
    object UpDown3: TUpDown
      Left = 41
      Top = 18
      Width = 15
      Height = 21
      Hint = 'Pattern number'
      Associate = Edit3
      Max = 84
      TabOrder = 1
    end
    object Edit4: TEdit
      Left = 8
      Top = 42
      Width = 33
      Height = 21
      Hint = 'Start pattern line'
      TabOrder = 2
      Text = '0'
    end
    object UpDown4: TUpDown
      Left = 41
      Top = 42
      Width = 15
      Height = 21
      Hint = 'Start pattern line'
      Associate = Edit4
      Max = 63
      TabOrder = 3
    end
    object Edit7: TEdit
      Left = 8
      Top = 66
      Width = 33
      Height = 21
      Hint = 'Channel number: 0 - A; 1 - B; 2 - C'
      TabOrder = 4
      Text = 'A'
      OnKeyDown = Edit6_7KeyDown
      OnKeyPress = Edit6_7KeyPress
    end
    object UpDown7: TUpDown
      Left = 41
      Top = 66
      Width = 15
      Height = 21
      Hint = 'Channel number: 0 - A; 1 - B; 2 - C'
      Max = 2
      TabOrder = 5
      OnChangingEx = UpDown6_7ChangingEx
    end
  end
  object GroupBox3: TGroupBox
    Left = 4
    Top = 98
    Width = 57
    Height = 36
    Caption = 'Copy'
    TabOrder = 2
    object SpeedButton1: TSpeedButton
      Left = 4
      Top = 16
      Width = 23
      Height = 16
      Caption = '<<'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = SpeedButton1Click
    end
    object SpeedButton2: TSpeedButton
      Left = 28
      Top = 16
      Width = 23
      Height = 16
      Caption = '>>'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = SpeedButton2Click
    end
  end
  object GroupBox4: TGroupBox
    Left = 62
    Top = 98
    Width = 57
    Height = 36
    Caption = 'Move'
    TabOrder = 3
    object SpeedButton3: TSpeedButton
      Left = 4
      Top = 16
      Width = 23
      Height = 16
      Caption = '<<'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = SpeedButton3Click
    end
    object SpeedButton4: TSpeedButton
      Left = 28
      Top = 16
      Width = 23
      Height = 16
      Caption = '>>'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = SpeedButton4Click
    end
  end
  object GroupBox5: TGroupBox
    Left = 120
    Top = 98
    Width = 57
    Height = 36
    Caption = 'Swap'
    TabOrder = 4
    object SpeedButton5: TSpeedButton
      Left = 4
      Top = 16
      Width = 49
      Height = 16
      Caption = '<<>>'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = SpeedButton5Click
    end
  end
  object GroupBox6: TGroupBox
    Left = 4
    Top = 133
    Width = 105
    Height = 73
    Caption = 'Area'
    TabOrder = 5
    object Label5: TLabel
      Left = 8
      Top = 18
      Width = 25
      Height = 13
      Caption = 'Lines'
    end
    object CheckBox1: TCheckBox
      Left = 7
      Top = 36
      Width = 94
      Height = 17
      Caption = 'Envelope track'
      TabOrder = 0
    end
    object CheckBox2: TCheckBox
      Left = 7
      Top = 52
      Width = 94
      Height = 17
      Caption = 'Noise track'
      TabOrder = 1
    end
    object Edit5: TEdit
      Left = 39
      Top = 14
      Width = 33
      Height = 21
      Hint = 'Number of pattern lines for operation'
      TabOrder = 2
      Text = '100'
    end
    object UpDown5: TUpDown
      Left = 72
      Top = 14
      Width = 15
      Height = 21
      Hint = 'Number of pattern lines for operation'
      Associate = Edit5
      Min = 1
      Position = 100
      TabOrder = 3
    end
  end
  object Button1: TButton
    Left = 180
    Top = 100
    Width = 41
    Height = 33
    Cancel = True
    Caption = 'Close'
    Default = True
    ModalResult = 1
    TabOrder = 6
    OnClick = Button1Click
  end
  object GroupBox7: TGroupBox
    Left = 108
    Top = 133
    Width = 113
    Height = 73
    Caption = 'Transposition'
    TabOrder = 7
    object Label8: TLabel
      Left = 8
      Top = 18
      Width = 49
      Height = 13
      Caption = 'Semitones'
    end
    object SpeedButton6: TSpeedButton
      Left = 7
      Top = 37
      Width = 97
      Height = 17
      Caption = 'Location 1'
      OnClick = SpeedButton6Click
    end
    object SpeedButton7: TSpeedButton
      Left = 7
      Top = 53
      Width = 97
      Height = 17
      Caption = 'Location 2'
      OnClick = SpeedButton7Click
    end
    object Edit8: TEdit
      Left = 64
      Top = 14
      Width = 25
      Height = 21
      Hint = 
        'Number of semitones to transpose: positive - up and negative - d' +
        'own'
      TabOrder = 0
      Text = '0'
    end
    object UpDown8: TUpDown
      Left = 89
      Top = 14
      Width = 15
      Height = 21
      Hint = 
        'Number of semitones to transpose: positive - up and negative - d' +
        'own'
      Associate = Edit8
      Min = -95
      Max = 95
      TabOrder = 1
    end
  end
end
