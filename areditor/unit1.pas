unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, Process, FileUtil, LCLType, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ENVBox: TComboBox;
    FindDialog1: TFindDialog;
    Label1: TLabel;
    DevListBox: TListBox;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    AddBtn: TSpeedButton;
    AboutBtn: TSpeedButton;
    SearchBtn: TSpeedButton;
    StaticText1: TStaticText;
    UpdateBtn: TSpeedButton;
    DefaultBtn: TSpeedButton;
    procedure AddBtnClick(Sender: TObject);
    procedure DevListBoxClick(Sender: TObject);
    procedure DevListBoxKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure ENVBoxChange(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
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
  SReconnectDevice = 'Reconnect your device.';

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
    ExProcess.Parameters.Add('lsusb | grep -ivE "Hub$|Reader$|Keyboard$|Mouse$"');
    ExProcess.Options := [poUsePipes]; //poStderrToOutPut
    ExProcess.Execute;

    DevListBox.Items.LoadFromStream(ExProcess.Output);

    if DevListBox.Count <> 0 then
      DevListBox.ItemIndex := 0
    else
    begin
      Memo2.Text := SNoDevices;
      AddBtn.Enabled := False;
      ENVBox.Enabled := False;
    end;

    //Обработка и принятие решения
    DevListBox.Click;

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

    Application.ProcessMessages;
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

//Вызов диалога поиска
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (Key = Ord('F')) and (ssCtrl in Shift) then
    SearchBtn.Click;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //Загружаем файл 51-android.rules и перечитываем устройства
  UpdateBtn.Click;
end;

//О программе
procedure TMainForm.AboutBtnClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Self);
  AboutForm.ShowModal;
end;

procedure TMainForm.SearchBtnClick(Sender: TObject);
begin
  //Позиция окна поиска
  FindDialog1.Top := MainForm.Top + 100;
  FindDialog1.Left := MainForm.Left + 100;
  //Показать диалог поиска
  FindDialog1.Execute;
end;

//Поиск idVerndor и установка курсора + select
procedure TMainForm.DevListBoxClick(Sender: TObject);
var
  x, y: integer;
  idVendor, idProduct, Description: string;
begin
  //Переменная окружения при щелчке = Default
  ENVBox.ItemIndex := 0;
  //Автоширина по тексту (вне фокуса)
  // ENVBox.Width := Canvas.GetTextWidth(Text) + 29;

  //Если список устройств не пуст
  if DevListBox.Count <> 0 then
  begin
    Screen.Cursor := crHourGlass;

    //Определяем idVendor, idProduct и Description
    idVendor := '"' + Copy(DevListBox.Items[DevListBox.ItemIndex], 24, 4) + '"';
    idProduct := '"' + Copy(DevListBox.Items[DevListBox.ItemIndex], 29, 4) + '"';
    Description := Copy(DevListBox.Items[DevListBox.ItemIndex], 34,
      Length(DevListBox.Items[DevListBox.ItemIndex]));

    //Поиск-1: только Вендор (разрешает все продукты этого вендора)
    x := Pos('ATTR{idVendor}==' + idVendor + ', ENV{adb_user}="yes"', Memo1.Text);

    if x = 0 then
      //Поиск-2: Вендор и Продукт
      x := Pos('ATTR{idVendor}==' + idVendor + ', ATTR{idProduct}==' +
        idProduct + ',', Memo1.Text);

    //Если найдено - выделяем строку idVendor или idVendor + idProduct
    if x <> 0 then
    begin
      Memo1.SetFocus;
      Memo1.SelStart := x - 1;
      Memo1.SelLength := Memo1.Lines[Memo1.CaretPos.Y].Length + 1;
    end;

    //Поиск-3: Вендор и Продукт в списке (GOTO/LABEL)
    if x = 0 then
    begin
      //Cтавим курсор в начало найденной строки
      x := Pos('ATTR{idVendor}!=' + idVendor, Memo1.Text);

      if x <> 0 then
      begin
        Memo1.SetFocus;
        Memo1.SelStart := x - 1;
        y := Memo1.CaretPos.Y;

        x := 0;
        //Пока не найден конец блока вендора - выделять содержимое
        while Pos('LABEL=', Memo1.Lines[y]) = 0 do
        begin
          x := x + Memo1.Lines[y].Length + 1;
          Memo1.SelLength := x;
          Inc(y);
        end;

        //Ищем idProduct в выделенном блоке вендора
        x := Pos('ATTR{idProduct}==' + idProduct, Memo1.SelText);
      end;
    end;

    //Решение парсинга
    if x <> 0 then
    begin
      Memo2.Text := SNoAction;
      AddBtn.Enabled := False;
    end
    else
    begin
      Memo2.Clear;
      Memo2.Lines.Add('# ' + Description);
      Memo2.Lines.Add('ATTR{idVendor}==' + idVendor + ', ATTR{idProduct}==' +
        idProduct + ', ' + ENVBox.Text);
      Memo1.SelStart := 0;
      AddBtn.Enabled := True;
    end;
    //Состояние списка выбора окружения
    ENVBox.Enabled := AddBtn.Enabled;

    Screen.Cursor := crDefault;
  end;
end;

//Отключаем Ctrl + комбинации в ListBox
procedure TMainForm.DevListBoxKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if (Key <> VK_UP) and (Key <> VK_DOWN) then
    Key := 0;
end;

//Выбор нужного ENV
procedure TMainForm.ENVBoxChange(Sender: TObject);
begin
  //Формируем строку правила
  Memo2.Lines[1] := Copy(Memo2.Lines[1], 1, 49) + ENVBox.Text;
  //Автоширина по тексту
  // ENVBox.Width := ENVBox.Canvas.GetTextWidth(ENVBox.Text) + 50;
end;


//Поиск текста
procedure TMainForm.FindDialog1Find(Sender: TObject);
var
  i: integer;
  Buf, Str: string;
begin
  Str := FindDialog1.FindText;

  if frDown in FindDialog1.Options then
  begin
    Buf := Copy(Memo1.Text, Memo1.SelStart + Memo1.SelLength + 1, Length(Memo1.Text));
    if not (frMatchCase in FindDialog1.Options) then
    begin
      Buf := UpperCase(Buf);
      i := Pos(UpperCase(Str), Buf);
    end
    else
      i := Pos(Str, Buf);
    if i = 0 then
    begin
      //  ShowMessage('не ');
      Exit;
    end
    else
    begin
      i := i + Memo1.SelStart + Memo1.SelLength;
      Memo1.SelStart := i - 1;
      Memo1.SelLength := Length(Str);
      Exit;
    end;
  end
  else
  begin
    Buf := Copy(Memo1.Text, 0, Memo1.SelStart);
    if not (frMatchCase in FindDialog1.Options) then
    begin
      Buf := UpperCase(Buf);
      Str := UpperCase(Str);
    end;

    for i := Length(Buf) + 1 - Length(Str) downto 1 do
    begin
      if Copy(Buf, i, Length(Str)) = Str then
      begin
        Memo1.SelStart := i - 1;
        Memo1.SelLength := Length(Str);
        Exit;
      end;
    end;
    // ShowMessage('не ');
    Exit;
  end;
end;

//Добавляем правила устройства
procedure TMainForm.AddBtnClick(Sender: TObject);
begin
  //Insert Rule
  with Memo1 do
  begin
    SetFocus;
    SelStart := Pos('LABEL="android_usb_rules_begin"', Text);
    // Lines.Insert(CaretPos.Y - 1, '');
    Lines.Insert(CaretPos.Y + 1, Memo2.Lines[0]);
    Lines.Insert(CaretPos.Y + 2, Memo2.Lines[1]);
    Lines.Insert(CaretPos.Y + 3, '');

    //Сохраняем новые правила
    Lines.SaveToFile('/etc/udev/rules.d/51-android.rules');
  end;

  //Курсор и Select
  DevListBox.Click;

  //Перименяем новые правила
  UdevReload;

  //Переподключить устройство
  // Application.ProcessMessages;
  MessageDlg(SReconnectDevice, mtInformation, [mbOK], 0);
end;

end.
