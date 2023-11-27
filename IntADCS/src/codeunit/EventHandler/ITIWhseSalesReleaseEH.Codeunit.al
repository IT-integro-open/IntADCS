codeunit 69092 "ITI WhseSalesRelease EH"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Sales Release", 'OnBeforeCreateWhseRequest', '', false, false)]
    local procedure OnBeforeCreateWhseRequest(var WhseRqst: Record "Warehouse Request";var SalesHeader: Record "Sales Header")
    begin
               WhseRqst."ITI Ship-to Code" := SalesHeader."Ship-to Code";
    end;
}
