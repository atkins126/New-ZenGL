program demo11;

{$I zglCustomConfig.cfg}
{$I zgl_config.cfg}

{$IFDEF WINDOWS}
  {$R *.res}
{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF USE_ZENGL_STATIC}
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_keyboard,
  zgl_fx,
  zgl_textures,
  zgl_textures_png,
  zgl_textures_jpg,
  zgl_grid_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_types,
  zgl_utils
  {$ELSE}
  zglHeader
  {$ENDIF}
  ;

var
  dirRes      : UTF8String {$IFNDEF MACOSX} = '../data/' {$ENDIF};
  fntMain     : LongWord;
  texBack     : zglPTexture;
  grid        : zglTGrid2D;
  wave        : Single;

  TimeStart  : LongWord = 0;

procedure Init;
var
  i, j : Integer;
begin
  texBack := tex_LoadFromFile( dirRes + 'back04.jpg' );

  fntMain := font_LoadFromFile( dirRes + 'font.zfi' );

  // RU: Инициализация сетки размером 21x16. Основная идея - каждый узел сетки это смещение относительно её верхнего левого угла.
  // EN: Initialization of grid with size 21x16. Main idea - every node of grid is an offset from the top left corner.
  grid.Cols := 21;
  grid.Rows := 16;
  SetLength( grid.Grid, grid.Cols, grid.Rows );
  for i := 0 to grid.Cols - 1 do
    for j := 0 to grid.Rows - 1 do
    begin
      grid.Grid[ i, j ].X := i * 40;
      grid.Grid[ i, j ].Y := j * 40;
    end;
  setFontTextScale(15, fntMain);
end;

procedure Draw;
begin
  // RU: Рендерим сетку в координатах 0,0.
  // EN: Render grid in coordinates 0,0.
  sgrid2d_Draw( texBack, 0, 0, @grid );

  text_Draw( fntMain, 0, 0, 'FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) );
end;

procedure Timer;
var
  i, j : Integer;
  cwave, swave : Single;
begin
  wave  := wave + random( 1000 ) / 10000;
  cwave := cos( wave );
  swave := sin( wave );

  // RU: Симуляция простого эффекта под водой.
  // EN: Simulation of simple underwater effect.
  for i := 1 to grid.Cols - 2 do
    for j := 1 to grid.Rows - 2 do
    begin
      if ( i mod 2 = 0 ) and ( j mod 2 = 0 ) Then
      begin
        grid.Grid[ i, j ].X := i * 40 + cwave;
        grid.Grid[ i, j ].Y := j * 40 + swave;
      end else
      begin
        grid.Grid[ i, j ].X := i * 40 - cwave;
        grid.Grid[ i, j ].Y := j * 40 - swave;
      end;
    end;
end;

Begin
  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  randomize();

  TimeStart := timer_Add( @Timer, 16, t_Start );

  zgl_Reg( SYS_LOAD, @Init );
  zgl_Reg( SYS_DRAW, @Draw );

  wnd_SetCaption(utf8_Copy('11 - Grid'));

  zgl_Init();
End.
