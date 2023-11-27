codeunit 69076 "ITI Sales Line EH"
{
    [EventSubscriber(ObjectType::Table, database::"Sales Line", OnBeforeValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidateEventSalesLineQty(var Rec: Record "Sales Line")
    begin
        Rec.VALIDATE("ITI Qty. to Ship from Whse.", Rec.Quantity);
    end;

    [EventSubscriber(ObjectType::Table, database::"Sales Line", OnBeforeCheckItemAvailable, '', false, false)]
    local procedure OnBeforeCheckItemAvailable(CalledByFieldNo: Integer; var SalesLine: Record "Sales Line")
    begin
        IF SalesLine."Document Type" = SalesLine."Document Type"::Order THEN
            CheckWhseItemAvailable(CalledByFieldNo, SalesLine);
    end;

    local procedure CheckWhseItemAvailable(CalledByFieldNo: Integer; SalesLine: Record "Sales Line")
    var
        WhseQty: Decimal;
    begin
        IF NOT GUIALLOWED THEN
            EXIT;
        IF CalledByFieldNo IN [SalesLine.FIELDNO("No."), SalesLine.FIELDNO(Quantity)] THEN BEGIN
            WhseQty := CalcQtyToPick(SalesLine);
            IF WhseQty - SalesLine.Quantity < 0 THEN
                IF NOT CONFIRM(STRSUBSTNO(ContinueQst, FORMAT(WhseQty)), FALSE) THEN
                    ERROR('');
        END;
    end;

    procedure CalcQtyToPick(SalesLine: Record "Sales Line"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        WhseShptLine: Record "Warehouse Shipment Line";
        CreatePick: Codeunit "Create Pick";
        QtyToPick: Decimal;
        QtyAssignedToShip: Decimal;
    begin

        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
        WhseEntry.SetRange("Item No.", SalesLine."No.");
        WhseEntry.SetRange("Location Code", SalesLine."Location Code");
        WhseEntry.SetRange("Variant Code", SalesLine."Variant Code");
        WhseEntry.SetFilter("Bin Type Code", CreatePick.GetBinTypeFilter(3));
        WhseEntry.CalcSums("Qty. (Base)");
        QtyToPick := WhseEntry."Qty. (Base)";

        QtyAssignedToShip := 0;
        WhseShptLine.Reset();
        WhseShptLine.SetRange("Item No.", SalesLine."No.");
        WhseShptLine.SetRange("Location Code", SalesLine."Location Code");
        WhseShptLine.SetRange("Variant Code", SalesLine."Variant Code");
        if WhseShptLine.FindSet() then
            repeat
                QtyAssignedToShip += (WhseShptLine."Qty. Outstanding (Base)" - WhseShptLine."Qty. Picked (Base)");
            until WhseShptLine.Next() = 0;
        exit(QtyToPick - QtyAssignedToShip);

    end;

    var
        ContinueQst: Label 'Warehouse Quantity is %1.\Do you want to continue?';
}
