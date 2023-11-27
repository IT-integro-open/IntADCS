codeunit 69120 "ITI Handle Transfer Order"
{
    procedure CreateReservationEntries(var TransferLine: Record "Transfer Line";
    Shipment: Boolean; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50];
    ExpiryDate: Date; ItemTrackingType: Enum "ITI Item Tracking Type")
    var
        TempReservEntry: Record "Reservation Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservStatus: Enum "Reservation Status";
        CurrentSourceRowID: Text[250];
        SecondSourceRowID: Text[250];
    begin
        if Shipment then begin
            if TransferLine."Qty. to Ship" = 0 then
                Error(QtyErr, TransferLine."Line No.", TransferLine."Item No.");
        end else
            if TransferLine."Qty. to Receive" = 0 then
                Error(QtyErr, TransferLine."Line No.", TransferLine."Item No.");

        case ItemTrackingType of
            ItemTrackingType::"Lot No.":
                CreateTempReservationEntryForLotNo(TempReservEntry, TransferLine, Shipment, LotNo, ExpiryDate);
            ItemTrackingType::"Serial No.":
                CreateTempReservationEntryForSerialNo(TempReservEntry, TransferLine, Shipment, SerialNo, ExpiryDate);
            ItemTrackingType::"Package No.":
                CreateTempReservationEntryPackageNo(TempReservEntry, TransferLine, Shipment, PackageNo, ExpiryDate);
        end;

        CreateReservEntry.SetDates(0D, TempReservEntry."Expiration Date");
        CreateReservEntry.CreateReservEntryFor(
          Database::"Transfer Line", 0,
          TransferLine."Document No.", '', TransferLine."Derived From Line No.", TransferLine."Line No.", TransferLine."Qty. per Unit of Measure",
          TempReservEntry.Quantity, TempReservEntry.Quantity * TransferLine."Qty. per Unit of Measure", TempReservEntry);
        CreateReservEntry.CreateEntry(
          TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Transfer-from Code", '', TransferLine."Receipt Date", 0D, 0, ReservStatus::Surplus);

        CurrentSourceRowID := ItemTrackingMgt.ComposeRowID(Database::"Transfer Line", 0, TransferLine."Document No.", '', 0, TransferLine."Line No.");

        SecondSourceRowID := ItemTrackingMgt.ComposeRowID(Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.");

        ItemTrackingMgt.SynchronizeItemTracking(CurrentSourceRowID, SecondSourceRowID, '');

        TransferLine.Modify();
    end;

    local procedure CreateTempReservationEntryForLotNo(var TempReservationEntry: Record "Reservation Entry" temporary;
    var TransferLine: Record "Transfer Line"; Shipment: Boolean; LotNo: Code[50]; ExpiryDate: Date)
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Lot No." := LotNo;
        if Shipment then
            TempReservationEntry.Quantity := TransferLine."Qty. to Ship"
        else
            TempReservationEntry.Quantity := TransferLine."Qty. to Receive";
        if ExpiryDate <> 0D then
            TempReservationEntry."Expiration Date" := ExpiryDate
        else
            TempReservationEntry."Expiration Date" := FindLedgerEntryLotNo(LotNo,
             TransferLine."Item No.");
        TempReservationEntry."Source ID" := TransferLine."Document No.";
        TempReservationEntry."Source Ref. No." := TransferLine."Line No.";
        TempReservationEntry.Insert();
    end;

    local procedure CreateTempReservationEntryPackageNo(var TempReservationEntry: Record "Reservation Entry" temporary;
 var TransferLine: Record "Transfer Line"; Shipment: Boolean; PackageNo: Code[50]; ExpiryDate: Date)
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Package No." := PackageNo;
        if Shipment then
            TempReservationEntry.Quantity := TransferLine."Qty. to Ship"
        else
            TempReservationEntry.Quantity := TransferLine."Qty. to Receive";
        if ExpiryDate <> 0D then
            TempReservationEntry."Expiration Date" := ExpiryDate
        else
            TempReservationEntry."Expiration Date" := FindLedgerEntryPackageNo(PackageNo,
             TransferLine."Item No.");
        TempReservationEntry."Source ID" := TransferLine."Document No.";
        TempReservationEntry."Source Ref. No." := TransferLine."Line No.";
        TempReservationEntry.Insert();
    end;

    local procedure CreateTempReservationEntryForSerialNo(var TempReservationEntry: Record "Reservation Entry" temporary;
     var TransferLine: Record "Transfer Line"; Shipment: Boolean; SerialNo: Code[50]; ExpiryDate: Date)
    begin
        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := 10000;
        TempReservationEntry."Lot No." := SerialNo;
        TempReservationEntry.Quantity := 1;
        TempReservationEntry."Expiration Date" := ExpiryDate;
        TempReservationEntry."Source ID" := TransferLine."Document No.";
        TempReservationEntry."Source Ref. No." := TransferLine."Line No.";
        TempReservationEntry.Insert();
    end;

    local procedure FindLedgerEntryLotNo(LotNo: Code[50]; ItemNo: Code[20]): Date
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        if ItemLedgerEntry.FindFirst() then
            exit(ItemLedgerEntry."Expiration Date");
    end;

    local procedure FindLedgerEntryPackageNo(PackageNo: Code[50]; ItemNo: Code[20]): Date
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Package No.", PackageNo);
        if ItemLedgerEntry.FindFirst() then
            exit(ItemLedgerEntry."Expiration Date");
    end;

    var
        QtyErr: Label 'Qty. to ship or Qty. to Receive must be filled for Line %1, Item %2', Comment = '%1 - Line No., %2 - Item No.';
}