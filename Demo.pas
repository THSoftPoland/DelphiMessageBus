unit Demo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, MessageBus, Vcl.StdCtrls;

const
  MSG_TEST1 = 'MessageType_1';
  MSG_TEST2 = '{0C2DE102-5718-42E0-A2F1-666161B6DB34}';
  MSG_TEST3 = 'MessageType_2';

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    fRecv: THandle;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TMyBigDataMessage = class
    private
      fData: String;
      fCounter: Integer;
    public
      property Data: String read fData;
      property Counter: Integer read fCounter;
      constructor Create;
      procedure ChangeData;
  end;

constructor TMyBigDataMessage.Create;
begin
  inherited Create;
  fData := GetTickCount.ToString;
end;

procedure TMyBigDataMessage.ChangeData;
begin
  Inc(fCounter);
end;

//*********************  SUBSCRIBERS part **************************************

procedure TForm1.FormCreate(Sender: TObject);
begin
  fRecv := TMessageBus.Default.Subscribe<String>(MSG_TEST1,
    procedure(const aValue: String; aEnv: TMessageBus.TBusEnvir)                // procedure on receive string message type MSG_TEST1
    begin
      Caption := aValue;
    end);

  with TMessageBusSubscribers.Create(self) do begin                             // helper - you don't need call Free or unsubscribe
    Subscribe<TMyBigDataMessage>(MSG_TEST2,
      procedure(const aValue: TMyBigDataMessage; aEnv: TMessageBus.TBusEnvir)
      begin
        Button1.Caption := aValue.Data + ' / ' + aValue.Counter.ToString;       // procedure on receive TMyBigDataMessage message type MSG_TEST2
        aValue.ChangeData;                                                      // inside this Proc, you can change some data of aValue
        aEnv.MessageBus.Send(MSG_TEST3, aValue);                                // nested Send to MsgType MSG_TEST3 (inside same TMessageBus)
      end);
    Subscribe<TMyBigDataMessage>(MSG_TEST3,
      procedure(const aValue: TMyBigDataMessage; aEnv: TMessageBus.TBusEnvir)
      begin
        Button2.Caption := aValue.Data + ' / ' + aValue.Counter.ToString;       // procedure on receive TMyBigDataMessage message type MSG_TEST3
        aValue.ChangeData;
      end);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TMessageBus.Default.Unsubscribe(fRecv);                                       // you must unsubsribe message before Free
end;

//*********************  EMITERS part ******************************************

procedure TForm1.Button1Click(Sender: TObject);
begin
  TMessageBus.Default.Send(MSG_TEST1, 'FirstTest');                             // send string message type MSG_TEST1
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  aMessage: TMyBigDataMessage;
begin
  aMessage := TMyBigDataMessage.Create;
  try
    TMessageBus.Default.Send(MSG_TEST2, aMessage);                              // send TButton message type MSG_TEST2
    self.Caption := aMessage.Counter.ToString;
  finally
    aMessage.Free;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  TMessageBus.Default.Enabled[fRecv] := not TMessageBus.Default.Enabled[fRecv]; // enable/disable subscriber
end;


end.
