codeunit 69067 "ITI Get Src Doc Evnt Hndler"
{
    [EventSubscriber(ObjectType::Report, Report::"Get Source Documents", 'OnAfterCreateWhseDocuments', '', false, false)]
    local procedure RunOnAfterCreateWhseDocuments(var WarehouseRequest: Record "Warehouse Request"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        AutomaticPickPutAwayMgt: Codeunit "ITI Automatic Pick PutAway Mgt";
    begin
        if WarehouseRequest.Type = WarehouseRequest.Type::Outbound then
            AutomaticPickPutAwayMgt.AutomaticPick(WarehouseRequest, WhseShipmentHeader)
    end;
}

