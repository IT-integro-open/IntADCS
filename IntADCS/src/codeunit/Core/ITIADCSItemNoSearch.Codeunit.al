codeunit 69122 ITIADCSItemNoSearch
{
    var
        MoreThanOneItemFountErr: Label 'Found more than one matching Item.';
    procedure GetItemNo(QuestionInputTxt: Text; var VariantCode: Code[10]; LocationCode: Code[10]; VendorCode: Code[20]; CustomerCode: Code[20]; var UnitOfMeasureCode: Code[10]): code[20]
    var
        ITIADCSItemSearchTemplate: Record ITIADCSItemSearchTemplate;
        OutputItemNoData: Code[20];
        QuestionInputCode: Code[20];

    begin
        if QuestionInputTxt = '' then
            exit;

        Evaluate(QuestionInputCode, QuestionInputTxt);

        ITIADCSItemSearchTemplate.FindSet();
        repeat
            if ITIADCSItemSearchTemplate."No." then begin
                OutputItemNoData := SearchItemsByItemNo(QuestionInputCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;

            if ITIADCSItemSearchTemplate."Vendor Item No." then begin
                OutputItemNoData := SearchItemsByVendorItemNo(QuestionInputCode, VariantCode, LocationCode, VendorCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;
            if ITIADCSItemSearchTemplate."Identifier No." then begin
                OutputItemNoData := SearchItemsByItemIdentifier(QuestionInputCode, VariantCode, UnitOfMeasureCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;
            if ITIADCSItemSearchTemplate."Reference No." then begin
                OutputItemNoData := SearchItemsByItemReference(QuestionInputCode, ITIADCSItemSearchTemplate."Reference Type", VendorCode, CustomerCode, VariantCode, UnitOfMeasureCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData);
            end;
            if ITIADCSItemSearchTemplate."Lot No." then begin
                OutputItemNoData := SearchItemsByItemLotNo(QuestionInputCode, VariantCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;
            if ITIADCSItemSearchTemplate."Package No." then begin
                OutputItemNoData := SearchItemsByPackageNo(QuestionInputCode, VariantCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;
            if ITIADCSItemSearchTemplate."Serial No." then begin
                OutputItemNoData := SearchItemsBySerialNo(QuestionInputCode, VariantCode);
                if OutputItemNoData <> '' then
                    exit(OutputItemNoData)
            end;
        until ITIADCSItemSearchTemplate.Next() = 0;
    end;

    local procedure SearchItemsByItemNo(QuestionInputItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        if Item.Get(QuestionInputItemNo) then
            exit(Item."No.");
    end;

    local procedure SearchItemsByVendorItemNo(QuestionInputItemNo: Code[20]; var VariantCode: Code[10]; LocationCode: code[10]; VendorCode: Code[20]): Code[20]
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemVendor: Record "Item Vendor";
        IsHandled: Boolean;
        NoFound: Integer;

    begin
        StockkeepingUnit.SetRange("Vendor Item No.", QuestionInputItemNo);
        if LocationCode <> '' then
            StockkeepingUnit.SetRange("Location Code", LocationCode);
        if VariantCode <> '' then
            StockkeepingUnit.SetRange("Variant Code", VariantCode);
        if VendorCode <> '' then
            StockkeepingUnit.SetRange("Vendor No.", VendorCode);
        NoFound := StockkeepingUnit.Count;
        if NoFound = 1 then begin
            StockkeepingUnit.FindFirst();
            exit(StockkeepingUnit."Item No.");
        end;
        if NoFound > 1 then begin
            OnBeforeShowMoreThatOneOutputFoundErrinSKUByVendorItemNoEvent(StockkeepingUnit, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(StockkeepingUnit."Item No.");
        end;

        if (StockkeepingUnit."Variant Code" <> '') and (VariantCode = '') then
            VariantCode := StockkeepingUnit."Variant Code";

        ItemVendor.SetRange("Vendor Item No.", QuestionInputItemNo);
        if VariantCode <> '' then
            ItemVendor.SetRange("Variant Code", VariantCode);
        if VendorCode <> '' then
            ItemVendor.SetRange("Vendor No.", VendorCode);
        NoFound := ItemVendor.Count;
        if NoFound = 1 then begin
            ItemVendor.FindFirst();
            exit(ItemVendor."Item No.");
        end;
        if NoFound > 1 then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInItemVendorByVendorItemNoEvent(ItemVendor, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ItemVendor."Item No.");
        end;

        Item.SetRange("Vendor Item No.", QuestionInputItemNo);
        if VendorCode <> '' then
            Item.SetRange("Vendor No.", VendorCode);
        if NoFound = 1 then begin
            ItemVendor.FindFirst();
            exit(ItemVendor."Item No.");
        end;

        if NoFound = 1 then begin
            Item.FindFirst();
            exit(Item."No.");
        end;
        if NoFound > 1 then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrByVendorItemNoEvent(Item, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(Item."No.");
        end;
    end;

    local procedure SearchItemsByItemIdentifier(QuestionInputItemNo: Code[20]; var VariantCode: Code[10]; var UnitOfMeasureCode: Code[10]): Code[20]
    var
        ItemIdentifier: Record "Item Identifier";
    begin
        if ItemIdentifier.Get(QuestionInputItemNo) then
            if (ItemIdentifier."Variant Code" <> '') and (VariantCode <> '') then
                VariantCode := ItemIdentifier."Variant Code";
        if (ItemIdentifier."Unit of Measure Code" <> '') and (UnitOfMeasureCode <> '') then
            UnitOfMeasureCode := ItemIdentifier."Unit of Measure Code";
        exit(ItemIdentifier."Item No.");
    end;

    local procedure SearchItemsByItemReference(QuestionInputItemNo: Code[20]; ReferenceType: Enum "Item Reference Type"; VendorNo: Code[20]; CustomerNo: Code[20]; var VariantCode: Code[10]; UnitOfMeasureCode: Code[20]): Code[20]
    var
        ItemReference: Record "Item Reference";
        IsHandled: Boolean;
        NoFound: Integer;

    begin
        ItemReference.SetRange("Reference No.", QuestionInputItemNo);
        ItemReference.SetRange("Reference Type", ReferenceType);

        if VendorNo <> '' then
            ItemReference.SetRange("Reference Type No.", VendorNo);

        if CustomerNo <> '' then
            ItemReference.SetRange("Reference Type No.", CustomerNo);

        if VariantCode <> '' then
            ItemReference.SetRange("Variant Code", VariantCode);

        if UnitOfMeasureCode <> '' then
            ItemReference.SetRange("Unit of Measure" , UnitOfMeasureCode);

        NoFound := ItemReference.Count();

        if NoFound = 1 then begin
            ItemReference.FindFirst();
            if (ItemReference."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ItemReference."Variant Code";
            if (ItemReference."Unit of Measure" <> '') and (UnitOfMeasureCode = '') then
                UnitOfMeasureCode := ItemReference."Unit of Measure";
            exit(ItemReference."Item No.")
        end;
        if NoFound > 1 then begin
            OnBeforeShowMoreThatOneOutputFoundErrByReferenceNoEvent(ItemReference, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ItemReference."Item No.");
        end;

    end;

    local procedure SearchItemsByItemLotNo(QuestionInputItemNo: Code[20]; VariantCode: Code[10]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNoInformation: Record "Lot No. Information";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
        NoFound: Integer;

    begin
        LotNoInformation.SetRange("Lot No.", QuestionInputItemNo);
        NoFound := LotNoInformation.Count();

        if VariantCode <> '' then
            LotNoInformation.SetRange("Variant Code", VariantCode);

        if NoFound = 1 then begin
            LotNoInformation.FindFirst();
            if (LotNoInformation."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := LotNoInformation."Variant Code";
            exit(LotNoInformation."Item No.");
        end;
        if NoFound > 1 then begin
            OnBeforeShowMoreThatOneOutputFoundErrByLotNoEvent(LotNoInformation, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(LotNoInformation."Item No.");
        end;

        ReservationEntry.SetRange("Lot No.", QuestionInputItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        if VariantCode <> '' then
            ReservationEntry.SetRange("Variant Code", VariantCode);

        NoFound := ReservationEntry.Count();
        // Check if all items with found lot no. are same
        ReservationEntry.SetRange("Item No.", ReservationEntry."Item No.");
        if (NoFound > 0) and (NoFound = ReservationEntry.Count()) then begin
            ReservationEntry.FindFirst();
            if (ReservationEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ReservationEntry."Variant Code";
            exit(ReservationEntry."Item No.")
        end;

        if NoFound <> ReservationEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInReservationByLotNoEvent(ReservationEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ReservationEntry."Item No.");
        end;

        ItemLedgerEntry.SetRange("Lot No.", QuestionInputItemNo);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        if VariantCode <> '' then
            ItemLedgerEntry.SetRange("Variant Code", VariantCode);

        NoFound := ItemLedgerEntry.Count();
        // Check if all items with found lot no. are same
        ItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if (NoFound > 0) and (NoFound = ItemLedgerEntry.Count()) then begin
            ItemLedgerEntry.FindFirst();
            if (ItemLedgerEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ItemLedgerEntry."Variant Code";
            exit(ItemLedgerEntry."Item No.")
        end;

        if NoFound <> ItemLedgerEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryByLotNoEvent(ItemLedgerEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ItemLedgerEntry."Item No.");
        end;
    end;

    local procedure SearchItemsBySerialNo(QuestionInputItemNo: Code[20]; VariantCode: Code[10]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNoInformation: Record "Serial No. Information";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
        NoFound: Integer;
    begin
        SerialNoInformation.SetRange("Serial No.", QuestionInputItemNo);
        NoFound := SerialNoInformation.Count();

        if VariantCode <> '' then
            SerialNoInformation.SetRange("Variant Code", VariantCode);

        if NoFound = 1 then begin
            SerialNoInformation.FindFirst();
            if (SerialNoInformation."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := SerialNoInformation."Variant Code";
            exit(SerialNoInformation."Item No.");
        end;
        if NoFound > 1 then begin
            OnBeforeShowMoreThatOneOutputFoundErrBySerialNoEvent(SerialNoInformation, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(SerialNoInformation."Item No.");
        end;

        ReservationEntry.SetRange("Serial No.", QuestionInputItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        if VariantCode <> '' then
            ReservationEntry.SetRange("Variant Code", VariantCode);

        NoFound := ReservationEntry.Count();
        ReservationEntry.SetRange("Item No.", ReservationEntry."Item No.");
        if (NoFound > 0) and (NoFound = ReservationEntry.Count()) then begin
            ReservationEntry.FindFirst();
            if (ReservationEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ReservationEntry."Variant Code";
            exit(ReservationEntry."Item No.")
        end;

        if NoFound <> ReservationEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInReservationBySerialNoEvent(ReservationEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ReservationEntry."Item No.");
        end;

        ItemLedgerEntry.SetRange("Serial No.", QuestionInputItemNo);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        if VariantCode <> '' then
            ItemLedgerEntry.SetRange("Variant Code", VariantCode);

        NoFound := ItemLedgerEntry.Count();
        ItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if (NoFound > 0) and (NoFound = ItemLedgerEntry.Count()) then begin
            ItemLedgerEntry.FindFirst();
            if (ItemLedgerEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ItemLedgerEntry."Variant Code";
            exit(ItemLedgerEntry."Item No.")
        end;

        if NoFound <> ItemLedgerEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryBySerialNoEvent(ItemLedgerEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ItemLedgerEntry."Item No.");
        end;
    end;

    local procedure SearchItemsByPackageNo(QuestionInputItemNo: Code[20]; VariantCode: Code[10]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInformation: Record "Package No. Information";
        IsHandled: Boolean;
        NoFound: Integer;
    begin
        PackageNoInformation.SetRange("Package No.", QuestionInputItemNo);
        NoFound := PackageNoInformation.Count();

        if VariantCode <> '' then
            PackageNoInformation.SetRange("Variant Code", VariantCode);

        if NoFound = 1 then begin
            PackageNoInformation.FindFirst();
            if (PackageNoInformation."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := PackageNoInformation."Variant Code";
            exit(PackageNoInformation."Item No.");
        end;
        if NoFound > 1 then begin
            OnBeforeShowMoreThatOneOutputFoundErrByPackageNoEvent(PackageNoInformation, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(PackageNoInformation."Item No.");
        end;

        ReservationEntry.SetRange("Package No.", QuestionInputItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        if VariantCode <> '' then
            ReservationEntry.SetRange("Variant Code", VariantCode);

        NoFound := ReservationEntry.Count();
        ReservationEntry.SetRange("Item No.", ReservationEntry."Item No.");
        if (NoFound > 0) and (NoFound = ReservationEntry.Count()) then begin
            ReservationEntry.FindFirst();
            if (ReservationEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ReservationEntry."Variant Code";
            exit(ReservationEntry."Item No.")
        end;

        if NoFound <> ReservationEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInReservationByPackageNoEvent(ReservationEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ReservationEntry."Item No.");
        end;

        ItemLedgerEntry.SetRange("Package No.", QuestionInputItemNo);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        if VariantCode <> '' then
            ItemLedgerEntry.SetRange("Variant Code", VariantCode);

        NoFound := ItemLedgerEntry.Count();
        ItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if (NoFound > 0) and (NoFound = ItemLedgerEntry.Count()) then begin
            ItemLedgerEntry.FindFirst();
            if (ItemLedgerEntry."Variant Code" <> '') and (VariantCode = '') then
                VariantCode := ItemLedgerEntry."Variant Code";
            exit(ItemLedgerEntry."Item No.")
        end;

        if NoFound <> ItemLedgerEntry.Count() then begin
            IsHandled := false;
            OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryByPackageNoEvent(ItemLedgerEntry, IsHandled);
            if not IsHandled then
                Error(MoreThanOneItemFountErr);
            if IsHandled then
                exit(ItemLedgerEntry."Item No.");
        end;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByReferenceNoEvent(var ItemReference: Record "Item Reference"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByVendorItemNoEvent(var Item: Record "Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInItemVendorByVendorItemNoEvent(var ItemVendor: Record "Item Vendor"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrinSKUByVendorItemNoEvent(var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByLotNoEvent(var LotNoInformation: Record "Lot No. Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInReservationByLotNoEvent(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInReservationByPackageNoEvent(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInReservationBySerialNoEvent(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrBySerialNoEvent(var SerialNoInformation: Record "Serial No. Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByPackageNoEvent(var PackageNoInformation: Record "Package No. Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryByLotNoEvent(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryByPackageNoEvent(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrInItemLedgerEntryBySerialNoEvent(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;


}
// codeunit 69122 ITIADCSItemNoSearch
// {
    
//     procedure GetItemNo(QuestionInputTxt: Text): code[20]
//     var 
//         ITIADCSItemSearchTemplate: Record ITIADCSItemSearchTemplate; 
//         OutputItemNoData: Code[20];
//         QuestionInputCode: Code[20];

//     begin
//         if QuestionInputTxt = '' then 
//             exit;

//         Evaluate(QuestionInputCode, QuestionInputTxt);
        
//         ITIADCSItemSearchTemplate.FindSet();
//         repeat
//             if ITIADCSItemSearchTemplate."No." then begin
//                 OutputItemNoData := SearchInItemsByItemNo(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;
                
//             if ITIADCSItemSearchTemplate."Vendor Item No." then begin
//                 OutputItemNoData := SearchInItemsByVendorItemNo(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;               
//             if ITIADCSItemSearchTemplate."Identifier No." then begin
//                 OutputItemNoData := SearchInItemsByItemIdentifier(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;
//             if ITIADCSItemSearchTemplate."Reference No." then begin
//                 OutputItemNoData := SearchInItemsByItemReference(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;                
//             if ITIADCSItemSearchTemplate."Lot No." then begin
//                 OutputItemNoData := SearchInItemsByItemLotNo(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;                
//             if ITIADCSItemSearchTemplate."Package No." then begin
//                 OutputItemNoData := SearchInItemsByPackageNo(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;  
//             if ITIADCSItemSearchTemplate."Serial No." then begin
//                 OutputItemNoData := SearchInItemsBySerialNo(QuestionInputCode);
//                 if OutputItemNoData <> '' then
//                     exit(OutputItemNoData)
//             end;              
            
//         until ITIADCSItemSearchTemplate.Next() = 0;

//     end;
    
//     local procedure SearchInItemsByItemNo(QuestionInputItemNo: Code[20]): Code[20]
//     var
//         Item: Record Item;
//     begin
//         if Item.Get(QuestionInputItemNo) then
//             exit(Item."No.");
//     end;

//     local procedure SearchInItemsByVendorItemNo(QuestionInputItemNo: Code[20]): Code[20]
//     var
//         Item: Record Item;
//     begin
//         Item.SetFilter("Vendor Item No." , QuestionInputItemNo);
//         if Item.FindFirst() then
//             exit(Item."No.");
//     end;

//     local procedure SearchInItemsByItemIdentifier(QuestionInputItemNo: Code[20]):Code[20]
//     var
//         ItemIdentifier: Record "Item Identifier";
//     begin
//         ItemIdentifier.SetFilter(Code, QuestionInputItemNo);
//         if ItemIdentifier.FindFirst() then
//             exit(ItemIdentifier."Item No.");
//     end;

//     local procedure SearchInItemsByItemReference(QuestionInputItemNo: Code[20]):Code[20]
//     var
//         ItemReference: Record "Item Reference";
//     begin
//         ItemReference.SetFilter("Reference No.", QuestionInputItemNo);
//         if ItemReference.FindFirst() then
//             exit(ItemReference."Item No.");
//     end;
    
//     local procedure SearchInItemsByItemLotNo(QuestionInputItemNo: Code[20]): Code[20]
//     var
//         ItemLedgerEntry: Record "Item Ledger Entry";
//         LotNoInformation: Record "Lot No. Information";
//         ReservationEntry: Record "Reservation Entry";
//         // OutputQuestionCode: Code[50];
//     begin  
//         LotNoInformation.SetFilter("Lot No." , QuestionInputItemNo);
//         if LotNoInformation.FindFirst() then
//             exit(LotNoInformation."Item No.");
        
//         ReservationEntry.SetRange("Package No.", QuestionInputItemNo);
//         if ReservationEntry.FindFirst() then
//             if ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Surplus then
//                 exit(ReservationEntry."Item No.");

//         ItemLedgerEntry.SetRange("Lot No.", QuestionInputItemNo); 
//         ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
//         if ItemLedgerEntry.FindFirst() then 
//             exit(ItemLedgerEntry."Item No.");
//     end;

//     local procedure SearchInItemsBySerialNo(QuestionInputItemNo: Code[20]):Code[20]
//     var
//         ItemLedgerEntry: Record "Item Ledger Entry";
//         SerialNoInformation: Record "Serial No. Information";
//         ReservationEntry: Record "Reservation Entry";
//     begin
//         SerialNoInformation.SetFilter("Serial No." , QuestionInputItemNo);
        
//         if SerialNoInformation.FindFirst() then
//             exit(SerialNoInformation."Item No.");
        
//         ReservationEntry.SetRange("Package No.", QuestionInputItemNo);
//         if ReservationEntry.FindFirst() then
//             if ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Surplus then
//                 exit(ReservationEntry."Item No.");


//         ItemLedgerEntry.SetRange("Serial No.", QuestionInputItemNo);
//         ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
//         if ItemLedgerEntry.FindFirst() then 
//             exit(ItemLedgerEntry."Item No.");
        
//     end;

//     local procedure SearchInItemsByPackageNo(QuestionInputItemNo: Code[20]): Code[20]
//     var
//         ItemLedgerEntry: Record "Item Ledger Entry";
//         ReservationEntry: Record "Reservation Entry";
//         PackageNoInformation: Record "Package No. Information";
//     begin
//         PackageNoInformation.SetRange("Package No.", QuestionInputItemNo);
//         if PackageNoInformation.FindFirst() then
//             exit(PackageNoInformation."Item No.");
        
//         ReservationEntry.SetRange("Package No.", QuestionInputItemNo);
//         if ReservationEntry.FindFirst() then
//             if ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Surplus then
//                 exit(ReservationEntry."Item No.");
        
//         ItemLedgerEntry.SetRange("Package No.", QuestionInputItemNo);
//         ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
//         if ItemLedgerEntry.FindFirst() then 
//             exit(ItemLedgerEntry."Item No.");

//     end;
    
// }