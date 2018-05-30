{ ****************************************************************************** }
{ * movement engine create by qq600585                                         * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ ****************************************************************************** }
unit MovementEngine;

{$I zDefine.inc}

interface

uses SysUtils, Geometry2DUnit, CoreClasses, Math;

type
  TMovementStep = packed record
    Position: TVec2;
    Angle: TGeoFloat;
    Index: Integer;
  end;

  IMovementEngineIntf = interface
    function GetPosition: TVec2;
    procedure SetPosition(const Value: TVec2);

    function GetRollAngle: TGeoFloat;
    procedure SetRollAngle(const Value: TGeoFloat);

    procedure DoStartMovement;
    procedure DoMovementDone;

    procedure DoRollMovementStart;
    procedure DoRollMovementOver;

    procedure DoLoop;

    procedure DoStop;
    procedure DoPause;
    procedure DoContinue;

    procedure DoMovementStepChange(OldStep, NewStep: TMovementStep);
  end;

  TMovementOperationMode = (momMovementPath, momStopRollAngle);

  TMovementEngine = class(TCoreClassObject)
  private
    FIntf: IMovementEngineIntf;

    FSteps: packed array of TMovementStep;

    FActive: Boolean;
    FPause: Boolean;
    FMoveSpeed: TGeoFloat;
    FRollSpeed: TGeoFloat;
    FRollMoveRatio: TGeoFloat;
    // movement operation mode
    FOperationMode: TMovementOperationMode;

    FLooped: Boolean;
    FStopRollAngle: TGeoFloat;

    FLastProgressNewTime: Double;
    FLastProgressDeltaTime: Double;

    FCurrentPathStepTo: Integer;

    FFromPosition: TVec2;
    FToPosition: TVec2;
    FMovementDone, FRollDone: Boolean;

  protected
    function GetPosition: TVec2;
    procedure SetPosition(const Value: TVec2);

    function GetRollAngle: TGeoFloat;
    procedure SetRollAngle(const Value: TGeoFloat);

    function FirstStep: TMovementStep;
    function LastStep: TMovementStep;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(ATo: TVec2); overload;
    procedure Start(APaths: TVec2List); overload;
    procedure Start; overload;
    procedure Stop;
    procedure Pause;

    procedure Progress(const deltaTime: Double);

    property Intf: IMovementEngineIntf read FIntf write FIntf;

    property Position: TVec2 read GetPosition write SetPosition;
    property RollAngle: TGeoFloat read GetRollAngle write SetRollAngle;

    // pause
    property IsPause: Boolean read FPause;

    // movementing
    property Active: Boolean read FActive;

    // speed
    property MoveSpeed: TGeoFloat read FMoveSpeed write FMoveSpeed;

    // roll speed
    property RollSpeed: TGeoFloat read FRollSpeed write FRollSpeed;

    // roll movement Ratio
    property RollMoveRatio: TGeoFloat read FRollMoveRatio write FRollMoveRatio;

    // movement operation mode
    property OperationMode: TMovementOperationMode read FOperationMode write FOperationMode;

    // loop movement
    property Looped: Boolean read FLooped write FLooped;

    property FromPosition: TVec2 read FFromPosition;
    property ToPosition: TVec2 read FToPosition;
  end;

implementation

uses Geometry3DUnit;

function TMovementEngine.GetPosition: TVec2;
begin
  Result := FIntf.GetPosition;
end;

procedure TMovementEngine.SetPosition(const Value: TVec2);
begin
  FIntf.SetPosition(Value);
end;

function TMovementEngine.GetRollAngle: TGeoFloat;
begin
  Result := FIntf.GetRollAngle;
end;

procedure TMovementEngine.SetRollAngle(const Value: TGeoFloat);
begin
  FIntf.SetRollAngle(Value);
end;

function TMovementEngine.FirstStep: TMovementStep;
begin
  Result := FSteps[0];
end;

function TMovementEngine.LastStep: TMovementStep;
begin
  Result := FSteps[Length(FSteps) - 1];
end;

constructor TMovementEngine.Create;
begin
  inherited Create;
  SetLength(FSteps, 0);
  FIntf := nil;

  FActive := False;
  FPause := False;
  FMoveSpeed := 100;
  FRollSpeed := 180;
  FRollMoveRatio := 0.5;
  FOperationMode := momMovementPath;

  FLooped := False;
  FStopRollAngle := 0;

  FLastProgressDeltaTime := 0;

  FCurrentPathStepTo := -1;

  FFromPosition := NullPoint;
  FToPosition := NullPoint;

  FMovementDone := False;
  FRollDone := False;
end;

destructor TMovementEngine.Destroy;
begin
  SetLength(FSteps, 0);
  FIntf := nil;
  inherited Destroy;
end;

procedure TMovementEngine.Start(ATo: TVec2);
begin
  if not FActive then
    begin
      SetLength(FSteps, 0);
      FStopRollAngle := CalcAngle(Position, ATo);
      FOperationMode := momStopRollAngle;
      FActive := True;
      FPause := False;
      FToPosition := ATo;
      Intf.DoStartMovement;
    end;
end;

procedure TMovementEngine.Start(APaths: TVec2List);
var
  i: Integer;
begin
  APaths.FixedSameError;

  if not FActive then
    begin
      FCurrentPathStepTo := 0;
      FFromPosition := NullPoint;
      FMovementDone := False;
      FRollDone := False;
      FOperationMode := momMovementPath;

      FActive := (APaths <> nil) and (APaths.Count > 0) and (FIntf <> nil);
      if FActive then
        begin
          SetLength(FSteps, APaths.Count);
          for i := 0 to APaths.Count - 1 do
            with FSteps[i] do
              begin
                Position := APaths[i]^;
                if i > 0 then
                    Angle := CalcAngle(APaths[i - 1]^, APaths[i]^)
                else
                    Angle := CalcAngle(Position, APaths[i]^);
                index := i;
              end;

          FPause := False;
          FFromPosition := Position;

          FStopRollAngle := 0;

          FToPosition := APaths.Last^;
          Intf.DoStartMovement;
        end;
    end;
end;

procedure TMovementEngine.Start;
begin
  if (FActive) and (FPause) then
    begin
      FPause := False;
      Intf.DoContinue;
    end;
end;

procedure TMovementEngine.Stop;
begin
  if FActive then
    begin
      SetLength(FSteps, 0);
      FCurrentPathStepTo := 0;
      FFromPosition := NullPoint;
      FMovementDone := False;
      FRollDone := True;
      FPause := False;
      FActive := False;
      FOperationMode := momMovementPath;
      Intf.DoStop;
    end;
end;

procedure TMovementEngine.Pause;
begin
  if not FPause then
    begin
      FPause := True;
      if FActive then
          Intf.DoPause;
    end;
end;

procedure TMovementEngine.Progress(const deltaTime: Double);
var
  CurrentDeltaTime: Double;
  toStep: TMovementStep;
  FromV, ToV, v: TVec2;
  dt, rt: Double;
  d: TGeoFloat;
begin
  FLastProgressDeltaTime := deltaTime;
  if FActive then
    begin
      CurrentDeltaTime := deltaTime;
      FActive := (Length(FSteps) > 0) or (FOperationMode = momStopRollAngle);
      if (not FPause) and (FActive) then
        begin
          case FOperationMode of
            momStopRollAngle:
              begin
                RollAngle := SmoothAngle(RollAngle, FStopRollAngle, deltaTime * FRollSpeed);
                FActive := not AngleEqual(RollAngle, FStopRollAngle);
              end;
            momMovementPath:
              begin
                FromV := Position;

                while True do
                  begin
                    if FMovementDone and FRollDone then
                      begin
                        FActive := False;
                        Break;
                      end;

                    if FMovementDone and not FRollDone then
                      begin
                        RollAngle := SmoothAngle(RollAngle, LastStep.Angle, deltaTime * FRollSpeed);
                        FRollDone := not AngleEqual(RollAngle, LastStep.Angle);
                        Break;
                      end;

                    if FCurrentPathStepTo >= Length(FSteps) then
                      begin
                        v := LastStep.Position;
                        Position := v;
                        if not AngleEqual(RollAngle, LastStep.Angle) then
                          begin
                            FOperationMode := momStopRollAngle;
                            FStopRollAngle := LastStep.Angle;
                          end
                        else
                            FActive := False;
                        Break;
                      end;

                    toStep := FSteps[FCurrentPathStepTo];
                    ToV := toStep.Position;
                    FMovementDone := FCurrentPathStepTo >= Length(FSteps);

                    if (FRollDone) and (not AngleEqual(RollAngle, toStep.Angle)) then
                        FIntf.DoRollMovementStart;

                    if (not FRollDone) and (AngleEqual(RollAngle, toStep.Angle)) then
                        FIntf.DoRollMovementOver;

                    FRollDone := AngleEqual(RollAngle, toStep.Angle);

                    if FRollDone then
                      begin
                        // uses direct movement

                        dt := MovementDistanceDeltaTime(FromV, ToV, FMoveSpeed);
                        if dt > CurrentDeltaTime then
                          begin
                            // direct calc movement
                            v := MovementDistance(FromV, ToV, CurrentDeltaTime * FMoveSpeed);
                            Position := v;
                            Break;
                          end
                        else
                          begin
                            CurrentDeltaTime := CurrentDeltaTime - dt;
                            FromV := ToV;
                            Inc(FCurrentPathStepTo);

                            // trigger execute event
                            if (FCurrentPathStepTo < Length(FSteps)) then
                                FIntf.DoMovementStepChange(toStep, FSteps[FCurrentPathStepTo]);
                          end;
                      end
                    else
                      begin
                        // uses roll attenuation movement

                        rt := AngleRollDistanceDeltaTime(RollAngle, toStep.Angle, FRollSpeed);
                        d := Distance(FromV, ToV);

                        if rt >= CurrentDeltaTime then
                          begin
                            if d > CurrentDeltaTime * FMoveSpeed * FRollMoveRatio then
                              begin
                                // position vector dont cross endge for ToV
                                v := MovementDistance(FromV, ToV, CurrentDeltaTime * FMoveSpeed * FRollMoveRatio);
                                Position := v;
                                RollAngle := SmoothAngle(RollAngle, toStep.Angle, CurrentDeltaTime * FRollSpeed);
                                Break;
                              end
                            else
                              begin
                                // position vector cross endge for ToV
                                dt := MovementDistanceDeltaTime(FromV, ToV, FMoveSpeed * FRollMoveRatio);
                                v := ToV;
                                Position := v;
                                RollAngle := SmoothAngle(RollAngle, toStep.Angle, dt * FRollSpeed);
                                CurrentDeltaTime := CurrentDeltaTime - dt;
                                FromV := ToV;
                                Inc(FCurrentPathStepTo);

                                // trigger execute event
                                if (FCurrentPathStepTo < Length(FSteps)) then
                                    FIntf.DoMovementStepChange(toStep, FSteps[FCurrentPathStepTo]);
                              end;
                          end
                        else
                          begin
                            // preprocess roll movement speed attenuation
                            if rt * FMoveSpeed * FRollMoveRatio > d then
                              begin
                                // position vector cross endge for ToV
                                dt := MovementDistanceDeltaTime(FromV, ToV, FMoveSpeed * FRollMoveRatio);
                                v := ToV;
                                Position := v;
                                RollAngle := SmoothAngle(RollAngle, toStep.Angle, dt * FRollSpeed);
                                CurrentDeltaTime := CurrentDeltaTime - dt;
                                FromV := ToV;
                                Inc(FCurrentPathStepTo);

                                // trigger execute event
                                if (FCurrentPathStepTo < Length(FSteps)) then
                                    FIntf.DoMovementStepChange(toStep, FSteps[FCurrentPathStepTo]);
                              end
                            else
                              begin
                                // position vector dont cross endge for ToV
                                v := MovementDistance(FromV, ToV, rt * FMoveSpeed * FRollMoveRatio);
                                Position := v;
                                RollAngle := toStep.Angle;
                                CurrentDeltaTime := CurrentDeltaTime - rt;
                              end;
                          end;
                      end;
                  end;
              end;
          end;

          if (not FActive) then
            begin
              if (FLooped) and (Length(FSteps) > 0) then
                begin
                  FCurrentPathStepTo := 0;
                  FActive := True;
                  FMovementDone := False;
                  FRollDone := False;
                  FOperationMode := momMovementPath;
                  FSteps[0].Angle := CalcAngle(Position, FSteps[0].Position);
                  FIntf.DoLoop;
                end
              else
                begin
                  FCurrentPathStepTo := 0;
                  FFromPosition := NullPoint;
                  FMovementDone := False;
                  FRollDone := False;
                  FOperationMode := momMovementPath;
                  FIntf.DoMovementDone;
                end;
            end;
        end;
    end;
end;

end.
