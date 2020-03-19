unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList, Vcl.ImgList,
  Vcl.StdCtrls, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    EdtURL: TEdit;
    lblUrl: TLabel;
    EdtPort: TEdit;
    LblPort: TLabel;
    EdtPrivateKey: TEdit;
    LblPrivateKey: TLabel;
    BtnSend: TButton;
    EdtFile: TEdit;
    LblFile: TLabel;
    ImageList1: TImageList;
    EdtRemoteDir: TEdit;
    LblRemoteDir: TLabel;
    PageControl1: TPageControl;
    TabScript: TTabSheet;
    MemoScript: TMemo;
    TabLog: TTabSheet;
    MemoLog: TMemo;
    procedure BtnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function CreateProcessAndWait(cmd: string): Integer;
    procedure SendFile(AURL, APort, APrivateKeyPath, AFile, ARemoteDir: string);

    function WinSCP: string;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses IOUtils;

procedure TForm1.BtnSendClick(Sender: TObject);
begin
  // Validate params
  if not FileExists(WinSCP) then
    raise Exception.Create('WinSCP.com not found!');

  if not FileExists(EdtPrivateKey.Text) then
    raise Exception.Create('Private key [' + EdtPrivateKey.Text + '] not found!');

  if not FileExists(EdtFile.Text) then
    raise Exception.Create('File [' + EdtFile.Text + '] not found!');

  // Execute communication
  SendFile(EdtURL.Text, EdtPort.Text, EdtPrivateKey.Text, EdtFile.Text, EdtRemoteDir.Text);
end;

procedure TForm1.SendFile(AURL, APort, APrivateKeyPath, AFile, ARemoteDir: string);
begin
  // Create temporary script.tmp with the desired sftp commands
  // In this example I just open a secure SSH FTP session and upload a dummy file, and then exit the session
  TFile.WriteAllLines('script.tmp',
    ['open sftp://'+AURL+':'+APort+'/ -privatekey="'+APrivateKeyPath+'" -hostkey="ssh-rsa 1024 LpjV3C3/5UTYp3fLHmLEwHU1h2Qx/DVM+HrBuxXtoDs="',
     'put "'+AFile+'" '+ARemoteDir,
     'exit']);

  // Load script in the script memo, if the temporary script file exists
  if TFile.Exists('script.tmp') then
    MemoScript.Lines.LoadFromFile('script.tmp');

  // Run windows command, if temporary script exists
  if TFile.Exists('script.tmp') then
    CreateProcessAndWait(WinSCP + ' /log=WinSCP.log /loglevel=0 /ini=nul /script=script.tmp');

  // Load log, if exists
  MemoLog.Lines.Clear;
  if TFile.Exists('WinSCP.log') then
    MemoLog.Lines.LoadFromFile('WinSCP.log');
end;

function TForm1.WinSCP: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'WinSCP.com';
end;

function TForm1.CreateProcessAndWait(cmd:string): Integer;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Executed : Boolean;
  CodigoSaida : LongWord;
begin
  Result := -1;
  FillChar(SUInfo, SizeOf(SUInfo), #0);
  SUInfo.cb          := SizeOf(SUInfo);
  SUInfo.dwFlags     := STARTF_USESHOWWINDOW;
  SUInfo.wShowWindow := SW_HIDE;

  Executed := CreateProcess(nil,
                            PChar(cmd),
                            nil,
                            nil,
                            false,
                            CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
                            nil,
                            nil,
                            SUInfo,
                            ProcInfo);

  if (Executed) then
  begin
    while WaitForSingleObject(ProcInfo.hProcess, 1000) <> WAIT_TIMEOUT do
      Application.ProcessMessages; // Not the best practice, but...

    GetExitCodeProcess(ProcInfo.hProcess, CodigoSaida);
    Result := CodigoSaida;

    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Create dummy file
  if not TFile.Exists(ExtractFilePath(ParamStr(0)) + 'FileToSend.txt') then
    TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + 'FileToSend.txt', 'Content Here');
  EdtFile.Text := ExtractFilePath(ParamStr(0)) + 'FileToSend.txt';
end;

end.
