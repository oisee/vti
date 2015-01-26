object TSSel: TTSSel
  Left = 443
  Top = 290
  Width = 412
  Height = 331
  BorderIcons = [biSystemMenu]
  Caption = 'Select module for Turbo Sound mode'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 404
    Height = 297
    Align = alClient
    ItemHeight = 13
    TabOrder = 0
    OnKeyPress = ListBox1KeyPress
    OnMouseUp = ListBox1MouseUp
  end
end
