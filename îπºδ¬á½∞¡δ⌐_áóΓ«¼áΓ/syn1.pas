{
Пример синтезатора звука
клавишами 0..9,-,=
оригинал: programania.com/syn.zip
}
unit syn1;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,Dialogs,
  StdCtrls,mmsystem, ExtCtrls, Spin;

type
  TForm1 = class(TForm)
    btnPlay: TButton;
    Image1: TImage;
    Timer1: TTimer;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    sbf: TScrollBar;
    sbdi: TScrollBar;
    sbN: TScrollBar;
    Label3: TLabel;
    sbS: TScrollBar;
    Label4: TLabel;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    sbFM: TScrollBar;
    sbDIM: TScrollBar;
    sbNM: TScrollBar;
    sbSM: TScrollBar;
    GroupBox3: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    sbFMM: TScrollBar;
    sbDIMm: TScrollBar;
    sbNMm: TScrollBar;
    sbSMm: TScrollBar;
    cbM: TCheckBox;
    cbMM: TCheckBox;
    output: TCheckBox;
    sbVol: TScrollBar;
    sbMas: TScrollBar;
    Label9: TLabel;
    sbT: TScrollBar;
    Label14: TLabel;
    procedure sbfChange(Sender: TObject);
    procedure sbdiChange(Sender: TObject);
    procedure sbNChange(Sender: TObject);
    procedure sbSChange(Sender: TObject);
    procedure sbFMChange(Sender: TObject);
    procedure sbDIMChange(Sender: TObject);
    procedure sbNMChange(Sender: TObject);
    procedure sbSMChange(Sender: TObject);
    procedure sbFMMChange(Sender: TObject);
    procedure sbDIMmChange(Sender: TObject);
    procedure sbNMmChange(Sender: TObject);
    procedure sbSMmChange(Sender: TObject);
    procedure cbMClick(Sender: TObject);
    procedure cbMMClick(Sender: TObject);
    procedure outputClick(Sender: TObject);
    procedure sbVolChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure sbfEnter(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure sbMasChange(Sender: TObject);
    procedure sbTChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
   procedure WaveOutMess(var msg: TMessage); message MM_WOM_DONE;
  end;

const
BlockSize = (1024)*3; // размер буфера вывода

var
Form1: TForm1;

implementation

{$R *.DFM}
//для синтеза
const fo=44100; tzn=fo div 8; tzk=fo div 8; ts=1/fo;
qi=1; //число инструментов
qv=8; //число инструментов одновременно играемых
qn=12;//число нот в инструменте
qb=8; //число инструментов разных

type
tg=record          //параметры генератора или модулятора
  s:byte;          //состояние 1-нарастание 2-макс 3-спад 0 - пауза
  ti:extended;     //время изменения состояния
  p,di,dp:extended;//период,длительность импульса и паузы %
  t1,tm,t2: extended; //время нарастания максимума и спада
  i1,i2: extended; //изменение амплитуды на отсчет
  f: extended;     //частота гц
  a: integer;      //амплитуда
  k: extended;     //коэфициент усиления 0..1
  wk:boolean;      //включен
  rm:boolean;      //растягивать максимум
end;

ti=record //инструмент
 n: string[16];//название
 g:tg;        //генератор основного тона
 m:tg;        //модулятор генератора
 mm:tg;       //модулятор модулятора
 ac: boolean; //активен
 ns: word;    //номер семпла, 0-семпл не создан
 ps: integer; //позиция семпла
 ds: integer; //длина семпла
 a:  integer; //амплитуда
 nn: byte;    //номер ноты
end;

asi=array[1..BlockSize] of smallInt;
pAsi=^asi;

var
tf:  textFile;
nz:  integer;   //еще надо записать отсчетов
tz:  integer;   //текущий отсчет
f:   integer;   //частота гц
r:   extended;  //частота радиан на отсчет
a:   integer;   //амплитуда
//sr:  extended;  //среднее значение
post:extended;  //вычитаемая постоянная составляющая
//g:tg;
display:tg;
//m:tg;         //модулятор
//mm:tg;        //модулятор модулятора
oWk:boolean=true; //выход
md: array of smallInt;
vol:integer;  //громкость
rrr:integer;
t:extended;   //текущее время
a2:extended;  //половина макс амплитуды для вычитания
h2,w:integer;
wfx: tWaveFormatEx;
s,td,ini: string;
note:array[1..12] of extended; //частоты нот 1 октавы
v:array[1..qv] of ti;  //инструменты играемые
b:array[1..qb] of ti; //инструменты все

//семплы 8 инструментов по 12 нот
ms:array[1..qi,1..qn] of record
  d:integer;//длина отсчетов
  z:array of smallInt; //звук
end;

Buf : array[1..2] of pAsi;

hwo : hWaveOut;
wh  : array[1..2] of tWaveHdr;
nb: byte;
iLoad:boolean=false; //инструменты загружены

// самостоятельная игра
auto:boolean=false;
mt: array[1..16] of integer; //массив такта 1..16
qt: integer;//число нот в такте
nd: integer;//номер играемого такта
qo: integer;//число прошедших отсчетов
dt: integer;//число отсчетов на долю такта
pt: integer;//проиграно тактов

PROCEDURE ik(var g:tg);
begin
//изменение коэфициентов генератора и модулятором
with g do begin
if wk then
case s of
 0: k:=0;
 1: begin k:=k+i1; if k>1 then k:=1 end;
 2: k:=1;
 3: begin k:=k-i2; if k<0 then k:=0 end;
end
else k:=1;
end
end;

PROCEDURE startI(ni,nt,amp:integer);
var nv:integer;
begin
//запуск инструмента ni с нотой nt амплтитудой a на игру
//поиск свободного
nv:=1;
while (nv<=qv)and v[nv].ac do inc(nv);
if nv>qv then nv:=1;
with v[nv] do begin
  ac:=false;
  ns:=ni;
  nn:=nt;
  ps:=1;
  ds:=ms[ni,nt].d;
  a:=amp;
  ac:=true;

end;
end;

PROCEDURE notaT(i:integer);
begin
//получение ноты для доли такта i в mt
if (random(10)<9) or(i=1) then mt[i]:=random(12)+1 else mt[i]:=0;
end;

PROCEDURE impuls(var p:pAsi;  size : LongInt);
var
i,z,sz,nt,d,a:integer;
ni:byte;
begin
// Заполнение массива активными инструментами
for i := 1 to size  do begin
  sz:=0;
  for ni:=1 to qv do with v[ni] do if ac then begin
    z:=ms[ns,nn].z[ps]*a div 24000;
    inc(sz,z);
    inc(ps);
    if ps>ds then ac:=false;
  end;

  if not oWk then sz:=0 else sz:=sz*vol div 1024;
  if sz>+32767 then sz:=+32767;
  if sz<-32767 then sz:=-32767;
  p^[i]:=sz;

  inc(qo);
  if auto and(qo>dt) then begin
//начинается новая доля такта
    qo:=0;
    inc(nd);
    if nd>qt then begin
//внесение разнообразия в новый такт
//смена тактового размера
      if random(10)=9 then if qt<8 then inc(qt,2);
      if random(10)=9 then if qt>2 then dec(qt,2);
      nd:=1;
      d:=random(qt)+1;      //смена 1 ноты такта
      notaT(d);
{     if pt mod 4=0 then
      if random(3)=2 then begin //смена темпа
        dec(dt,fo div 16);
        if dt<fo div 6 then dt:=fo div 4;
      end; }
      inc(pt);
      if random(10)>4 then begin
//аккорд в начале такта
        nt:=mt[1];
        if nt<6 then inc(nt,3+random(2))else dec(nt,3+random(2));
        startI(1,nt,20000);
      end;
    end;
    nt:=mt[nd];
    a:=24000-(nd-1)*2000;
    if nt>0 then begin
      startI(1,nt,a);
    end;
  end;
end;
end;


procedure WOutProc(h:HWAVEOUT;Msg:UINT;Inst,par1,par2:Dword);stdcall;
begin
if (msg=WOM_DONE) then begin
//Музыка кончилась
//заполняем проиграный буфер новым звуком и пишем снова
impuls(buf[nb], BlockSize);
//меняем буфер
waveOutWrite(hwo, @wh[nb], sizeof(WAVEHDR));
if nb=1 then nb:=2 else nb:=1;
end;
end;

procedure tForm1.WaveOutMess(var msg: TMessage);
begin
//Музыка кончилась
//заполняем проиграный буфер новым звуком и пишем снова
impuls(buf[nb], BlockSize);
//меняем буфер
waveOutWrite(hwo, @wh[nb], sizeof(WAVEHDR));
if nb=1 then nb:=2 else nb:=1;
end;

procedure Play;
var
i   : integer;
wfx : tWaveFormatEx;
si  : tSystemInfo;
begin
// заполнение параметров звука
fillChar(wfx,Sizeof(tWaveFormatEx),#0);
with wfx do begin
  wFormatTag:=WAVE_FORMAT_PCM;      // используется PCM формат
  nChannels:=1;                     // моно
  nSamplesPerSec:=fo;               // частота дискретизации
  wBitsPerSample:=16;               // размер отсчета бит
  nBlockAlign:=wBitsPerSample div 8 * nChannels; // число байт в выбоке
  nAvgBytesPerSec:=nSamplesPerSec * nBlockAlign; // число байт в секундном интервале
end;

//открытие устройства
//с посылкой сообщения окну
//  waveOutOpen(@hwo,WAVE_MAPPER,@Wfx,form1.Handle,0,CALLBACK_WINDOW);
//другой вариант с вызовом CALLBACK_FUNCTION
waveOutOpen(@hwo,WAVE_MAPPER,@Wfx,integer(@WOutProc),0,CALLBACK_FUNCTION);

// подготовка 2-ух буферов устройства
  for i:=1 to 2 do begin
// выделение памяти под буферы, выравниваются под страницу памяти Windows
    GetSystemInfo(si);
    buf[i]:=VirtualAlloc(nil,
    (BlockSize*2+si.dwPageSize-1) div si.dwPagesize*si.dwPageSize,
                         MEM_RESERVE or MEM_COMMIT, PAGE_READWRITE);
    FillChar(wh[i],sizeof(TWAVEHDR),#0);
    with wh[i] do begin
      lpData := @buf[i]^;            // указатель на буфер
      dwBufferLength := BlockSize*2; // длина буфера в байтах
      dwBytesRecorded := 0;
      dwUser := 0;
      dwFlags := 0;//WHDR_BEGINLOOP;//{WHDR_BEGINLOOP or WHDR_ENDLOOP or} WHDR_DONE;
      dwLoops := 0;//число повторов
    end;
    waveOutPrepareHeader(hwo, @wh[i], sizeof(TWAVEHDR));
//заполнение
    impuls(buf[i], BlockSize);
  end;

  nb:=1;//номер воспроизводимого буфера
//запуск воспроизведения
  for i:=1 to 2 do waveOutWrite(hwo, @wh[i], sizeof(WAVEHDR));
end;


function mypower(x,y:extended):extended;
begin
mypower:=0;
if x=0 then mypower:=0 else
if x>0 then mypower:=exp(y*ln(x))else
if trunc(y)<>y  then showMessage ('Не могу вычислить') else
if odd(trunc(y))=true then mypower:=-exp(y*ln(-x))
                      else mypower:=exp(y*ln(-x))
end;

PROCEDURE rdi(ni:byte);
begin
//иницилизация инструмента ni  по регуляторам

//модуляторы
with form1,v[ni].m do begin
p:=1/f;
di:=p*sbDIm.position/100;
dp:=p-di;
t1:=di*sbNm.position/100; //время нарастания
t2:=di*sbSm.position/100; //время спада
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //время максимума
//изменение коэфициента на отсчет
i1:=t1/ts; if i1>=1 then i1:=1/i1 else i1:=1;
i2:=t2/ts; if i2>=1 then i2:=1/i2 else i2:=1;
if Wk then k:=0 else k:=1;
s:=0;
ti:=t;
end;

//модулятор модулятора
with form1,v[ni].mm do begin
p:=sbFmm.position/1000;
di:=p*sbDImm.position/100;
dp:=p-di;
t1:=di*sbNmm.position/100; //время нарастания
t2:=di*sbSmm.position/100; //время спада
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //время максимума
//изменение коэфициента на отсчет
i1:=t1/ts; if i1>=1 then i1:=1/i1 else i1:=1;
i2:=t2/ts; if i2>=1 then i2:=1/i2 else i2:=1;

if Wk then k:=0 else k:=1;
s:=0;
ti:=t;
end;

//генератор
with form1,v[ni].g do begin
f:=v[ni].m.f*4;//trunc(myPower(10,sbF.position/100));
p:=1/f;
di:=p*sbDI.position/100;
dp:=p-di;
t1:=di*sbN.position/100; //время нарастания
t2:=di*sbS.position/100; //время спада
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //время максимума
//изменение коэфициента на отсчет
i1:=t1/ts; if i1>=1 then i1:=1/i1 else i1:=1;
i2:=t2/ts; if i2>=1 then i2:=1/i2 else i2:=1;
k:=0;
a:=20000;
a2:=a/2;
s:=0;
wk:=true;
ti:=t+dp;
end;

end;


procedure TForm1.outputClick(Sender: TObject);
begin
if not oWk then with v[1] do begin
g.k:=0; g.s:=0; m.k:=0; m.s:=0; mm.k:=0; mm.s:=0 end;
oWk:=outPut.Checked;
end;

procedure TForm1.sbVolChange(Sender: TObject);
begin
vol:=sbVol.position;
end;

Function wel:integer;
var se:string; i:integer;
begin
//выделение элемента до символа c из s
se:='';
i:=1;
while (i<=length(s))and(s[i]<>',') do begin
  if s[i] in['0'..'9'] then se:=se+s[i];
  inc(i);
end;
wel:=strToIntDef(trim(se),0);
delete(s,1,i);
end;

FUNCTION sb(sbp:tScrollBar):string;begin sb:=intToStr(sbp.position)+',' end;
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
{$i-}
assignFile(tf,ini);
rewrite(tf);
if ioresult<>0 then begin
  showMessage('Не смогла создать '#13+ini+#13+'и запомнить настройки');
  halt;
end;
{$i+}
write(tf,
'Музакальный автомат из http://programania.com'#13#10,
'Громкость='+sb(sbVol),#13#10,
'Масштаб='+sb(sbMas),#13#10,
'График='+sb(sbT),#13#10,
'Top='+intToStr(top),#13#10,
'Left='+intToStr(left),#13#10,
'Инструмент 1=',#13#10,
'Регуляторы=',
sb(sbf)+sb(sbdi)+sb(sbN)+sb(sbS),
sb(sbfm)+sb(sbdim)+sb(sbNm)+sb(sbSm),
sb(sbfmm)+sb(sbdimm)+sb(sbNmm)+sb(sbSmm)+sb(sbVol)+#13#10,
'Включатели=',
intToStr(integer(cbM.checked)),',',
intToStr(integer(cbMM.checked)),',',
intToStr(integer(outPut.checked)));

closeFile(tf);
end;


PROCEDURE gen(ni:integer);
var
i,nt,no,z:  integer;
pusk:  boolean;
puskM: boolean;
e,t: extended;
begin
//создание семплов инструмента i по qn нотам
for nt:=1 to qn do with v[ni] do begin
  m.f:=note[nt];
  rdi(ni);
  t:=0;
  no:=0;
  while t<=mm.di do begin
    pusk:=false;
    puskM:=false;
    if t>g.ti then with g do begin
//изменение состояния генератора
      case s of
        0: if k=0 then begin s:=1; ti:=t+t1;  pusk:=true end;
        1: if k=1 then begin s:=2; ti:=t+tm;  end;
        2: begin s:=3; ti:=t+t2;  k:=1; end;
        3: if k=0 then begin s:=0; ti:=t+dp; end;
      end;
    end;

    if (t>m.ti)and pusk and m.Wk and(g.k=0) then with m do begin
//изменение состояния модулятора синхронно с началом импульса
       case s of
         0: if k=0 then begin s:=1; ti:=t+t1; puskM:=true end;
         1: if k=1 then begin s:=2; ti:=t+tm; end;
         2: begin s:=3; ti:=t+t2;  k:=1; end;
         3: if k=0 then begin s:=0; ti:=t+dp; end;
       end;
     end;

     if (t>mm.ti)and (puskM or not m.Wk and pusk)and mm.Wk and(g.k=0)then with mm do begin
//изменение состояния модулятора модулятора синхронно с модулятором
       case s of
         0: if k=0 then begin s:=1; ti:=t+t1 end;
         1: if k=1 then begin s:=2; ti:=t+tm end;
         2: begin s:=3; ti:=t+t2; k:=1; end;
         3: if k=0 then begin
         s:=0; ti:=t+dp; {wp:=true; if p1 then} ac:=false end;
       end;
    end;

//изменение коэфициента генераторов и модуляторов
    ik(g);
    ik(m);
    ik(mm);

    if g.s=0 then e:=0 else e:=30000*g.k;

//модуляция
    z:=trunc((e-15000)*m.k*mm.k);
    t:=t+ts;
//запись в массив семпла
    inc(no);
    if no>=length(ms[ni,nt].z) then
    setLength(ms[ni,nt].z,no+100000);
    ms[ni,nt].z[no]:=z;
  end;
  ms[ni,nt].d:=no;
end;
end;

PROCEDURE vis(ni:integer);
var x,xx,y,m,n,d:integer;
begin
//показ семпла ni
with form1,form1.Image1.picture.Bitmap.canvas do begin
  fillrect(rect(0,0,w,h2*2));
  pen.color:=$CCCCCC; moveTo(0,h2); lineTo(w,h2);
  pen.color:=$2280DD;
  d:=ms[ni,1].d;
  sbT.max:=d-w;
  sbT.pageSize:=w;
  n:=sbT.position;
  m:=sbMas.position;
  m:=w+(d-w)*m div 100;
  for x:=1 to w do begin
    xx:=x*d div m;
    if xx<d then y:=h2-ms[ni,1].z[xx+n]*h2 div 16000 else y:=0;
    if x=1 then moveTo(0,y) else lineTo(x,y);
  end;
end;
end;

PROCEDURE ir;
var i:integer;
begin
// Изменение регулятора
if iLoad then begin
for i:=1 to qi do gen(i);
vis(1);
end;
end;

procedure TForm1.sbfChange(Sender: TObject);
begin ir; label1.caption:='Частота '+formatFloat('0',v[1].g.f)+' гц' end;
procedure TForm1.sbdiChange(Sender: TObject);
begin ir; label2.caption:='Длина импульса '+intToStr(sbDI.position)+'%' end;
procedure TForm1.sbNChange(Sender: TObject);
begin ir; label3.caption:='Нарастание '+intToStr(sbN.position)+'%' end;
procedure TForm1.sbSChange(Sender: TObject);
begin ir; label4.caption:='Спад '+intToStr(sbS.position)+'%' end;

procedure TForm1.sbFMChange(Sender: TObject);
begin ir; label5.caption:='Частота '+formatFloat('0',v[1].m.f)+' гц'end;
procedure TForm1.sbDIMChange(Sender: TObject);
begin ir; label6.caption:='Длина импульса '+intToStr(sbDIm.position)+'%' end;
procedure TForm1.sbNMChange(Sender: TObject);
begin ir; label7.caption:='Нарастание '+intToStr(sbNm.position)+'%'end;
procedure TForm1.sbSMChange(Sender: TObject);
begin ir; label8.caption:='Спад '+intToStr(sbSm.position)+'%'end;

procedure TForm1.sbFMMChange(Sender: TObject);
begin ir; label10.caption:='Период '+formatFloat('0.0',v[1].mm.p)+' сек.'end;
procedure TForm1.sbDIMmChange(Sender: TObject);
begin ir; label11.caption:='Длина импульса '+intToStr(sbDImm.position)+'%' end;
procedure TForm1.sbNMmChange(Sender: TObject);
begin ir; label12.caption:='Нарастание '+intToStr(sbNmm.position)+'%'end;
procedure TForm1.sbSMmChange(Sender: TObject);
begin ir; label13.caption:='Спад '+intToStr(sbSmm.position)+'%'end;

procedure TForm1.cbMClick(Sender: TObject);
begin v[1].m.Wk:=cbM.checked; if v[1].m.Wk then v[1].m.k:=0 else v[1].m.k:=1 end;
procedure TForm1.cbMMClick(Sender: TObject);
begin v[1].mm.Wk:=cbMm.checked; if not v[1].mm.Wk then v[1].mm.k:=0 else v[1].mm.k:=1 end;


procedure TForm1.FormCreate(Sender: TObject);
var
e:extended;
i:integer;
WOutCaps : tWaveOutCaps;

begin
// проверка наличия устройства вывода
FillChar(WOutCaps,SizeOf(TWAVEOUTCAPS),#0);
if mmSysErr_noError <> WaveOutGetDevCaps(0,@WOutCaps,SizeOf(TWAVEOUTCAPS)) then
begin
  showMessage('Не могу тут играть');
  halt;
end;
color:=$C0CCE0;
image1.Canvas.brush.color:=$D8E8FF;
td:=extractFilePath(application.exeName);
ini:=td+'Syn.ini';
assignFile(tf,ini);
{$i-}reset(tf);{$i+}
if ioresult<>0 then rewrite(tf) else
while not eof(tf) do begin
  readln(tf,s);
  if pos('Регуляторы=',s)=1 then begin
    sbf.position:=wel;   sbdi.position:=wel;   sbN.position:=wel;   sbS.position:=wel;
    sbfm.position:=wel;  sbdim.position:=wel;  sbNm.position:=wel;  sbSm.position:=wel;
    sbfmm.position:=wel; sbdimm.position:=wel; sbNmm.position:=wel; sbSmm.position:=wel;
    sbVol.position:=wel;
  end else
  if pos('Включатели=',s)=1 then begin
    cbM.checked:=bool(wel);
    cbMM.checked:=bool(wel);
    outPut.checked:=bool(wel);
  end else
  if pos('Top=',s)=1       then top:=wel  else
  if pos('Left=',s)=1      then left:=wel else
  if pos('Масштаб=',s)=1   then sbMas.position:=wel else
  if pos('Громкость=',s)=1 then sbVol.position:=wel else
  if pos('График=',s)=1    then begin
    i:=wel;if sbT.max<i then sbT.max:=i; sbT.position:=i;
  end;
end;
//v[1].m.Wk:=cbM.checked;
//g.wk:=true;mm.Wk:=cbMm.checked;
closeFile(tf);

with form1.Image1 do begin
  w:=width;
  h2:=height;
  picture.Bitmap.width:=w;
  picture.Bitmap.height:=h2;
  h2:=h2 div 2;
end;

vol:=form1.sbVol.position;
randomize;

//расчет нот из Ля 1 октавы - 440Гц
e:=myPower(2,1/12);
note[12]:=440*e*e;
for i:=11 downTo 1 do note[i]:=note[i+1]/e;

// подготовка параметров сигнала
for i:=1 to qi do with form1,v[i] do begin
  ac:=false; g.s:=0; m.s:=0; mm.s:=0; g.wk:=true; g.a:=20000;
  m.Wk:=cbM.checked; g.wk:=true; mm.Wk:=cbMm.checked;
end;

//создание семплов
iLoad:=true;
ir;
play
end;


procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var ni,n:byte;
begin
case chr(key) of
 '0'..'9','Ѕ'{189},'»'{187}: begin
    case chr(key) of
     '0':n:=10; 'Ѕ':n:=11;'»':n:=12;
    else n:=key-ord('1')+1;
    end;
    startI(1,n,20000);
  end;
end;
end;

procedure TForm1.sbfEnter(Sender: TObject);
begin
btnPlay.SetFocus
end;

procedure TForm1.btnPlayClick(Sender: TObject);
var i:integer;
begin
if auto then
 begin
  auto:=false;
  btnPlay.caption:='Играй сам'
 end
else begin
  qt:=(random(3)+2)*2; //число долей в такте
  for i:=1 to qt do notaT(i);
  pt:=0;
  qo:=0;
  dt:=fo div 5;
  auto:=true;
  btnPlay.caption:='Стоп'
end;
end;

procedure TForm1.sbMasChange(Sender: TObject);
begin
vis(1);
end;

procedure TForm1.sbTChange(Sender: TObject);
begin
if iLoad then vis(1);
end;


end.

{Создание
инструмент
переменные:
  длительность,
  частота
  амплитуда

остальные постоянные
  тип: относительные длительности и абсолютные
  генератор заполнения
  2 модулятора

Создать несколько приятных

такт
  несколько амплитуд 2..16
  несколько частот из ряда

и сохранение

однократное проигрывание по клавише

Ля 1 октавы - 440Гц
Ля 2 октавы - 880Гц
Ля 3 октавы - 1760Гц
Do1, DoD1, Re1, ReD1, Mi1, Fa1, FaD1, Sol1,SolD1,La1, LaD1, Si1,
Do2, DoD2, Re2, ReD2, Mi2, Fa2, FaD2, Sol2,SolD2,La2, LaD2, Si2

Музыкальный автомат

Почему музыку пишут как 1000 лет назад по нотам
это так утомительно а результат однообразен
Сейчас есть возможность задать
только правила и параметры музыки
а программа по ним будет создавать
музыку бесконечно и разнообразно
тогда музыку смогут сочинять широкие народные массы
Очевидно параметры иерархические и лучше в xml
<темп>
 Основной Bpm 50..200
 более мелкий 1..32
 разнообразие внутри такта
   по амплитуде 0-100%
   по частоте
 частота смены
    основного темпа
    внутри такта
    внутри такта
</темп>
<мелодия>
  Длина повторяемой части 0.100 от темпа
   Длина повторов внутри основной
     Длина повторов внутри основной
  число
</мелодия>

массив такта 1..16
}
