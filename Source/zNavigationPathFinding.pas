{ ****************************************************************************** }
{ * Decision imp create by qq600585                                            * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ ****************************************************************************** }
unit zNavigationPathFinding;

{$I zDefine.inc}

interface

uses CoreClasses, zNavigationPass, Geometry2DUnit;

type
  TStepStackData = packed record
    PassIndex: integer;
  end;

  PStepStackData = ^TStepStackData;

  TDecisionInt = -1 .. 1;

  TNavStepFinding = class(TCoreClassPersistent)
  private
    FPassManager: TPolyPassManager;
  private
    FStackList: TCoreClassList;
    FSourcePositionPass, FTargetPositionPass: TPointPass;
    FSourcePositionPassIndex, FTargetPositionPassIndex: integer;
    FSourcePosition, FTargetPosition: TVec2;
    FCurrentPassIndex: integer;
    FPassStateID: ShortInt;
    FStepCount: Int64;
    FDone: Boolean;
    FAbort: Boolean;
    FIgnoreDynamicPoly: TCoreClassListForObj;

    procedure InitState;
    procedure FreeState;
    procedure ResetState;

    procedure PushState;
    procedure PopState;
    function IsEmptyStack: Boolean;
  private
    {
      return state
      -1, prev step
      0: next step
      1: done to end position
    }
    function Decision(const AStateID: ShortInt; const b, e: integer; out PassIndex: integer): TDecisionInt;
  public
    constructor Create(APassManager: TPolyPassManager);
    destructor Destroy; override;

    function FindPath(ASour: TNavBio; ADest: TVec2): Boolean;

    procedure ResetStep;
    procedure NextStep;
    function FindingPathOver: Boolean;

    procedure MakeCurrentPath(OutPath: TVec2List);
    // Remove more/spam corner nodes
    procedure MakeLevel1OptimizationPath(OutPath: TVec2List);
    // remmove intersect corner nodes
    procedure MakeLevel2OptimizationPath(OutPath: TVec2List);
    // remove near lerp corner nodes
    procedure MakeLevel3OptimizationPath(OutPath: TVec2List);
    // subdivision and lerp
    procedure MakeLevel4OptimizationPath(OutPath: TVec2List);

    function GetSearchDepth: integer;
    function GetStepCount: integer;

    property PassManager: TPolyPassManager read FPassManager;
    property Done: Boolean read FDone;
    property Abort: Boolean read FAbort;
    function Success: Boolean;
  end;

procedure Level1OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat);
procedure Level2OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);
procedure Level3OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);
procedure Level4OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);

implementation

procedure Level1OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat);
var
  i, j: integer;
  pl: TVec2List;
begin
  pl := TVec2List.Create;
  pl.Assign(APath);
  APath.Clear;

  if pl.Count > 3 then
    begin
      i := 0;
      while i < pl.Count do
        begin
          APath.Add(pl[i]^);
          j := pl.Count - 1;
          while j > i do
            begin
              if not cm.LineIntersect(ARadius, pl[i]^, pl[j]^, ignore) then
                begin
                  APath.Add(pl[j]^);
                  i := j;
                  Break;
                end
              else
                  Dec(j);
            end;
          Inc(i);
        end;
    end
  else
      APath.Assign(pl);
  DisposeObject(pl);
end;

procedure Level2OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);
var
  pl: TVec2List;
  b, e, ipt: TVec2;
  idx1, idx2: integer;
begin
  pl := TVec2List.Create;
  pl.Assign(APath);
  APath.Clear;
  if LowLap then
      Level1OptimizationPath(cm, ignore, pl, ARadius);

  if pl.Count >= 3 then
    begin
      b := pl[0]^;
      pl.Delete(0);
      APath.Add(b);
      while pl.Count > 0 do
        begin
          e := pl[0]^;
          pl.Delete(0);

          if (pl.Line2NearIntersect(b, e, False, idx1, idx2, ipt)) then
            begin
              APath.Add(ipt);
              e := pl[idx2]^;
              APath.Add(e);
              b := e;
              while idx2 > 0 do
                begin
                  pl.Delete(0);
                  Dec(idx2);
                end;
            end
          else
            begin
              APath.Add(e);
              b := e;
            end;
        end;
      Level1OptimizationPath(cm, ignore, APath, ARadius);
    end
  else
      APath.Assign(pl);
  DisposeObject(pl);
end;

procedure Level3OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);
  function LerpLineCheck(Sour, e, b: TVec2; out OutPt: TVec2): Boolean;
  var
    i: integer;
    ne: TVec2;
    SmoothLevel: integer;
  begin
    Result := False;
    SmoothLevel := Trunc(PointDistance(b, e) / (ARadius * 2));
    for i := 1 to SmoothLevel - 1 do
      begin
        ne := PointLerp(b, e, i * (1.0 / SmoothLevel));
        if not cm.LineIntersect(ARadius, Sour, ne, ignore) then
          begin
            OutPt := ne;
            Result := True;
            Exit;
          end;
      end;
  end;

  function LerpCheck(Sour: TVec2; pl: TVec2List; out OutPt: TVec2; out NextIdx: integer): Boolean;
  var
    i: integer;
    b, e: TVec2;
  begin
    Result := False;
    if (pl.Count > 1) then
      begin
        b := pl[0]^;
        for i := 1 to pl.Count - 1 do
          begin
            e := pl[i]^;
            if (PointDistance(b, e) > (ARadius * 2)) and (LerpLineCheck(Sour, b, e, OutPt)) then
              begin
                NextIdx := i;
                Result := True;
                Exit;
              end;
            b := e;
          end;
      end;
  end;

var
  pl: TVec2List;
  b, ipt: TVec2;
  idx: integer;
begin
  pl := TVec2List.Create;
  pl.Assign(APath);
  APath.Clear;
  if LowLap then
      Level2OptimizationPath(cm, ignore, pl, ARadius, True);

  if pl.Count >= 3 then
    begin
      while pl.Count > 0 do
        begin
          b := pl[0]^;
          APath.Add(b);
          pl.Delete(0);

          if LerpCheck(b, pl, ipt, idx) then
            begin
              APath.Add(ipt);
              APath.Add(pl[idx]^);
              while idx > 0 do
                begin
                  pl.Delete(0);
                  Dec(idx);
                end;
            end;
        end;

      pl.Assign(APath);
      APath.Clear;
      while pl.Count > 0 do
        begin
          b := pl[0]^;
          APath.Add(b);
          pl.Delete(0);

          if LerpCheck(b, pl, ipt, idx) then
            begin
              APath.Add(ipt);
              APath.Add(pl[idx]^);
              while idx > 0 do
                begin
                  pl.Delete(0);
                  Dec(idx);
                end;
            end;
        end;

      Level1OptimizationPath(cm, ignore, APath, ARadius);
    end
  else
      APath.Assign(pl);
  DisposeObject(pl);
end;

procedure Level4OptimizationPath(cm: TPolyPassManager; ignore: TCoreClassListForObj; APath: TVec2List; ARadius: TGeoFloat; LowLap: Boolean);
var
  pl, pl2: TVec2List;
  i: integer;
begin
  pl := TVec2List.Create;
  pl.Assign(APath);
  if LowLap then
    begin
      Level3OptimizationPath(cm, ignore, pl, ARadius, True);
      pl.Reverse;
      Level3OptimizationPath(cm, ignore, pl, ARadius, False);
      pl.Reverse;
    end;
  APath.Clear;

  if pl.Count > 0 then
    begin
      pl2 := TVec2List.Create;
      for i := 0 to pl.Count - 1 do
          pl2.AddSubdivision(10, pl[i]^);
      Level3OptimizationPath(cm, ignore, pl2, ARadius, False);
      pl2.Reverse;
      Level3OptimizationPath(cm, ignore, pl2, ARadius, False);
      pl2.Reverse;

      pl.Clear;
      for i := 0 to pl2.Count - 1 do
          pl.AddSubdivision(10, pl2[i]^);
      Level3OptimizationPath(cm, ignore, pl, ARadius, False);
      pl.Reverse;
      Level3OptimizationPath(cm, ignore, pl, ARadius, False);
      pl.Reverse;

      APath.Assign(pl);
      DisposeObject(pl2);
    end;
  DisposeObject(pl);
end;

procedure TNavStepFinding.InitState;
begin
  FStackList := TCoreClassList.Create;
  FSourcePositionPass := nil;
  FTargetPositionPass := nil;
  FSourcePositionPassIndex := -1;
  FTargetPositionPassIndex := -1;
  FSourcePosition := NullPoint;
  FTargetPosition := NullPoint;
  FCurrentPassIndex := -1;
  FPassStateID := 0;
  FStepCount := 0;
  FDone := False;
  FAbort := False;
  FIgnoreDynamicPoly := TCoreClassListForObj.Create;
end;

procedure TNavStepFinding.FreeState;
begin
  ResetState;
  DisposeObject(FStackList);
  DisposeObject(FIgnoreDynamicPoly);
end;

procedure TNavStepFinding.ResetState;
var
  i: integer;
begin
  for i := 0 to FStackList.Count - 1 do
      Dispose(PStepStackData(FStackList[i]));
  FStackList.Clear;

  if FSourcePositionPass <> nil then
    begin
      FSourcePositionPass.Delete;
    end;
  FSourcePositionPass := nil;

  if FTargetPositionPass <> nil then
    begin
      FTargetPositionPass.Delete;
    end;
  FTargetPositionPass := nil;

  FSourcePositionPassIndex := -1;
  FTargetPositionPassIndex := -1;
  FSourcePosition := NullPoint;
  FTargetPosition := NullPoint;

  FCurrentPassIndex := -1;
  FPassStateID := 0;
  FStepCount := 0;
  FDone := False;
  FAbort := False;

  FIgnoreDynamicPoly.Clear;
end;

procedure TNavStepFinding.PushState;
var
  p: PStepStackData;
begin
  New(p);
  p^.PassIndex := FCurrentPassIndex;
  FStackList.Add(p);
end;

procedure TNavStepFinding.PopState;
var
  p: PStepStackData;
begin
  if FStackList.Count > 0 then
    begin
      p := FStackList[FStackList.Count - 1];
      FCurrentPassIndex := p^.PassIndex;
      FStackList.Delete(FStackList.Count - 1);
      Dispose(p);
    end;
end;

function TNavStepFinding.IsEmptyStack: Boolean;
begin
  Result := FStackList.Count = 0;
end;

{
  return state
  -1, prev step
  0: next step
  1: done to end position
}

function TNavStepFinding.Decision(const AStateID: ShortInt; const b, e: integer; out PassIndex: integer): TDecisionInt;
var
  bc, ec: TBasePass;
  bp, ep: TVec2;

  bi: integer;
  d, bd: TGeoFloat;
  i: integer;
begin
  if (b < 0) or (e < 0) then
    begin
      // return prev step
      Result := -1;
      Exit;
    end;

  bc := FPassManager[b];
  ec := FPassManager[e];

  if bc.Exists(ec) and (bc[bc.IndexOf(ec)]^.Enabled(FIgnoreDynamicPoly)) then
    begin
      // return success
      PassIndex := ec.PassIndex;
      Result := 1;
      Exit;
    end;

  bp := bc.GetPosition;
  ep := ec.GetPosition;

  bi := -1;

  bd := 0;

  // compute distance
  for i := 0 to bc.Count - 1 do
    with bc.Data[i]^ do
      if (State <> AStateID) and (passed <> bc) and (Enabled(FIgnoreDynamicPoly)) then
        begin
          d := PointDistance(ep, passed.GetPosition);

          if (bd = 0) or (d < bd) then
            begin
              bi := i;
              bd := d;
            end;
        end;

  if (bi = -1) then
    begin
      // return prev step
      Result := -1;
      Exit;
    end;

  bc.State[bi] := AStateID;
  PassIndex := bc.Data[bi]^.passed.PassIndex;
  if PassIndex < 0 then
    begin
      // step prev step
      Result := -1;
      Exit;
    end;

  // next step
  Result := 0;
end;

constructor TNavStepFinding.Create(APassManager: TPolyPassManager);
begin
  inherited Create;
  FPassManager := APassManager;
  InitState;
end;

destructor TNavStepFinding.Destroy;
begin
  FreeState;
  inherited Destroy;
end;

function TNavStepFinding.FindPath(ASour: TNavBio; ADest: TVec2): Boolean;
var
  i: integer;
begin
  ResetState;
  if ASour.IsFlight then
    begin
      FSourcePosition := ASour.DirectPosition;
      FTargetPosition := ADest;
      FSourcePositionPass := TPointPass.Create(FPassManager, ASour.DirectPosition);
      FTargetPositionPass := TPointPass.Create(FPassManager, ADest);
      FSourcePositionPassIndex := FPassManager.Add(FSourcePositionPass, False);
      FTargetPositionPassIndex := FPassManager.Add(FTargetPositionPass, False);
      Result := True;
      Exit;
    end;

  FIgnoreDynamicPoly.Add(ASour);
  Result := False;
  FSourcePosition := ASour.DirectPosition;
  FTargetPosition := ADest;
  FDone := not FPassManager.LineIntersect(FPassManager.ExtandDistance, ASour.DirectPosition, ADest, FIgnoreDynamicPoly);

  if not FPassManager.PointOk(FPassManager.ExtandDistance - 1, ASour.DirectPosition, FIgnoreDynamicPoly) then
      Exit;
  if not FPassManager.PointOk(FPassManager.ExtandDistance - 1, ADest, FIgnoreDynamicPoly) then
      Exit;

  if FDone then
    begin
      FSourcePositionPass := TPointPass.Create(FPassManager, ASour.DirectPosition);
      FTargetPositionPass := TPointPass.Create(FPassManager, ADest);
      FSourcePositionPassIndex := FPassManager.Add(FSourcePositionPass, False);
      FTargetPositionPassIndex := FPassManager.Add(FTargetPositionPass, False);
      Result := True;
    end
  else
    begin
      FSourcePositionPass := TPointPass.Create(FPassManager, ASour.DirectPosition);
      FTargetPositionPass := TPointPass.Create(FPassManager, ADest);
      FSourcePositionPassIndex := FPassManager.Add(FSourcePositionPass, True);
      FTargetPositionPassIndex := FPassManager.Add(FTargetPositionPass, True);
      for i := 0 to FPassManager.Count - 1 do
          FPassManager[i].PassIndex := i;

      FPassStateID := FPassManager.NewPassStateIncremental;

      case Decision(FPassStateID, FSourcePositionPassIndex, FTargetPositionPassIndex, FCurrentPassIndex) of
        - 1:
          begin
            // prev step
          end;
        0:
          begin
            // next step
            PushState;
            Result := True;
          end;
        else
          begin
            // done to dest
            FDone := True;
            Result := True;
          end;
      end;
    end;
end;

procedure TNavStepFinding.ResetStep;
var
  i: integer;
begin
  if FTargetPositionPassIndex < 0 then
      Exit;
  if FSourcePositionPassIndex < 0 then
      Exit;
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;

  FDone := False;
  FCurrentPassIndex := -1;
  FStepCount := 0;
  FDone := False;
  FAbort := False;

  for i := 0 to FStackList.Count - 1 do
      Dispose(PStepStackData(FStackList[i]));
  FStackList.Clear;

  FPassStateID := FPassManager.NewPassStateIncremental;

  case Decision(FPassStateID, FSourcePositionPassIndex, FTargetPositionPassIndex, FCurrentPassIndex) of
    - 1:
      begin
        // prev step
      end;
    0:
      begin
        // next step
        PushState;
      end;
    else
      begin
        // done to dest
        FDone := True;
      end;
  end;
end;

procedure TNavStepFinding.NextStep;
var
  r, i: integer;
begin
  if FDone then
      Exit;
  if FAbort then
      Exit;
  if FCurrentPassIndex < 0 then
      Exit;
  if FTargetPositionPassIndex < 0 then
      Exit;
  if FSourcePositionPassIndex < 0 then
      Exit;
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;

  Inc(FStepCount);
  PushState;

  i := FCurrentPassIndex;
  r := Decision(FPassStateID, i, FTargetPositionPassIndex, FCurrentPassIndex);
  case r of
    - 1:
      begin
        // prev step
        PopState;
        if IsEmptyStack then
          begin
            FAbort := True;
            Exit;
          end;
        PopState;
      end;
    0:
      begin
        // next step
      end;
    else
      begin
        // done to dest
        FDone := True;
      end;
  end;
end;

function TNavStepFinding.FindingPathOver: Boolean;
begin
  Result := FDone or FAbort;
end;

procedure TNavStepFinding.MakeCurrentPath(OutPath: TVec2List);
var
  i: integer;
begin
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;
  OutPath.Add(FSourcePositionPass.GetPosition);
  for i := 0 to FStackList.Count - 1 do
      OutPath.Add(FPassManager[PStepStackData(FStackList[i])^.PassIndex].GetPosition);
  if FindingPathOver and (not FAbort) then
      OutPath.Add(FTargetPositionPass.GetPosition);
end;

procedure TNavStepFinding.MakeLevel1OptimizationPath(OutPath: TVec2List);
var
  pl: TVec2List;
begin
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;
  pl := TVec2List.Create;
  MakeCurrentPath(pl);
  OutPath.Assign(pl);
  Level1OptimizationPath(FPassManager, FIgnoreDynamicPoly, OutPath, FPassManager.ExtandDistance);
  DisposeObject(pl);
end;

procedure TNavStepFinding.MakeLevel2OptimizationPath(OutPath: TVec2List);
var
  pl: TVec2List;
begin
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;
  pl := TVec2List.Create;
  MakeCurrentPath(pl);
  OutPath.Assign(pl);
  Level2OptimizationPath(FPassManager, FIgnoreDynamicPoly, OutPath, FPassManager.ExtandDistance, True);
  DisposeObject(pl);
end;

procedure TNavStepFinding.MakeLevel3OptimizationPath(OutPath: TVec2List);
begin
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;
  MakeCurrentPath(OutPath);
  Level3OptimizationPath(FPassManager, FIgnoreDynamicPoly, OutPath, FPassManager.ExtandDistance, True);
  OutPath.Reverse;
  Level3OptimizationPath(FPassManager, FIgnoreDynamicPoly, OutPath, FPassManager.ExtandDistance, True);
  OutPath.Reverse;
end;

procedure TNavStepFinding.MakeLevel4OptimizationPath(OutPath: TVec2List);
begin
  if FSourcePositionPass = nil then
      Exit;
  if FTargetPositionPass = nil then
      Exit;
  MakeCurrentPath(OutPath);
  Level4OptimizationPath(FPassManager, FIgnoreDynamicPoly, OutPath, FPassManager.ExtandDistance, True);
end;

function TNavStepFinding.GetSearchDepth: integer;
begin
  Result := FStackList.Count;
end;

function TNavStepFinding.GetStepCount: integer;
begin
  Result := FStepCount;
end;

function TNavStepFinding.Success: Boolean;
begin
  Result := (not Abort) and (FDone)
end;

end.
