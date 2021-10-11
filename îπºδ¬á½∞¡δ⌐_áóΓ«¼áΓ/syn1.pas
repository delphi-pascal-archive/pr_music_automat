{
������ ����������� �����
��������� 0..9,-,=
��������: programania.com/syn.zip
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
BlockSize = (1024)*3; // ������ ������ ������

var
Form1: TForm1;

implementation

{$R *.DFM}
//��� �������
const fo=44100; tzn=fo div 8; tzk=fo div 8; ts=1/fo;
qi=1; //����� ������������
qv=8; //����� ������������ ������������ ��������
qn=12;//����� ��� � �����������
qb=8; //����� ������������ ������

type
tg=record          //��������� ���������� ��� ����������
  s:byte;          //��������� 1-���������� 2-���� 3-���� 0 - �����
  ti:extended;     //����� ��������� ���������
  p,di,dp:extended;//������,������������ �������� � ����� %
  t1,tm,t2: extended; //����� ���������� ��������� � �����
  i1,i2: extended; //��������� ��������� �� ������
  f: extended;     //������� ��
  a: integer;      //���������
  k: extended;     //���������� �������� 0..1
  wk:boolean;      //�������
  rm:boolean;      //����������� ��������
end;

ti=record //����������
 n: string[16];//��������
 g:tg;        //��������� ��������� ����
 m:tg;        //��������� ����������
 mm:tg;       //��������� ����������
 ac: boolean; //�������
 ns: word;    //����� ������, 0-����� �� ������
 ps: integer; //������� ������
 ds: integer; //����� ������
 a:  integer; //���������
 nn: byte;    //����� ����
end;

asi=array[1..BlockSize] of smallInt;
pAsi=^asi;

var
tf:  textFile;
nz:  integer;   //��� ���� �������� ��������
tz:  integer;   //������� ������
f:   integer;   //������� ��
r:   extended;  //������� ������ �� ������
a:   integer;   //���������
//sr:  extended;  //������� ��������
post:extended;  //���������� ���������� ������������
//g:tg;
display:tg;
//m:tg;         //���������
//mm:tg;        //��������� ����������
oWk:boolean=true; //�����
md: array of smallInt;
vol:integer;  //���������
rrr:integer;
t:extended;   //������� �����
a2:extended;  //�������� ���� ��������� ��� ���������
h2,w:integer;
wfx: tWaveFormatEx;
s,td,ini: string;
note:array[1..12] of extended; //������� ��� 1 ������
v:array[1..qv] of ti;  //����������� ��������
b:array[1..qb] of ti; //����������� ���

//������ 8 ������������ �� 12 ���
ms:array[1..qi,1..qn] of record
  d:integer;//����� ��������
  z:array of smallInt; //����
end;

Buf : array[1..2] of pAsi;

hwo : hWaveOut;
wh  : array[1..2] of tWaveHdr;
nb: byte;
iLoad:boolean=false; //����������� ���������

// ��������������� ����
auto:boolean=false;
mt: array[1..16] of integer; //������ ����� 1..16
qt: integer;//����� ��� � �����
nd: integer;//����� ��������� �����
qo: integer;//����� ��������� ��������
dt: integer;//����� �������� �� ���� �����
pt: integer;//��������� ������

PROCEDURE ik(var g:tg);
begin
//��������� ������������ ���������� � �����������
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
//������ ����������� ni � ����� nt ����������� a �� ����
//����� ����������
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
//��������� ���� ��� ���� ����� i � mt
if (random(10)<9) or(i=1) then mt[i]:=random(12)+1 else mt[i]:=0;
end;

PROCEDURE impuls(var p:pAsi;  size : LongInt);
var
i,z,sz,nt,d,a:integer;
ni:byte;
begin
// ���������� ������� ��������� �������������
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
//���������� ����� ���� �����
    qo:=0;
    inc(nd);
    if nd>qt then begin
//�������� ������������ � ����� ����
//����� ��������� �������
      if random(10)=9 then if qt<8 then inc(qt,2);
      if random(10)=9 then if qt>2 then dec(qt,2);
      nd:=1;
      d:=random(qt)+1;      //����� 1 ���� �����
      notaT(d);
{     if pt mod 4=0 then
      if random(3)=2 then begin //����� �����
        dec(dt,fo div 16);
        if dt<fo div 6 then dt:=fo div 4;
      end; }
      inc(pt);
      if random(10)>4 then begin
//������ � ������ �����
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
//������ ���������
//��������� ���������� ����� ����� ������ � ����� �����
impuls(buf[nb], BlockSize);
//������ �����
waveOutWrite(hwo, @wh[nb], sizeof(WAVEHDR));
if nb=1 then nb:=2 else nb:=1;
end;
end;

procedure tForm1.WaveOutMess(var msg: TMessage);
begin
//������ ���������
//��������� ���������� ����� ����� ������ � ����� �����
impuls(buf[nb], BlockSize);
//������ �����
waveOutWrite(hwo, @wh[nb], sizeof(WAVEHDR));
if nb=1 then nb:=2 else nb:=1;
end;

procedure Play;
var
i   : integer;
wfx : tWaveFormatEx;
si  : tSystemInfo;
begin
// ���������� ���������� �����
fillChar(wfx,Sizeof(tWaveFormatEx),#0);
with wfx do begin
  wFormatTag:=WAVE_FORMAT_PCM;      // ������������ PCM ������
  nChannels:=1;                     // ����
  nSamplesPerSec:=fo;               // ������� �������������
  wBitsPerSample:=16;               // ������ ������� ���
  nBlockAlign:=wBitsPerSample div 8 * nChannels; // ����� ���� � ������
  nAvgBytesPerSec:=nSamplesPerSec * nBlockAlign; // ����� ���� � ��������� ���������
end;

//�������� ����������
//� �������� ��������� ����
//  waveOutOpen(@hwo,WAVE_MAPPER,@Wfx,form1.Handle,0,CALLBACK_WINDOW);
//������ ������� � ������� CALLBACK_FUNCTION
waveOutOpen(@hwo,WAVE_MAPPER,@Wfx,integer(@WOutProc),0,CALLBACK_FUNCTION);

// ���������� 2-�� ������� ����������
  for i:=1 to 2 do begin
// ��������� ������ ��� ������, ������������� ��� �������� ������ Windows
    GetSystemInfo(si);
    buf[i]:=VirtualAlloc(nil,
    (BlockSize*2+si.dwPageSize-1) div si.dwPagesize*si.dwPageSize,
                         MEM_RESERVE or MEM_COMMIT, PAGE_READWRITE);
    FillChar(wh[i],sizeof(TWAVEHDR),#0);
    with wh[i] do begin
      lpData := @buf[i]^;            // ��������� �� �����
      dwBufferLength := BlockSize*2; // ����� ������ � ������
      dwBytesRecorded := 0;
      dwUser := 0;
      dwFlags := 0;//WHDR_BEGINLOOP;//{WHDR_BEGINLOOP or WHDR_ENDLOOP or} WHDR_DONE;
      dwLoops := 0;//����� ��������
    end;
    waveOutPrepareHeader(hwo, @wh[i], sizeof(TWAVEHDR));
//����������
    impuls(buf[i], BlockSize);
  end;

  nb:=1;//����� ���������������� ������
//������ ���������������
  for i:=1 to 2 do waveOutWrite(hwo, @wh[i], sizeof(WAVEHDR));
end;


function mypower(x,y:extended):extended;
begin
mypower:=0;
if x=0 then mypower:=0 else
if x>0 then mypower:=exp(y*ln(x))else
if trunc(y)<>y  then showMessage ('�� ���� ���������') else
if odd(trunc(y))=true then mypower:=-exp(y*ln(-x))
                      else mypower:=exp(y*ln(-x))
end;

PROCEDURE rdi(ni:byte);
begin
//������������ ����������� ni  �� �����������

//����������
with form1,v[ni].m do begin
p:=1/f;
di:=p*sbDIm.position/100;
dp:=p-di;
t1:=di*sbNm.position/100; //����� ����������
t2:=di*sbSm.position/100; //����� �����
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //����� ���������
//��������� ����������� �� ������
i1:=t1/ts; if i1>=1 then i1:=1/i1 else i1:=1;
i2:=t2/ts; if i2>=1 then i2:=1/i2 else i2:=1;
if Wk then k:=0 else k:=1;
s:=0;
ti:=t;
end;

//��������� ����������
with form1,v[ni].mm do begin
p:=sbFmm.position/1000;
di:=p*sbDImm.position/100;
dp:=p-di;
t1:=di*sbNmm.position/100; //����� ����������
t2:=di*sbSmm.position/100; //����� �����
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //����� ���������
//��������� ����������� �� ������
i1:=t1/ts; if i1>=1 then i1:=1/i1 else i1:=1;
i2:=t2/ts; if i2>=1 then i2:=1/i2 else i2:=1;

if Wk then k:=0 else k:=1;
s:=0;
ti:=t;
end;

//���������
with form1,v[ni].g do begin
f:=v[ni].m.f*4;//trunc(myPower(10,sbF.position/100));
p:=1/f;
di:=p*sbDI.position/100;
dp:=p-di;
t1:=di*sbN.position/100; //����� ����������
t2:=di*sbS.position/100; //����� �����
if t1+t2>di then t2:=di-t1;
tm:=di-t1-t2;  //����� ���������
//��������� ����������� �� ������
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
//��������� �������� �� ������� c �� s
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
  showMessage('�� ������ ������� '#13+ini+#13+'� ��������� ���������');
  halt;
end;
{$i+}
write(tf,
'����������� ������� �� http://programania.com'#13#10,
'���������='+sb(sbVol),#13#10,
'�������='+sb(sbMas),#13#10,
'������='+sb(sbT),#13#10,
'Top='+intToStr(top),#13#10,
'Left='+intToStr(left),#13#10,
'���������� 1=',#13#10,
'����������=',
sb(sbf)+sb(sbdi)+sb(sbN)+sb(sbS),
sb(sbfm)+sb(sbdim)+sb(sbNm)+sb(sbSm),
sb(sbfmm)+sb(sbdimm)+sb(sbNmm)+sb(sbSmm)+sb(sbVol)+#13#10,
'����������=',
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
//�������� ������� ����������� i �� qn �����
for nt:=1 to qn do with v[ni] do begin
  m.f:=note[nt];
  rdi(ni);
  t:=0;
  no:=0;
  while t<=mm.di do begin
    pusk:=false;
    puskM:=false;
    if t>g.ti then with g do begin
//��������� ��������� ����������
      case s of
        0: if k=0 then begin s:=1; ti:=t+t1;  pusk:=true end;
        1: if k=1 then begin s:=2; ti:=t+tm;  end;
        2: begin s:=3; ti:=t+t2;  k:=1; end;
        3: if k=0 then begin s:=0; ti:=t+dp; end;
      end;
    end;

    if (t>m.ti)and pusk and m.Wk and(g.k=0) then with m do begin
//��������� ��������� ���������� ��������� � ������� ��������
       case s of
         0: if k=0 then begin s:=1; ti:=t+t1; puskM:=true end;
         1: if k=1 then begin s:=2; ti:=t+tm; end;
         2: begin s:=3; ti:=t+t2;  k:=1; end;
         3: if k=0 then begin s:=0; ti:=t+dp; end;
       end;
     end;

     if (t>mm.ti)and (puskM or not m.Wk and pusk)and mm.Wk and(g.k=0)then with mm do begin
//��������� ��������� ���������� ���������� ��������� � �����������
       case s of
         0: if k=0 then begin s:=1; ti:=t+t1 end;
         1: if k=1 then begin s:=2; ti:=t+tm end;
         2: begin s:=3; ti:=t+t2; k:=1; end;
         3: if k=0 then begin
         s:=0; ti:=t+dp; {wp:=true; if p1 then} ac:=false end;
       end;
    end;

//��������� ����������� ����������� � �����������
    ik(g);
    ik(m);
    ik(mm);

    if g.s=0 then e:=0 else e:=30000*g.k;

//���������
    z:=trunc((e-15000)*m.k*mm.k);
    t:=t+ts;
//������ � ������ ������
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
//����� ������ ni
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
// ��������� ����������
if iLoad then begin
for i:=1 to qi do gen(i);
vis(1);
end;
end;

procedure TForm1.sbfChange(Sender: TObject);
begin ir; label1.caption:='������� '+formatFloat('0',v[1].g.f)+' ��' end;
procedure TForm1.sbdiChange(Sender: TObject);
begin ir; label2.caption:='����� �������� '+intToStr(sbDI.position)+'%' end;
procedure TForm1.sbNChange(Sender: TObject);
begin ir; label3.caption:='���������� '+intToStr(sbN.position)+'%' end;
procedure TForm1.sbSChange(Sender: TObject);
begin ir; label4.caption:='���� '+intToStr(sbS.position)+'%' end;

procedure TForm1.sbFMChange(Sender: TObject);
begin ir; label5.caption:='������� '+formatFloat('0',v[1].m.f)+' ��'end;
procedure TForm1.sbDIMChange(Sender: TObject);
begin ir; label6.caption:='����� �������� '+intToStr(sbDIm.position)+'%' end;
procedure TForm1.sbNMChange(Sender: TObject);
begin ir; label7.caption:='���������� '+intToStr(sbNm.position)+'%'end;
procedure TForm1.sbSMChange(Sender: TObject);
begin ir; label8.caption:='���� '+intToStr(sbSm.position)+'%'end;

procedure TForm1.sbFMMChange(Sender: TObject);
begin ir; label10.caption:='������ '+formatFloat('0.0',v[1].mm.p)+' ���.'end;
procedure TForm1.sbDIMmChange(Sender: TObject);
begin ir; label11.caption:='����� �������� '+intToStr(sbDImm.position)+'%' end;
procedure TForm1.sbNMmChange(Sender: TObject);
begin ir; label12.caption:='���������� '+intToStr(sbNmm.position)+'%'end;
procedure TForm1.sbSMmChange(Sender: TObject);
begin ir; label13.caption:='���� '+intToStr(sbSmm.position)+'%'end;

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
// �������� ������� ���������� ������
FillChar(WOutCaps,SizeOf(TWAVEOUTCAPS),#0);
if mmSysErr_noError <> WaveOutGetDevCaps(0,@WOutCaps,SizeOf(TWAVEOUTCAPS)) then
begin
  showMessage('�� ���� ��� ������');
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
  if pos('����������=',s)=1 then begin
    sbf.position:=wel;   sbdi.position:=wel;   sbN.position:=wel;   sbS.position:=wel;
    sbfm.position:=wel;  sbdim.position:=wel;  sbNm.position:=wel;  sbSm.position:=wel;
    sbfmm.position:=wel; sbdimm.position:=wel; sbNmm.position:=wel; sbSmm.position:=wel;
    sbVol.position:=wel;
  end else
  if pos('����������=',s)=1 then begin
    cbM.checked:=bool(wel);
    cbMM.checked:=bool(wel);
    outPut.checked:=bool(wel);
  end else
  if pos('Top=',s)=1       then top:=wel  else
  if pos('Left=',s)=1      then left:=wel else
  if pos('�������=',s)=1   then sbMas.position:=wel else
  if pos('���������=',s)=1 then sbVol.position:=wel else
  if pos('������=',s)=1    then begin
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

//������ ��� �� �� 1 ������ - 440��
e:=myPower(2,1/12);
note[12]:=440*e*e;
for i:=11 downTo 1 do note[i]:=note[i+1]/e;

// ���������� ���������� �������
for i:=1 to qi do with form1,v[i] do begin
  ac:=false; g.s:=0; m.s:=0; mm.s:=0; g.wk:=true; g.a:=20000;
  m.Wk:=cbM.checked; g.wk:=true; mm.Wk:=cbMm.checked;
end;

//�������� �������
iLoad:=true;
ir;
play
end;


procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var ni,n:byte;
begin
case chr(key) of
 '0'..'9','�'{189},'�'{187}: begin
    case chr(key) of
     '0':n:=10; '�':n:=11;'�':n:=12;
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
  btnPlay.caption:='����� ���'
 end
else begin
  qt:=(random(3)+2)*2; //����� ����� � �����
  for i:=1 to qt do notaT(i);
  pt:=0;
  qo:=0;
  dt:=fo div 5;
  auto:=true;
  btnPlay.caption:='����'
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

{��������
����������
����������:
  ������������,
  �������
  ���������

��������� ����������
  ���: ������������� ������������ � ����������
  ��������� ����������
  2 ����������

������� ��������� ��������

����
  ��������� �������� 2..16
  ��������� ������ �� ����

� ����������

����������� ������������ �� �������

�� 1 ������ - 440��
�� 2 ������ - 880��
�� 3 ������ - 1760��
Do1, DoD1, Re1, ReD1, Mi1, Fa1, FaD1, Sol1,SolD1,La1, LaD1, Si1,
Do2, DoD2, Re2, ReD2, Mi2, Fa2, FaD2, Sol2,SolD2,La2, LaD2, Si2

����������� �������

������ ������ ����� ��� 1000 ��� ����� �� �����
��� ��� ����������� � ��������� �����������
������ ���� ����������� ������
������ ������� � ��������� ������
� ��������� �� ��� ����� ���������
������ ���������� � ������������
����� ������ ������ �������� ������� �������� �����
�������� ��������� ������������� � ����� � xml
<����>
 �������� Bpm 50..200
 ����� ������ 1..32
 ������������ ������ �����
   �� ��������� 0-100%
   �� �������
 ������� �����
    ��������� �����
    ������ �����
    ������ �����
</����>
<�������>
  ����� ����������� ����� 0.100 �� �����
   ����� �������� ������ ��������
     ����� �������� ������ ��������
  �����
</�������>

������ ����� 1..16
}
