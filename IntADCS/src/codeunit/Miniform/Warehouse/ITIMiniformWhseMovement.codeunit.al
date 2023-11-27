codeunit 69102 "ITI Miniform Whse. Movement"
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
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        ReturnedNode: XmlNode;
        DOMxmlin: XmlDocument;
        RootNode: XmlNode;
        TextValue: Text[250];
        ADCSUserId: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        PreviousCode: Text[250];
        StackCode: Text[250];
        Remark: Text[250];
        ActiveInputField: Integer;
        RecRef: RecordRef;
        Text000: Label 'Function not Found';
        Text004: Label 'Invalid %1._BELL__BELL_';
        Text006: Label 'No input Node found';
        Text007: Label 'Record not found';
        Text008: Label 'Register Movement [F3]_BELL_';
        Text010: Label 'Bin %1_BELL_';
        Text011: Label 'Invalid Quantity_BELL__BELL_';
        Text013: Label 'Bin not empty._BELL__BELL_';
        Text014: Label 'Bin blocked._BELL__BELL_';
        Text015: Label 'There is no item in bin._BELL__BELL_';
        Text016: Label 'There is no enough quantity in bin._BELL__BELL_';
        Text017: Label 'Wrong value._BELL__BELL_';

    local procedure ProcessInput()
    var
        ADCSSetup: Record "ITI ADCS Setup";
        ItemTrackingSetup: record "Item Tracking Setup";
        WhseJnlBatch: Record 7310;
        WhseJnlLine: Record 7311;
        FuncGroup: Record "ITI Miniform Function Group";
        ItemTrackingMgt: Codeunit 6500;
        TableNo: Integer;
        RecordId: RecordID;
        FldNo: Integer;
        TextValue: Text[250];
        SNRequired: Boolean;
        LNRequired: Boolean;
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseJnlLine);
            WhseJnlLine.SETRANGE("Journal Template Name", WhseJnlLine."Journal Template Name");
            WhseJnlLine.SETRANGE("Journal Batch Name", WhseJnlLine."Journal Batch Name");
            WhseJnlLine.SETRANGE("Location Code", WhseJnlLine."Location Code");
            RecRef.GETTABLE(WhseJnlLine);
            ADCSCommunication.SetRecRef(RecRef);
        END ELSE BEGIN
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            EXIT;
        END;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        CASE FuncGroup.KeyDef OF
            FuncGroup.KeyDef::Esc:
                BEGIN
                    WhseJnlLine.SETRANGE("Journal Template Name", WhseJnlLine."Journal Template Name");
                    WhseJnlLine.SETRANGE("Journal Batch Name", WhseJnlLine."Journal Batch Name");
                    WhseJnlLine.SETRANGE("Location Code", WhseJnlLine."Location Code");
                    WhseJnlLine.DELETEALL(TRUE);
                    ADCSCommunication.RunPreviousMiniform(DOMxmlin);
                END;
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
            FuncGroup.KeyDef::Reset:
                Reset(WhseJnlLine);
            FuncGroup.KeyDef::Register:
                BEGIN
                    Register(WhseJnlLine);
                    IF Remark = '' THEN BEGIN
                        WhseJnlBatch.GET(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
                        SetupNewLine(WhseJnlLine, WhseJnlBatch);
                        Reset(WhseJnlLine);
                        SendForm(ActiveInputField);
                    END ELSE
                        SendForm(ActiveInputField);
                END;
            FuncGroup.KeyDef::Input:
                BEGIN
                    EVALUATE(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    CASE FldNo OF
                        WhseJnlLine.FIELDNO("From Bin Code"):
                            CheckFromBinCode(WhseJnlLine, UPPERCASE(TextValue));
                        WhseJnlLine.FIELDNO("Item No."):
                            CheckItemNo(WhseJnlLine, UPPERCASE(TextValue));
                        WhseJnlLine.FIELDNO("Lot No."):
                            CheckLotNo(WhseJnlLine, TextValue);
                        WhseJnlLine.FIELDNO("Serial No."):
                            CheckSerialNo(WhseJnlLine, TextValue);
                        WhseJnlLine.FIELDNO(Quantity):
                            CheckQty(WhseJnlLine, TextValue);
                        WhseJnlLine.FIELDNO("To Bin Code"):
                            CheckToBinCode(WhseJnlLine, UPPERCASE(TextValue));
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(WhseJnlLine);
                        END;
                    END;
                    WhseJnlLine.MODIFY;
                    RecRef.GETTABLE(WhseJnlLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);

                    IF Remark = '' THEN BEGIN
                        IF ADCSCommunication.GetActiveInputNo(CurrentCode, WhseJnlLine.FIELDNO("Lot No.")) = ActiveInputField + 1 THEN BEGIN
                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJnlLine."Item No.", ItemTrackingSetup);
                            IF NOT ItemTrackingSetup."Lot No. Required" THEN BEGIN
                                FldNo := WhseJnlLine.FIELDNO("Lot No.");
                                ActiveInputField += 1;
                            END;
                        END;
                        IF ADCSCommunication.GetActiveInputNo(CurrentCode, WhseJnlLine.FIELDNO("Serial No.")) = ActiveInputField + 1 THEN BEGIN
                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseJnlLine."Item No.", ItemTrackingSetup);
                            IF NOT ItemTrackingSetup."Serial No. Required" THEN BEGIN
                                FldNo := WhseJnlLine.FIELDNO("Serial No.");
                                ActiveInputField += 1;
                            END;
                        END;
                        IF ADCSCommunication.GetActiveInputNo(CurrentCode, WhseJnlLine.FIELDNO(Quantity)) = ActiveInputField + 1 THEN BEGIN
                            IF (WhseJnlLine.Quantity <> 0) AND (WhseJnlLine."Serial No." <> '') THEN BEGIN
                                FldNo := WhseJnlLine.FIELDNO(Quantity);
                                ActiveInputField += 1;
                            END;
                        END;
                    END;
                    IF Remark = '' THEN
                        IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                            // <-- Automatic Register
                            ADCSSetup.GET;
                            IF ADCSSetup."Automatic Movment Reg." THEN BEGIN
                                Register(WhseJnlLine);
                                WhseJnlBatch.GET(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
                                SetupNewLine(WhseJnlLine, WhseJnlBatch);
                                Reset(WhseJnlLine);
                                RecRef.GETTABLE(WhseJnlLine);
                                Remark := Text010;
                                ActiveInputField := 1;
                            END ELSE BEGIN
                                // --> Automatic Register
                                RecRef.GETTABLE(WhseJnlLine);
                                Remark := Text008;
                            END;
                        END ELSE
                            ActiveInputField += 1;
                END;
            ELSE
                ERROR(Text000);
        END;

        IF NOT (FuncGroup.KeyDef IN [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) THEN
            SendForm(ActiveInputField);
    end;

    local procedure SetupNewLine(var WhseJnlLine: Record 7311; WhseJnlBatch: Record 7310)
    var
        WhseJnlLine2: Record 7311;
        WhseJnlTemplate: Record 7309;
        LastLineNo: Integer;
    begin
        WhseJnlTemplate.GET(WhseJnlBatch."Journal Template Name");
        WhseJnlLine.INIT;
        WhseJnlLine."Journal Template Name" := WhseJnlBatch."Journal Template Name";
        WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
        WhseJnlLine."Location Code" := LocationFilter;
        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement;
        WhseJnlLine."Line No." := GetNextLineNo(WhseJnlBatch);
        WhseJnlLine."Registering Date" := TODAY;
        WhseJnlLine."User ID" := WhseEmpId;
        WhseJnlLine."Source Code" := WhseJnlTemplate."Source Code";
        WhseJnlLine."Reason Code" := WhseJnlBatch."Reason Code";
        WhseJnlLine."Registering No. Series" := WhseJnlBatch."Registering No. Series";
        WhseJnlLine.INSERT;
    end;

    local procedure DeleteLines(var WhseJnlLine: Record 7311; WhseJnlBatch: Record 7310)
    begin
        WhseJnlLine.SETRANGE("Journal Template Name", WhseJnlBatch."Journal Template Name");
        WhseJnlLine.SETRANGE("Journal Batch Name", WhseJnlBatch.Name);
        WhseJnlLine.SETRANGE("Location Code", WhseJnlBatch."Location Code");
        WhseJnlLine.DELETEALL(TRUE);
    end;

    local procedure CheckFromBinCode(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        Bin: Record 7354;
        BinContent: Record 7302;
    begin
        IF Bin.GET(WhseJnlLine."Location Code", InputValue) THEN BEGIN
            IF Bin."Block Movement" IN [Bin."Block Movement"::Outbound, Bin."Block Movement"::All] THEN BEGIN
                Remark := Text014;
                EXIT;
            END;
            CheckBin(WhseJnlLine."Location Code", InputValue, '', '', '');

            IF Remark = '' THEN
                WhseJnlLine.VALIDATE("From Bin Code", Bin.Code);
        END ELSE
            Remark := STRSUBSTNO(Text004, WhseJnlLine.FIELDCAPTION("Bin Code"));
    end;

    local procedure CheckToBinCode(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        Bin: Record 7354;
    begin
        IF Bin.GET(WhseJnlLine."Location Code", InputValue) THEN BEGIN
            IF Bin."Block Movement" IN [Bin."Block Movement"::Inbound, Bin."Block Movement"::All] THEN BEGIN
                Remark := Text014;
                EXIT;
            END;
            SetAllToBinCode(WhseJnlLine, Bin.Code)
        END ELSE
            Remark := STRSUBSTNO(Text004, WhseJnlLine.FIELDCAPTION("Bin Code"));
    end;

    local procedure SetAllToBinCode(var WhseJnlLine2: Record 7311; BinCode: Text[250])
    begin
        IF WhseJnlLine2.FINDSET THEN
            REPEAT
                WhseJnlLine2.VALIDATE("To Bin Code", BinCode);
                WhseJnlLine2.MODIFY;
            UNTIL WhseJnlLine2.NEXT = 0
    end;

    local procedure CheckBin(LocationCode: Code[20]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[20]; SerialNo: Code[20])
    var
        BinContent: Record 7302;
    begin
        BinContent.SETCURRENTKEY("Location Code", "Bin Code", "Item No.");
        BinContent.SETRANGE("Location Code", LocationCode);
        BinContent.SETRANGE("Bin Code", BinCode);
        IF ItemNo <> '' THEN
            BinContent.SETRANGE("Item No.", ItemNo);
        IF LotNo <> '' THEN
            BinContent.SETFILTER("Lot No. Filter", LotNo);

        IF SerialNo <> '' THEN
            BinContent.SETFILTER("Serial No. Filter", SerialNo);

        BinContent.SETFILTER("Quantity (Base)", '<>%1', 0);

        IF BinContent.ISEMPTY THEN
            Remark := Text015;
    end;

    local procedure CheckItemNo(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        ItemIdent: Record 7704;
    begin
        IF InputValue = '' THEN BEGIN
            Remark := STRSUBSTNO(Text004, WhseJnlLine.FIELDCAPTION("Item No."));
            EXIT;
        END;

        IF NOT ItemIdent.GET(InputValue) THEN BEGIN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION("Item No."));
            EXIT;
        END;

        CheckBin(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", ItemIdent."Item No.", '', '');

        IF Remark = '' THEN
            WhseJnlLine.VALIDATE("Item No.", ItemIdent."Item No.");
    end;

    local procedure CheckLotNo(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        WarehouseEntry: Record 7312;
        BinContent: Record 7302;
        BinContBuff2: Record 7330 temporary;
        WhseJnlBatch: Record 7310;
        LotNo: Code[20];
        BinCode: Code[20];
    begin
        IF InputValue = '' THEN BEGIN
            Remark := STRSUBSTNO(Text004, WhseJnlLine.FIELDCAPTION("Lot No."));
            EXIT;
        END;

        CheckBin(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", WhseJnlLine."Item No.", InputValue, '');

        IF Remark = '' THEN
            WhseJnlLine.VALIDATE("Lot No.", InputValue);
    end;

    local procedure CheckSerialNo(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        WarehouseEntry: Record 7312;
        BinContent: Record 7302;
        BinContBuff2: Record 7330 temporary;
        WhseJnlBatch: Record 7310;
        LotNo: Code[20];
        BinCode: Code[20];
    begin
        IF InputValue = '' THEN BEGIN
            Remark := STRSUBSTNO(Text004, WhseJnlLine.FIELDCAPTION("Serial No."));
            EXIT;
        END;

        CheckBin(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code", WhseJnlLine."Item No.", WhseJnlLine."Lot No.", InputValue);

        IF Remark = '' THEN BEGIN
            WhseJnlLine.VALIDATE("Serial No.", InputValue);
            CheckQty(WhseJnlLine, '1');
        END;
    end;

    local procedure SetAllNewLotNo(var WhseJnlLine2: Record 7311; LotNo: Text[250])
    begin
        IF WhseJnlLine2.FINDSET THEN
            REPEAT
                WhseJnlLine2.VALIDATE("New Lot No.", LotNo);
                WhseJnlLine2.MODIFY;
            UNTIL WhseJnlLine2.NEXT = 0
    end;

    local procedure CheckQty(var WhseJnlLine: Record 7311; InputValue: Text[250])
    var
        BinContent: Record 7302;
        Item: Record 27;
        ItemUnitOfMeasure: Record 5404;
        Location: Record 14;
        QtyToHandle: Decimal;
        QtyToTake: Decimal;
    begin
        IF InputValue = '' THEN BEGIN
            Remark := Text011;
            EXIT;
        END;

        IF NOT EVALUATE(QtyToHandle, InputValue) THEN BEGIN
            Remark := Text011;
            EXIT;
        END;

        IF QtyToHandle = 0 THEN BEGIN
            Remark := Text011;
            EXIT;
        END;

        Location.GET(WhseJnlLine."Location Code");
        IF (WhseJnlLine."From Bin Code" <> '') AND
           (WhseJnlLine."From Bin Code" <> Location."Adjustment Bin Code") AND
           Location."Directed Put-away and Pick"
        THEN BEGIN
            BinContent.GET(WhseJnlLine."Location Code", WhseJnlLine."From Bin Code",
              WhseJnlLine."Item No.", WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code");
            IF WhseJnlLine."Lot No." <> '' THEN
                BinContent.SETRANGE("Lot No. Filter", WhseJnlLine."Lot No.");
            IF WhseJnlLine."Serial No." <> '' THEN
                BinContent.SETRANGE("Serial No. Filter", WhseJnlLine."Serial No.");

            QtyToTake := BinContent.CalcQtyAvailToTakeUOM;
            IF QtyToTake < ABS(QtyToHandle) THEN BEGIN
                Remark := Text016;
                EXIT;
            END;

            IF NOT CheckDecreaseBinContent(WhseJnlLine, ABS(QtyToHandle), ABS(QtyToHandle)) THEN BEGIN
                Remark := Text016;
                EXIT;
            END;
        END;

        WhseJnlLine.VALIDATE(Quantity, QtyToHandle);
    end;


    procedure CheckDecreaseBinContent(var WhseJnlLine: Record 7311; QtyBase: Decimal; DecreaseQtyBase: Decimal): Boolean
    var
        BinContent: Record 7302;
        Location: Record 14;
        WhseActivLine: Record 5767;
        QtyAvailToPickBase: Decimal;
    begin
        Location.GET(WhseJnlLine."Location Code");
        IF WhseJnlLine."From Bin Code" = Location."Adjustment Bin Code" THEN
            EXIT;

        WhseActivLine.SETCURRENTKEY(
          "Item No.", "Bin Code", "Location Code", "Action Type",
          "Variant Code", "Unit of Measure Code", "Breakbulk No.",
          "Activity Type", "Lot No.", "Serial No.", "Original Breakbulk");
        WhseActivLine.SETRANGE("Item No.", WhseJnlLine."Item No.");
        WhseActivLine.SETRANGE("Bin Code", WhseJnlLine."From Bin Code");
        WhseActivLine.SETRANGE("Location Code", WhseJnlLine."Location Code");
        WhseActivLine.SETRANGE("Unit of Measure Code", WhseJnlLine."Unit of Measure Code");
        WhseActivLine.SETRANGE("Variant Code", WhseJnlLine."Variant Code");

        IF Location."Allow Breakbulk" THEN BEGIN
            WhseActivLine.SETRANGE("Action Type", WhseActivLine."Action Type"::Take);
            WhseActivLine.SETRANGE("Original Breakbulk", TRUE);
            WhseActivLine.SETRANGE("Breakbulk No.", 0);
            WhseActivLine.CALCSUMS("Qty. (Base)");
            DecreaseQtyBase := DecreaseQtyBase + WhseActivLine."Qty. (Base)";
        END;

        BinContent.GET(
          WhseJnlLine."Location Code", WhseJnlLine."From Bin Code",
          WhseJnlLine."Item No.", WhseJnlLine."Variant Code", WhseJnlLine."Unit of Measure Code");
        BinContent.SETRANGE("Lot No. Filter", WhseJnlLine."Lot No.");

        QtyAvailToPickBase := BinContent.CalcQtyAvailToPick(DecreaseQtyBase);
        IF QtyAvailToPickBase < QtyBase THEN
            EXIT(FALSE);

        EXIT(TRUE);
    end;

    local procedure GetNextLineNo(WhseJnlBatch: Record 7310): Integer
    var
        WhseJnlLine: Record 7311;
    begin
        WhseJnlLine.SETRANGE("Journal Template Name", WhseJnlBatch."Journal Template Name");
        WhseJnlLine.SETRANGE("Journal Batch Name", WhseJnlBatch.Name);
        WhseJnlLine.SETRANGE("Location Code", WhseJnlBatch."Location Code");
        IF WhseJnlLine.FINDLAST THEN
            EXIT(WhseJnlLine."Line No." + 10000)
        ELSE
            EXIT(10000);
    end;

    local procedure Reset(var WhseJnlLine2: Record 7311)
    var
        WhseJnlLine: Record 7311;
    begin
        IF NOT WhseJnlLine.GET(
          WhseJnlLine2."Journal Template Name", WhseJnlLine2."Journal Batch Name", WhseJnlLine2."Location Code", WhseJnlLine2."Line No.")
        THEN
            ERROR(Text007);

        //Remark := '';
        WhseJnlLine.VALIDATE("Item No.", '');
        WhseJnlLine.VALIDATE("Lot No.", '');
        WhseJnlLine.VALIDATE("From Bin Code", '');
        WhseJnlLine.VALIDATE("To Bin Code", '');
        WhseJnlLine.VALIDATE(Quantity, 0);
        WhseJnlLine.MODIFY;

        RecRef.GETTABLE(WhseJnlLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
    end;

    local procedure Register(WhseJnlLine2: Record 7311)
    var
        WhseJnlLine: Record 7311;
        WhseJnlLinePost: Codeunit 7301;
        WMSMgt: Codeunit 7302;
    begin
        WhseJnlLine.SETRANGE("Journal Template Name", WhseJnlLine2."Journal Template Name");
        WhseJnlLine.SETRANGE("Journal Batch Name", WhseJnlLine2."Journal Batch Name");
        WhseJnlLine.SETRANGE("Location Code", WhseJnlLine2."Location Code");
        IF WhseJnlLine.FINDSET THEN
            REPEAT
                WMSMgt.CheckWhseJnlLine(WhseJnlLine, 4, WhseJnlLine."Qty. (Absolute, Base)", FALSE);
                WhseJnlLine.TESTFIELD("To Bin Code");
                WhseJnlLinePost.RUN(WhseJnlLine);
                WhseJnlLine.DELETE;
            UNTIL WhseJnlLine.NEXT = 0;
    end;

    local procedure PrepareData()
    var
        TableNo: Integer;
        RecordId: RecordID;
        WhseJnlTemplate: Record 7309;
        WhseJnlBatch: Record 7310;
        WhseJnlLine: Record 7311;
        JournalError: Text[250];
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        JournalError := ADCSMgt.GetWarehouseJournal(2, WhseJnlBatch, WhseEmpId);

        IF JournalError <> '' THEN BEGIN
            ADCSMgt.SendError(JournalError);
            EXIT;
        END;

        DeleteLines(WhseJnlLine, WhseJnlBatch);
        SetupNewLine(WhseJnlLine, WhseJnlBatch);

        RecRef.GETTABLE(WhseJnlLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
        SendForm(ActiveInputField);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

