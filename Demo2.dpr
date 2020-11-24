program Demo2;

{$APPTYPE CONSOLE}

{$R *.res}

// Message Bus = we are independent !

uses Demo2_0, Demo2_2;

var
  aIndependentObject1: TMailSender;
  aIndependentObjectA, aIndependentObjectB, aIndependentObjectC: TObject;

begin
  aIndependentObject1 := TMailSender.Create;
  aIndependentObjectA := TMailAdresSourceA.Create;
  aIndependentObjectB := TMailAdresSourceB.Create;
  aIndependentObjectC := TMailAdresSourceC.Create;

  aIndependentObject1.SendMail('Title', 'Text');

  aIndependentObject1.Free;
  aIndependentObjectA.Free;
  aIndependentObjectB.Free;
  aIndependentObjectC.Free;
end.
