{ ****************************************************************************** }
{ * draw engine with PXL Support                                               * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ ****************************************************************************** }
unit zDrawEngineInterface_PXL;

{$I ..\zDefine.inc}

interface

uses
  System.Math.Vectors, System.Math, System.UITypes, System.Types, System.UIConsts,
  CoreClasses, DrawEngine, UnicodeMixedLib, Geometry2DUnit, MemoryRaster,
  DataFrameEngine, Geometry3DUnit, ListEngine, PascalStrings,
  PXL.Types, PXL.Canvas, PXL.Textures, PXL.Surfaces, PXL.Images;

type
  TDrawEngineInterface_PXL = class(TCoreClassInterfacedObject, IDrawEngineInterface)
  private
    FCanvas: TCustomCanvas;
    FOwnerCanvasScale: TDEFloat;
    FLineWidth: TDEFloat;
    FDebug: Boolean;
    FCurrSiz: TDEVec;
    procedure SetCanvas(const Value: TCustomCanvas);
  protected
    procedure SetSize(r: TDERect); virtual;
    procedure SetLineWidth(w: TDEFloat); virtual;
    procedure DrawLine(pt1, pt2: TDEVec; color: TDEColor); virtual;
    procedure DrawRect(r: TDERect; color: TDEColor); virtual;
    procedure FillRect(r: TDERect; color: TDEColor); virtual;
    procedure DrawEllipse(r: TDERect; color: TDEColor); virtual;
    procedure FillEllipse(r: TDERect; color: TDEColor); virtual;
    procedure DrawText(text: SystemString; size: TDEFloat; r: TDERect; color: TDEColor; center: Boolean); virtual;
    procedure DrawTexture(t: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat); virtual;
    procedure Flush; virtual;
    procedure ResetState; virtual;
    procedure BeginDraw; virtual;
    procedure EndDraw; virtual;
    function CurrentScreenSize: TDEVec; virtual;
    function GetTextSize(text: SystemString; size: TDEFloat): TDEVec; virtual;
    function ReadyOK: Boolean; virtual;
    function EngineIntfObject: TCoreClassObject; virtual;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetSurface(c: TCustomCanvas; OwnerCtrl: TObject);
    property Canvas: TCustomCanvas read FCanvas write SetCanvas;

    property Debug: Boolean read FDebug write FDebug;
    // only work in mobile device and gpu fast mode
    property OwnerCanvasScale: TDEFloat read FOwnerCanvasScale write FOwnerCanvasScale;
    property CanvasScale: TDEFloat read FOwnerCanvasScale write FOwnerCanvasScale;
    property ScreenSize: TDEVec read FCurrSiz;
  end;

  TDETexture_PXL = class(TDETexture)
  protected
    FCanvas: TCustomCanvas;
    FTexture: TAtlasImage;
    function GetTexture: TAtlasImage;
  public
    constructor Create; overload; override;
    constructor Create(ACanvas: TCustomCanvas); overload;
    destructor Destroy; override;

    procedure ReleaseFMXResource; override;
    procedure FastUpdateTexture; override;

    property Texture: TAtlasImage read GetTexture;
  end;

  TResourceTexture = class(TDETexture_PXL)
  protected
    FLastLoadFile: SystemString;
  public
    constructor Create; overload; override;
    constructor Create(filename: SystemString); overload; virtual;

    procedure LoadFromFileIO(filename: SystemString);
    property LastLoadFile: SystemString read FLastLoadFile;
  end;

  TResourceTextureIntf = class(TCoreClassInterfacedObject)
  public
    Texture: TResourceTexture;
    TextureRect: TDERect;
    SizeScale: TDEVec;

    constructor Create(tex: TResourceTexture); virtual;
    destructor Destroy; override;
    function SizeOfVec: TDEVec;
    procedure ChangeTexture(tex: TResourceTexture); virtual;
  end;

  TResourceTextureCache = class(TCoreClassObject)
  protected
    TextureList: THashObjectList;
  public
    DefaultTexture: TResourceTexture;

    constructor Create; virtual;
    destructor Destroy; override;
    function CreateResourceTexture(filename: SystemString): TResourceTextureIntf;
    procedure ReleaseAllFMXRsource;
  end;

function c2c(c: TDEColor): TIntColor; inline; overload;
function c2c(c: TFloatColor): TDEColor; inline; overload;
function p2p(pt: TDEVec): TPoint2f; inline; overload;
function r2r(r: TDERect): TFloatRect; inline; overload;
function r2r(r: TDE4V): TQuad; inline; overload;
function r2r(r: TFloatRect): TDE4V; inline; overload;
function AlphaColor2RasterColor(c: TIntColor): TRasterColor; inline;
function DE4V2Corners(sour: TDE4V): TQuad; inline;
function DEColor(c: TFloatColor): TDEColor; inline; overload;
function PrepareColor(const SrcColor: TIntColor; const Opacity: TDEFloat): TIntColor; inline;
procedure MakeMatrixRotation(Angle, Width, Height, X, Y: TDEFloat; var OutputMatrix: TMatrix; var OutputRect: TRectf); inline;

var
  // resource texture cache
  TextureCache: TResourceTextureCache = nil;

implementation

uses
  MemoryStream64, MediaCenter;

function c2c(c: TDEColor): TIntColor;
begin
  Result:= FloatColor(c[0], c[1], c[2], c[3]).ToInt;
end;

function c2c(c: TFloatColor): TDEColor;
begin
  Result:= DEColor(c.Red, c.Green, c.Blue, c.Alpha);
end;

function p2p(pt: TDEVec): TPoint2f;
begin
  Result:= Point2f(pt[0], pt[1]);
end;

function r2r(r: TDERect): TFloatRect;
begin
  Result:= FloatRectBDS(r[0][0], r[0][1], r[1][0], r[1][1]);
end;

function r2r(r: TDE4V): TQuad;
begin
  Result:= Quad(r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top);
end;

function r2r(r: TFloatRect): TDE4V;
begin
  Result.Left:= r.Left;
  Result.Top:= r.Top;
  Result.Right:= r.Right;
  Result.Bottom:= r.Bottom;
end;

function AlphaColor2RasterColor(c: TIntColor): TRasterColor;
var
  ce: TRasterColorEntry;
begin
  ce.r := TIntColorRec(c).Red;
  ce.G := TIntColorRec(c).Green;
  ce.b := TIntColorRec(c).Blue;
  ce.A := TIntColorRec(c).Alpha;
  Result := ce.RGBA;
end;

function DE4V2Corners(sour: TDE4V): TQuad;
begin
//  Result.TopLeft:= Point2f(sour[0][0], sour[0][1]);
//  Result.TopRight:= Point2f(sour[1][0], sour[0][1]);
//  Result.BottomLeft:= Point2f(sour[0][0], sour[1][1]);
//  Result.BottomRight:= Point2f(sour[1][0], sour[1][1]);
end;

function DEColor(c: TFloatColor): TDEColor;
begin
  Result:= DEColor(c.Red, c.Green, c.Blue, c.Alpha);
end;

function PrepareColor(const SrcColor: TIntColor; const Opacity: TDEFloat): TIntColor;
begin
  if Opacity <= 1.0 then
    begin
      TIntColorRec(Result).Red := Round(TIntColorRec(SrcColor).Red * Opacity);
      TIntColorRec(Result).Green := Round(TIntColorRec(SrcColor).Green * Opacity);
      TIntColorRec(Result).Blue := Round(TIntColorRec(SrcColor).Blue * Opacity);
      TIntColorRec(Result).Alpha := Round(TIntColorRec(SrcColor).Alpha * Opacity);
    end
  else if (TAlphaColorRec(SrcColor).A < $FF) then
      Result := PremultiplyAlpha(SrcColor)
  else
      Result := SrcColor;
end;

procedure MakeMatrixRotation(Angle, Width, Height, X, Y: TDEFloat; var OutputMatrix: TMatrix; var OutputRect: TRectf);
const
  Scale_X          = 1.0;
  Scale_Y          = 1.0;
  RotationCenter_X = 0.5;
  RotationCenter_Y = 0.5;
var
  ScaleMatrix, RotMatrix, M1, M2: TMatrix;
begin
  ScaleMatrix := TMatrix.Identity;
  ScaleMatrix.m11 := Scale_X;
  ScaleMatrix.m22 := Scale_Y;
  OutputMatrix := ScaleMatrix;

  M1 := TMatrix.Identity;
  M1.m31 := -(RotationCenter_X * Width * Scale_X + X);
  M1.m32 := -(RotationCenter_Y * Height * Scale_Y + Y);
  M2 := TMatrix.Identity;
  M2.m31 := RotationCenter_X * Width * Scale_X + X;
  M2.m32 := RotationCenter_Y * Height * Scale_Y + Y;
  RotMatrix := M1 * (TMatrix.CreateRotation(DegToRad(Angle)) * M2);
  OutputMatrix := OutputMatrix * RotMatrix;

  OutputRect.TopLeft := Pointf(X, Y);
  OutputRect.BottomRight := Pointf(X + Width, Y + Height);
end;

{ TDrawEngineInterface_PXL }

procedure TDrawEngineInterface_PXL.SetCanvas(const Value: TCustomCanvas);
begin
  if Value = nil then
    begin
      FCanvas := nil;
      exit;
    end;

  FCanvas := Value;
  FCurrSiz := DEVec(FCanvas.ClipRect.Width, FCanvas.ClipRect.Height);
end;

procedure TDrawEngineInterface_PXL.SetSize(r: TDERect);
begin
  FCanvas.ClipRect:= FloatRectBDS(r[0][0], r[0][1], r[1][0], r[1][1]).ToInt;
end;

procedure TDrawEngineInterface_PXL.SetLineWidth(w: TDEFloat);
begin
  if not IsEqual(FLineWidth, w) then
    FLineWidth := w;
end;

procedure TDrawEngineInterface_PXL.DrawLine(pt1, pt2: TDEVec; color: TDEColor);
begin
  FCanvas.Line(p2p(pt1), p2p(pt2), c2c(color));
end;

procedure TDrawEngineInterface_PXL.DrawRect(r: TDERect; color: TDEColor);
begin
  FCanvas.FrameRect(r2r(r), c2c(color));
end;

procedure TDrawEngineInterface_PXL.FillRect(r: TDERect; color: TDEColor);
begin
  FCanvas.FillRect(r2r(r), c2c(color));
end;

procedure TDrawEngineInterface_PXL.DrawEllipse(r: TDERect; color: TDEColor);
begin
  FCanvas.Ellipse(Point2f(r[0][0], r[0][1]),
                  Point2f(r[1][0], r[1][1]), 200, c2c(color));
end;

procedure TDrawEngineInterface_PXL.FillEllipse(r: TDERect; color: TDEColor);
begin
  FCanvas.FillEllipse(Point2f(r[0][0], r[0][1]),
                      Point2f(r[1][0], r[1][1]), 200, c2c(color));
end;

procedure TDrawEngineInterface_PXL.DrawText(text: SystemString; size: TDEFloat; r: TDERect; color: TDEColor; center: Boolean);
begin
  // FTFont.Print(...);
end;

procedure TDrawEngineInterface_PXL.DrawTexture(t: TCoreClassObject; sour, dest: TDE4V; alpha: TDEFloat);
var
  LColor: TFloatColor;
  LImage: TAtlasImage;
begin
  if not (t is TAtlasImage) then Exit;
  //
  LColor:= FloatColorWhite;
  LColor.Alpha:= alpha;
  LImage:= TAtlasImage(t);
  FCanvas.UseImagePx(LImage, r2r(sour));
  FCanvas.TexQuad(r2r(dest), ColorRect(LColor.ToInt));
end;

procedure TDrawEngineInterface_PXL.Flush;
begin
  FCanvas.Flush;
end;

procedure TDrawEngineInterface_PXL.ResetState;
begin
  FLineWidth:= 0;
end;

procedure TDrawEngineInterface_PXL.BeginDraw;
begin
  FCanvas.BeginScene;
end;

procedure TDrawEngineInterface_PXL.EndDraw;
begin
  FCanvas.EndScene;
end;

function TDrawEngineInterface_PXL.CurrentScreenSize: TDEVec;
begin
  Result := FCurrSiz;
end;

function TDrawEngineInterface_PXL.GetTextSize(text: SystemString; size: TDEFloat): TDEVec;
begin

end;

function TDrawEngineInterface_PXL.ReadyOK: Boolean;
begin
  Result := FCanvas <> nil;
end;

function TDrawEngineInterface_PXL.EngineIntfObject: TCoreClassObject;
begin
  Result := Self;
end;

constructor TDrawEngineInterface_PXL.Create;
begin
  inherited Create;
  FCanvas := nil;
  FOwnerCanvasScale := 1.0;
  FDebug := False;
  FCurrSiz := DEVec(100, 100);
end;

destructor TDrawEngineInterface_PXL.Destroy;
begin
  inherited Destroy;
end;

procedure TDrawEngineInterface_PXL.SetSurface(c: TCustomCanvas; OwnerCtrl: TObject);
var
  pf: TPoint2f;
begin
  FCanvas := c;
//  if OwnerCtrl is TControl then
//    begin
//      pf := TControl(OwnerCtrl).AbsoluteScale;
//      FOwnerCanvasScale := (pf.X + pf.Y) * 0.5;
//      FCurrSiz := DEVec(TControl(OwnerCtrl).Width, TControl(OwnerCtrl).Height);
//    end
//  else if OwnerCtrl is TCustomForm then
//    begin
//      FOwnerCanvasScale := 1.0;
//      FCurrSiz := DEVec(TCustomForm(OwnerCtrl).ClientWidth, TCustomForm(OwnerCtrl).ClientHeight);
//    end
//  else
//    begin
//      FOwnerCanvasScale := 1.0;
//      FCurrSiz := DEVec(c.Width, c.Height);
//    end;
end;

{ TDETexture_PXL }

function TDETexture_PXL.GetTexture: TAtlasImage;
begin
  if FTexture = nil then
      FastUpdateTexture;
  Result := FTexture;
end;

constructor TDETexture_PXL.Create;
begin
  inherited Create;
  FTexture := nil;
end;

constructor TDETexture_PXL.Create(ACanvas: TCustomCanvas);
begin
  inherited Create;
  FCanvas:= ACanvas;
end;

destructor TDETexture_PXL.Destroy;
begin
  ReleaseFMXResource;
  inherited Destroy;
end;

procedure TDETexture_PXL.ReleaseFMXResource;
begin
  if FTexture <> nil then
      DisposeObject(FTexture);
  FTexture := nil;
end;

procedure TDETexture_PXL.FastUpdateTexture;
begin
  ReleaseFMXResource;
  FTexture := TAtlasImage.Create(FCanvas.Device);
end;

constructor TResourceTexture.Create;
begin
  inherited Create;
  FLastLoadFile := '';
end;

constructor TResourceTexture.Create(filename: SystemString);
begin
  inherited Create;
  FLastLoadFile := '';

  if filename <> '' then
      LoadFromFileIO(filename);
end;

procedure TResourceTexture.LoadFromFileIO(filename: SystemString);
var
  stream: TCoreClassStream;
begin
  FLastLoadFile := '';
  if FileIOExists(filename) then
    begin
      try
        stream := FileIOOpen(filename);
        stream.Position := 0;
        LoadFromStream(stream);
        DisposeObject(stream);
        FLastLoadFile := filename;
      except
          RaiseInfo('texture "%s" format error! ', [filename]);
      end;
    end
  else
      RaiseInfo('file "%s" no exists', [filename]);
end;

constructor TResourceTextureIntf.Create(tex: TResourceTexture);
begin
  inherited Create;
  Texture := tex;
  TextureRect := Texture.BoundsRectV2;
  SizeScale := DEVec(1.0, 1.0);
end;

destructor TResourceTextureIntf.Destroy;
begin
  inherited Destroy;
end;

function TResourceTextureIntf.SizeOfVec: TDEVec;
begin
  Result := DEVec(RectWidth(TextureRect) * SizeScale[0], RectHeight(TextureRect) * SizeScale[1]);
end;

procedure TResourceTextureIntf.ChangeTexture(tex: TResourceTexture);
begin
  Texture := tex;
  TextureRect := Texture.BoundsRectV2;
  SizeScale := DEVec(1.0, 1.0);
end;

constructor TResourceTextureCache.Create;
begin
  inherited Create;
  TextureList := THashObjectList.Create(True, 1024);
  DefaultTexture := TResourceTexture.Create('');
  DefaultTexture.SetSize(2, 2, RasterColorF(0, 0, 0, 1.0));
end;

destructor TResourceTextureCache.Destroy;
begin
  DisposeObject(TextureList);
  DisposeObject(DefaultTexture);
  inherited Destroy;
end;

function TResourceTextureCache.CreateResourceTexture(filename: SystemString): TResourceTextureIntf;
var
  tex: TResourceTexture;
begin
  if filename = '' then
      exit(nil);

  filename := umlTrimSpace(filename);

  if filename = '' then
    begin
      tex := DefaultTexture;
    end
  else
    begin
      if not TextureList.Exists(filename) then
        begin
          if FileIOExists(filename) then
            begin
              try
                tex := TResourceTexture.Create(filename);
                TextureList.Add(filename, tex);
              except
                  tex := DefaultTexture;
              end;
            end
          else
              tex := DefaultTexture;
        end
      else
          tex := TextureList[filename] as TResourceTexture;
    end;

  Result := TResourceTextureIntf.Create(tex);
  Result.TextureRect := tex.BoundsRectV2;
  Result.SizeScale := DEVec(1.0, 1.0);
end;

procedure TResourceTextureCache.ReleaseAllFMXRsource;
begin
  TextureList.Progress(
    procedure(const Name: PSystemString; obj: TCoreClassObject)
    begin
      if obj is TDETexture_PXL then
          TDETexture_PXL(obj).ReleaseFMXResource;
    end);
end;

function _NewRaster: TMemoryRaster;
begin
  Result := DefaultTextureClass.Create;
end;

initialization
DefaultTextureClass := TResourceTexture;
TextureCache := TResourceTextureCache.Create;
NewRaster := _NewRaster;

finalization
DisposeObject(TextureCache);

end.
