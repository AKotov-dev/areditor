unit Udev_TRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  StartUdevReload = class(TThread)
  private

    { Private declarations }
  protected

    procedure Execute; override;

  end;

implementation

{ TRD }

//udev reload
procedure StartUdevReload.Execute;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    //   ExProcess.Options := [poWaitOnExit];
    ExProcess.Parameters.Add('udevadm control --reload-rules; udevadm trigger');
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

end.

