{
This is part of Vortex Tracker II project
(c)2000-2009 S.V.Bulba
Author Sergey Bulba
E-mail: vorobey@mail.khstu.ru
Support page: http://bulba.untergrund.net/
}

unit WaveOutAPI;

interface

uses Windows, Messages, MMSystem, SysUtils, Forms, trfuncs;

type
//Digital sound data buffer
  TWaveOutBuffer = packed array of byte;

const
  NumberOfBuffersDef = 3;
  BufLen_msDef = 100; //726;
  WODevice: DWORD = WAVE_MAPPER;

var
  NumberOfBuffers, BufferLength, BuffLen, BufLen_ms: integer;
  NOfTicks: DWORD;
  IsPlaying: boolean = False;
  Reseted: boolean = False;
  Interrupt_Freq, NumberOfChannels, SampleRate, SampleBit: integer;
  PlayingGrid: array of record
    M1, M2: integer;
  end;
  MkVisPos, VisPosMax, VisPoint, VisStep, VisTickMax: DWORD;
  ResetMutex: THandle;
  HWO: HWAVEOUT;
  waveOutBuffers: array of record
    Buf: TWaveOutBuffer;
    WH: WAVEHDR;
  end;
  LineReady: boolean;

procedure InitForAllTypes(All: boolean);
procedure StartWOThread;
procedure WOThreadFinalization;
procedure StopPlaying;
procedure WOCheck(Res: MMRESULT);
procedure ResetAYChipEmulation(chip: integer);
function WOThreadActive: boolean;
procedure ResetPlaying;
procedure UnresetPlaying;

implementation

uses AY, Childwin, Main;

var
  WOEventH: THANDLE;
  WOThreadID: DWORD;
  WOThreadH: THANDLE = 0;
  WOCS: RTL_CRITICAL_SECTION;

  TSEventH: THANDLE;
  TSThreadID: DWORD;
  TSThreadH: THANDLE;

type
  EMultiMediaError = class(Exception);

procedure WOCheck(Res: MMRESULT);
var
  ErrMsg: array[0..255] of Char;
begin
  if Res <> 0 then
  begin
    EnterCriticalSection(WOCS);
    waveOutGetErrorText(Res, ErrMsg, SizeOf(ErrMsg));
    LeaveCriticalSection(WOCS);
    raise EMultiMediaError.Create(ErrMsg)
  end
end;

function TSThreadFunc(a: pointer): dword; stdcall;
var
  CurVisPos, t: DWORD;
  MMTIME1: MMTime;
begin
  while WaitForSingleObject(TSEventH, 0) <> WAIT_OBJECT_0 do
  begin
    if IsPlaying and WOThreadActive and (PlayMode in [PMPlayModule, PMPlayPattern]) then
    begin
      t := GetTickCount;
      MMTIME1.wType := TIME_SAMPLES;
      EnterCriticalSection(WOCS);
      waveOutGetPosition(HWO, @MMTIME1, sizeof(MMTIME1));
      LeaveCriticalSection(WOCS);
      if MMTIME1.sample <> 0 then //if woReseted then don't redraw
      begin
        CurVisPos := MMTIME1.sample mod VisTickMax div VisStep;
      //SendMessage directly call message function (no thread-safe}
      {SendMessage} PostMessage(MainForm.Handle, UM_REDRAWTRACKS,
          PlayingGrid[CurVisPos].M1, PlayingGrid[CurVisPos].M2);
      end;
      Inc(t, 20 - GetTickCount);
      if integer(t) < 0 then
        t := 0;
      Sleep(t)
    end
    else
      Sleep(20)
  end;
  Result := STILL_ACTIVE - 1;
end;

procedure StartTrackSlider;
begin
  TSEventH := CreateEvent(nil, False, False, nil);
  TSThreadH := CreateThread(nil, 0, @TSThreadFunc, nil, 0, TSThreadID)
end;

procedure SkipRedraw;
var
  msg: TMsg;
begin
  Sleep(0);
  if PlayMode in [PMPlayModule, PMPlayPattern] then
    PeekMessage(msg, MainForm.Handle, UM_REDRAWTRACKS, UM_REDRAWTRACKS, PM_REMOVE);
end;

procedure StopTrackSlider;
var
  ExCode: DWORD;
begin
  SetEvent(TSEventH);
  repeat
    if not GetExitCodeThread(TSThreadH, ExCode) then break;
    if ExCode = STILL_ACTIVE then SkipRedraw;
  until ExCode <> STILL_ACTIVE;
  CloseHandle(TSThreadH);
  CloseHandle(TSEventH);
end;

procedure WaitForWOThreadExit;
var
  ExCode: DWORD;
begin
  if WOThreadH = 0 then exit;
  repeat
    if not GetExitCodeThread(WOThreadH, ExCode) then break;
    if ExCode = STILL_ACTIVE then Sleep(0);
  until ExCode <> STILL_ACTIVE;
  CloseHandle(WOThreadH);
  WOThreadH := 0
end;

procedure StopPlaying;
var
  msg: TMsg;
begin
  if WOThreadActive then
  begin
    IsPlaying := False;
    ResetPlaying;
    UnresetPlaying;
    SetEvent(WOEventH);
    WaitForWOThreadExit;
    while not PeekMessage(msg, MainForm.Handle,
      UM_FINALIZEWO, UM_FINALIZEWO, PM_REMOVE) do Sleep(0);
    WOThreadFinalization
  end
end;

function WOThreadFunc(a: pointer): dword; stdcall;

  function AllBuffersDone: boolean;
  var
    i: integer;
  begin
    Result := False;
    for i := 0 to NumberOfBuffers - 1 do
      if waveOutBuffers[i].WH.dwFlags and WHDR_DONE = 0 then exit;
    Result := True
  end;

var
  i, j, SampleSize: integer;
  mut: boolean;
begin
  SampleSize := (SampleBit div 8) * NumberOfChannels;
  mut := False;
  try
    repeat
      WaitForSingleObject(ResetMutex, INFINITE);
      mut := True;
      if not Real_End_All then
      begin
        for i := 0 to NumberOfBuffers - 1 do
          with waveOutBuffers[i] do
          begin
            if Reseted then break;
            if not IsPlaying then break;
            if WH.dwFlags and WHDR_DONE <> 0 then
            begin
              MakeBuffer(WH.lpdata);
              if Reseted then break;
              if not IsPlaying then break;
              if BuffLen = 0 then
              begin
                if AllBuffersDone then break
              end
              else
              begin
                WH.dwBufferLength := BuffLen * SampleSize;
                WH.dwFlags := WH.dwFlags and not WHDR_DONE;
                EnterCriticalSection(WOCS);
                try
                  WOCheck(waveOutWrite(HWO, @WH, sizeof(WAVEHDR)))
                finally
                  LeaveCriticalSection(WOCS);
                end
              end
            end
          end
      end;
      if Real_End_All and not Reseted and AllBuffersDone then break;
      mut := False;
      ReleaseMutex(ResetMutex);
      if not IsPlaying then break;
      j := WaitForSingleObject(WOEventH, BufLen_ms);
      if (j <> WAIT_OBJECT_0) and (j <> WAIT_TIMEOUT) then break
    until not IsPlaying
  finally
    if mut then
      ReleaseMutex(ResetMutex);
    PostMessage(MainForm.Handle, UM_FINALIZEWO, 0, 0);
    Result := STILL_ACTIVE - 1
  end
end;

procedure StartWOThread;
var
  pwfx: pcmwaveformat;
  i, bl: integer;
begin
  if WOThreadActive then exit;
  with pwfx.wf do
  begin
    wFormatTag := 1;
    nChannels := NumberOfChannels;
    nSamplesPerSec := SampleRate;
    nBlockAlign := (SampleBit div 8) * NumberOfChannels;
    nAvgBytesPerSec := SampleRate * pwfx.wf.nBlockAlign;
  end;
  pwfx.wBitsPerSample := SampleBit;
  try
    WOCheck(waveOutOpen(@HWO, WODevice, @pwfx, WOEventH, 0, CALLBACK_EVENT));
  except
    PostMessage(MainForm.Handle, UM_PLAYINGOFF, 0, 0);
    ShowException(ExceptObject, ExceptAddr);
    exit;
  end;
  WaitForSingleObject(WOEventH, INFINITE);
  try
    bl := BufferLength * pwfx.wf.nBlockAlign;
    for i := 0 to NumberOfBuffers - 1 do
      with waveOutBuffers[i] do
      begin
        SetLength(Buf, bl);
        with WH do
        begin
          lpdata := @Buf[0];
          dwBufferLength := bl;
          dwFlags := 0;
          dwUser := 0;
          dwLoops := 0;
        end;
        WOCheck(waveOutPrepareHeader(HWO, @WH, sizeof(WAVEHDR)));
        WH.dwFlags := WH.dwFlags or WHDR_DONE;
      end
  except
    PostMessage(MainForm.Handle, UM_PLAYINGOFF, 0, 0);
    ShowException(ExceptObject, ExceptAddr);
    WOCheck(waveOutClose(HWO));
    exit;
  end;

  StartTrackSlider;

  IsPlaying := True;
  Reseted := False;
  WOThreadH := CreateThread(nil, 0, @WOThreadFunc, nil, 0, WOThreadID)
end;

procedure WOThreadFinalization;
var
  i: integer;
begin
  WaitForWOThreadExit;
  StopTrackSlider;

  try
    WOCheck(waveOutReset(HWO));
    for i := 0 to NumberOfBuffers - 1 do
      with waveOutBuffers[i] do
      begin
        while WH.dwFlags and WHDR_DONE = 0 do Sleep(0);
        if WH.dwFlags and WHDR_PREPARED <> 0 then
          WOCheck(waveOutUnprepareHeader(HWO, @WH, sizeof(WAVEHDR)));
        Buf := nil
      end;
    WOCheck(waveOutClose(HWO));
  except
    ShowException(ExceptObject, ExceptAddr);
  end;

  IsPlaying := False;
  Reseted := False

end;

procedure ResetAYChipEmulation;
begin
  with SoundChip[chip] do
  begin
    FillChar(AYRegisters, 14, 0);
    SetEnvelopeRegister(0);
    First_Period := False;
    Ampl := 0;
    SetMixerRegister(0);
    SetAmplA(0);
    SetAmplB(0);
    SetAmplC(0);
    IntFlag := False;
    Number_Of_Tiks.Re := 0;
    Current_Tik := 0;
    Envelope_Counter.Re := 0;
    Ton_Counter_A.Re := 0;
    Ton_Counter_B.Re := 0;
    Ton_Counter_C.Re := 0;
    Noise_Counter.Re := 0;
    Ton_A := 0;
    Ton_B := 0;
    Ton_C := 0;
    Left_Chan := 0; Right_Chan := 0; Tick_Counter := 0;
    Tik.Re := Delay_In_Tiks;
    Noise.Seed := $FFFF;
    Noise.Val := 0
  end
end;

procedure InitForAllTypes;
var
  i: integer;
begin
  LineReady := False;
  MkVisPos := 0;
  VisPoint := 0;
  NOfTicks := 0;
  for i := 1 to NumberOfSoundChips do
  begin
    ResetAYChipEmulation(i);
    Real_End[i] := False;
  end;
  Real_End_All := False;
  if Optimization_For_Quality and IsFilt then
  begin
    FillChar(Filt_XL[0], (Filt_M + 1) * 4, 0);
    FillChar(Filt_XR[0], (Filt_M + 1) * 4, 0);
    Filt_I := 0;
  end;
  for i := NumberOfSoundChips downto 1 do
  begin
    Module_SetPointer(PlayingWindow[i].VTMP, i);
    InitTrackerParameters(All);
  end;
end;

function WOThreadActive;
var
  ExCode: DWORD;
begin
  Result := (WOThreadH <> 0) and
    GetExitCodeThread(WOThreadH, ExCode) and
    (ExCode = STILL_ACTIVE);
  if not Result then
    if WOThreadH <> 0 then
    begin
      CloseHandle(WOThreadH);
      WOThreadH := 0
    end
end;

procedure ResetPlaying;
var
  i: integer;
begin
  if Reseted then exit;
  Reseted := True;
  WaitForSingleObject(ResetMutex, INFINITE);
  EnterCriticalSection(WOCS);
  WOCheck(waveOutReset(HWO));
  LeaveCriticalSection(WOCS);
  MkVisPos := 0;
  VisPoint := 0;
  NOfTicks := 0;
  for i := 0 to NumberOfBuffers - 1 do
    with waveOutBuffers[i] do
      while WH.dwFlags and WHDR_DONE = 0 do Sleep(0)
end;

procedure UnresetPlaying;
begin
  if Reseted then
  begin
    SetEvent(WOEventH);
    Reseted := False;
    ReleaseMutex(ResetMutex)
  end
end;

initialization

  WOEventH := CreateEvent(nil, False, False, nil);
  InitializeCriticalSection(WOCS);

finalization

  DeleteCriticalSection(WOCS);
  CloseHandle(WOEventH);

end.
