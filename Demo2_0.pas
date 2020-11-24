unit Demo2_0;

interface

type

// I know nothing about source of mail addresses, I am independent object. I know only TMailSenderMessage
// You can change and test me independently

  TMailSender = class
    public
      constructor Create;
      destructor Destroy; override;
      procedure SendMail(aTitle, aText: String);
  end;

implementation

uses MessageBus, Demo2_1, Classes, SysUtils;

constructor TMailSender.Create;
begin
  inherited;
end;

destructor TMailSender.Destroy;
begin
  inherited;
end;

procedure TMailSender.SendMail(aTitle, aText: String);
var
  aMessage: TMailSenderMessage;
  i: Integer;
begin
  aMessage := TMailSenderMessage.Create(msfTwo);
  try
    aMessage.SecondFilter :=
      function(aMail: String): Boolean
      begin
        Result := aMail.ToUpper.EndsWith('.PL');                                // set break here
      end;
	  
    TMessageBus.Default.Send<TMailSenderMessage>(TMailSenderMessage.MB_MAILSENDER, aMessage);

    for i := 0 to aMessage.MailList.Count - 1 do begin                          // set break here
      // SendProcedure(aTitle, aText, aMessage.MailList.Names[i], aMessage.MailList.ValueFromIndex[i])
    end;
  finally
    aMessage.Free;
  end;
end;


end.
