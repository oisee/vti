{
This is part of Vortex Tracker II project
(c)2000-2009 S.V.Bulba
Author Sergey Bulba
E-mail: vorobey@mail.khstu.ru
Support page: http://bulba.untergrund.net/
}

unit AY;

interface

uses Windows, trfuncs, WaveOutAPI;

type
//Available soundchips
  ChTypes = (No_Chip, AY_Chip, YM_Chip);
  TPlayModes = (PMPlayModule, PMPlayPattern, PMPlayLine);

const
//Two amplitude tables of sound chips (c)Hacker KAY
  Amplitudes_AY: array[0..15] of Word =
  (0, 836, 1212, 1773, 2619, 3875, 5397, 8823, 10392, 16706, 23339,
    29292, 36969, 46421, 55195, 65535);
  Amplitudes_YM: array[0..31] of Word =
  (0, 0, $F8, $1C2, $29E, $33A, $3F2, $4D7, $610, $77F, $90A, $A42,
    $C3B, $EC2, $1137, $13A7, $1750, $1BF9, $20DF, $2596, $2C9D, $3579,
    $3E55, $4768, $54FF, $6624, $773B, $883F, $A1DA, $C0FC, $E094, $FFFF);

  AY_Freq_Def = 1750000; //1773400;
  Interrupt_Freq_Def = 48828; //50000;
  NumberOfChannels_Def = 2;
  SampleRate_Def = 44100;
  SampleBit_Def = 16;
  Index_AL_Def = 255;
  Index_AR_Def = 13;
  Index_BL_Def = 170;
  Index_BR_Def = 170;
  Index_CL_Def = 13;
  Index_CR_Def = 255;
  StdChannelsAllocationDef = 1;
  Filt_NKoefs = 32; //powers of 2

type
  TRegisters = packed record
    case Boolean of
      True: (Index: array[0..13] of byte);
      False: (TonA, TonB, TonC: word;
        Noise, Mixer: byte;
        AmplitudeA, AmplitudeB, AmplitudeC: byte;
        Envelope: word;
        EnvType: byte);
  end;
  TSoundChip = object
    AYRegisters: TRegisters;
    First_Period: boolean;
    Ampl: integer;
    Ton_Counter_A, Ton_Counter_B, Ton_Counter_C, Noise_Counter: packed record
      case integer of
        0: (Lo: word;
          Hi: word);
        1: (Re: longword);
    end;
    Envelope_Counter: packed record
      case integer of
        0: (Lo: dword;
          Hi: dword);
        1: (Re: int64);
    end;
    Ton_A, Ton_B, Ton_C: integer;
    Noise: packed record
      case boolean of
        True: (Seed: longword);
        False: (Low: word;
          Val: dword);
    end;
    Case_EnvType: procedure of object;
    Ton_EnA, Ton_EnB, Ton_EnC, Noise_EnA, Noise_EnB, Noise_EnC: boolean;
    Envelope_EnA, Envelope_EnB, Envelope_EnC: boolean;
    procedure Case_EnvType_0_3__9;
    procedure Case_EnvType_4_7__15;
    procedure Case_EnvType_8;
    procedure Case_EnvType_10;
    procedure Case_EnvType_11;
    procedure Case_EnvType_12;
    procedure Case_EnvType_13;
    procedure Case_EnvType_14;
    procedure Synthesizer_Logic_Q;
    procedure Synthesizer_Logic_P;
    procedure SetMixerRegister(Value: byte);
    procedure SetEnvelopeRegister(Value: byte);
    procedure SetAmplA(Value: byte);
    procedure SetAmplB(Value: byte);
    procedure SetAmplC(Value: byte);
    procedure Synthesizer_Mixer_Q;
    procedure Synthesizer_Mixer_Q_Mono;

  end;
  TFilt_K = array of integer;
var
  Filt_M: integer = Filt_NKoefs;
  IsFilt: boolean = True;
  Filt_K, Filt_XL, Filt_XR: TFilt_K;
  Filt_I: integer;
  PlayMode: TPlayModes;

  NumberOfSoundChips: integer = MaxNumberOfSoundChips;

 //Sound chip parameters
  SoundChip: array[1..MaxNumberOfSoundChips] of TSoundChip;

 //Parameters for all sound chips
  Index_AL, Index_AR, Index_BL, Index_BR, Index_CL, Index_CR: byte;
  Emulating_Chip: ChTypes;
  AY_Freq: integer;
  Level_AR, Level_AL, Level_BR, Level_BL, Level_CR, Level_CL: array[0..31] of Integer;
  LevelL, LevelR, Left_Chan, Right_Chan: integer;
  Tick_Counter: byte;
  Tik: packed record
    case Integer of
      0: (Lo: Word;
        Hi: word);
      1: (Re: dword);
  end;
  Delay_in_tiks: dword;
  Current_Tik: longword;
  Number_Of_Tiks: packed record
    case boolean of
      false: (lo: longword;
        hi: longword);
      true: (re: int64);
  end;
  IntFlag: boolean;
  AY_Tiks_In_Interrupt, Sample_Tiks_in_Interrupt: longword;
  Synthesizer: procedure(Buf: pointer);
  StdChannelsAllocation: integer;

  Real_End: array[1..MaxNumberOfSoundChips] of boolean;
  Real_End_All, LoopAllowed: boolean;


(*type
 TFilt_K = array of integer;
var
 Filt_M:integer = Filt_NKoefs;
 IsFilt:boolean = True;
 Filt_K,Filt_XL,Filt_XR:TFilt_K;
 Filt_I:integer;
 PlayMode:TPlayModes;
 Index_AL,Index_AR,Index_BL,Index_BR,Index_CL,Index_CR:byte;
 Emulating_Chip:ChTypes;
 AY_Freq:integer;
 First_Period:boolean;
 Ampl:integer;
 Ton_Counter_A,
 Ton_Counter_B,
 Ton_Counter_C,
 Noise_Counter:packed record
     case integer of
      0:(Lo:word;
         Hi:word);
      1:(Re:longword);
     end;
 Envelope_Counter:packed record
     case integer of
     0:(Lo:dword;
        Hi:dword);
     1:(Re:int64);
     end;
 Ton_A,Ton_B,Ton_C:integer;
 Noise:packed record
     case boolean of
      True: (Seed:longword);
      False:(Low:word;
             Val:dword);
     end;
 Level_AR,Level_AL,
 Level_BR,Level_BL,
 Level_CR,Level_CL:array[0..31]of Integer;
 Left_Chan,Right_Chan:integer;
 Tick_Counter:byte;
 Tik:packed record
     Case Integer of
      0:(Lo:Word;
         Hi:word);
      1:(Re:dword);
     end;
 Delay_in_tiks:dword;
 Case_EnvType:procedure;
 Ton_EnA,Ton_EnB,
 Ton_EnC,Noise_EnA,
 Noise_EnB,Noise_EnC:boolean;
 Envelope_EnA,Envelope_EnB,Envelope_EnC:boolean;
 Current_Tik:longword;*)
  Optimization_For_Quality: boolean = True;
(* Number_Of_Tiks:packed record
     case boolean of
      false:(lo:longword;
             hi:longword);
      true: (re:int64);
     end;
 IntFlag:boolean;
 AY_Tiks_In_Interrupt,Sample_Tiks_in_Interrupt:longword;
 Synthesizer:procedure(Buf:pointer);
 Real_End,LoopAllowed:boolean;
 StdChannelsAllocation:integer;*)

procedure Synthesizer_Stereo16(Buf: pointer);
procedure Synthesizer_Stereo16_P(Buf: pointer);
procedure Synthesizer_Stereo8(Buf: pointer);
procedure Synthesizer_Stereo8_P(Buf: pointer);
procedure Synthesizer_Mono16(Buf: pointer);
procedure Synthesizer_Mono16_P(Buf: pointer);
procedure Synthesizer_Mono8(Buf: pointer);
procedure Synthesizer_Mono8_P(Buf: pointer);
procedure MakeBuffer(Buf: pointer);
(*procedure SetEnvelopeRegister(Value:byte);
procedure SetMixerRegister(Value:byte);
procedure SetAmplA(Value:byte);
procedure SetAmplB(Value:byte);
procedure SetAmplC(Value:byte);*)
procedure SetDefault(samrate, nchan, sambit: integer);
procedure Calculate_Level_Tables;
function ToggleChanMode: string;
function SetStdChannelsAllocation(CA: integer): string;
procedure SetIntFreq(f: integer);
procedure SetSampleRate(f: integer);
procedure SetBuffers(len, num: integer);
procedure SetBitRate(SB: integer);
procedure SetNChans(St: integer);
procedure Set_Optimization(Q: boolean);
procedure SetAYFreq(f: integer);
procedure SetFilter(Filt: boolean; M: integer);
procedure CalcFiltKoefs;

implementation

uses Childwin, Main;

type
  TS16 = packed array[0..0] of record
    Left: smallint;
    Right: smallint;
  end;
  PS16 = ^TS16;
  TS8 = packed array[0..0] of record
    Left: byte;
    Right: byte;
  end;
  PS8 = ^TS8;
  TM16 = packed array[0..0] of smallint;
  PM16 = ^TM16;
  TM8 = packed array[0..0] of byte;
  PM8 = ^TM8;

procedure TSoundChip.Case_EnvType_0_3__9;
begin
  if First_Period then
  begin
    dec(Ampl);
    if Ampl = 0 then First_Period := False
  end
end;

procedure TSoundChip.Case_EnvType_4_7__15;
begin
  if First_Period then
  begin
    Inc(Ampl);
    if Ampl = 32 then
    begin
      First_Period := False;
      Ampl := 0
    end
  end
end;

procedure TSoundChip.Case_EnvType_8;
begin
  Ampl := (Ampl - 1) and 31
end;

procedure TSoundChip.Case_EnvType_10;
begin
  if First_Period then
  begin
    dec(Ampl);
    if Ampl < 0 then
    begin
      First_Period := False;
      Ampl := 0
    end
  end
  else
  begin
    inc(Ampl);
    if Ampl = 32 then
    begin
      First_Period := True;
      Ampl := 31
    end
  end
end;

procedure TSoundChip.Case_EnvType_11;
begin
  if First_Period then
  begin
    dec(Ampl);
    if Ampl < 0 then
    begin
      First_Period := False;
      Ampl := 31
    end
  end
end;

procedure TSoundChip.Case_EnvType_12;
begin
  Ampl := (Ampl + 1) and 31
end;

procedure TSoundChip.Case_EnvType_13;
begin
  if First_Period then
  begin
    inc(Ampl);
    if Ampl = 32 then
    begin
      First_Period := False;
      Ampl := 31
    end
  end
end;

procedure TSoundChip.Case_EnvType_14;
begin
  if not First_Period then
  begin
    dec(Ampl);
    if Ampl < 0 then
    begin
      First_Period := True;
      Ampl := 0
    end
  end
  else
  begin
    inc(Ampl);
    if Ampl = 32 then
    begin
      First_Period := False;
      Ampl := 31
    end
  end
end;

function NoiseGenerator(Seed: integer): integer;
asm
 shld edx,eax,16
 shld ecx,eax,19
 xor ecx,edx
 and ecx,1
 add eax,eax
 and eax,$1ffff
 inc eax
 xor eax,ecx
end;

procedure TSoundChip.Synthesizer_Logic_Q;
begin
  inc(Ton_Counter_A.Hi);
  if Ton_Counter_A.Hi >= AYRegisters.TonA then
  begin
    Ton_Counter_A.Hi := 0;
    Ton_A := Ton_A xor 1
  end;
  inc(Ton_Counter_B.Hi);
  if Ton_Counter_B.Hi >= AYRegisters.TonB then
  begin
    Ton_Counter_B.Hi := 0;
    Ton_B := Ton_B xor 1
  end;
  inc(Ton_Counter_C.Hi);
  if Ton_Counter_C.Hi >= AYRegisters.TonC then
  begin
    Ton_Counter_C.Hi := 0;
    Ton_C := Ton_C xor 1
  end;
  inc(Noise_Counter.Hi);
  if (Noise_Counter.Hi and 1 = 0) and
    (Noise_Counter.Hi >= AYRegisters.Noise shl 1) then
  begin
    Noise_Counter.Hi := 0;
    Noise.Seed := NoiseGenerator(Noise.Seed);
  end;
  if Envelope_Counter.Hi = 0 then Case_EnvType;
  inc(Envelope_Counter.Hi);
  if Envelope_Counter.Hi >= AYRegisters.Envelope then
    Envelope_Counter.Hi := 0
end;

procedure TSoundChip.Synthesizer_Logic_P;
var
  k: word;
  k2: longword;
begin

  inc(Ton_Counter_A.Re, Delay_In_Tiks);
  k := AYRegisters.TonA; if k = 0 then inc(k);
  if k <= Ton_Counter_A.Hi then
  begin
    Ton_A := Ton_A xor ((Ton_Counter_A.Hi div k) and 1);
    Ton_Counter_A.Hi := Ton_Counter_A.Hi mod k
  end;

  inc(Ton_Counter_B.Re, Delay_In_Tiks);
  k := AYRegisters.TonB; if k = 0 then inc(k);
  if k <= Ton_Counter_B.Hi then
  begin
    Ton_B := Ton_B xor ((Ton_Counter_B.Hi div k) and 1);
    Ton_Counter_B.Hi := Ton_Counter_B.Hi mod k
  end;

  inc(Ton_Counter_C.Re, Delay_In_Tiks);
  k := AYRegisters.TonC; if k = 0 then inc(k);
  if k <= Ton_Counter_C.Hi then
  begin
    Ton_C := Ton_C xor ((Ton_Counter_C.Hi div k) and 1);
    Ton_Counter_C.Hi := Ton_Counter_C.Hi mod k
  end;

  inc(Noise_Counter.Re, Delay_In_Tiks);
  k := AYRegisters.Noise; if k = 0 then inc(k);
  k := k shl 1;
  if Noise_Counter.Hi >= k then
  begin
    Noise_Counter.Hi := Noise_Counter.Hi mod k;
    Noise.Seed := NoiseGenerator(Noise.Seed);
  end;

  k2 := AYRegisters.Envelope; if k2 = 0 then inc(k2);
  if Envelope_Counter.Hi = 0 then inc(Envelope_Counter.Hi, k2);
  while (Envelope_Counter.Hi >= k2) do
  begin
    dec(Envelope_Counter.Hi, k2);
    Case_EnvType
  end;
  inc(Envelope_Counter.Re, int64(Delay_In_Tiks) shl 16)
end;

procedure TSoundChip.SetMixerRegister(Value: byte);
begin
  AYRegisters.Mixer := Value;
  Ton_EnA := (Value and 1) = 0;
  Noise_EnA := (Value and 8) = 0;
  Ton_EnB := (Value and 2) = 0;
  Noise_EnB := (Value and 16) = 0;
  Ton_EnC := (Value and 4) = 0;
  Noise_EnC := (Value and 32) = 0
end;

procedure TSoundChip.SetEnvelopeRegister(Value: byte);
begin
  Envelope_Counter.Hi := 0;
  First_Period := True;
  if (Value and 4) = 0 then
    ampl := 32
  else
    ampl := -1;
  AYRegisters.EnvType := Value;
  case Value of
    0..3, 9: Case_EnvType := Case_EnvType_0_3__9;
    4..7, 15: Case_EnvType := Case_EnvType_4_7__15;
    8: Case_EnvType := Case_EnvType_8;
    10: Case_EnvType := Case_EnvType_10;
    11: Case_EnvType := Case_EnvType_11;
    12: Case_EnvType := Case_EnvType_12;
    13: Case_EnvType := Case_EnvType_13;
    14: Case_EnvType := Case_EnvType_14;
  end;
end;

procedure TSoundChip.SetAmplA(Value: byte);
begin
  AYRegisters.AmplitudeA := Value;
  Envelope_EnA := (Value and 16) = 0;
end;

procedure TSoundChip.SetAmplB(Value: byte);
begin
  AYRegisters.AmplitudeB := Value;
  Envelope_EnB := (Value and 16) = 0;
end;

procedure TSoundChip.SetAmplC(Value: byte);
begin
  AYRegisters.AmplitudeC := Value;
  Envelope_EnC := (Value and 16) = 0;
end;

//sorry for assembler, I can't make effective qword procedure on pascal...

function ApplyFilter(Lev: integer; var Filt_X: TFilt_K): integer;
asm
        push    ebx
        push    esi
        push    edi
        add     esp,-8
        mov     ecx,Filt_M
        mov     edi,Filt_K
        lea     esi,edi+ecx*4
        mov     ebx,[edx]
        mov     ecx,Filt_I
        mov     [ebx+ecx*4],eax
        imul    dword ptr [edi]
        mov     [esp],eax
        mov     [esp+4],edx
@lp:    dec     ecx
        jns     @gz
        mov     ecx,Filt_M
@gz:    mov     eax,[ebx+ecx*4]
        add     edi,4
        imul    dword ptr [edi]
        add     [esp],eax
        adc     [esp+4],edx
        cmp     edi,esi
        jnz     @lp
        mov     Filt_I,ecx
        pop     eax
        pop     edx
        pop     edi
        pop     esi
        pop     ebx
        test    edx,edx
        jns     @nm
        add     eax,0FFFFFFh
        adc     edx,0
@nm:    shrd    eax,edx,24
end;

procedure TSoundChip.Synthesizer_Mixer_Q;
var
  LevL, LevR, k: integer;
begin
  LevL := 0;
  LevR := LevL;

  k := 1;
  if Ton_EnA then k := Ton_A;
  if Noise_EnA then k := k and Noise.Val;
  if k <> 0 then
  begin
    if Envelope_EnA then
    begin
      inc(LevL, Level_AL[AYRegisters.AmplitudeA * 2 + 1]);
      inc(LevR, Level_AR[AYRegisters.AmplitudeA * 2 + 1])
    end
    else
    begin
      inc(LevL, Level_AL[Ampl]);
      inc(LevR, Level_AR[Ampl])
    end
  end;

  k := 1;
  if Ton_EnB then k := Ton_B;
  if Noise_EnB then k := k and Noise.Val;
  if k <> 0 then
    if Envelope_EnB then
    begin
      inc(LevL, Level_BL[AYRegisters.AmplitudeB * 2 + 1]);
      inc(LevR, Level_BR[AYRegisters.AmplitudeB * 2 + 1])
    end
    else
    begin
      inc(LevL, Level_BL[Ampl]);
      inc(LevR, Level_BR[Ampl])
    end;

  k := 1;
  if Ton_EnC then k := Ton_C;
  if Noise_EnC then k := k and Noise.Val;
  if k <> 0 then
    if Envelope_EnC then
    begin
      inc(LevL, Level_CL[AYRegisters.AmplitudeC * 2 + 1]);
      inc(LevR, Level_CR[AYRegisters.AmplitudeC * 2 + 1])
    end
    else
    begin
      inc(LevL, Level_CL[Ampl]);
      inc(LevR, Level_CR[Ampl])
    end;

  inc(LevelL, LevL);
  inc(LevelR, LevR)
end;

procedure Synthesizer_Stereo16;
var
  Tmp: integer;
begin
  repeat
    Tmp := 0; LevelL := Tmp; LevelR := Tmp;
    for Tmp := 1 to NumberOfSoundChips do
    begin
      SoundChip[Tmp].Synthesizer_Logic_Q;
      SoundChip[Tmp].Synthesizer_Mixer_Q;
    end;
    if IsFilt then
    begin
      Tmp := Filt_I;
      LevelL := ApplyFilter(LevelL, Filt_XL);
      Filt_I := Tmp;
      LevelR := ApplyFilter(LevelR, Filt_XR)
    end;
    inc(Left_Chan, LevelL);
    inc(Right_Chan, LevelR);
    Inc(Current_Tik);
    Inc(Tick_Counter);
    if Tick_Counter >= Tik.Hi then
    begin
      Inc(Tik.Re, Delay_In_Tiks);
      Dec(Tik.Hi, Tick_Counter);
      Tmp := Left_Chan div Tick_Counter;
      if Tmp > 32767 then
        Tmp := 32767
      else if Tmp < -32768 then
        Tmp := -32768;
      PS16(Buf)^[BuffLen].Left := Tmp;
      Tmp := Right_Chan div Tick_Counter;
      if Tmp > 32767 then
        Tmp := 32767
      else if Tmp < -32768 then
        Tmp := -32768;
      PS16(Buf)^[BuffLen].Right := Tmp;
      Inc(BuffLen);
      if NOfTicks = VisPoint then
      begin
        PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
          (PlVars[1].CurrentPattern shl 9) +
          (PlVars[1].CurrentLine shl 17);
        if NumberOfSoundChips > 1 then
          PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
            (PlVars[2].CurrentPattern shl 9) +
            (PlVars[2].CurrentLine shl 17);
        if MkVisPos < VisPosMax - 1 then
          Inc(MkVisPos)
        else
          MkVisPos := 0;
        Inc(VisPoint, VisStep)
      end;
      Inc(NOfTicks);
      Tmp := 0;
      Left_Chan := Tmp;
      Right_Chan := Tmp;
      Tick_Counter := Tmp;
      if BuffLen = BufferLength then
      begin
        if Current_Tik < Number_Of_Tiks.Hi then
          IntFlag := True;
        exit
      end
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  Tmp := 0;
  Number_Of_Tiks.hi := Tmp;
  Current_Tik := Tmp
end;

procedure Synthesizer_Stereo8;
var
  Tmp: integer;
begin
  repeat
    Tmp := 0; LevelL := Tmp; LevelR := Tmp;
    for Tmp := 1 to NumberOfSoundChips do
    begin
      SoundChip[Tmp].Synthesizer_Logic_Q;
      SoundChip[Tmp].Synthesizer_Mixer_Q;
    end;
    if IsFilt then
    begin
      Tmp := Filt_I;
      LevelL := ApplyFilter(LevelL, Filt_XL);
      Filt_I := Tmp;
      LevelR := ApplyFilter(LevelR, Filt_XR)
    end;
    inc(Left_Chan, LevelL);
    inc(Right_Chan, LevelR);
    Inc(Current_Tik);
    Inc(Tick_Counter);
    if Tick_Counter >= Tik.Hi then
    begin
      Inc(Tik.Re, Delay_In_Tiks);
      Dec(Tik.Hi, Tick_Counter);
      Tmp := Left_Chan div Tick_Counter;
      if Tmp > 127 then
        Tmp := 127
      else if Tmp < -128 then
        Tmp := -128;
      PS8(Buf)^[BuffLen].Left := 128 + Tmp;
      Tmp := Right_Chan div Tick_Counter;
      if Tmp > 127 then
        Tmp := 127
      else if Tmp < -128 then
        Tmp := -128;
      PS8(Buf)^[BuffLen].Right := 128 + Tmp;
      Inc(BuffLen);
      if NOfTicks = VisPoint then
      begin
        PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
          (PlVars[1].CurrentPattern shl 9) +
          (PlVars[1].CurrentLine shl 17);
        if NumberOfSoundChips > 1 then
          PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
            (PlVars[2].CurrentPattern shl 9) +
            (PlVars[2].CurrentLine shl 17);
        if MkVisPos < VisPosMax - 1 then
          Inc(MkVisPos)
        else
          MkVisPos := 0;
        Inc(VisPoint, VisStep)
      end;
      Inc(NOfTicks);
      Tmp := 0;
      Left_Chan := Tmp;
      Right_Chan := Tmp;
      Tick_Counter := Tmp;
      if BuffLen = BufferLength then
      begin
        if Current_Tik < Number_Of_Tiks.Hi then
          IntFlag := True;
        exit
      end
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  Tmp := 0;
  Number_Of_Tiks.hi := Tmp;
  Current_Tik := Tmp
end;

procedure TSoundChip.Synthesizer_Mixer_Q_Mono;
var
  Lev, k: integer;
begin
  Lev := 0;

  k := 1;
  if Ton_EnA then k := Ton_A;
  if Noise_EnA then k := k and Noise.Val;
  if k <> 0 then
    if Envelope_EnA then
      inc(Lev, Level_AL[AYRegisters.AmplitudeA * 2 + 1])
    else
      inc(Lev, Level_AL[Ampl]);

  k := 1;
  if Ton_EnB then k := Ton_B;
  if Noise_EnB then k := k and Noise.Val;
  if k <> 0 then
    if Envelope_EnB then
      inc(Lev, Level_BL[AYRegisters.AmplitudeB * 2 + 1])
    else
      inc(Lev, Level_BL[Ampl]);

  k := 1;
  if Ton_EnC then k := Ton_C;
  if Noise_EnC then k := k and Noise.Val;
  if k <> 0 then
    if Envelope_EnC then
      inc(Lev, Level_CL[AYRegisters.AmplitudeC * 2 + 1])
    else
      inc(Lev, Level_CL[Ampl]);

  inc(LevelL, Lev)
end;

procedure Synthesizer_Mono16;
var
  Tmp: integer;
begin
  repeat
    LevelL := 0;
    for Tmp := 1 to NumberOfSoundChips do
    begin
      SoundChip[Tmp].Synthesizer_Logic_Q;
      SoundChip[Tmp].Synthesizer_Mixer_Q_Mono;
    end;
    if IsFilt then
      LevelL := ApplyFilter(LevelL, Filt_XL);
    inc(Left_Chan, LevelL);
    Inc(Current_Tik);
    Inc(Tick_Counter);
    if Tick_Counter >= Tik.Hi then
    begin
      Inc(Tik.Re, Delay_In_Tiks);
      Dec(Tik.Hi, Tick_Counter);
      Tmp := Left_Chan div Tick_Counter;
      if Tmp > 32767 then
        Tmp := 32767
      else if Tmp < -32768 then
        Tmp := -32768;
      PM16(Buf)^[BuffLen] := Tmp;
      Inc(BuffLen);
      if NOfTicks = VisPoint then
      begin
        PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
          (PlVars[1].CurrentPattern shl 9) +
          (PlVars[1].CurrentLine shl 17);
        if NumberOfSoundChips > 1 then
          PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
            (PlVars[2].CurrentPattern shl 9) +
            (PlVars[2].CurrentLine shl 17);
        if MkVisPos < VisPosMax - 1 then
          Inc(MkVisPos)
        else
          MkVisPos := 0;
        Inc(VisPoint, VisStep)
      end;
      Inc(NOfTicks);
      Tmp := 0;
      Left_Chan := Tmp;
      Tick_Counter := Tmp;
      if BuffLen = BufferLength then
      begin
        if Current_Tik < Number_Of_Tiks.Hi then
          IntFlag := True;
        exit
      end
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  Tmp := 0;
  Number_Of_Tiks.hi := Tmp;
  Current_Tik := Tmp
end;

procedure Synthesizer_Mono8;
var
  Tmp: integer;
begin
  repeat
    LevelL := 0;
    for Tmp := 1 to NumberOfSoundChips do
    begin
      SoundChip[Tmp].Synthesizer_Logic_Q;
      SoundChip[Tmp].Synthesizer_Mixer_Q_Mono;
    end;
    if IsFilt then
      LevelL := ApplyFilter(LevelL, Filt_XL);
    inc(Left_Chan, LevelL);
    inc(Current_Tik);
    inc(Tick_Counter);
    if Tick_Counter >= Tik.Hi then
    begin
      inc(Tik.Re, Delay_In_Tiks);
      dec(Tik.Hi, Tick_Counter);
      Tmp := Left_Chan div Tick_Counter;
      if Tmp > 127 then
        Tmp := 127
      else if Tmp < -128 then
        Tmp := -128;
      PM8(Buf)^[BuffLen] := 128 + Tmp;
      Inc(BuffLen);
      if NOfTicks = VisPoint then
      begin
        PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
          (PlVars[1].CurrentPattern shl 9) +
          (PlVars[1].CurrentLine shl 17);
        if NumberOfSoundChips > 1 then
          PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
            (PlVars[2].CurrentPattern shl 9) +
            (PlVars[2].CurrentLine shl 17);
        if MkVisPos < VisPosMax - 1 then
          Inc(MkVisPos)
        else
          MkVisPos := 0;
        Inc(VisPoint, VisStep)
      end;
      Inc(NOfTicks);
      Tmp := 0;
      Left_Chan := Tmp;
      Tick_Counter := Tmp;
      if BuffLen = BufferLength then
      begin
        if Current_Tik < Number_Of_Tiks.Hi then
          IntFlag := True;
        exit
      end
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  Tmp := 0;
  Number_Of_Tiks.hi := Tmp;
  Current_Tik := Tmp
end;

procedure Synthesizer_Stereo16_P;
var
  LevL, LevR, k, c: integer;
begin
  repeat
    for c := 1 to NumberOfSoundChips do
      SoundChip[c].Synthesizer_Logic_P;

    LevL := 0;
    LevR := LevL;

    for c := 1 to NumberOfSoundChips do
      with SoundChip[c] do
      begin
        k := 1;
        if Ton_EnA then k := Ton_A;
        if Noise_EnA then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnA then
          begin
            inc(LevL, Level_AL[AYRegisters.AmplitudeA * 2 + 1]);
            inc(LevR, Level_AR[AYRegisters.AmplitudeA * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_AL[Ampl]);
            inc(LevR, Level_AR[Ampl])
          end;

        k := 1;
        if Ton_EnB then k := Ton_B;
        if Noise_EnB then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnB then
          begin
            inc(LevL, Level_BL[AYRegisters.AmplitudeB * 2 + 1]);
            inc(LevR, Level_BR[AYRegisters.AmplitudeB * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_BL[Ampl]);
            inc(LevR, Level_BR[Ampl])
          end;

        k := 1;
        if Ton_EnC then k := Ton_C;
        if Noise_EnC then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnC then
          begin
            inc(LevL, Level_CL[AYRegisters.AmplitudeC * 2 + 1]);
            inc(LevR, Level_CR[AYRegisters.AmplitudeC * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_CL[Ampl]);
            inc(LevR, Level_CR[Ampl])
          end;
      end;

    if LevL > 32767 then LevL := 32767;
    if LevR > 32767 then LevR := 32767;

    PS16(Buf)^[BuffLen].Left := LevL;
    PS16(Buf)^[BuffLen].Right := LevR;
    Inc(BuffLen);
    if NOfTicks = VisPoint then
    begin
      PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
        (PlVars[1].CurrentPattern shl 9) +
        (PlVars[1].CurrentLine shl 17);
      if NumberOfSoundChips > 1 then
        PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
          (PlVars[2].CurrentPattern shl 9) +
          (PlVars[2].CurrentLine shl 17);
      if MkVisPos < VisPosMax - 1 then
        Inc(MkVisPos)
      else
        MkVisPos := 0;
      Inc(VisPoint, VisStep)
    end;
    Inc(NOfTicks);
    Inc(Current_Tik);
    if BuffLen = BufferLength then
    begin
      if Current_Tik < Number_Of_Tiks.Hi then
        IntFlag := True;
      exit
    end;
  until Current_Tik >= Number_Of_Tiks.Hi;
  k := 0;
  Number_Of_Tiks.hi := k;
  Current_Tik := k
end;

procedure Synthesizer_Stereo8_P;
var
  LevL, LevR, k, c: integer;
begin
  repeat
    for c := 1 to NumberOfSoundChips do
      SoundChip[c].Synthesizer_Logic_P;

    LevL := 128;
    LevR := LevL;

    for c := 1 to NumberOfSoundChips do
      with SoundChip[c] do
      begin
        k := 1;
        if Ton_EnA then k := Ton_A;
        if Noise_EnA then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnA then
          begin
            inc(LevL, Level_AL[AYRegisters.AmplitudeA * 2 + 1]);
            inc(LevR, Level_AR[AYRegisters.AmplitudeA * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_AL[Ampl]);
            inc(LevR, Level_AR[Ampl])
          end;

        k := 1;
        if Ton_EnB then k := Ton_B;
        if Noise_EnB then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnB then
          begin
            inc(LevL, Level_BL[AYRegisters.AmplitudeB * 2 + 1]);
            inc(LevR, Level_BR[AYRegisters.AmplitudeB * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_BL[Ampl]);
            inc(LevR, Level_BR[Ampl])
          end;

        k := 1;
        if Ton_EnC then k := Ton_C;
        if Noise_EnC then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnC then
          begin
            inc(LevL, Level_CL[AYRegisters.AmplitudeC * 2 + 1]);
            inc(LevR, Level_CR[AYRegisters.AmplitudeC * 2 + 1])
          end
          else
          begin
            inc(LevL, Level_CL[Ampl]);
            inc(LevR, Level_CR[Ampl])
          end;
      end;

    if LevL > 255 then LevL := 255;
    if LevR > 255 then LevR := 255;

    PS8(Buf)^[BuffLen].Left := LevL;
    PS8(Buf)^[BuffLen].Right := LevR;
    Inc(BuffLen);
    if NOfTicks = VisPoint then
    begin
      PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
        (PlVars[1].CurrentPattern shl 9) +
        (PlVars[1].CurrentLine shl 17);
      if NumberOfSoundChips > 1 then
        PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
          (PlVars[2].CurrentPattern shl 9) +
          (PlVars[2].CurrentLine shl 17);
      if MkVisPos < VisPosMax - 1 then
        Inc(MkVisPos)
      else
        MkVisPos := 0;
      Inc(VisPoint, VisStep)
    end;
    Inc(NOfTicks);
    Inc(Current_Tik);
    if BuffLen = BufferLength then
    begin
      if Current_Tik < Number_Of_Tiks.Hi then
        IntFlag := True;
      exit
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  k := 0;
  Number_Of_Tiks.hi := k;
  Current_Tik := k
end;

procedure Synthesizer_Mono16_P;
var
  Lev, k, c: integer;
begin
  repeat
    for c := 1 to NumberOfSoundChips do
      SoundChip[c].Synthesizer_Logic_P;

    Lev := 0;

    for c := 1 to NumberOfSoundChips do
      with SoundChip[c] do
      begin
        k := 1;
        if Ton_EnA then k := Ton_A;
        if Noise_EnA then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnA then
            Inc(Lev, Level_AL[AYRegisters.AmplitudeA * 2 + 1])
          else
            Inc(Lev, Level_AL[Ampl]);

        k := 1;
        if Ton_EnB then k := Ton_B;
        if Noise_EnB then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnB then
            inc(Lev, Level_BL[AYRegisters.AmplitudeB * 2 + 1])
          else
            inc(Lev, Level_BL[Ampl]);

        k := 1;
        if Ton_EnC then k := Ton_C;
        if Noise_EnC then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnC then
            inc(Lev, Level_CL[AYRegisters.AmplitudeC * 2 + 1])
          else
            inc(Lev, Level_CL[Ampl]);
      end;

    if Lev > 32767 then Lev := 32767;

    PM16(Buf)^[BuffLen] := Lev;
    Inc(BuffLen);
    if NOfTicks = VisPoint then
    begin
      PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
        (PlVars[1].CurrentPattern shl 9) +
        (PlVars[1].CurrentLine shl 17);
      if NumberOfSoundChips > 1 then
        PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
          (PlVars[2].CurrentPattern shl 9) +
          (PlVars[2].CurrentLine shl 17);
      if MkVisPos < VisPosMax - 1 then
        Inc(MkVisPos)
      else
        MkVisPos := 0;
      Inc(VisPoint, VisStep)
    end;
    Inc(NOfTicks);
    Inc(Current_Tik);
    if BuffLen = BufferLength then
    begin
      if Current_Tik < Number_Of_Tiks.Hi then
        IntFlag := True;
      exit
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  k := 0;
  Number_Of_Tiks.hi := k;
  Current_Tik := k
end;

procedure Synthesizer_Mono8_P;
var
  Lev, k, c: integer;
begin
  repeat
    for c := 1 to NumberOfSoundChips do
      SoundChip[c].Synthesizer_Logic_P;

    Lev := 128;

    for c := 1 to NumberOfSoundChips do
      with SoundChip[c] do
      begin
        k := 1;
        if Ton_EnA then k := Ton_A;
        if Noise_EnA then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnA then
            inc(Lev, Level_AL[AYRegisters.AmplitudeA * 2 + 1])
          else
            inc(Lev, Level_AL[Ampl]);

        k := 1;
        if Ton_EnB then k := Ton_B;
        if Noise_EnB then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnB then
            inc(Lev, Level_BL[AYRegisters.AmplitudeB * 2 + 1])
          else
            inc(Lev, Level_BL[Ampl]);

        k := 1;
        if Ton_EnC then k := Ton_C;
        if Noise_EnC then k := k and Noise.Val;
        if k <> 0 then
          if Envelope_EnC then
            inc(Lev, Level_CL[AYRegisters.AmplitudeC * 2 + 1])
          else
            inc(Lev, Level_CL[Ampl]);
      end;

    if Lev > 255 then Lev := 255;

    PM8(Buf)^[BuffLen] := Lev;
    Inc(BuffLen);
    if NOfTicks = VisPoint then
    begin
      PlayingGrid[MkVisPos].M1 := (PlVars[1].CurrentPosition and $1FF) +
        (PlVars[1].CurrentPattern shl 9) +
        (PlVars[1].CurrentLine shl 17);
      if NumberOfSoundChips > 1 then
        PlayingGrid[MkVisPos].M2 := (PlVars[2].CurrentPosition and $1FF) +
          (PlVars[2].CurrentPattern shl 9) +
          (PlVars[2].CurrentLine shl 17);
      if MkVisPos < VisPosMax - 1 then
        Inc(MkVisPos)
      else
        MkVisPos := 0;
      Inc(VisPoint, VisStep)
    end;
    Inc(NOfTicks);
    Inc(Current_Tik);
    if BuffLen = BufferLength then
    begin
      if Current_Tik < Number_Of_Tiks.Hi then
        IntFlag := True;
      exit
    end
  until Current_Tik >= Number_Of_Tiks.Hi;
  k := 0;
  Number_Of_Tiks.hi := k;
  Current_Tik := k
end;

procedure FrameSynthesizer(Buf: pointer);
begin
  if not IntFlag then
  begin
    if Optimization_For_Quality then
      Number_Of_Tiks.hi := AY_Tiks_In_Interrupt
    else
      Number_Of_Tiks.hi := Sample_Tiks_In_Interrupt
  end
  else
    IntFlag := False;
  Synthesizer(Buf)
end;

procedure Get_Registers;
begin
  if Real_End[CurChip] then
  begin
    SoundChip[CurChip].SetAmplA(0);
    SoundChip[CurChip].SetAmplB(0);
    SoundChip[CurChip].SetAmplC(0);
    exit
  end;
  case PlayMode of
    PMPlayModule:
      begin
        if Module_PlayCurrentLine = 3 then
          if not LoopAllowed and
            (not MainForm.LoopAllAllowed or (MainForm.MDIChildCount <> 1)) then
          begin
            Real_End[CurChip] := True;
            SoundChip[CurChip].SetAmplA(0);
            SoundChip[CurChip].SetAmplB(0);
            SoundChip[CurChip].SetAmplC(0);
          end;
      end;
    PMPlayPattern:
      begin
        if Pattern_PlayCurrentLine = 2 then
          if not LoopAllowed and not MainForm.LoopAllAllowed then
          begin
            Real_End[CurChip] := True;
            SoundChip[CurChip].SetAmplA(0);
            SoundChip[CurChip].SetAmplB(0);
            SoundChip[CurChip].SetAmplC(0);
          end
          else
          begin
            Pattern_SetCurrentLine(0);
            Pattern_PlayCurrentLine;
          end;
      end;
    PMPlayLine:
      Pattern_PlayOnlyCurrentLine;
  end;
end;

procedure MakeBuffer(Buf: pointer);
var
  i: integer;
begin
  BuffLen := 0;
  if IntFlag then FrameSynthesizer(Buf);
  if IntFlag then exit;
  if LineReady then
  begin
    LineReady := False;
    FrameSynthesizer(Buf)
  end;
  while not Real_End_All and (BuffLen < BufferLength) do
  begin
    Real_End_All := True;
    for i := 1 to NumberOfSoundChips do
    begin
      Module_SetPointer(PlayingWindow[i].VTMP, i);
      Get_Registers;
      Real_End_All := Real_End_All and Real_End[i];
    end;
    if not Real_End_All then FrameSynthesizer(Buf)
  end
end;

procedure Calculate_Level_Tables;
var i, b, l, r: integer;
  Index_A, Index_B, Index_C: integer;
  k: real;
begin
  Index_A := Index_AL; Index_B := Index_BL; Index_C := Index_CL;
  l := Index_A + Index_B + Index_C;
  r := Index_AR + Index_BR + Index_CR;
  if NumberOfChannels = 2 then
  begin
    if l < r then
      l := r;
  end
  else
  begin
    l := l + r;
    inc(Index_A, Index_AR);
    inc(Index_B, Index_BR);
    inc(Index_C, Index_CR)
  end;
  if l = 0 then inc(l);
  if SampleBit = 8 then r := 127 else r := 32767;
  l := 255 * r div l;
  case Emulating_Chip of
    AY_Chip: for i := 0 to 15 do
      begin
        b := round(Index_A / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_AL[i * 2] := b; Level_AL[i * 2 + 1] := b;
        b := round(Index_AR / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_AR[i * 2] := b; Level_AR[i * 2 + 1] := b;
        b := round(Index_B / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_BL[i * 2] := b; Level_BL[i * 2 + 1] := b;
        b := round(Index_BR / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_BR[i * 2] := b; Level_BR[i * 2 + 1] := b;
        b := round(Index_C / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_CL[i * 2] := b; Level_CL[i * 2 + 1] := b;
        b := round(Index_CR / 255 * Amplitudes_AY[i]);
        b := round(b / 65535 * l);
        Level_CR[i * 2] := b; Level_CR[i * 2 + 1] := b;
      end;
    YM_Chip: for i := 0 to 31 do
      begin
        b := round(Index_A / 255 * Amplitudes_YM[i]);
        Level_AL[i] := round(b / 65535 * l);
        b := round(Index_AR / 255 * Amplitudes_YM[i]);
        Level_AR[i] := round(b / 65535 * l);
        b := round(Index_B / 255 * Amplitudes_YM[i]);
        Level_BL[i] := round(b / 65535 * l);
        b := round(Index_BR / 255 * Amplitudes_YM[i]);
        Level_BR[i] := round(b / 65535 * l);
        b := round(Index_C / 255 * Amplitudes_YM[i]);
        Level_CL[i] := round(b / 65535 * l);
        b := round(Index_CR / 255 * Amplitudes_YM[i]);
        Level_CR[i] := round(b / 65535 * l);
      end;
  end;
  k := exp(MainForm.GlobalVolume * ln(2) / MainForm.GlobalVolumeMax) - 1;
  for i := 0 to 31 do
  begin
    Level_AL[i] := round(Level_AL[i] * k);
    Level_AR[i] := round(Level_AR[i] * k);
    Level_BL[i] := round(Level_BL[i] * k);
    Level_BR[i] := round(Level_BR[i] * k);
    Level_CL[i] := round(Level_CL[i] * k);
    Level_CR[i] := round(Level_CR[i] * k);
  end
end;

procedure SetDefault;
begin
  SampleRate := samrate;
  AY_Freq := AY_Freq_Def;
  Interrupt_Freq := Interrupt_Freq_Def;
  Delay_In_Tiks := round(8192 / SampleRate * AY_Freq);
  AY_Tiks_In_Interrupt := round(AY_Freq / (Interrupt_Freq / 1000 * 8));
  Sample_Tiks_in_Interrupt := round(SampleRate / Interrupt_Freq * 1000);
  SampleBit := sambit;
  NumberOfBuffers := NumberOfBuffersDef;
  BufLen_ms := BufLen_msDef;
  BufferLength := round(BufLen_ms * SampleRate / 1000);
  NumberOfChannels := nchan;
  StdChannelsAllocation := StdChannelsAllocationDef;
  Index_AL := Index_AL_Def; Index_AR := Index_AR_Def;
  Index_BL := Index_BL_Def; Index_BR := Index_BR_Def;
  Index_CL := Index_CL_Def; Index_CR := Index_CR_Def;
  Emulating_Chip := YM_Chip;
  Calculate_Level_Tables;
  SetLength(waveOutBuffers, NumberOfBuffers);
  VisStep := round(SampleRate * 500 / Interrupt_Freq);
  VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
  VisTickMax := VisStep * VisPosMax;
  SetLength(PlayingGrid, VisPosMax);
  IsFilt := True;
  Filt_M := Filt_NKoefs;
  SetLength(Filt_K, Filt_NKoefs + 1);
  CalcFiltKoefs;
  SetLength(Filt_XL, Filt_NKoefs + 1);
  SetLength(Filt_XR, Filt_NKoefs + 1);
  FillChar(Filt_XL[0], (Filt_M + 1) * 4, 0);
  FillChar(Filt_XR[0], (Filt_M + 1) * 4, 0);
  Filt_I := 0
end;

function ToggleChanMode;
begin
  Inc(StdChannelsAllocation);
  if StdChannelsAllocation > 3 then
    StdChannelsAllocation := 0;
  Result := SetStdChannelsAllocation(StdChannelsAllocation)
end;

function SetStdChannelsAllocation;
var
  Echo: integer;
begin
  Result := '';
  StdChannelsAllocation := CA;
  case Emulating_Chip of
    AY_Chip:
      Echo := 85
  else
    Echo := 13;
  end;
  case StdChannelsAllocation of
    0:
      begin
        MidChan := 0;
        Result := 'Mono';
        Index_AL := 255; Index_AR := 255;
        Index_BL := 255; Index_BR := 255;
        Index_CL := 255; Index_CR := 255
      end;
    1:
      begin
        MidChan := 1;
        Result := 'ABC';
        Index_AL := 255; Index_AR := Echo;
        Index_BL := 170; Index_BR := 170;
        Index_CL := Echo; Index_CR := 255
      end;
    2:
      begin
        MidChan := 2;
        Result := 'ACB';
        Index_AL := 255; Index_AR := Echo;
        Index_CL := 170; Index_CR := 170;
        Index_BL := Echo; Index_BR := 255
      end;
    3:
      begin
        MidChan := 0;
        Result := 'BAC';
        Index_BL := 255; Index_BR := Echo;
        Index_AL := 170; Index_AR := 170;
        Index_CL := Echo; Index_CR := 255
      end;
    4:
      begin
        MidChan := 2;
        Result := 'BCA';
        Index_BL := 255; Index_BR := Echo;
        Index_CL := 170; Index_CR := 170;
        Index_AL := Echo; Index_AR := 255
      end;
    5:
      begin
        MidChan := 0;
        Result := 'CAB';
        Index_CL := 255; Index_CR := Echo;
        Index_AL := 170; Index_AR := 170;
        Index_BL := Echo; Index_BR := 255
      end;
    6:
      begin
        MidChan := 1;
        Result := 'CBA';
        Index_CL := 255; Index_CR := Echo;
        Index_BL := 170; Index_BR := 170;
        Index_AL := Echo; Index_AR := 255
      end
  end;
  Calculate_Level_Tables
end;

procedure SetIntFreq;
var
  R: boolean;
begin
  if (f < 1000) or (f > 2000000) then exit;
  R := IsPlaying and not Reseted and (PlayMode = PMPlayModule);
  if not R and IsPlaying and not Reseted then StopPlaying;
  if R then ResetPlaying;
  Interrupt_Freq := f;
  AY_Tiks_In_Interrupt := round(AY_Freq / (Interrupt_Freq / 1000 * 8));
  Sample_Tiks_in_Interrupt := round(SampleRate / Interrupt_Freq * 1000);
  VisStep := round(SampleRate * 500 / Interrupt_Freq);
  VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
  VisTickMax := VisStep * VisPosMax;
  SetLength(PlayingGrid, VisPosMax);
  if R then
  begin
    PlayingWindow[1].RerollToLine(1);
    UnresetPlaying;
  end;
end;

procedure SetSampleRate(f: integer);
begin
  SampleRate := f;
  Delay_In_Tiks := round(8192 / SampleRate * AY_Freq);
  Sample_Tiks_in_Interrupt := round(SampleRate / Interrupt_Freq * 1000);
  VisStep := round(SampleRate * 500 / Interrupt_Freq);
  BufferLength := round(BufLen_ms * SampleRate / 1000);
  VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
  VisTickMax := VisStep * VisPosMax;
  SetLength(PlayingGrid, VisPosMax);
  CalcFiltKoefs
end;

procedure SetBuffers(len, num: integer);
begin
  BufLen_ms := len;
  NumberOfBuffers := num;
  SetLength(waveOutBuffers, NumberOfBuffers);
  BufferLength := round(BufLen_ms * SampleRate / 1000);
  VisPosMax := round(BufferLength * NumberOfBuffers / VisStep) + 1;
  VisTickMax := VisStep * VisPosMax;
  SetLength(PlayingGrid, VisPosMax)
end;

procedure SetBitRate(SB: integer);
begin
  SampleBit := SB;
  if Optimization_For_Quality then
  begin
    if NumberOfChannels = 2 then
    begin
      if SB = 8 then
        Synthesizer := Synthesizer_Stereo8
      else
        Synthesizer := Synthesizer_Stereo16;
    end
    else if SB = 8 then
      Synthesizer := Synthesizer_Mono8
    else
      Synthesizer := Synthesizer_Mono16;
  end
  else
  begin
    if NumberOfChannels = 2 then
    begin
      if SB = 8 then
        Synthesizer := Synthesizer_Stereo8_P
      else
        Synthesizer := Synthesizer_Stereo16_P;
    end
    else if SB = 8 then
      Synthesizer := Synthesizer_Mono8_P
    else
      Synthesizer := Synthesizer_Mono16_P;
  end;
  Calculate_Level_Tables
end;

procedure SetNChans(St: integer);
begin
  NumberOfChannels := St;
  if Optimization_For_Quality then
  begin
    if St = 2 then
    begin
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Stereo8
      else
        Synthesizer := Synthesizer_Stereo16
    end
    else
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Mono8
      else
        Synthesizer := Synthesizer_Mono16
  end
  else
  begin
    if St = 2 then
    begin
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Stereo8_P
      else
        Synthesizer := Synthesizer_Stereo16_P
    end
    else
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Mono8_P
      else
        Synthesizer := Synthesizer_Mono16_P
  end;
  Calculate_Level_Tables
end;

procedure Set_Optimization(Q: boolean);
var
  R: boolean;
begin
  if Optimization_For_Quality = Q then exit;
  R := IsPlaying and not Reseted and (PlayMode = PMPlayModule);
  if not R and IsPlaying and not Reseted then StopPlaying;
  if R then ResetPlaying;
  Optimization_For_Quality := Q;
  if Q then
  begin
    Current_Tik := round(Current_Tik / SampleRate * (AY_Freq div 8));
    Number_Of_Tiks.Re := round(Number_Of_Tiks.Re / SampleRate * (AY_Freq div 8));
    if NumberOfChannels = 2 then
    begin
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Stereo8
      else
        Synthesizer := Synthesizer_Stereo16
    end
    else if SampleBit = 8 then
      Synthesizer := Synthesizer_Mono8
    else
      Synthesizer := Synthesizer_Mono16
  end
  else
  begin
    Current_Tik := round(Current_Tik / (AY_Freq div 8) * SampleRate);
    Number_Of_Tiks.Re := round(Number_Of_Tiks.Re / (AY_Freq div 8) * SampleRate);
    if NumberOfChannels = 2 then
    begin
      if SampleBit = 8 then
        Synthesizer := Synthesizer_Stereo8_P
      else
        Synthesizer := Synthesizer_Stereo16_P
    end
    else if SampleBit = 8 then
      Synthesizer := Synthesizer_Mono8_P
    else
      Synthesizer := Synthesizer_Mono16_P
  end;
  if R then
  begin
    PlayingWindow[1].RerollToLine(1);
    UnresetPlaying;
  end;
end;

procedure SetAYFreq(f: integer);
var
  R: boolean;
begin
  if (f < 1000000) or (f > 3546800) then exit;
  R := IsPlaying and not Reseted and (PlayMode = PMPlayModule);
  if not R and IsPlaying and not Reseted then StopPlaying;
  if R then ResetPlaying;
  AY_Freq := f;
  Delay_In_Tiks := round(8192 / SampleRate * AY_Freq);
  AY_Tiks_In_Interrupt := round(AY_Freq / (Interrupt_Freq / 1000 * 8));
  CalcFiltKoefs;
  if R then
  begin
    PlayingWindow[1].RerollToLine(1);
    UnresetPlaying;
  end;
end;

procedure CalcFiltKoefs;
var
  i, i2, Filt_M2: integer;
  K, F, C: double;
  FKt: array of double;
begin
  C := Pi * SampleRate / (AY_Freq div 8);
  SetLength(FKt, Filt_M + 1);
  Filt_M2 := Filt_M div 2;
  K := 0;
  for i := 0 to Filt_M do
  begin
    i2 := i - Filt_M2;
    if i2 = 0 then
      F := C
    else
      F := sin(C * i2) / i2 * (0.54 - 0.46 * cos(2 * Pi / Filt_M * i));
    FKt[i] := F;
    K := K + F
  end;
  for i := 0 to Filt_M do
    Filt_K[i] := round(FKt[i] / K * $1000000)
end;

procedure SetFilter(Filt: boolean; M: integer);
var
  R: boolean;
begin
  if (Filt_M = M) and (IsFilt = Filt) then exit;
  R := IsPlaying and not Reseted and (PlayMode = PMPlayModule);
  if not R and IsPlaying and not Reseted then StopPlaying;
  if R then ResetPlaying;
  IsFilt := Filt;
  if Filt_M <> M then
  begin
    Filt_M := M;
    SetLength(Filt_K, M + 1);
    CalcFiltKoefs;
    SetLength(Filt_XL, M + 1);
    SetLength(Filt_XR, M + 1);
    FillChar(Filt_XL[0], (Filt_M + 1) * 4, 0);
    FillChar(Filt_XR[0], (Filt_M + 1) * 4, 0);
    Filt_I := 0;
  end;
  if R then
  begin
    PlayingWindow[1].RerollToLine(1);
    UnresetPlaying;
  end;
end;

end.
