{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ ****************************************************************************** }
unit PropsMaterialUnit;

{$I zDefine.inc}

interface

uses SysUtils,
  CoreClasses, PascalStrings,
  LibraryManager, UnicodeMixedLib,
  ObjectDataManager, MemoryStream64, TextDataEngine, ListEngine, StreamList,
  MemoryRaster;

type
  TPropsMaterialType = (
    pmtArrow, pmtArrowBullet, pmtBelt, pmtBigbox, pmtBook, pmtBoots, pmtBracer,
    pmtBullet, pmtCloak, pmtGlove, pmtIash, pmtIWAMAR, pmtIWAMBO, pmtIWAMBU,
    pmtIWAXBT, pmtIWAXGR, pmtIWAXHN, pmtIWBLCL, pmtIWBLFH, pmtIWBLFL, pmtIWBLHL,
    pmtIWBLHW, pmtIWBLML, pmtIWBLMS, pmtIWBWLC, pmtIWBWLN, pmtIWBWSC, pmtIWBWSH,
    pmtIWBWSL, pmtIWBWXH, pmtIWBWXL, pmtIWBWXR, pmtIWDBAX, pmtIWDBMA, pmtIWDBQS,
    pmtIWDBSW, pmtIWMGRD, pmtIWMGST, pmtIWMGWN, pmtIWPLHB, pmtIWPLSC, pmtIWPLSS,
    pmtIWSPGA, pmtIWSPKA, pmtIWSPKU, pmtIWSPSC, pmtIWSPSP, pmtIWSWBS, pmtIWSWDG,
    pmtIWSWGS, pmtIWSWKA, pmtIWSWLS, pmtIWSWRP, pmtIWSWSC, pmtIWSWSS, pmtIWTHAX,
    pmtIWTHDT, pmtIWTHSH, pmtKey, pmtMidmisc, pmtNeck, pmtNWNSpellPortrait, pmtPotion,
    pmtRing, pmtSmlmisc, pmtTalmisc, pmtThnmisc, pmtTrap);
  TPropsMaterialTypes = set of TPropsMaterialType;

const
  PropsMaterialTypeOfFile: array [TPropsMaterialType] of SystemString = (
    'arrow.txt', 'ArrowBullet.txt', 'belt.txt', 'bigbox.txt', 'book.txt', 'boots.txt', 'bracer.txt',
    'Bullet.txt', 'cloak.txt', 'glove.txt', 'iash.txt', 'IWAMAR.txt', 'IWAMBO.txt', 'IWAMBU.txt',
    'IWAXBT.txt', 'IWAXGR.txt', 'IWAXHN.txt', 'IWBLCL.txt', 'IWBLFH.txt', 'IWBLFL.txt', 'IWBLHL.txt',
    'IWBLHW.txt', 'IWBLML.txt', 'IWBLMS.txt', 'IWBWLC.txt', 'IWBWLN.txt', 'IWBWSC.txt', 'IWBWSH.txt',
    'IWBWSL.txt', 'IWBWXH.txt', 'IWBWXL.txt', 'IWBWXR.txt', 'IWDBAX.txt', 'IWDBMA.txt', 'IWDBQS.txt',
    'IWDBSW.txt', 'IWMGRD.txt', 'IWMGST.txt', 'IWMGWN.txt', 'IWPLHB.txt', 'IWPLSC.txt', 'IWPLSS.txt',
    'IWSPGA.txt', 'IWSPKA.txt', 'IWSPKU.txt', 'IWSPSC.txt', 'IWSPSP.txt', 'IWSWBS.txt', 'IWSWDG.txt',
    'IWSWGS.txt', 'IWSWKA.txt', 'IWSWLS.txt', 'IWSWRP.txt', 'IWSWSC.txt', 'IWSWSS.txt', 'IWTHAX.txt',
    'IWTHDT.txt', 'IWTHSH.txt', 'key.txt', 'midmisc.txt', 'neck.txt', 'NWNSpellPortrait.txt', 'potion.txt',
    'ring.txt', 'smlmisc.txt', 'talmisc.txt', 'thnmisc.txt', 'trap.txt');

  AllPropsType: TPropsMaterialTypes = [
    pmtArrow, pmtArrowBullet, pmtBelt, pmtBigbox, pmtBook, pmtBoots, pmtBracer,
    pmtBullet, pmtCloak, pmtGlove, pmtIash, pmtIWAMAR, pmtIWAMBO, pmtIWAMBU,
    pmtIWAXBT, pmtIWAXGR, pmtIWAXHN, pmtIWBLCL, pmtIWBLFH, pmtIWBLFL, pmtIWBLHL,
    pmtIWBLHW, pmtIWBLML, pmtIWBLMS, pmtIWBWLC, pmtIWBWLN, pmtIWBWSC, pmtIWBWSH,
    pmtIWBWSL, pmtIWBWXH, pmtIWBWXL, pmtIWBWXR, pmtIWDBAX, pmtIWDBMA, pmtIWDBQS,
    pmtIWDBSW, pmtIWMGRD, pmtIWMGST, pmtIWMGWN, pmtIWPLHB, pmtIWPLSC, pmtIWPLSS,
    pmtIWSPGA, pmtIWSPKA, pmtIWSPKU, pmtIWSPSC, pmtIWSPSP, pmtIWSWBS, pmtIWSWDG,
    pmtIWSWGS, pmtIWSWKA, pmtIWSWLS, pmtIWSWRP, pmtIWSWSC, pmtIWSWSS, pmtIWTHAX,
    pmtIWTHDT, pmtIWTHSH, pmtKey, pmtMidmisc, pmtNeck, pmtNWNSpellPortrait, pmtPotion,
    pmtRing, pmtSmlmisc, pmtTalmisc, pmtThnmisc, pmtTrap];

type
  TPropsMaterial = class;

  TPropsMaterialBitmap = class(TCoreClassPersistent)
  protected
    FOwner            : TPropsMaterial;
    FBitmap           : TMemoryRaster;
    FKeyExpression    : umlString;
    FPropsMaterialType: TPropsMaterialType;

    procedure SetKeyExpression(const Value: umlString);
    function GetBitmap: TMemoryRaster;
  public
    constructor Create(AOwner: TPropsMaterial); virtual;
    destructor Destroy; override;

    property Owner: TPropsMaterial read FOwner;
    property Bitmap: TMemoryRaster read GetBitmap;

    property KeyExpression: umlString read FKeyExpression write SetKeyExpression;
    property PropsMaterialType: TPropsMaterialType read FPropsMaterialType;
  end;

  TPropsMaterial = class(TCoreClassPersistent)
  protected
    FDBEng                : TObjectDataManager;
    FLibMan               : TLibraryManager;
    FIndexListOfTextEngine: THashObjectList;
    FItemBitmap           : THashObjectList;
    FMemoryBitmapClass    : TMemoryRasterClass;

    function GetItemBitmap(KeyExpression: umlString): TPropsMaterialBitmap;
  public
    constructor Create(Stream: TCoreClassStream); virtual;
    destructor Destroy; override;

    function MakePropsMaterial(aPortType: TPropsMaterialType; OnlyOnes: Boolean): TPropsMaterialBitmap; overload;
    function MakePropsMaterial(aPortType: TPropsMaterialType): TPropsMaterialBitmap; overload;
    function MakePropsMaterial(KeyExpression: umlString): TPropsMaterialBitmap; overload;

    procedure Clear;
    procedure OptimizationMemory;

    property Items[KeyExpression: umlString]: TPropsMaterialBitmap read GetItemBitmap; default;

    property LibMan: TLibraryManager read FLibMan;
    property MemoryBitmapClass: TMemoryRasterClass read FMemoryBitmapClass write FMemoryBitmapClass;
  published
  end;

function PortraitType2Str(t: TPropsMaterialType): umlString;
function Str2PortraitType(s: umlString): TPropsMaterialType;
function PortraitBlend(StreamList: TCoreClassStrings; Output: TMemoryRaster): Boolean;
function FillPortraitKeyExpression(LibMan: TLibraryManager; const AExpression: umlString; OutList: TCoreClassStrings): TPropsMaterialType;

procedure ExportPortraitTypeToPreview(PropsMaterial: TPropsMaterial; pts: TPropsMaterialTypes; destPath: SystemString; SamplerCount: Integer);

implementation

function PortraitType2Str(t: TPropsMaterialType): umlString;
begin
  Result := PropsMaterialTypeOfFile[t];
end;

function Str2PortraitType(s: umlString): TPropsMaterialType;
var
  i: Integer;
begin
  Result := pmtTrap;
  for i := 0 to Length(PropsMaterialTypeOfFile) do
    begin
      Result := TPropsMaterialType(i);
      if s.Same(PropsMaterialTypeOfFile[Result]) then
          Exit;
    end;
end;

function PortraitBlend(StreamList: TCoreClassStrings; Output: TMemoryRaster): Boolean;

  function OpenStreamAsNewGraphic(_Name: umlString; Stream: TCoreClassStream): TMemoryRaster;
  begin
    Result := TMemoryRaster.Create;
    Stream.Position := 0;
    Result.LoadFromStream(Stream);
    Stream.Position := 0;
  end;

var
  RepInt: Integer;
  G     : TMemoryRaster;
begin
  Result := False;
  if (StreamList = nil) or (Output = nil) then
      Exit;
  if StreamList.Count = 0 then
      Exit;

  Output.LoadFromStream(TCoreClassStream(StreamList.Objects[0]));
  Output.DrawMode := dmBlend;
  Output.CombineMode := cmBlend;

  if StreamList.Count > 1 then
    begin
      G := TMemoryRaster.Create;
      G.DrawMode := dmBlend;
      G.CombineMode := cmBlend;
      for RepInt := 1 to StreamList.Count - 1 do
        begin
          G.LoadFromStream(TCoreClassStream(StreamList.Objects[RepInt]));
          G.DrawTo(Output);
        end;
      DisposeObject(G);
    end;

  Result := True;
end;

function FillPortraitKeyExpression(LibMan: TLibraryManager; const AExpression: umlString; OutList: TCoreClassStrings): TPropsMaterialType;
var
  n, fn    : umlString;
  p        : PHashStreamListData;
  errorflag: Boolean;
begin
  n := AExpression;
  Result := TPropsMaterialType(umlStrToInt(umlGetFirstStr(n, '#'), 0));
  n := umlDeleteFirstStr(n, '#');

  errorflag := False;
  while n <> '' do
    begin
      fn := umlGetFirstStr(n, '#');
      p := LibMan.PathItems[fn.Text];
      if p <> nil then
          OutList.AddObject(fn.Text, p^.Stream)
      else
        begin
          errorflag := True;
        end;
      n := umlDeleteFirstStr(n, '#');
    end;
end;

procedure TPropsMaterialBitmap.SetKeyExpression(const Value: umlString);
var
  n, fn    : umlString;
  ns       : TCoreClassStringList;
  p        : PHashStreamListData;
  errorflag: Boolean;
begin
  if Value = '' then
      Exit;

  ns := TCoreClassStringList.Create;

  n := Value;
  FPropsMaterialType := TPropsMaterialType(umlStrToInt(umlGetFirstStr(n, '#'), 0));
  n := umlDeleteFirstStr(n, '#');

  errorflag := False;
  while n <> '' do
    begin
      fn := umlGetFirstStr(n, '#');
      p := FOwner.FLibMan.PathItems[fn.Text];
      if p <> nil then
          ns.AddObject(fn.Text, p^.Stream)
      else
        begin
          errorflag := True;
        end;
      n := umlDeleteFirstStr(n, '#');
    end;
  if (ns.Count > 0) and (not errorflag) then
    begin
      PortraitBlend(ns, FBitmap);
      FKeyExpression := Value;
    end;
  DisposeObject(ns);
end;

function TPropsMaterialBitmap.GetBitmap: TMemoryRaster;
begin
  if FBitmap.Empty then
      SetKeyExpression(FKeyExpression);
  Result := FBitmap;
end;

constructor TPropsMaterialBitmap.Create(AOwner: TPropsMaterial);
begin
  inherited Create;
  FOwner := AOwner;
  FBitmap := AOwner.FMemoryBitmapClass.Create;
  FKeyExpression := '';
end;

destructor TPropsMaterialBitmap.Destroy;
begin
  DisposeObject(FBitmap);
  inherited Destroy;
end;

function TPropsMaterial.GetItemBitmap(KeyExpression: umlString): TPropsMaterialBitmap;
begin
  Result := TPropsMaterialBitmap(FItemBitmap[KeyExpression.Text]);
  if Result = nil then
    begin
      Result := TPropsMaterialBitmap.Create(self);
      Result.KeyExpression := KeyExpression;

      if Result.KeyExpression <> '' then
          FItemBitmap[Result.KeyExpression.Text] := Result;
    end;
end;

constructor TPropsMaterial.Create(Stream: TCoreClassStream);
var
  lst: TCoreClassStrings;
  i  : Integer;
  p  : PHashStreamListData;
  t  : TSectionTextData;
begin
  inherited Create;
  FMemoryBitmapClass := TMemoryRaster;

  FDBEng := TObjectDataManager.CreateAsStream(Stream, '', ObjectDataMarshal.ID, True, False, True);
  FLibMan := TLibraryManager.Create(FDBEng, '/');

  FIndexListOfTextEngine := THashObjectList.Create(True);
  FItemBitmap := THashObjectList.Create(True);

  lst := TCoreClassStringList.Create;

  FLibMan.Root.GetOriginNameListFromFilter('*.txt', lst);

  for i := 0 to lst.Count - 1 do
    begin
      p := FLibMan.Root[lst[i]];
      t := TSectionTextData.Create;
      t.LoadFromStream(p^.Stream);
      FIndexListOfTextEngine[lst[i]] := t;
    end;

  DisposeObject(lst);
end;

destructor TPropsMaterial.Destroy;
begin
  DisposeObject(FItemBitmap);
  DisposeObject(FIndexListOfTextEngine);
  DisposeObject(FLibMan);
  DisposeObject(FDBEng);
  inherited Destroy;
end;

function TPropsMaterial.MakePropsMaterial(aPortType: TPropsMaterialType; OnlyOnes: Boolean): TPropsMaterialBitmap;
var
  IdxFile: umlString;
  t      : TSectionTextData;
  lst, ns: TCoreClassStrings;
  blends : umlString;
  i, c   : Integer;
begin
  IdxFile := PropsMaterialTypeOfFile[aPortType];
  Result := nil;

  if not FIndexListOfTextEngine.Exists(IdxFile.Text) then
      Exit;

  t := TSectionTextData(FIndexListOfTextEngine[IdxFile.Text]);

  lst := TCoreClassStringList.Create;
  t.GetSectionList(lst);

  c := 0;
  repeat
    blends := umlIntToStr(Integer(aPortType));
    for i := 0 to lst.Count - 1 do
      begin
        ns := t.Names[lst[i]];
        blends := blends + '#' + ns[umlRandomRange(0, ns.Count - 1)];
      end;

    Result := TPropsMaterialBitmap(FItemBitmap[blends.Text]);
    Inc(c);
  until (not OnlyOnes) or (Result = nil) or (c > 100);

  DisposeObject(lst);

  if Result = nil then
    begin
      Result := TPropsMaterialBitmap.Create(self);
      Result.KeyExpression := blends;

      if Result.KeyExpression <> '' then
          FItemBitmap[Result.KeyExpression.Text] := Result;
    end;
end;

function TPropsMaterial.MakePropsMaterial(aPortType: TPropsMaterialType): TPropsMaterialBitmap;
begin
  Result := MakePropsMaterial(aPortType, False);
end;

function TPropsMaterial.MakePropsMaterial(KeyExpression: umlString): TPropsMaterialBitmap;
begin
  Result := Items[KeyExpression];
end;

procedure TPropsMaterial.Clear;
begin
  FItemBitmap.Clear;
end;

procedure TPropsMaterial.OptimizationMemory;
var
  lst: TCoreClassListForObj;
  i  : Integer;
begin
  lst := TCoreClassListForObj.Create;
  FItemBitmap.GetAsList(lst);
  for i := 0 to lst.Count - 1 do
      TPropsMaterialBitmap(lst[i]).FBitmap.Reset;
  DisposeObject(lst);
end;

procedure ExportPortraitTypeToPreview(PropsMaterial: TPropsMaterial; pts: TPropsMaterialTypes; destPath: SystemString; SamplerCount: Integer);
var
  t: TPropsMaterialType;
  n: SystemString;
  b: TPropsMaterialBitmap;
  i: Integer;
begin
  umlCreateDirectory(destPath);
  for t in pts do
    begin
      for i := 1 to SamplerCount do
        begin
          n := PortraitType2Str(t);
          b := PropsMaterial.MakePropsMaterial(t, True);
          n := umlDeleteLastStr(n, '.');
          n := Format('%s_%d.bmp', [n, i]);
          b.Bitmap.SaveToFile(umlCombineFileName(destPath, n));
        end;
    end;
end;

end.
