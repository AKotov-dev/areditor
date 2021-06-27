unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, Process;

type

  { TMainForm }

  TMainForm = class(TForm)
    Label1: TLabel;
    DevListBox: TListBox;
    Label2: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    UpdateBtn: TSpeedButton;
    ApplyBtn: TSpeedButton;
    DefaultBtn: TSpeedButton;
    procedure DevListBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure UpdateBtnClick(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure DefaultBtnClick(Sender: TObject);
    procedure StartScan;

  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

//StartScan
procedure TMainForm.StartScan;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('lsusb');
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Execute;

    DevListBox.Items.LoadFromStream(ExProcess.Output);
  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.UpdateBtnClick(Sender: TObject);
begin
  StartScan;
  if FileExists('/usr/lib/udev/rules.d/51-android.rules') then
    Memo1.Lines.LoadFromFile('/usr/lib/udev/rules.d/51-android.rules');
end;

procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  output: ansistring;
begin
  Memo1.Lines.SaveToFile(ExtractFilePath(ParamStr(0)) + '51-android.rules_tmp');

  //Apply rules
  Application.ProcessMessages;

  RunCommand('/usr/bin/bash',
    ['-c', '/usr/bin/pkexec /usr/bin/bash -c "cp -f ' + '''' +
    ExtractFilePath(ParamStr(0)) + '51-android.rules_tmp' + '''' +
    ' /usr/lib/udev/rules.d/51-android.rules; udevadm control --reload-rules; udevadm trigger'
    + '"'], output);
end;

//Resore Default
procedure TMainForm.DefaultBtnClick(Sender: TObject);
var
  output: ansistring;
begin
  //Apply rules
  Application.ProcessMessages;

  RunCommand('/usr/bin/bash',
    ['-c', '/usr/bin/pkexec /usr/bin/bash -c "cp -f ' + '''' +
    ExtractFilePath(ParamStr(0)) + '51-android.rules' + '''' +
    ' /usr/lib/udev/rules.d/51-android.rules; udevadm control --reload-rules; udevadm trigger'
    + '"'], output);

  //Update
  UpdateBtn.Click;
end;

//Scan connected USB-devices
procedure TMainForm.FormShow(Sender: TObject);
begin
  UpdateBtn.Click;
end;

procedure TMainForm.DevListBoxClick(Sender: TObject);
var
  i: integer;
  idVendor: string;
begin
  idVendor := 'ATTR{idVendor}=="' + Copy(DevListBox.Items[DevListBox.ItemIndex],
    24, 4) + '"';
  //Label3.Caption:='ATTR{idProduct}=="' + Copy(DevListBox.Items[DevListBox.ItemIndex], 29, 4) + '"';

  i := Pos(idVendor, Memo1.Text);
  if i <> 0 then
  begin
    Memo2.Text := 'The device is already in the list of rules. No action is needed.';
    Memo1.SelStart := i - 1;
    Memo1.SelLength := 22;
    //AddBtn.Enabled := False;
  end
  else
  begin
    Memo2.Clear;
    Memo2.Lines.Add('#My Android device');
    Memo2.Lines.Add('SUBSYSTEM=="usb", ' + idVendor + ', ENV{adb_user}="yes"');
    //AddBtn.Enabled := True;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
end;

end.
