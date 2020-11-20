unit MessageBus;

interface

{$region 'Comment'}
{
Message Bus send message T with name MsgType everone, who is interested in

To be "inetreseted in" you should register method with MasgType name, for example:
  Subscribe<Integer>('CommonName1', procedure(aValue: Integer; aEnvir: TMessageBus.TBusEnvir) begin <do something> end)
  Subscribe<TObject>('CommonName2', procedure(aValue: TObject; aEnvir: TMessageBus.TBusEnvir) begin <do something> end)
The one (emiter) who has something to say (has the source data) sends, for example:
  Send<Integer>('CommonName1', 17);
  Send<TObject>('CommonName2', TObject);

ATTENTION
Data type with name MsgType must be the same for subscribers and emiter !! One name one type.
This is wrong:
  Subscribe<Integer>('Name', procedure(aValue: Integer) begin end)
  Send<TObject>('Name', TObject);
}
{$endregion}

uses
  SysUtils, RTTI, Generics.Collections, Classes, Windows;

type

  TMessageBus = class
    public type
      TBusKey = string;                                                         // Integer or any simple data type
    private type

    public type
      TBusEnvir = class                                                         // Subscribers can Lock/Unlock in multithreaded environment (look TBusProc<T>)
        private                                                                 // and send nested messages
          fOwner: TMessageBus;
          fLocker: TRTLCriticalSection;
          fMultiThreaded: Boolean;
          constructor Create(aOwner: TMessageBus);
          destructor Destroy; override;
          procedure _SetMultiThreaded(aValue: Boolean);
        public
          property MessageBus: TMessageBus read fOwner;
          procedure Lock;
          procedure Unlock;
      end;
      TBusProc<T> = reference to procedure(const aValue: T; aEnv: TBusEnvir);   // subscribers main procedure
    private type
      TBusItem = class
        private
          fHandle: THandle;
          fMsgProc:TProc<TValue, TBusEnvir>;
          fEnabled: Boolean;
        public
          property MsgProc:TProc<TValue, TBusEnvir> read fMsgProc;
          property Handle: THandle read FHandle;
          property Enabled: Boolean read fEnabled write fEnabled;
          constructor Create(aMsgProc:TProc<TValue, TBusEnvir>);
      end;
      TBusType = class                                                          // message type
        private
          fReceiverList: TList<TBusItem>;
        public
          constructor Create;
          destructor Destroy; override;
      end;
    private
      class var fDefault: TMessageBus;
      class function _GetDefault: TMessageBus; static;
      class destructor ClassDestroy;
    private
      fBusEnv: TBusEnvir;
      fList: TDictionary<TBusKey, TBusType>;                                    // list of messages type
      fLocker: TRTLCriticalSection;
      fMultiThreaded: Boolean;
      function _GetMultiThreaded: Boolean;
      procedure _SetMultiThreaded(aValue: Boolean);
      procedure _Lock;
      procedure _Unlock;
      function _GetEnabled(aHandle: THandle): Boolean;
      procedure _SetEnabled(aHandle: THandle; aValue: Boolean);
      function _FindHandle(aHandles: TArray<THandle>; aProc: TProc<TBusType, TBusItem>): Boolean;
    public
      class property Default: TMessageBus read _GetDefault;
      property MultiThreaded: Boolean read _GetMultiThreaded write _SetMultiThreaded;
      property Enabled[aHandle: THandle]: Boolean read _GetEnabled write _SetEnabled;
      constructor Create;
      destructor Destroy; override;
      procedure Send<T>(aMsgType: TBusKey; aData: T);                           // send message aMsgType to subscribers
      function Subscribe<T>(aMsgType: TBusKey; aMsgProc: TBusProc<T>): THandle; // subscribe message aMsgType
      procedure Unsubscribe(aHandles: TArray<THandle>); overload;               // unsubscribe subscribers
      procedure Unsubscribe(aHandle: THandle); overload;
  end;

  TMessageBusSubscribers = class(TComponent)                                    // helper class - keeps all Handles (subscribers) in one place. Useful for any Forms or Datamodule
    private
      fHandles: TArray<THandle>;
    public
      destructor Destroy; override;
      function Subscribe<T>(aMsgType: TMessageBus.TBusKey; aMsgProc: TMessageBus.TBusProc<T>): THandle;
  end;

implementation

constructor TMessageBus.TBusType.Create;
begin
  inherited;
  fReceiverList := TObjectList<TBusItem>.Create;
end;

destructor TMessageBus.TBusType.Destroy;
begin
  FreeAndNil(fReceiverList);
  inherited;
end;

constructor TMessageBus.TBusItem.Create(aMsgProc:TProc<TValue, TBusEnvir>);
begin
  inherited Create;
  fMsgProc := aMsgProc;
  fEnabled := True;
  fHandle := THandle(@fMsgProc);
end;

constructor TMessageBus.TBusEnvir.Create(aOwner: TMessageBus);
begin
  inherited Create;
  fOwner := aOwner;
  fMultiThreaded := False;
end;

destructor TMessageBus.TBusEnvir.Destroy;
begin
  _SetMultiThreaded(False);
  inherited;
end;

procedure TMessageBus.TBusEnvir._SetMultiThreaded(aValue: Boolean);
begin
  if (fMultiThreaded and (not aValue)) then
    DeleteCriticalSection(fLocker);
  fMultiThreaded := aValue;
  if fMultiThreaded then
    InitializeCriticalSection(fLocker);
end;

procedure TMessageBus.TBusEnvir.Lock;
begin
  if fMultiThreaded then
    EnterCriticalSection(fLocker);
end;

procedure TMessageBus.TBusEnvir.Unlock;
begin
  if fMultiThreaded then
    LeaveCriticalSection(fLocker);
end;

class destructor TMessageBus.ClassDestroy;
begin
  FreeAndNil(fDefault);
end;

class function TMessageBus._GetDefault: TMessageBus;
begin
  if (not Assigned(fDefault)) then
    fDefault := TMessageBus.Create;
  Result := fDefault;
end;

constructor TMessageBus.Create;
begin
  inherited;
  fList := TObjectDictionary<TBusKey, TBusType>.Create([doOwnsValues]);
  fBusEnv := TBusEnvir.Create(self);
  _SetMultiThreaded(IsMultiThread);
end;

destructor TMessageBus.Destroy;
begin
  FreeAndNil(fList);
  FreeAndNil(fBusEnv);
  inherited;
end;

function TMessageBus._GetMultiThreaded: Boolean;
begin
  Result := fMultiThreaded;
end;

procedure TMessageBus._SetMultiThreaded(aValue: Boolean);
begin
  if (fMultiThreaded and (not aValue)) then
    DeleteCriticalSection(fLocker);
  fMultiThreaded := aValue;
  if fMultiThreaded then
    InitializeCriticalSection(fLocker);
  fBusEnv._SetMultiThreaded(fMultiThreaded);
end;

procedure TMessageBus._Lock;
begin
  if fMultiThreaded then
    EnterCriticalSection(fLocker);
end;

procedure TMessageBus._Unlock;
begin
  if fMultiThreaded then
    LeaveCriticalSection(fLocker);
end;

procedure TMessageBus.Send<T>(aMsgType: TBusKey; aData: T);
var
  aProcObj: TBusType;
  aBusItem: TBusItem;
begin
  _Lock;
  try
    if fList.TryGetValue(aMsgType, aProcObj) then
      for aBusItem in aProcObj.fReceiverList do
        if aBusItem.Enabled then
          aBusItem.MsgProc(TValue.From<T>(aData), fBusEnv);
  finally
    _Unlock;
  end;
end;

function TMessageBus.Subscribe<T>(aMsgType: TBusKey; aMsgProc: TBusProc<T>): THandle;
var
  aBusType: TBusType;
begin
  _Lock;
  try
    if not fList.TryGetValue(aMsgType, aBusType) then begin
      aBusType := TBusType.Create;
      fList.Add(aMsgType, aBusType);
    end;
    aBusType.fReceiverList.Add(TBusItem.Create(procedure(aValue: TValue; aEnv: TBusEnvir)
      begin
        aMsgProc(aValue.AsType<T>, aEnv);
      end));
    Result := aBusType.fReceiverList.Last.Handle;
  finally
    _UnLock;
  end;
end;

function TMessageBus._FindHandle(aHandles: TArray<THandle>; aProc: TProc<TBusType, TBusItem>): Boolean;
  function InArray(aHandle: THandle): Boolean;
  var
    i: Integer;
  begin
    i := Low(aHandles);
    while (i <= High(aHandles)) and (aHandles[i] <> aHandle) do Inc(i);
    Result := (i <= High(aHandles));
  end;
var
  aKey: TBusKey;
  aBusItem: TBusItem;
  aCounter: Integer;
  aMsgType: TBusType;
begin
  aCounter := High(aHandles) - Low(aHandles) + 1;
  _Lock;
  try
    for aKey in fList.Keys do begin
      aMsgType := fList[aKey];
      for aBusItem in aMsgType.fReceiverList do
        if InArray(aBusItem.Handle) then begin
          aProc(aMsgType, aBusItem);
          Dec(aCounter);
          if (aCounter = 0) then
            Exit;
        end;
    end;
  finally
    _Unlock;
  end;
end;

procedure TMessageBus.Unsubscribe(aHandles: TArray<THandle>);
begin
  _FindHandle(aHandles,
    procedure(aBusType: TBusType; aBusItem: TBusItem)
    begin
      aBusType.fReceiverList.Remove(aBusItem);
    end);
end;

procedure TMessageBus.Unsubscribe(aHandle: THandle);
begin
  Unsubscribe(TArray<THandle>.Create(aHandle));
end;

function TMessageBus._GetEnabled(aHandle: THandle): Boolean;
var
  aResult: Boolean;
begin
  _FindHandle(TArray<THandle>.Create(aHandle),
    procedure(aBusType: TBusType; aBusItem: TBusItem)
    begin
      aResult := aBusItem.Enabled;
    end);
  Result := aResult;
end;

procedure TMessageBus._SetEnabled(aHandle: THandle; aValue: Boolean);
begin
  _FindHandle(TArray<THandle>.Create(aHandle),
    procedure(aBusType: TBusType; aBusItem: TBusItem)
    begin
      aBusItem.fEnabled := aValue;
    end);
end;

destructor TMessageBusSubscribers.Destroy;
begin
  if (Length(fHandles) > 0) then
    TMessageBus.Default.Unsubscribe(fHandles);
  inherited;
end;

function TMessageBusSubscribers.Subscribe<T>(aMsgType: TMessageBus.TBusKey; aMsgProc: TMessageBus.TBusProc<T>): THandle;
begin
  Result := TMessageBus.Default.Subscribe<T>(aMsgType, aMsgProc);
  if Assigned(fHandles) then begin
    SetLength(fHandles, Length(fHandles) + 1);
    fHandles[Length(fHandles) - 1] := Result;
  end
  else
    fHandles := TArray<THandle>.Create(Result);
end;

end.
