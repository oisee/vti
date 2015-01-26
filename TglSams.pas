unit TglSams;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TToglSams = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure CheckBoxClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ToglSams: TToglSams;
  TogSam: array[1..31] of TCheckBox;

implementation

uses Main, Childwin, trfuncs;

{$R *.dfm}

procedure TToglSams.FormCreate(Sender: TObject);
var
  i, y, x: integer;
begin
  y := 8; x := 8;
  for i := 1 to 31 do
  begin
    TogSam[i] := TCheckBox.Create(Self);
    with TogSam[i] do
    begin
      Parent := Self;
      Top := y; inc(y, Height + 8);
      Left := x; if i mod 8 = 0 then begin inc(x, 40); y := 8; end;
      Caption := SampToStr(i);
      Width := 32;
      Tag := i;
      Checked := True;
      OnClick := CheckBoxClick;
    end;
  end;
  ClientWidth := 4 * 40 + 4;
  ClientHeight := 8 * (TogSam[1].Height + 8) + 8;
end;

procedure TToglSams.CheckBoxClick(Sender: TObject);
var
  CurrentWindow: TMDIChild;
  sam: integer;
begin
  if MainForm.MDIChildCount = 0 then exit;
  CurrentWindow := TMDIChild(MainForm.ActiveMDIChild);
  with CurrentWindow do
    if VTMP <> nil then
    begin
      sam := (Sender as TCheckBox).Tag;
      ValidateSample2(sam);
      VTMP.Samples[sam].Enabled := (Sender as TCheckBox).Checked;
    end;
end;

procedure TToglSams.FormHide(Sender: TObject);
var
  i, j: integer;
  sam: PSample;
  VTM: PModule;
begin
  if MainForm.MDIChildCount = 0 then exit;
  for i := 0 to MainForm.MDIChildCount - 1 do
  begin
    VTM := TMDIChild(MainForm.MDIChildren[i]).VTMP;
    if VTM <> nil then
      for j := 1 to 31 do
      begin
        sam := VTM.Samples[j];
        if sam <> nil then sam.Enabled := True;
      end;
  end;
end;

end.
