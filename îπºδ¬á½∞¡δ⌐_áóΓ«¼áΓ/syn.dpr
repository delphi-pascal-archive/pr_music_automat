program syn;

uses
  Forms,
  syn1 in 'syn1.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '����������� �������';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
