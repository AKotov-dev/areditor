unit about_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Bevel1: TBevel;
    Button1: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  Label1.Caption := Application.Title;
end;

procedure TAboutForm.FormShow(Sender: TObject);
begin
  //Scaling in Plasma
  AboutForm.Height := Button1.Top + Button1.Height + 10;
  AboutForm.Width := Label2.Left + Label2.Width + 20;
end;

procedure TAboutForm.Button1Click(Sender: TObject);
begin
  AboutForm.Close;
end;

procedure TAboutForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

end.

