codeunit 69070 "ITI Bin Content EventHand"
{
    [EventSubscriber(ObjectType::Table, database::"Bin Content", OnBeforeValidateEvent, 'Default', true, true)]
    local procedure OnAfterValidateEventDefaultBinContent(var Rec: Record "Bin Content")
    begin
        if Rec.istemporary then
            exit;

        Rec.TESTFIELD("ITI Additional", FALSE);
    end;
}
