
/// <summary>
/// Codeunit ITI Get Src Doc Inbd Evnt Hndl (ID 69066).
/// </summary>
codeunit 69066 "ITI Get Src Doc Inbd Evnt Hndl"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", 'OnOpenWarehouseReceiptPage', '', false, false)]
    local procedure RunOnOnOpenWarehouseReceiptPage(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    var
        Location: Record Location;
    begin
        if Location.Get(WarehouseReceiptHeader."Location Code") and Location."ITI Automatic Create Put-Away" then
            if not WarehouseReceiptHeader.Get(WarehouseReceiptHeader."No.") then begin
                RunPostedWhseReceiptPage(WarehouseReceiptHeader."No.");
                IsHandled := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", 'OnAfterGetSingleInboundDoc', '', false, false)]
    local procedure RunOnAfterGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        Location: Record Location;
        AutomaticPickPutAwayMgt: Codeunit "ITI Automatic Pick PutAway Mgt";
        PostingReceiptProblemMsg: Label 'Error with Receipt posting occurs! Check Warehouse Receipt: %1', Comment = '%1 - Receipt no.';
    begin
        if Location.Get(WarehouseReceiptHeader."Location Code") and Location."ITI Automatic Create Put-Away" then begin
            if WarehouseReceiptHeader.Get(WarehouseReceiptHeader."No.") then
                AutomaticPickPutAwayMgt.PostReceiptCreatePutAway(WarehouseReceiptHeader);
            if not WarehouseReceiptHeader.Get(WarehouseReceiptHeader."No.") then
                RunPostedWhseReceiptPage(WarehouseReceiptHeader."No.")
            else
                Message(StrSubstNo(PostingReceiptProblemMsg, WarehouseReceiptHeader."No."));
        end;
    end;

    local procedure RunPostedWhseReceiptPage(WarehouseReceiptNo: Code[20])
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceipt: Page "Posted Whse. Receipt";
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptNo);
        if PostedWhseReceiptHeader.FindFirst() then begin
            PostedWhseReceipt.SetRecord(PostedWhseReceiptHeader);
            PostedWhseReceipt.Run();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", 'OnAfterSetWarehouseRequestFilters', '', false, false)]
    local procedure OnBeforeGetSourceDocForHeader(var WarehouseRequest: Record "Warehouse Request"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WarehouseRequest.SETRANGE("Destination Type", WarehouseReceiptHeader."ITI Origin Type");
        WarehouseRequest.SETRANGE("Destination No.", WarehouseReceiptHeader."ITI Origin No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", 'OnOpenWarehouseReceiptPage', '', false, false)]
    local procedure OnOpenWarehouseReceiptPage(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ServVendDocNo: Code[20]; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        IsHandled := true;
        IF WarehouseEmployee.GET(USERID, WarehouseReceiptHeader."Location Code") THEN
            PAGE.RUN(PAGE::"Warehouse Receipt", WarehouseReceiptHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", OnAfterCreateWhseReceiptHeaderFromWhseRequest, '', false, false)]
    local procedure OnBeforeWhseShptHeaderInsert(var WarehouseRequest: Record "Warehouse Request"; var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        Vendor: Record Vendor;
        Location: Record Location;
        WhseReceiptHeaderCheckExist: Record "Warehouse Receipt Header";
    begin
        case WarehouseRequest."Destination Type" of
            WarehouseRequest."Destination Type"::Vendor:
                if Vendor.Get(WarehouseRequest."Destination No.") then begin
                    WhseReceiptHeader."ITI Origin No." := Vendor."No.";
                    WhseReceiptHeader."ITI Origin Description" := Vendor.Name;
                    WhseReceiptHeader."ITI Origin Description 2" := Vendor."Name 2";
                    WhseReceiptHeaderCheckExist.SetRange("No.", WhseReceiptHeader."No.");
                    if not WhseReceiptHeaderCheckExist.IsEmpty() then
                        WhseReceiptHeader.Modify();
                end;
            WarehouseRequest."Destination Type"::Location:
                if Location.Get(WarehouseRequest."Destination No.") then begin
                    WhseReceiptHeader."ITI Origin No." := Location.Code;
                    WhseReceiptHeader."ITI Origin Description" := Location.Name;
                    WhseReceiptHeader."ITI Origin Description 2" := Location."Name 2";
                    WhseReceiptHeaderCheckExist.SetRange("No.", WhseReceiptHeader."No.");
                    if not WhseReceiptHeaderCheckExist.IsEmpty() then
                        WhseReceiptHeader.Modify();
                end;
        end;

    end;

}
