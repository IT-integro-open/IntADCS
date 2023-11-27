codeunit 69103 "ITI Miniform Item Tracking"
{
    TableNo = "ITI Miniform Header";

    trigger OnRun()
    var
        MiniformMgmt: Codeunit "ITI Miniform Management";
    begin
        MiniformMgmt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        if Rec.Code <> CurrentCode then
            PrepareData()
        else
            ProcessInput();

        Clear(DOMxmlin);
    end;

    var
        ADCSSetup: Record "ITI ADCS Setup";
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ITIADCSItemManagement: Codeunit "ITI ADCS Item Management";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        QtyExceedsMaxQtyErr: Label 'Quantity of %1 exceeds max Quantity of %2', Comment = '%1 - Current Qty, %2 - Max Qty';
        FuncNotFoundErr: Label 'Function not Found.';
        InvalidErr: Label 'Invalid %1._BELL__BELL_', Comment = '%1 - Field Caption';
        NoInputErr: Label 'No input Node found.';
        NoRecordErr: Label 'Record not found._BELL__BELL_';
        EoDLbl: Label 'End of Document.';
        QtyErr: Label 'Invalid Quantity._BELL__BELL_';
        LinesErr: Label 'No Lines available._BELL__BELL_';
        QtyScannedMsg: Label 'All Qty was scanned._BELL__BELL_';
        SerialScannedMsg: Label 'Serial No. was scanned._BELL__BELL_';
        SerialWarehouseMsg: Label 'Serial No. is in warehouse._BELL__BELL_';
        ADCSUserId: Text[250];
        CurrentCode: Text[250];
        LocationFilter: Text[250];
        Remark: Text[250];
        StackCode: Text[250];
        WhseEmpId: Text[250];
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure ProcessInput()
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        FuncGroup: Record "ITI Miniform Function Group";
        WhseRcptLine: Record "Warehouse Receipt Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ITIVerifyItemTracking: Codeunit "ITI Verify Item Tracking";
        RecordId: RecordId;
        FldNo: Integer;
        TableNo: Integer;
        TextValue: Text[250];
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(NoInputErr);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(WhseRcptLine);
            WhseRcptLine.SetRange("No.", WhseRcptLine."No.");
            RecRef.GetTable(WhseRcptLine);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;
        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := EoDLbl;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := EoDLbl;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Reset:
                Reset(WhseRcptLine);
            FuncGroup.KeyDef::Register:
                Post(WhseRcptLine);
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    case FldNo of
                        WhseRcptLine.FieldNo("Item No."):
                            if CheckItemNo(WhseRcptLine, UpperCase(TextValue)) then
                                exit;
                        WhseRcptLine.FieldNo("ITI Lot No."):
                            CheckLotNo(WhseRcptLine, UpperCase(TextValue));
                        WhseRcptLine.FieldNo("ITI Serial No."):
                            CheckSerialNo(WhseRcptLine, UpperCase(TextValue));
                        WhseRcptLine.FieldNo("ITI Package No."):
                            CheckPackageNo(WhseRcptLine, UpperCase(TextValue));
                        WhseRcptLine.FieldNo("ITI Expiry Date"):
                            CheckExpiryDate(WhseRcptLine, UpperCase(TextValue));
                        WhseRcptLine.FieldNo("ITI Qty. to Assign"):
                            CheckQty(WhseRcptLine, TextValue);
                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(WhseRcptLine);
                        end;
                    end;

                    WhseRcptLine.Modify();
                    RecRef.GetTable(WhseRcptLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), FldNo);

                    if Remark = '' then begin
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseRcptLine.FieldNo("ITI Lot No.")) = ActiveInputField + 1 then begin
                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseRcptLine."Item No.", ItemTrackingSetup);
                            if not (ItemTrackingSetup."Lot No. Required") then begin
                                FldNo := WhseRcptLine.FieldNo("ITI Lot No.");
                                ActiveInputField += 1;
                            end;
                        end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseRcptLine.FieldNo("ITI Serial No.")) = ActiveInputField + 1 then begin
                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseRcptLine."Item No.", ItemTrackingSetup);
                            if not (ItemTrackingSetup."Serial No. Required") then begin
                                FldNo := WhseRcptLine.FieldNo("ITI Serial No.");
                                ActiveInputField += 1;
                            end;
                        end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseRcptLine.FieldNo("ITI Package No.")) = ActiveInputField + 1 then begin
                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseRcptLine."Item No.", ItemTrackingSetup);
                            if not (ItemTrackingSetup."Package No. Required") then begin
                                FldNo := WhseRcptLine.FieldNo("ITI Package No.");
                                ActiveInputField += 1;
                            end;
                        end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseRcptLine.FieldNo("ITI Expiry Date")) = ActiveInputField + 1 then
                            if not (ITIVerifyItemTracking.VerifyExpirationDateRequired(WhseRcptLine."Item No.")) then begin
                                FldNo := WhseRcptLine.FieldNo("ITI Expiry Date");
                                ActiveInputField += 1;
                            end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseRcptLine.FieldNo("ITI Qty. to Assign")) = ActiveInputField + 1 then
                            if (WhseRcptLine."ITI Qty. to Assign" <> 0) then begin
                                FldNo := WhseRcptLine.FieldNo("ITI Qty. to Assign");
                                ActiveInputField += 1;
                            end;
                    end;

                    if Remark = '' then
                        if ADCSCommunication.LastEntryField(CopyStr(CurrentCode, 1, 20), FldNo) then begin
                            RegisterLine(WhseRcptLine, TextValue);
                            RecRef.GetTable(WhseRcptLine);
                            ADCSCommunication.SetRecRef(RecRef);
                            if WhseRcptLine."Qty. to Receive" < WhseRcptLine."Qty. Outstanding" then
                                ActiveInputField := 1
                            else
                                if (not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List")) or
                                   (not FindLinesToScan(WhseRcptLine))
                                then begin
                                    ADCSSetup.Get();
                                    if ADCSSetup."Post Receipt Line" then begin
                                        Post(WhseRcptLine);
                                        FuncGroup.KeyDef := FuncGroup.KeyDef::Esc;
                                    end else
                                        if not ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List") then begin
                                            Remark := EoDLbl;
                                            ActiveInputField := 1;
                                        end else
                                            ActiveInputField := 1;
                                end else
                                    ActiveInputField := 1;
                        end else
                            ActiveInputField += 1;
                end;
            else
                Error(FuncNotFoundErr);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);
    end;

    local procedure CheckItemNo(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250]): Boolean
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
        ItemNo: Code[20];
    begin
        ITIADCSItemManagement.GetItemNo(WhseRcptLine."Item No.", InputValue, ItemNo);

        if ItemNo <> WhseRcptLine."Item No." then begin
            WhseRcptLine2.SetRange("No.", WhseRcptLine."No.");
            WhseRcptLine2.SetRange("Item No.", ItemNo);
            WhseRcptLine2.SetRange("ITI Scanned", false);
            if WhseRcptLine2.FindFirst() then
                WhseRcptLine.Get(WhseRcptLine2."No.", WhseRcptLine2."Line No.")
            else begin
                WhseRcptLine2.SetRange("ITI Scanned", true);
                if not WhseRcptLine2.IsEmpty() then
                    Remark := QtyScannedMsg
                else
                    Remark := StrSubstNo(InvalidErr, WhseRcptLine.FieldCaption("Item No."));
            end;
        end;

        if WhseRcptLine."ITI Qty. to Scan" = 0 then
            Remark := QtyScannedMsg;
    end;

    local procedure CheckQty(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250])
    var
        UoMMgt: Codeunit "Unit of Measure Management";
        QtyToHandle: Decimal;
        QtyToReceiveBeforeValidate: Decimal;
    begin
        if InputValue = '' then begin
            Remark := QtyErr;
            exit;
        end;

        Evaluate(QtyToHandle, InputValue);
        if QtyToHandle = Abs(QtyToHandle) then begin
            QtyToReceiveBeforeValidate := WhseRcptLine."Qty. to Receive" + QtyToHandle;
            WhseRcptLine.Validate("Qty. to Receive", QtyToHandle + WhseRcptLine."Qty. to Receive");
            WhseRcptLine."Qty. to Receive" := QtyToReceiveBeforeValidate;
            if WhseRcptLine."Qty. to Receive (Base)" = 0 then
                WhseRcptLine."Qty. to Receive (Base)" := UoMMgt.CalcBaseQty(WhseRcptLine."Item No.", WhseRcptLine."Variant Code", WhseRcptLine."Unit of Measure Code", WhseRcptLine."Qty. to Receive",
                WhseRcptLine."Qty. per Unit of Measure", WhseRcptLine."Qty. Rounding Precision (Base)", WhseRcptLine.FieldCaption("Qty. Rounding Precision"), WhseRcptLine.FieldCaption("Qty. to Receive"),
                 WhseRcptLine.FieldCaption("Qty. to Receive (Base)"));
            WhseRcptLine."ITI Qty. to Assign" := QtyToHandle;
        end else
            Remark := QtyErr;
    end;

    local procedure CheckLotNo(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250])
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseRcptLine.FieldCaption("ITI Lot No."));
            exit;
        end;
        WhseRcptLine."ITI Lot No." := CopyStr(InputValue, 1, MaxStrLen(WhseRcptLine."ITI Lot No."));
    end;

    local procedure CheckPackageNo(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: TExt[250])
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseRcptLine.FieldCaption("ITI Package No."));
            exit;
        end;
        WhseRcptLine."ITI Package No." := CopyStr(InputValue, 1, MaxStrLen(WhseRcptLine."ITI Package No."));
    end;

    local procedure CheckExpiryDate(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250])
    var
        ResultDate: Date;
    begin
        ResultDate := ConvertDate(InputValue);
        if ResultDate = 0D then begin
            Remark := StrSubstNo(InvalidErr, WhseRcptLine.FieldCaption("ITI Expiry Date"));
            exit;
        end;
        WhseRcptLine."ITI Expiry Date" := ResultDate;

    end;

    local procedure ConvertDate(InputValue: Text): Date
    var
        Days: Integer;
        Months: Integer;
        Year: Integer;
    begin
        if InputValue = '' then
            exit(0D);
        Evaluate(Days, CopyStr(InputValue, 1, 2));
        Evaluate(Months, CopyStr(InputValue, 4, 2));
        Evaluate(Year, CopyStr(InputValue, 7, 4));
        exit(DMY2Date(Days, Months, Year));
    end;


    local procedure CheckSerialNo(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservEntry: Record "Reservation Entry";
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseRcptLine.FieldCaption("ITI Serial No."));
            exit;
        end;

        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date");
        ReservEntry.SetRange("Item No.", WhseRcptLine."Item No.");
        ReservEntry.SetRange("Location Code", WhseRcptLine."Location Code");
        ReservEntry.SetRange("Variant Code", WhseRcptLine."Variant Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
        ReservEntry.SetRange("Serial No.", InputValue);
        if not ReservEntry.IsEmpty() then begin
            Remark := SerialScannedMsg;
            exit;
        end;

        ItemLedgerEntry.SetRange("Item No.", WhseRcptLine."Item No.");
        ItemLedgerEntry.SetRange("Location Code", WhseRcptLine."Location Code");
        ItemLedgerEntry.SetRange("Variant Code", WhseRcptLine."Variant Code");
        ItemLedgerEntry.SetRange("Serial No.", InputValue);
        ItemLedgerEntry.CalcSums("Remaining Quantity");
        if ItemLedgerEntry."Remaining Quantity" <> 0 then begin
            Remark := SerialWarehouseMsg;
            exit;
        end;

        WhseRcptLine."ITI Serial No." := CopyStr(InputValue, 1, MaxStrLen(WhseRcptLine."ITI Serial No."));
        CheckQty(WhseRcptLine, '1');
    end;

    local procedure Reset(var WhseRcptLine2: Record "Warehouse Receipt Line")
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        if not WhseRcptLine.Get(WhseRcptLine2."No.", WhseRcptLine2."Line No.") then
            Error(NoRecordErr);

        Remark := '';
        WhseRcptLine.Validate("Qty. to Receive", 0);
        WhseRcptLine."ITI Scanned" := false;
        WhseRcptLine."ITI Qty. to Assign" := 0;
        WhseRcptLine."ITI Lot No." := '';
        WhseRcptLine."ITI Serial No." := '';
        WhseRcptLine."ITI Qty. to Scan" := WhseRcptLine."Qty. Outstanding";
        WhseRcptLine.Modify();

        ResetReservEntry(WhseRcptLine);

        RecRef.GetTable(WhseRcptLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
    end;

    local procedure RegisterLine(var WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250])
    var
        ITIItemTrackingType: Enum "ITI Item Tracking Type";
    begin
        if (WhseRcptLine."ITI Serial No." <> '') then
            UpdateReservEntry(WhseRcptLine, InputValue, ITIItemTrackingType::"Serial No.");
        if (WhseRcptLine."ITI Lot No." <> '') then
            UpdateReservEntry(WhseRcptLine, InputValue, ITIItemTrackingType::"Lot No.");
        if WhseRcptLine."ITI Package No." <> '' then
            UpdateReservEntry(WhseRcptLine, InputValue, ITIItemTrackingType::"Package No.");

        if WhseRcptLine."Qty. to Receive" = WhseRcptLine."Qty. Outstanding" then
            WhseRcptLine."ITI Scanned" := true;
        WhseRcptLine."ITI Qty. to Scan" := WhseRcptLine."Qty. Outstanding" - WhseRcptLine."Qty. to Receive";
        WhseRcptLine."ITI Lot No." := '';
        WhseRcptLine."ITI Serial No." := '';
        WhseRcptLine."ITI Qty. to Assign" := 0;
        WhseRcptLine.Modify();
    end;

    procedure UpdateReservEntry(WhseRcptLine: Record "Warehouse Receipt Line"; InputValue: Text[250]; ITIItemTrackingType: Enum "ITI Item Tracking Type")
    var
        ITIHandleReceipt: Codeunit "ITI Handle Receipt";
        ITIVerifyItemTracking: Codeunit "ITI Verify Item Tracking";
        MaxQty: Decimal;
        QtyToAssign: Decimal;
        TotalQty: Decimal;
    begin

        if not ITIVerifyItemTracking.VerifyItemTracking(WhseRcptLine, TotalQty, MaxQty, ITIItemTrackingType) then
            Error(QtyExceedsMaxQtyErr, TotalQty, MaxQty)
        else
            if not (ITIItemTrackingType = ITIItemTrackingType::"Serial No.") then begin
                Evaluate(QtyToAssign, InputValue);
                ITIHandleReceipt.CreateItemTrackingForLine(WhseRcptLine, QtyToAssign, ITIItemTrackingType);
            end else
                ITIHandleReceipt.CreateItemTrackingForLine(WhseRcptLine, 1, ITIItemTrackingType);
    end;

    procedure ResetReservEntry(WhseRcptLine: Record "Warehouse Receipt Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name",
  "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date");
        ReservEntry.SetRange("Source ID", WhseRcptLine."Source No.");
        ReservEntry.SetRange("Source Ref. No.", WhseRcptLine."Source Line No.");
        ReservEntry.SetRange("Source Type", WhseRcptLine."Source Type");
        ReservEntry.SetRange("Source Subtype", WhseRcptLine."Source Subtype");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
        //ReservEntry.SETRANGE("Lot No.",WhseRcptLine."Lot No.");
        ReservEntry.DeleteAll();
    end;

    local procedure FindLinesToScan(var WhseRcptLine: Record "Warehouse Receipt Line"): Boolean
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine2.SetRange("No.", WhseRcptLine."No.");
        WhseRcptLine2.SetRange("ITI Scanned", false);
        exit(not WhseRcptLine2.IsEmpty());
    end;

    local procedure Post(WhseRcptLine2: Record "Warehouse Receipt Line")
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        if not WhseRcptLine.Get(WhseRcptLine2."No.", WhseRcptLine2."Line No.") then
            Error(NoRecordErr);

        WhseRcptHeader.Get(WhseRcptLine."No.");

        RecRef.GetTable(WhseRcptHeader);
        ADCSCommunication.SetRecRef(RecRef);
        ADCSCommunication.SetNodeAttribute(ReturnedNode, 'TableNo', FORMAT(RecRef.NUMBER));
        ADCSCommunication.SetNodeAttribute(ReturnedNode, 'RecordID', FORMAT(RecRef.RECORDID));
        ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
        MiniformHeader2.SaveXMLinExt(DOMxmlin);
        Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;

    local procedure PrepareData()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        RecordId: RecordId;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(WhseRcptHeader);
            WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
            if not WhseRcptLine.FindFirst() then begin
                ADCSMgt.SendError(LinesErr);
                exit;
            end;
            RecRef.GetTable(WhseRcptLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end else
            Error(NoRecordErr);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;


}

