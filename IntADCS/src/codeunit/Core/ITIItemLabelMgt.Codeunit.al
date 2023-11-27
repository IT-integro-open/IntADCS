codeunit 69071 "ITI Item Label Mgt."
{
    procedure HandleWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ItemNo: Code[20];
    var OrderNo: Text[50]; var VendorName: Text[100]; var DeliveryDate: Date): Boolean
    var
        WarehouseReceiptLine: record "Warehouse Receipt Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        if WarehouseReceiptLine.FindFirst() then begin
            OrderNo := WarehouseReceiptLine."Source No.";
            if PurchaseHeader.get(PurchaseHeader."Document Type"::Order, WarehouseReceiptLine."Source No.") then begin
                VendorName := COPYSTR(PurchaseHeader."Buy-from Vendor Name", 1, 50);
                DeliveryDate := WarehouseReceiptHeader."Posting Date";
                exit(true);
            end;
            exit(false);
        end;
    end;

    procedure HandlePostedWarehouseReceipt(PostedWarehouseReceiptHeader: Record "Posted Whse. Receipt Header"; ItemNo: Code[20];
    var OrderNo: Text[50]; var VendorName: Text[100]; var DeliveryDate: Date): Boolean
    var
        PostedWarehouseReceiptLine: record "Posted Whse. Receipt Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PostedWarehouseReceiptLine.SetRange("No.", PostedWarehouseReceiptHeader."No.");
        PostedWarehouseReceiptLine.SetRange("Item No.", ItemNo);
        if PostedWarehouseReceiptLine.FindFirst() then begin
            OrderNo := PostedWarehouseReceiptLine."Source No.";
            if PurchaseHeader.get(PurchaseHeader."Document Type"::Order, PostedWarehouseReceiptLine."Source No.") then begin
                VendorName := COPYSTR(PurchaseHeader."Buy-from Vendor Name", 1, 50);
                DeliveryDate := PostedWarehouseReceiptHeader."Posting Date";
                exit(true);
            end;
            exit(false);
        end;
    end;
}