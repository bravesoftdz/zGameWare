unit Movementdebugfrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  MovementDebugViewFrameUnit, CoreClasses;

type
  TExecutePlatform = (epWin32, epWin64, epOSX, epIOS, epIOSSIM, epANDROID, epUnknow);

  TMovementDebugForm = class(TForm)
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    FInitUIScale: Double;
    FMovementFrame: TMovementDebugViewFrame;
  public
    { Public declarations }
  end;

const
{$IF Defined(WIN32)}
  CurrentPlatform = TExecutePlatform.epWin32;
{$ELSEIF Defined(WIN64)}
  CurrentPlatform = TExecutePlatform.epWin64;
{$ELSEIF Defined(OSX)}
  CurrentPlatform = TExecutePlatform.epOSX;
{$ELSEIF Defined(IOS)}
{$IFDEF CPUARM}
  CurrentPlatform = TExecutePlatform.epIOS;
{$ELSE}
  CurrentPlatform = TExecutePlatform.epIOSSIM;
{$ENDIF}
{$ELSEIF Defined(ANDROID)}
  CurrentPlatform = TExecutePlatform.epANDROID;
{$ELSE}
  CurrentPlatform = TExecutePlatform.epUnknow;
{$IFEND}


var
  MovementDebugForm: TMovementDebugForm;

implementation

{$R *.fmx}


procedure TMovementDebugForm.FormCreate(Sender: TObject);
begin
  FMovementFrame := TMovementDebugViewFrame.Create(Self);
  FMovementFrame.Parent := Self;
  FMovementFrame.Align := TAlignLayout.Client;

  case CurrentPlatform of
    epIOS, epIOSSIM, epANDROID:
      begin
        FInitUIScale := Round(((ClientWidth / FormFactor.Width) + (ClientHeight / FormFactor.Height)) * 0.5 * 10) * 0.1;
        BorderStyle := TFmxFormBorderStyle.None;
      end;
    else
      FInitUIScale := 1.0;
  end;
  FMovementFrame.Scale.Point := Pointf(FInitUIScale, FInitUIScale);
end;

procedure TMovementDebugForm.FormDestroy(Sender: TObject);
begin
  DisposeObject(FMovementFrame);
  FMovementFrame := nil;
end;

procedure TMovementDebugForm.TimerTimer(Sender: TObject);
var
  k: Double;
begin
  k := 1000.0 / TTimer(Sender).Interval;
  FMovementFrame.Redraw := True;
  FMovementFrame.Progress(1.0 / k);
end;

end.
