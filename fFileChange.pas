unit fFileChange;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    procedure InitializeDirFix;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TXStringList = class(TStringList)
  public
    procedure Sort; override;
  end;

const
  MaxLines = 200;

var
  Init: Boolean = False;
  DoJob: Boolean = True;
  FDirFiles: TXStringList = nil;
  FLines: TStringList = nil;
  nLines: Integer = 0;
  CurrentFileIndex: Integer = 0;
  nRead: Boolean = True;

procedure TForm1.Button1Click(Sender: TObject);
var
  I: Integer;
  S: string;
  SL: TStringList;
  TF: TextFile;
  L: Integer;
begin
  Memo1.Clear;
  Memo1.Lines.BeginUpdate;
  if DoJob then
  begin
    InitializeDirFix;
    if (FLines.Count > 0) and (nLines >= FLines.Count) then
    begin
      { Make txt file blank ! }
      // ------------------------------------------
      DeleteFile(FDirFiles[CurrentFileIndex]);
      AssignFile(TF, FDirFiles[CurrentFileIndex]);
      Rewrite(TF);
      CloseFile(TF);
      // -------------------------------------------
      nLines := 0;
      nRead  := True;
      Inc(CurrentFileIndex); // Process Next txt file.
      FLines.Clear;
    end;
    if nRead and (CurrentFileIndex < FDirFiles.Count) then
    begin
      { Read current txt file }
      nRead  := False;
      AssignFile(TF, FDirFiles[CurrentFileIndex]);
      Reset(TF);
      while not Eof(TF) do
      begin
        Readln(TF, S);
        FLines.Add(S);
      end;
      CloseFile(TF);
    end;
    L     := 0;
    for I := nLines to FLines.Count - 1 do
    begin
      if L >= MaxLines then
        Break;
      Inc(L);
      { ==> Process here <== }
      Memo1.Lines.Add(FLines[I]);
    end;
    if CurrentFileIndex < FDirFiles.Count then
    begin
      SL      := TStringList.Create;
      SL.LoadFromFile(FDirFiles[CurrentFileIndex]);
      if SL.Count > 0 then
      begin
        for I := 0 to MaxLines - 1 do
        begin
          if I < SL.Count then
            SL.Delete(I)
          else
            Break;
        end;
        SL.SaveToFile(FDirFiles[CurrentFileIndex]);
      end;
      SL.Free;
      Inc(nLines, MaxLines);
    end;
    if CurrentFileIndex >= FDirFiles.Count then
      DoJob := False; // Job done !
  end
  else
  begin
    { Clear used vars }
    if Assigned(FLines) then
      FreeAndNil(FLines);
    if Assigned(FDirFiles) then
      FreeAndNil(FLines);
  end;
  Memo1.Lines.EndUpdate;
end;

const
  nSplit = 2000;

procedure TForm1.Button2Click(Sender: TObject);
var
  SL, Tmp: TStringList;
  I, n: Integer;
begin
  SL    := TStringList.Create;
  SL.LoadFromFile('src.txt');
  n     := 0;
  Tmp   := TStringList.Create;
  for I := 0 to SL.Count - 1 do
  begin
    Tmp.Add(SL[I]);
    if (I > 0) and (I mod nSplit = 0) then
    begin
      Inc(n);
      Tmp.SaveToFile(IntToStr(n) + '.txt');
      Tmp.Clear;
    end;
  end;
  if Tmp.Count > 0 then
  begin
    Inc(n);
    Tmp.SaveToFile(IntToStr(n) + '.txt');
    Tmp.Clear;
  end;
  Tmp.Free;
  SL.Free;
end;

procedure TForm1.InitializeDirFix;
var
  Path: string;
  SR: TSearchRec;
begin
  if not Init then
  begin
    { Init vars }
    Init := True;
    Path := IncludeTrailingPathDelimiter(GetCurrentDir);
    FDirFiles := TXStringList.Create;
    FLines := TStringList.Create;
    { Enum director txt files }
    if FindFirst(Path + '*.txt', faArchive, SR) = 0 then
    begin
      repeat
        if SR.Size > 0 then
          FDirFiles.Add(SR.Name);
      until // Fill the list
      FindNext(SR) <> 0;
      FindClose(SR);
    end;
    FDirFiles.Sort;
  end;
end;

{ TXStringList }
function StringAsIntListCompareStrings(List: TStringList; Index1, Index2: Integer): Integer;
var
  S1, S2: string;
  L1, L2: Int64;
  R1, R2: Boolean;
begin
  S1     := List[Index1].Replace('.txt', '');
  S2     := List[Index2].Replace('.txt', '');
  R1     := TryStrToInt64(S1, L1);
  R2     := TryStrToInt64(S2, L2);
  if (not R1) or (not R2) then
    exit(CompareStr(S1, S2));
  Result := L1 - L2;
end;

procedure TXStringList.Sort;
begin
  CustomSort(StringAsIntListCompareStrings);
end;

end.
