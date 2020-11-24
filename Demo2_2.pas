unit Demo2_2;

interface

// suppose all objects are in different, independent files

type

// I know nothing about who need my mail addresses, I am independent source of mail addresses. I know only TMailSenderMessage
// You can change and test me independently

  TMailAdresSourceA = class
    private
      fMessageHandle: THandle;
    public
      constructor Create;
      destructor Destroy; override;
  end;

  TMailAdresSourceB = class
    private
      fMessageHandle: THandle;
    public
      constructor Create;
      destructor Destroy; override;
  end;

  TMailAdresSourceC = class
    private
      fMessageHandle: THandle;
    public
      constructor Create;
      destructor Destroy; override;
  end;



implementation

uses MessageBus, Demo2_1;

constructor TMailAdresSourceA.Create;
begin
  inherited;
  fMessageHandle := TMessageBus.Default.Subscribe<TMailSenderMessage>(TMailSenderMessage.MB_MAILSENDER, // when I receive question about TMailSenderMessage.MB_MAILSENDER
    procedure(const aData: TMailSenderMessage; aEnv: TMessageBus.TBusEnvir)                             // this is my answer
    begin                                                                       // set break here
      // this is my email database:
      if (aData.Filter = TMailSenderMessage.TMailSenderFilter.msfOne) then begin // I have only msfOne type mail addresses
        if aData.SecondFilter('adresA_1@domain.pl') then                        // are you interested in this mail adres ?
          aData.Add('MailUserA_1', 'adresA_1@domain.pl');
        if aData.SecondFilter('adresA_2@domain.gb') then                        // are you interested in this mail adres ?
          aData.Add('MailUserA_2', 'adresA_2@domain.gb');
      end;
    end
  )
end;

destructor TMailAdresSourceA.Destroy;
begin
  TMessageBus.Default.Unsubscribe(fMessageHandle);
  inherited;
end;

constructor TMailAdresSourceB.Create;
begin
  inherited;
  fMessageHandle := TMessageBus.Default.Subscribe<TMailSenderMessage>(TMailSenderMessage.MB_MAILSENDER,
    procedure(const aData: TMailSenderMessage; aEnv: TMessageBus.TBusEnvir)
    begin                                                                       // set break here
      if (aData.Filter = TMailSenderMessage.TMailSenderFilter.msfTwo) then begin // I have only msfTwo type mail addresses
        if aData.SecondFilter('adresB_1@domain.pl') then
          aData.Add('MailUserB_1', 'adresB_1@domain.pl');
        if aData.SecondFilter('adresB_2@domain.gb') then
          aData.Add('MailUserB_2', 'adresB_2@domain.gb');
      end;
    end
  )
end;

destructor TMailAdresSourceB.Destroy;
begin
  TMessageBus.Default.Unsubscribe(fMessageHandle);
  inherited;
end;

constructor TMailAdresSourceC.Create;
begin
  inherited;
  fMessageHandle := TMessageBus.Default.Subscribe<TMailSenderMessage>(TMailSenderMessage.MB_MAILSENDER,
    procedure(const aData: TMailSenderMessage; aEnv: TMessageBus.TBusEnvir)
    begin                                                                       // set break here
      if (aData.Filter = TMailSenderMessage.TMailSenderFilter.msfTwo) then begin // I have only msfTwo type mail addresses
        if aData.SecondFilter('adresC_1@domain.pl') then
          aData.Add('MailUserC_1', 'adresC_1@domain.pl');
        if aData.SecondFilter('adresC_2@domain.gb') then
          aData.Add('MailUserC_2', 'adresC_2@domain.gb');
      end;
    end
  )
end;

destructor TMailAdresSourceC.Destroy;
begin
  TMessageBus.Default.Unsubscribe(fMessageHandle);
  inherited;
end;

end.
