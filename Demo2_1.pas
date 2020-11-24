unit Demo2_1;

interface

uses
  Classes, SysUtils;

type

  // this is Message Data

  TMailSenderMessage = class
    public const
      MB_MAILSENDER = '{5ACDE5DB-2BD6-497E-9B65-BB2A3FEE2D38}';
    public type
      TMailSenderFilter = (msfOne, msfTwo);
    private
      fFilter: TMailSenderFilter;
      fMailList: TStrings;
      fSecondFilter: TPredicate<String>;
    public
      property Filter: TMailSenderFilter read fFilter;
      property SecondFilter: TPredicate<String> read fSecondFilter write fSecondFilter;
      property MailList: TStrings read fMailList;
      constructor Create(aFilter: TMailSenderFilter);
      destructor Destroy; override;
      procedure Add(aName, aMail: String);
  end;



implementation

constructor TMailSenderMessage.Create(aFilter: TMailSenderFilter);
begin
  inherited Create;
  fMailList := TStringList.Create;
  fFilter := aFilter;
end;

destructor TMailSenderMessage.Destroy;
begin
  FreeAndNil(fMailList);
  inherited;
end;

procedure TMailSenderMessage.Add(aName, aMail: String);
begin
  fMailList.Values[aName] := aMail;
end;

end.
