codeunit 69121 "ITI Verify Item Tracking"
{
    procedure VerifyExpirationDateRequired(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if Item.Get(ItemNo) then
            if Item."Item Tracking Code" <> '' then
                if ItemTrackingCode.Get(Item."Item Tracking Code") then
                    exit(ItemTrackingCode."Man. Expir. Date Entry Reqd.");

    end;

    procedure VerifyItemTracking(var WarehouseReceiptLine: Record "Warehouse Receipt Line";
    var TotalQty: Decimal; var MaxQty: Decimal; ITIItemTrackingType: Enum "ITI Item Tracking Type"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
    begin
        ReservationEntry.SetRange("Item No.", WarehouseReceiptLine."Item No.");
        ReservationEntry.SetRange("Location Code", WarehouseReceiptLine."Location Code");
        ReservationEntry.SetRange("Variant Code", WarehouseReceiptLine."Variant Code");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        case ITIItemTrackingType of
            ITIItemTrackingType::"Lot No.":
                ReservationEntry.SetFilter("Lot No.", '<>%1', '');
            ITIItemTrackingType::"Serial No.":
                ReservationEntry.SetFilter("Serial No.", '<>%1', '');
            ITIItemTrackingType::"Package No.":
                ReservationEntry.SetFilter("Package No.", '<>%1', '');
        end;

        if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Purchase Order" then
            if PurchaseLine.Get(WarehouseReceiptLine."Source Subtype", WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then begin
                ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name",
                "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date");

                ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
                ReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type".AsInteger());
                ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
                ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
                if not ReservationEntry.IsEmpty() then begin
                    ReservationEntry.CalcSums(Quantity);
                    TotalQty := ReservationEntry.Quantity + WarehouseReceiptLine."ITI Qty. to Assign";
                    exit(VerifyQty(WarehouseReceiptLine, TotalQty, MaxQty));
                end;
            end;
        if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Inbound Transfer" then
            if TransferLine.Get(WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then begin
                ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name",
                "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date");
                ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
                ReservationEntry.SetRange("Source Subtype", 0);
                ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
                ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
                if not ReservationEntry.IsEmpty() then begin
                    ReservationEntry.CalcSums(Quantity);
                    TotalQty := ReservationEntry.Quantity + WarehouseReceiptLine."ITI Qty. to Assign";
                    exit(VerifyQty(WarehouseReceiptLine, TotalQty, MaxQty));
                end;
            end;
        exit(true);
    end;

    local procedure VerifyQty(var WarehouseReceiptLine: Record "Warehouse Receipt Line";
    Quantity: Decimal; var MaxQty: Decimal): Boolean
    begin
        MaxQty := WarehouseReceiptLine.Quantity;
        exit((Quantity <= MaxQty));
    end;
}