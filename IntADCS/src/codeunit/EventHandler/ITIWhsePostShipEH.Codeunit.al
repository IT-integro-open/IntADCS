codeunit 69090 ITIWhsePostShipEH
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnBeforeConfirmWhseShipmentPost', '', false, false)]
    local procedure OnBeforeConfirmWhseShipmentPost(var Selection: Integer; var HideDialog: Boolean)
    begin
        Selection := 1;
        HideDialog := true;
    end;
}
