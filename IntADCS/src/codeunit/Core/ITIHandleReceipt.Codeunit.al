codeunit 69119 "ITI Handle Receipt"
{
    procedure CreateItemTrackingForLine(WarehouseReceiptLine: Record "Warehouse Receipt Line"; QtyToAssign: Decimal; ItemTrackingType: Enum "ITI Item Tracking Type")
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ITIHandleTransferOrder: Codeunit "ITI Handle Transfer Order";
    begin

        case WarehouseReceiptLine."Source Document" of
            WarehouseReceiptLine."Source Document"::"Purchase Order":
                begin
                    case ItemTrackingType of
                        ItemTrackingType::"Lot No.":
                            CreateTempReservationEntryForLotNo(TempReservationEntry, WarehouseReceiptLine, QtyToAssign);
                        ItemTrackingType::"Serial No.":
                            CreateTempReservationEntryForSerialNo(TempReservationEntry, WarehouseReceiptLine);
                        ItemTrackingType::"Package No.":
                            CreateTempReservationEntryForPackageNo(TempReservationEntry, WarehouseReceiptLine, QtyToAssign);
                    end;

                    if PurchaseLine.Get(WArehouseReceiptLine."Source Subtype", WArehouseREceiptLine."Source No.", WArehouseREceiptLine."Source Line No.") then begin
                        CreateReservEntry.SetDates(0D, TempReservationEntry."Expiration Date");
                        CreateReservEntry.CreateReservEntryFor(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
                        PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", PurchaseLine."Qty. per Unit of Measure",
                        TempReservationEntry.Quantity, TempReservationEntry.Quantity * PurchaseLine."Qty. per Unit of Measure", TempReservationEntry);
                        CreateReservEntry.CreateEntry(PurchaseLine."No.", WarehouseReceiptLine."Variant Code", WarehouseReceiptLine."Location Code",
                        '', PurchaseLine."Expected Receipt Date", 0D, 0, TempReservationEntry."Reservation Status"::Surplus);
                    end;
                end;
            WarehouseReceiptLine."Source Document"::"Inbound Transfer":
                if TransferLine.Get(WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then
                    ITIHandleTransferOrder.CreateReservationEntries(TransferLine, false, WarehouseReceiptLine."ITI Lot No."
                    , WarehouseReceiptLine."ITI Serial No.", WarehouseReceiptLine."ITI Package No.",
                    WarehouseReceiptLine."ITI Expiry Date", ItemTrackingType);
        end;

    end;

    local procedure CreateTempReservationEntryForLotNo(var TempReservationEntry: Record "Reservation Entry" temporary;
    WarehouseReceiptline: Record "Warehouse Receipt Line"; QtyToAssign: Decimal)
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Lot No." := WarehouseReceiptLine."ITI Lot No.";
        TempReservationEntry.Quantity := QtyToAssign;
        if WarehouseReceiptLine."ITI Expiry Date" <> 0D then begin
            TempReservationEntry."Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
            TempReservationEntry."New Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
        end else begin
            TempReservationEntry."Expiration Date" := Today();
            TempReservationEntry."New Expiration Date" := Today();
        end;
        TempReservationEntry.Insert();
    end;

    local procedure CreateTempReservationEntryForSerialNo(var TempReservationEntry: Record "Reservation Entry" temporary;
    WarehouseReceiptline: Record "Warehouse Receipt Line")
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Serial No." := WarehouseReceiptLine."ITI Serial No.";
        TempReservationEntry.Quantity := 1;
        if WarehouseReceiptLine."ITI Expiry Date" <> 0D then begin
            TempReservationEntry."Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
            TempReservationEntry."New Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
        end else begin
            TempReservationEntry."Expiration Date" := Today();
            TempReservationEntry."New Expiration Date" := Today();
        end;
        TempReservationEntry.Insert();
    end;

    local procedure CreateTempReservationEntryForPackageNo(var TempReservationEntry: Record "Reservation Entry" temporary;
    WarehouseReceiptline: Record "Warehouse Receipt Line"; QtyToAssign: Decimal)
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Package No." := WarehouseReceiptline."ITI Package No.";
        TempReservationEntry.Quantity := QtyToAssign;
        if WarehouseReceiptLine."ITI Expiry Date" <> 0D then begin
            TempReservationEntry."Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
            TempReservationEntry."New Expiration Date" := WarehouseReceiptLine."ITI Expiry Date";
        end else begin
            TempReservationEntry."Expiration Date" := Today();
            TempReservationEntry."New Expiration Date" := Today();
        end;
        TempReservationEntry.Insert();
    end;
}