{
 *  Copyright (c) 2012 Andrey Kemka
 *
 *  This software is provided 'as-is', without any express or
 *  implied warranty. In no event will the authors be held
 *  liable for any damages arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute
 *  it freely, subject to the following restrictions:
 *
 *  1. The origin of this software must not be misrepresented;
 *     you must not claim that you wrote the original software.
 *     If you use this software in a product, an acknowledgment
 *     in the product documentation would be appreciated but
 *     is not required.
 *
 *  2. Altered source versions must be plainly marked as such,
 *     and must not be misrepresented as being the original software.
 *
 *  3. This notice may not be removed or altered from any
 *     source distribution.

 !!! modification from Serge 16.07.2021
}
unit zgl_timers;

{$I zgl_config.cfg}

interface
{$IfDef UNIX}
uses UnixType;
{$ENDIF}
{$IFDEF WINDOWS}
uses Windows;
{$ENDIF}

const
  MAX_TIMERS   =  50;        // максимальное количество таймеров.

  // биты работы с таймером
  t_Stop         =   1;        // таймер останавливается незамедлительно
  t_Start        =   2;        // таймер создаётся и стартует незамедлительно
  t_Tiks         =   4;        // используется только внутри таймеров!
  t_SleepToStart =   8;        // таймер создаётся и запускается с установленной задержкой
  t_SleepToStop  =  16;        // таймер останавливается через определённое время
  t_Enable       = 128;        // используется или нет данный таймер (существует или нет?)

  t_Stop_or_SleepToStart = t_Stop or t_SleepToStart;
  t_Start_or_SleepToStop = t_Start or t_SleepToStop;

type
  zglPTimer = ^zglTTimer;
  zglTTimer = record
    Interval, SInterval: Cardinal;
    Flags: LongWord;
    LastTick, LastTickForSleep: Double;
    OnTimer: procedure;
  end;

  zglPTimerManager = ^zglTTimerManager;
  zglTTimerManager = record
    Count: Byte;
    maxTimers: Byte;
    Timers: array of zglPTimer;
  end;

// Все таймера работают в милисекундах! (отсчёт в милисекундах)

(*  получить данное время  *)
function  timer_GetTicks: Double;

(*  добавить процедуру-таймер (если не добавить обрабатываемую процедуру таймер "как бы" будет работать)
  *)
function timer_Add(OnTimer: Pointer; Interval: Cardinal; Flags: LongWord = t_Start; SleepInterval: Cardinal = 5): Byte;

(*  Удаляется таймер, но не уничтожается
    Если во время удаления таймера создаётся новый таймер, то большая вероятность, что удалённый таймер уничтожится.
    (новый таймер займёт его место)    *)
procedure timer_Del(var num: Byte);

(*  Уничтожает все таймера, процедура нужна только по закрытию программы или внепланового закрытия
    происходит по умолчанию (как закрывается программа)        *)
procedure timers_Destroy;

(* Запускает/останавливает незамедлительно СУЩЕСТВУЮЩИЙ таймер   *)
function timer_StartStop(num: Byte; Flags: Byte = 2): Boolean;

(* Запускает/останавливает через определённое время СУЩЕСТВУЮЩИЙ таймер   *)
function timer_SleepStartStop(num: Byte; Flags: Byte = 2; IntervalSleep: Cardinal = 3): Boolean;

// Обработка всех запущенных процедур-таймеров
procedure timer_MainLoop;

// Обнуление всех существующих таймеров
procedure timer_Reset;

var
  managerTimer : zglTTimerManager;

implementation
uses
  zgl_application,
  zgl_window;

{$IfDef UNIX}{$IfNDef MAC_COCOA}
function fpGetTimeOfDay(val: PTimeVal; tzp: Pointer): Integer; cdecl; external 'libc' name 'gettimeofday';
{$Else}
type
  mach_timebase_info_t = record
    numer: LongWord;
    denom: LongWord;
  end;

  function mach_timebase_info(var info: mach_timebase_info_t): Integer; cdecl; external 'libc';
  function mach_absolute_time: QWORD; cdecl; external 'libc';
{$ENDIF}{$EndIf}

var
  timersToKill : Byte = 0;
  aTimersToKill: array[1..MAX_TIMERS + 1] of Byte;

  {$IfDef UNIX}{$IfNDef MAC_COCOA}
  timerTimeVal: TimeVal;
  {$Else}
  timerTimebaseInfo: mach_timebase_info_t;
  {$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}
  timerFrequency: Int64;
  {$ENDIF}
  timerStart: Double;

function timer_Add(OnTimer: Pointer; Interval: Cardinal; Flags: LongWord = t_Start; SleepInterval: Cardinal = 5): Byte;
var
  i: LongWord;
  t: Double;
  newTimer: zglPTimer;
  {$IFDEF DELPHI7_AND_DOWN}
  z: Pointer;
  {$ENDIF}
begin
  Result := 255;
  if managerTimer.Count >= managerTimer.maxTimers then
  begin
    inc(managerTimer.maxTimers, 5);
    if managerTimer.maxTimers > MAX_TIMERS then
    begin
      managerTimer.maxTimers := MAX_TIMERS;
      exit;
    end;

    SetLength(managerTimer.Timers, managerTimer.maxTimers);
  end;

  if (Flags and (t_Start or t_Stop or t_SleepToStart or t_SleepToStop) = 0) then
    Flags := t_Start;
  i := 0;
  while i < managerTimer.maxTimers do
  begin
    newTimer := managerTimer.Timers[i];
    if (not Assigned(newTimer)) then
      Break;
    if ((newTimer.Flags and t_Enable) = 0) then
      break;
    inc(i);
  end;

  if not Assigned(newTimer) then
  begin
    {$IFDEF DELPHI7_AND_DOWN}
    zgl_GetMem(z, SizeOf(zglTTimer));
    newTimer := z;
    {$ELSE}
    zgl_GetMem(newTimer, SizeOf(zglTTimer));
    {$ENDIF}
    managerTimer.Timers[i] := newTimer;
  end;

  newTimer.OnTimer := OnTimer;
  t := timer_GetTicks;
  if (Flags and t_SleepToStart) > 0 then
  begin
    Flags := Flags and (255 - t_Start);
    newTimer.LastTickForSleep := t;
  end;
  newTimer.LastTick := t;
  if (Flags and t_Start) > 0 then
    newTimer.Flags := newTimer.Flags and (255 - t_Stop) or t_Enable or Flags
  else
    newTimer.Flags := (newTimer.Flags and (255 - t_Start)) or t_Enable or Flags;
  newTimer.Interval := Interval;
  newTimer.SInterval := SleepInterval;
  inc(managerTimer.Count);
  Result := i;
  newTimer := nil;
end;

function timer_StartStop(num: Byte; Flags: Byte = 2): Boolean;
var
  useTimer: zglPTimer;
begin
  Result := False;
  if (num >= managerTimer.maxTimers) or (num = timeCalcFPS) {$IfNDef USE_INIT_HANDLE}or (num = timeAppEvents){$EndIf} then
    exit;

  if (managerTimer.Timers[num].Flags and t_Enable) = 0 then
    Exit;

  if (Flags and (t_Start or t_Stop or t_SleepToStop or t_SleepToStart) = 0) then
    Flags := t_Start;

  useTimer := managerTimer.Timers[num];
  if (Flags = t_Start) or (Flags = t_SleepToStart) then
  begin
    useTimer.Flags := (useTimer.Flags and (255 - t_Stop)) or t_Start;
    useTimer.LastTick := timer_GetTicks;
  end
  else
    useTimer.Flags := (useTimer.Flags and (255 - t_Start)) or t_Stop;
  Result := True;
  useTimer := nil;
end;

function timer_SleepStartStop(num: Byte; Flags: Byte = 2; IntervalSleep: Cardinal = 3): Boolean;
var
  t: Double;
  useTimer: zglPTimer;
begin
  Result := False;
  if (num >= managerTimer.maxTimers) or (num = timeCalcFPS) {$IfNDef USE_INIT_HANDLE}or (num = timeAppEvents){$EndIf} then
    exit;

  if (managerTimer.Timers[num].Flags and t_Enable) = 0 then
    Exit;

  if (Flags and (t_Start or t_Stop or t_SleepToStop or t_SleepToStart) = 0) then
    Flags := t_Start;

  useTimer := managerTimer.Timers[num];
  useTimer.SInterval := IntervalSleep;
  if (Flags = t_Start) or (Flags = t_SleepToStart) then
    useTimer.Flags := (useTimer.Flags or t_Stop_or_SleepToStart) and (255 - t_Start)
  else
    useTimer.Flags := (useTimer.Flags or t_Start_or_SleepToStop) and (255 - t_Stop);
  t := timer_GetTicks;
  useTimer.LastTick := t;
  useTimer.LastTickForSleep := t;

  Result := True;
  useTimer := nil;
end;

procedure timer_Del(var num: Byte);
begin
  if managerTimer.Count = 0 then Exit;
  if (num > managerTimer.maxTimers) or (num = timeCalcFPS) {$IfNDef USE_INIT_HANDLE}or (num = timeAppEvents){$EndIf} then
    exit;
  if (managerTimer.Timers[num].Flags and t_Enable) > 0 then
  begin
    inc(timersToKill);
    aTimersToKill[timersToKill] := num;
    num := 0;
  end;
end;

procedure timers_Destroy;
var
  i: LongWord;
  delTimer: zglPTimer;
begin
  if managerTimer.Count = 0 then Exit;
  for i := 0 to managerTimer.Count - 1 do
  begin
    delTimer := managerTimer.Timers[i];
    if (Assigned(delTimer)) and (Assigned(delTimer.OnTimer)) then
    begin
      delTimer.OnTimer := nil;
      Freemem(delTimer);
      managerTimer.Timers[i] := nil;
    end;
  end;
  SetLength(managerTimer.Timers, 0);
  delTimer := nil;
end;

procedure timer_MainLoop;
var
  i, j, Flag: LongWord;
  t : Double;
  useTimer: zglPTimer;
begin
  j := managerTimer.Count;
  i := 0;
  while j > 0 do
  begin
    if i > managerTimer.maxTimers - 1 then
      Break;
    if Assigned(managerTimer.Timers[i]) then
    begin

      if ((managerTimer.Timers[i].Flags and t_Enable) > 0) then
      begin
        t := timer_GetTicks;
        useTimer := managerTimer.Timers[i];
        Flag := useTimer.Flags;
        if ((Flag and t_SleepToStart) > 0) then
        begin
          if (t - useTimer.LastTickForSleep) > 1000 then
          begin
            dec(useTimer.SInterval);
            useTimer.LastTickForSleep := useTimer.LastTickForSleep + 1000;
          end;
          if useTimer.SInterval = 0 then
          begin
            useTimer.Flags := (Flag or t_Start) and (255 - t_SleepToStart - t_Stop);
            useTimer.LastTick := t;
          end
          else begin
            inc(i);
            Continue;
          end;
        end;
        if ((Flag and t_Start ) > 0) then
        begin
          while ((t - useTimer.LastTick) > useTimer.Interval) do
          begin
            if (Flag and t_Tiks) = 0 then
            begin
              useTimer.OnTimer;
              Flag := Flag or t_Tiks;
            end;
            useTimer.LastTick :=  useTimer.LastTick + useTimer.Interval;
          end;
          if (Flag and t_SleepToStop) > 0 then
          begin
            if (t - useTimer.LastTickForSleep) > 1000 then
            begin
              useTimer.LastTickForSleep := useTimer.LastTickForSleep + 1000;
              dec(useTimer.SInterval);
            end;
            if useTimer.SInterval = 0 then
            begin
              useTimer.Flags := (useTimer.Flags or t_Stop) and (255 - t_SleepToStop - t_Start);
            end;
          end;
          dec(j);
        end;
      end;
    end;
    inc(i);
  end;

  for i := 1 to timersToKill do
  begin
    managerTimer.Timers[aTimersToKill[i]].Flags := managerTimer.Timers[aTimersToKill[i]].Flags and (255 - t_Enable);
    dec(managerTimer.Count);
  end;
  timersToKill := 0;
  useTimer := nil;
end;

function timer_GetTicks: Double;
  {$IFDEF WINDOWS}
  var
    t: int64;
    m: LongWord;
  {$ENDIF}
begin
{$IfDef UNIX}{$IfNDef MAC_COCOA}
  fpGetTimeOfDay(@timerTimeVal, nil);
  {$Q-}
  // FIXME: почему-то overflow вылетает с флагом -Co
  Result := timerTimeVal.tv_sec * 1000 + timerTimeVal.tv_usec / 1000 - timerStart;
  {$Q+}
{$Else}
  Result := mach_absolute_time() * timerTimebaseInfo.numer / timerTimebaseInfo.denom / 1000000 - timerStart;
{$ENDIF}{$EndIf}
{$IFDEF WINDOWS}
  m := SetThreadAffinityMask(GetCurrentThread(), 1);
  QueryPerformanceCounter(t);
  Result := 1000 * t / timerFrequency - timerStart;
  SetThreadAffinityMask(GetCurrentThread(), m);
{$ENDIF}
end;

procedure timer_Reset;
var
  i: LongWord;
  useTimer: zglPTimer;
  t: Double;
begin
  appdt := timer_GetTicks();
  {$IfNDef USE_INIT_HANDLE}
  oldTimeDraw := appdt;
  {$EndIf}
  if managerTimer.Count = 0 then Exit;
  i := 0;
  while i < managerTimer.maxTimers do
  begin
    useTimer := managerTimer.Timers[i];
    if (Assigned(useTimer)) and (Assigned(useTimer.OnTimer)) then
    begin
      t := timer_GetTicks;
      useTimer.LastTick := t;
      useTimer.LastTickForSleep := t;
    end;
    inc(i);
  end;
  useTimer := nil;
  if Assigned(app_PReset) then
    app_PReset;
end;

initialization
  managerTimer.Count := 0;
  managerTimer.maxTimers := 0;
{$IFDEF WINDOWS}
  SetThreadAffinityMask(GetCurrentThread(), 1);
  QueryPerformanceFrequency(timerFrequency);
{$ENDIF}
{$IFDEF DARWIN}
  mach_timebase_info(timerTimebaseInfo);
{$ENDIF}
  timerStart := timer_GetTicks();

end.
