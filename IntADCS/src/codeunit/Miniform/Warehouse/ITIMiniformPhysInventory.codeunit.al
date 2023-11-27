codeunit 69097 "ITI Miniform Phys Inventory"
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

        IF Rec.Code <> CurrentCode THEN
            PrepareData
        ELSE
            ProcessInput;

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        WhseJournalLine: Record "Warehouse Journal Line";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        RecRef: RecordRef;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
        ADCSUserId: Text[250];
        Remark: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        Text000: Label 'Function not Found.';
        Text004: Label 'Invalid %1.';
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found.';
        Text008: Label 'End of Document.';
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;
        Text012: Label 'No Lines available.';

    local procedure ProcessInput()
    var
        FuncGroup: Record "ITI Miniform Function Group";
        ItemTrackingSetup: record "Item Tracking Setup";
        RecordId: RecordID;
        TableNo: Integer;
        FldNo: Integer;
        TextValue: Text[250];
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));    // Key1 = TableNo
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));   // Key2 = RecordID
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseJournalLine);
            WhseJournalLine.SETCURRENTKEY("Location Code", "Bin Code", "Item No.", "Variant Code");
            WhseJournalLine.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
            WhseJournalLine.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
            WhseJournalLine.SETRANGE("Location Code", WhseJournalLine."Location Code");
            RecRef.GETTABLE(WhseJournalLine);
            ADCSCommunication.SetRecRef(RecRef);
        END ELSE BEGIN
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            EXIT;
        END;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        CASE FuncGroup.KeyDef OF
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                IF NOT ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") THEN
                    Remark := Text008;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                IF NOT ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") THEN
                    Remark := Text008;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                BEGIN
                    EVALUATE(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));

                    CASE FldNo OF
                        WhseJournalLine.FIELDNO("Bin Code"):
                            CheckBinNo(UPPERCASE(TextValue));
                        WhseJournalLine.FIELDNO("Item No."):
                            CheckItemNo(UPPERCASE(TextValue));
                        WhseJournalLine.FIELDNO("Lot No."):
                            CheckLotNo(UPPERCASE(TextValue));
                        WhseJournalLine.FIELDNO("Serial No."):
                            CheckSerialNo(UPPERCASE(TextValue));
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(WhseJournalLine);
                        END;
                    END;

                    WhseJournalLine.MODIFY;
                    RecRef.GETTABLE(WhseJournalLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    IF Remark = '' THEN BEGIN
                        IF ADCSCommunication.GetActiveInputNo(CurrentCode, WhseJournalLine.FIELDNO("Lot No.")) = ActiveInputField + 1 THEN BEGIN
                             ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJournalLine."Item No.", ItemTrackingSetup);
                            IF NOT ItemTrackingSetup."Lot No. Required" THEN BEGIN
                                FldNo := WhseJournalLine.FIELDNO("Lot No.");
                                ActiveInputField += 1;
                            END;
                        END;
                        IF ADCSCommunication.GetActiveInputNo(CurrentCode, WhseJournalLine.FIELDNO("Serial No.")) = ActiveInputField + 1 THEN BEGIN

                             ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJournalLine."Item No.", ItemTrackingSetup);
                            IF NOT ItemTrackingSetup."Serial No. Required" THEN BEGIN
                                FldNo := WhseJournalLine.FIELDNO("Serial No.");
                                ActiveInputField += 1;
                            END;
                        END;
                        IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                            RecRef.GETTABLE(WhseJournalLine);
                            IF NOT ADCSCommunication.FindRecRef(1, ActiveInputField) THEN BEGIN
                                IF (NOT ADCSCommunication.FindRecRef(2, ActiveInputField)) THEN BEGIN
                                    Remark := Text008;
                                END ELSE
                                    ActiveInputField := 1;
                            END ELSE
                                ActiveInputField := 1;
                        END ELSE
                            ActiveInputField += 1;
                    END;
                END;
            ELSE
                ERROR(Text000);
        END;

        IF NOT (FuncGroup.KeyDef IN [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) THEN
            SendForm(ActiveInputField);
    end;

    local procedure CheckBinNo(InputValue: Text[250])
    var
        WhseJournalLine2: Record "Warehouse Journal Line";
        Bin: Record Bin;
    begin
        IF InputValue = WhseJournalLine."Bin Code" THEN
            EXIT;

        IF InputValue = '' THEN
            EXIT;

        IF NOT Bin.GET(WhseJournalLine."Location Code", InputValue) THEN BEGIN
            Remark := STRSUBSTNO(Text004, WhseJournalLine.FIELDCAPTION("Bin Code"));
            EXIT;
        END;

        WhseJournalLine2.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
        WhseJournalLine2.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
        WhseJournalLine2.SETRANGE("Location Code", WhseJournalLine."Location Code");
        WhseJournalLine2.SETRANGE("Bin Code", Bin.Code);
        IF WhseJournalLine2.FINDFIRST THEN
            WhseJournalLine.GET(WhseJournalLine2."Journal Template Name", WhseJournalLine2."Journal Batch Name", WhseJournalLine2."Location Code", WhseJournalLine2."Line No.")
        ELSE
            CreateNewWhseJournalLineBin(InputValue);
    end;

    local procedure CheckItemNo(InputValue: Text[250])
    var
        ItemIdent: Record "Item Identifier";
        WhseJournalLine2: Record "Warehouse Journal Line";
    begin
        IF InputValue = WhseJournalLine."Item No." THEN
            EXIT;

        IF NOT ItemIdent.GET(InputValue) THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION(Code));

        // START/ASM/ADCS/009
        /*Original Code:
        IF ItemIdent."Item No." <> WhseJournalLine."Item No." THEN
          Remark := STRSUBSTNO(Text004,ItemIdent.FIELDCAPTION(Code));
        
        IF (ItemIdent."Variant Code" <> '') AND (ItemIdent."Variant Code" <> WhseJournalLine."Variant Code") THEN
          Remark := STRSUBSTNO(Text004,ItemIdent.FIELDCAPTION(Code));
        
        IF ((ItemIdent."Unit of Measure Code" <> '') AND (ItemIdent."Unit of Measure Code" <> WhseJournalLine."Unit of Measure Code"))
        THEN
          Remark := STRSUBSTNO(Text004,ItemIdent.FIELDCAPTION(Code));
        */
        IF ItemIdent."Item No." <> WhseJournalLine."Item No." THEN BEGIN
            WhseJournalLine2.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
            WhseJournalLine2.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
            WhseJournalLine2.SETRANGE("Bin Code", WhseJournalLine."Bin Code");
            WhseJournalLine2.SETRANGE("Item No.", ItemIdent."Item No.");
            IF WhseJournalLine2.FINDFIRST THEN
                WhseJournalLine.GET(WhseJournalLine2."Journal Template Name", WhseJournalLine2."Journal Batch Name", WhseJournalLine2."Location Code", WhseJournalLine2."Line No.")
            ELSE BEGIN
                IF WhseJournalLine."Item No." = '' THEN
                    UpdateWhseJournalLine(ItemIdent."Item No.", '', '', WhseJournalLine."Bin Code")
                ELSE
                    CreateNewWhseJournalLineItem(ItemIdent."Item No.", '', '', WhseJournalLine."Bin Code")
            END;
        END;

    end;

    local procedure PrepareData()
    var
        TableNo: Integer;
        RecordId: RecordID;
        WhseJournalBatch: Record "Warehouse Journal Batch";
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseJournalBatch);
            WhseJournalLine.SETCURRENTKEY("Location Code", "Bin Code", "Item No.", "Variant Code");
            WhseJournalLine.SETRANGE("Journal Template Name", WhseJournalBatch."Journal Template Name");
            WhseJournalLine.SETRANGE("Journal Batch Name", WhseJournalBatch.Name);
            WhseJournalLine.SETRANGE("Location Code", WhseJournalBatch."Location Code");
            IF NOT WhseJournalLine.FINDFIRST THEN BEGIN
                ADCSMgt.SendError(Text012);
                EXIT;
            END;
            RecRef.GETTABLE(WhseJournalLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        END ELSE
            ERROR(Text007);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;



    local procedure Reset()
    begin
        WhseJournalLine.VALIDATE("Qty. (Phys. Inventory)", 0);
        WhseJournalLine.MODIFY;
        ActiveInputField := 1;
    end;

    local procedure CheckLotNo(InputValue: Text[250])
    var
        ItemIdent: Record "Item Identifier";
        WhseJournalLine2: Record "Warehouse Journal Line";
    begin
        IF InputValue = WhseJournalLine."Lot No." THEN
            EXIT;

        WhseJournalLine2.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
        WhseJournalLine2.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
        WhseJournalLine2.SETRANGE("Bin Code", WhseJournalLine."Bin Code");
        WhseJournalLine2.SETRANGE("Item No.", ItemIdent."Item No.");
        WhseJournalLine2.SETRANGE("Lot No.", InputValue);
        IF WhseJournalLine2.FINDFIRST THEN
            WhseJournalLine.GET(WhseJournalLine2."Journal Template Name", WhseJournalLine2."Journal Batch Name", WhseJournalLine2."Location Code", WhseJournalLine2."Line No.")
        ELSE BEGIN
            IF WhseJournalLine."Lot No." = '' THEN
                UpdateWhseJournalLine(WhseJournalLine."Item No.", InputValue, '', WhseJournalLine."Bin Code")
            ELSE
                CreateNewWhseJournalLineItem(WhseJournalLine."Item No.", InputValue, '', WhseJournalLine."Bin Code")
        END;
    end;

    local procedure CheckSerialNo(InputValue: Text[250])
    var
        ItemIdent: Record "Item Identifier";
        WhseJournalLine2: Record "Warehouse Journal Line";
    begin
        IF InputValue = WhseJournalLine."Serial No." THEN
            EXIT;

        WhseJournalLine2.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
        WhseJournalLine2.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
        WhseJournalLine2.SETRANGE("Bin Code", WhseJournalLine."Bin Code");
        WhseJournalLine2.SETRANGE("Item No.", ItemIdent."Item No.");
        WhseJournalLine2.SETRANGE("Serial No.", InputValue);
        IF WhseJournalLine2.FINDFIRST THEN
            WhseJournalLine.GET(WhseJournalLine2."Journal Template Name", WhseJournalLine2."Journal Batch Name", WhseJournalLine2."Location Code", WhseJournalLine2."Line No.")
        ELSE BEGIN
            IF WhseJournalLine."Serial No." = '' THEN
                UpdateWhseJournalLine(WhseJournalLine."Item No.", '', InputValue, WhseJournalLine."Bin Code")
            ELSE
                CreateNewWhseJournalLineItem(WhseJournalLine."Item No.", '', InputValue, WhseJournalLine."Bin Code")
        END;
    end;

    procedure CreateNewWhseJournalLineBin(BinCode: Code[20])
    var
        WhseJournalLine2: Record "Warehouse Journal Line";
        NewLineNo: Integer;
    begin
        WhseJournalLine2.SETRANGE("Journal Template Name", WhseJournalLine."Journal Template Name");
        WhseJournalLine2.SETRANGE("Journal Batch Name", WhseJournalLine."Journal Batch Name");
        IF WhseJournalLine2.FINDLAST THEN
            NewLineNo := WhseJournalLine2."Line No." + 10000
        ELSE
            NewLineNo := 10000;
        WhseJournalLine2.RESET;
        WhseJournalLine2.INIT;
        WhseJournalLine2 := WhseJournalLine;
        WhseJournalLine2."Line No." := NewLineNo;
        WhseJournalLine2."Qty. (Phys. Inventory)" := 0;
        WhseJournalLine2."Qty. (Calculated)" := 0;
        WhseJournalLine2."Qty. (Calculated) (Base)" := 0;
        WhseJournalLine2."Qty. (Phys. Inventory) (Base)" := 0;
        WhseJournalLine2."Phys. Inventory" := FALSE;
        WhseJournalLine2.VALIDATE("Item No.", '');
        WhseJournalLine2."Serial No." := '';
        WhseJournalLine2."Lot No." := '';
        WhseJournalLine2.Description := '';
        WhseJournalLine2.VALIDATE(Quantity, 0);
        WhseJournalLine2."Bin Code" := BinCode;
        WhseJournalLine2.INSERT;
        WhseJournalLine.GET(WhseJournalLine2."Journal Template Name", WhseJournalLine2."Journal Batch Name", WhseJournalLine2."Location Code", WhseJournalLine2."Line No.");

    end;

    procedure CreateNewWhseJournalLineItem(ItemNo: Code[20]; LotNo: Code[20]; SerialNo: Code[20]; BinCode: Code[20])
    var
        WhseJournalLine2: Record "Warehouse Journal Line";
        NewLineNo: Integer;
    begin
        CreateNewWhseJournalLineBin(WhseJournalLine."Bin Code");
        WhseJournalLine."Phys. Inventory" := FALSE;
        WhseJournalLine.VALIDATE("Item No.", ItemNo);

        WhseJournalLine.VALIDATE("Bin Code", BinCode);
        WhseJournalLine."Phys. Inventory" := TRUE;
        WhseJournalLine.VALIDATE("Qty. (Calculated)", 0);
        WhseJournalLine.VALIDATE("Qty. (Calculated) (Base)", 0);
        WhseJournalLine.VALIDATE("Qty. (Phys. Inventory)", 0);
        IF LotNo <> '' THEN
            WhseJournalLine.VALIDATE("Lot No.", LotNo);
        IF SerialNo <> '' THEN
            WhseJournalLine.VALIDATE("Serial No.", SerialNo);
        WhseJournalLine.MODIFY;
    end;

    procedure UpdateWhseJournalLine(ItemNo: Code[20]; LotNo: Code[20]; SerialNo: Code[20]; BinCode: Code[20])
    begin
        WhseJournalLine.VALIDATE("Item No.", ItemNo);
        WhseJournalLine.VALIDATE("Bin Code", BinCode);
        WhseJournalLine."Phys. Inventory" := TRUE;
        WhseJournalLine.VALIDATE("Qty. (Calculated)", 0);
        WhseJournalLine.VALIDATE("Qty. (Calculated) (Base)", 0);
        WhseJournalLine.VALIDATE("Qty. (Phys. Inventory)", 0);
        WhseJournalLine.VALIDATE("Qty. (Phys. Inventory) (Base)", 0);
        IF LotNo <> '' THEN
            WhseJournalLine.VALIDATE("Lot No.", LotNo);
        IF SerialNo <> '' THEN
            WhseJournalLine.VALIDATE("Serial No.", SerialNo);
    end;
}

