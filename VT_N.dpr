{
This is part of Vortex Tracker II project
(c)2000-2009 S.V.Bulba
Author Sergey Bulba
E-mail: vorobey@mail.khstu.ru
Support page: http://bulba.untergrund.net/
}

program VT_N;

uses
  Forms,
  Main in 'main.pas' {MainForm},
  Childwin in 'CHILDWIN.PAS' {MDIChild},
  About in 'about.pas' {AboutBox},
  trfuncs in 'trfuncs.pas',
  AY in 'AY.pas',
  WaveOutAPI in 'WaveOutAPI.pas',
  options in 'options.pas' {Form1},
  TrkMng in 'TrkMng.pas' {TrMng},
  GlbTrn in 'GlbTrn.pas' {GlbTrans},
  ExportZX in 'ExportZX.pas' {ExpDlg},
  FXMImport in 'FXMImport.pas' {FXMParams},
  selectts in 'selectts.pas' {TSSel},
  TglSams in 'TglSams.pas' {ToglSams};

{$R *.RES}
{$R SNDH\SNDH.RES}
{$R ZXAYHOBETA\ZX.RES}

begin
  Application.Initialize;
  Application.Title := 'Vortex Tracker II';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TTrMng, TrMng);
  Application.CreateForm(TGlbTrans, GlbTrans);
  Application.CreateForm(TExpDlg, ExpDlg);
  Application.CreateForm(TFXMParams, FXMParams);
  Application.CreateForm(TTSSel, TSSel);
  Application.CreateForm(TToglSams, ToglSams);
  MainForm.CheckCommandLine;
  Application.Run;
end.

