//Delphi��ѩ���㷨
//���ߣ�������
//https://github.com/suiyunonghen/DelphiSnowflake
//QQ: 75492895
unit DxSnowflake;

interface
uses Winapi.Windows, System.SysUtils,System.Generics.Collections,System.DateUtils;

type
  TWorkerID = 0..1023;
  TDxSnowflake = class
  private
    FStartUnix: int64;
    FWorkerID: TWorkerID;
    fTime: Int64;
    fstep: int64;
    FStartEpoch: Int64;
    freq: Int64;
    startC: Int64;
    function CurrentUnix: Int64;
  public
    constructor Create(StartTime: TDateTime);
    destructor Destroy;override;
    property WorkerID: TWorkerID read FWorkerID write FWorkerID;
    function Generate: Int64;
  end;

implementation

const
  Epoch: int64 = 1539615188000; //����ʱ��2018-10-15��
  //����վ�Ľڵ�λ��
  WorkerNodeBits:Byte = 10;
  //���кŵĽڵ���
	StepBits: Byte = 12;
  timeShift: Byte = 22;
	nodeShift: Byte = 12;
var
	WorkerNodeMax: int64;
	nodeMask:int64;

	stepMask:int64;

procedure InitNodeInfo;
begin
	WorkerNodeMax := -1 xor (-1 shl WorkerNodeBits);
	nodeMask := WorkerNodeMax shl StepBits;
	stepMask := -1 xor (-1 shl StepBits);
end;
{ TDxSnowflake }

constructor TDxSnowflake.Create(StartTime: TDateTime);
begin
  if StartTime >= Now then
    FStartEpoch := DateTimeToUnix(IncMinute(Now,-2))
  else if YearOf(StartTime) < 1984 then
    FStartEpoch := Epoch
  else FStartEpoch := DateTimeToUnix(StartTime);
  FStartEpoch := FStartEpoch * 1000;//ms
  FStartUnix := DateTimeToUnix(Now) * 1000;
  //���ϵͳ�ĸ�����Ƶ�ʼ�������һ�����ڵ��𶯴���
  queryperformancefrequency(freq);
  QueryPerformanceCounter(startC);
end;


function TDxSnowflake.CurrentUnix: Int64;
var
  nend: Int64;
begin
  QueryPerformanceCounter(nend);
  Result := FStartUnix + (nend - startC) * 1000 div freq;
end;

destructor TDxSnowflake.Destroy;
begin
  inherited;
end;

function TDxSnowflake.Generate: Int64;
var
  curtime: Int64;
begin
  TMonitor.Enter(Self);
  try
    curtime := CurrentUnix;//DateTimeToUnix(Now) * 1000;
    if curtime = fTime then
    begin
      fstep := (fstep + 1) and stepMask;
      if fstep = 0 then
      begin
        while curtime <= fTime do
          curtime := CurrentUnix;//DateTimeToUnix(Now) * 1000;
      end;
    end
    else fstep := 0;
    fTime := curtime;
    Result := (curtime - FStartEpoch) shl timeShift or FWorkerID shl nodeShift  or fstep;
  finally
    TMonitor.Exit(Self);
  end;
end;

initialization
  InitNodeInfo;
end.
