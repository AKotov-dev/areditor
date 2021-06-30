unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Process, FileUtil, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    Label1: TLabel;
    DevListBox: TListBox;
    Label2: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    AddBtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    StaticText1: TStaticText;
    UpdateBtn: TSpeedButton;
    DefaultBtn: TSpeedButton;
    procedure AddBtnClick(Sender: TObject);
    procedure DevListBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure DefaultBtnClick(Sender: TObject);
    procedure StartScan;
    procedure UdevReload;
    procedure RestoreDefault;

  private

  public

  end;

resourcestring
  SNoAction = 'The device is already in the list of rules. No action is needed.';
  SFileNotFound =
    'The main rules file was not found:' + #10#13 +
    '/usr/lib/udev/rules.d/51-android.rules';
  SNoDevices = 'No devices were found...';
  SRestoreDefault = 'Your changes will be reset! Continue?';

var
  MainForm: TMainForm;

implementation

uses Udev_TRD, About_Unit;

{$R *.lfm}

{ TMainForm }

//Restore Default
procedure TMainForm.RestoreDefault;
begin
  UdevReload;
  UpdateBtn.Click;
end;

//udev reload
procedure TMainForm.UdevReload;
var
  FUdevReloadThread: TThread;
begin
  //Запуск потока udev
  FUdevReloadThread := StartUdevReload.Create(False);
  FUdevReloadThread.Priority := tpNormal;
end;

//StartScan (Update usb-devices list)
procedure TMainForm.StartScan;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('lsusb | grep -vE "hub|Hub|Reader|Keyboard|Mouse"');
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Execute;

    DevListBox.Items.LoadFromStream(ExProcess.Output);

    if DevListBox.Count <> 0 then
    begin
      DevListBox.ItemIndex := 0;
      DevListBox.Click;
    end
    else
    begin
      Memo2.Text := SNoDevices;
      AddBtn.Enabled := False;
    end;

  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  Memo1.Lines.LoadFromFile('/etc/udev/rules.d/51-android.rules');
  StartScan;
end;

//Resore Default
procedure TMainForm.DefaultBtnClick(Sender: TObject);
begin
  if MessageDlg(SRestoreDefault, mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    //Copy Default rules
    CopyFile('/usr/lib/udev/rules.d/51-android.rules',
      '/etc/udev/rules.d/51-android.rules', [cffOverwriteFile]);

    RestoreDefault;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Есть ли основной файл правил? Нет - Выход!
  if not FileExists('/usr/lib/udev/rules.d/51-android.rules') then
  begin
    MessageDlg(SFileNotFound, mtError, [mbOK], 0);
    Application.Terminate;
  end
  else
  if not FileExists('/etc/udev/rules.d/51-android.rules') then
    //Copy Default rules
    CopyFile('/usr/lib/udev/rules.d/51-android.rules',
      '/etc/udev/rules.d/51-android.rules', [cffOverwriteFile]);

  MainForm.Caption := Application.Title;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //Загружаем файл 51-android.rules и перечитываем устройства
  UpdateBtn.Click;
end;

//О программе
procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Self);
  AboutForm.ShowModal;
end;

//Поиск idVerndor и установка курсора + select
procedure TMainForm.DevListBoxClick(Sender: TObject);
var
  i: integer;
  idVendor: string;
begin
  if DevListBox.Count = 0 then
    Exit;

  idVendor := 'ATTR{idVendor}=="' + Copy(DevListBox.Items[DevListBox.ItemIndex],
    24, 4) + '"';

  i := Pos(idVendor, Memo1.Text);
  if i <> 0 then
  begin
    Memo2.Text := SNoAction;
    Memo1.SelStart := i - 1;
    Memo1.SelLength := 22;
    AddBtn.Enabled := False;
  end
  else
  begin
    Memo2.Clear;
    Memo2.Lines.Add('# My Android device');
    Memo2.Lines.Add('SUBSYSTEM=="usb", ' + idVendor + ', ENV{adb_user}="yes"');
    Memo1.SelStart := 0;
    AddBtn.Enabled := True;
  end;
end;

//Добавляем правила устройства
procedure TMainForm.AddBtnClick(Sender: TObject);
begin
  //Insert Rule
  with Memo1 do
  begin
    SetFocus;
    SelStart := Pos('# Skip other vendor tests', Text);
    Lines.Insert(CaretPos.Y - 1, '');
    Lines.Insert(CaretPos.Y + 0, Memo2.Lines[0]);
    Lines.Insert(CaretPos.Y + 1, Memo2.Lines[1]);
    Lines.Insert(CaretPos.Y + 2, '');
  end;

  //Apply rules
  Memo1.Lines.SaveToFile('/etc/udev/rules.d/51-android.rules');
  //Перименяем новые правила
  UdevReload;
  //Курсор и select
  DevListBox.Click;
end;

end.
