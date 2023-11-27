codeunit 69075 "ITI Miniform Whse. Act. Line"
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
            PrepareData()
        ELSE
            ProcessInput();

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        Text000: Label 'Function not Found.';
        Text004: Label 'Invalid %1.';
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found.';
        Text008: Label 'End of Document.';
        Text009: Label 'Qty. does not match.';
        Text011: Label 'Invalid Quantity.';
        Text012: Label 'No Lines available.';
        ADCSUserId: Text;
        CurrentCode: Text;
        LocationFilter: Text;
        Remark: Text;
        StackCode: Text;
        WhseEmpId: Text;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure ProcessInput()
    var
        WhseActivityLine: Record 5767;
        FuncGroup: Record 7702;
        RecId: RecordID;
        FldNo: Integer;
        TableNo: Integer;
        TextValue: Text;
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecId) THEN BEGIN
            RecRef.SETTABLE(WhseActivityLine);
            WhseActivityLine.SETCURRENTKEY("Activity Type", "No.", "Sorting Sequence No.");
            WhseActivityLine.SETRANGE("Activity Type", WhseActivityLine."Activity Type");
            WhseActivityLine.SETRANGE("No.", WhseActivityLine."No.");
            RecRef.GETTABLE(WhseActivityLine);
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
            FuncGroup.KeyDef::Reset:
                Reset(WhseActivityLine);
            FuncGroup.KeyDef::Register:
                BEGIN
                    Register(WhseActivityLine);
                    IF Remark = '' THEN
                        ADCSCommunication.RunPreviousMiniform(DOMxmlin)
                    ELSE
                        SendForm(ActiveInputField);
                END;
            FuncGroup.KeyDef::Input:
                BEGIN
                    EVALUATE(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    CASE FldNo OF
                        WhseActivityLine.FIELDNO("Bin Code"):
                            CheckBinNo(WhseActivityLine, UPPERCASE(TextValue));
                        WhseActivityLine.FIELDNO("Item No."):
                            CheckItemNo(WhseActivityLine, UPPERCASE(TextValue));
                        WhseActivityLine.FIELDNO("Qty. to Handle"):
                            CheckQty(WhseActivityLine, TextValue);
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(WhseActivityLine);
                        END;
                    END;

                    WhseActivityLine.MODIFY();
                    RecRef.GETTABLE(WhseActivityLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    IF Remark = '' THEN
                        IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                            RecRef.GETTABLE(WhseActivityLine);
                            IF NOT ADCSCommunication.FindRecRef(1, ActiveInputField) THEN BEGIN
                                Remark := Text008;
                            END ELSE
                                ActiveInputField := 1;
                        END ELSE
                            ActiveInputField += 1;
                END;
            ELSE
                ERROR(Text000);
        END;

        IF NOT (FuncGroup.KeyDef IN [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) THEN
            SendForm(ActiveInputField);
    end;

    local procedure CheckBinNo(var WhseActLine: Record 5767; InputValue: Text)
    begin
        IF InputValue = WhseActLine."Bin Code" THEN
            EXIT;

        Remark := STRSUBSTNO(Text004, WhseActLine.FIELDCAPTION("Bin Code"));
    end;

    local procedure CheckItemNo(var WhseActLine: Record 5767; InputValue: Text)
    var
        ItemIdent: Record 7704;
    begin
        IF InputValue = WhseActLine."Item No." THEN
            EXIT;

        IF NOT ItemIdent.GET(InputValue) THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION("Item No."));

        IF ItemIdent."Item No." <> WhseActLine."Item No." THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION("Item No."));

        IF (ItemIdent."Variant Code" <> '') AND (ItemIdent."Variant Code" <> WhseActLine."Variant Code") THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION("Variant Code"));

        IF (ItemIdent."Unit of Measure Code" <> '') AND (ItemIdent."Unit of Measure Code" <> WhseActLine."Unit of Measure Code") THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION("Unit of Measure Code"));
    end;

    local procedure CheckQty(var WhseActLine: Record 5767; InputValue: Text)
    var
        QtyToHandle: Decimal;
    begin
        IF InputValue = '' THEN BEGIN
            Remark := Text011;
            EXIT;
        END;

        EVALUATE(QtyToHandle, InputValue);
        IF QtyToHandle = ABS(QtyToHandle) THEN BEGIN
            CheckItemNo(WhseActLine, WhseActLine."Item No.");
            IF QtyToHandle <= WhseActLine."Qty. Outstanding" THEN
                WhseActLine.VALIDATE("Qty. to Handle", QtyToHandle)
            ELSE
                Remark := Text011;
        END ELSE
            Remark := Text011;
    end;

    local procedure Reset(var WhseActLine2: Record 5767)
    var
        WhseActLine: Record 5767;
    begin
        IF NOT WhseActLine.GET(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") THEN
            ERROR(Text007);

        Remark := '';
        WhseActLine.VALIDATE("Qty. to Handle", 0);
        WhseActLine.MODIFY();

        RecRef.GETTABLE(WhseActLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
    end;

    local procedure Register(WhseActLine2: Record 5767)
    var
        WhseActLine: Record 5767;
        WhseActivityRegister: Codeunit 7307;
    begin
        IF NOT WhseActLine.GET(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") THEN
            ERROR(Text007);
        IF NOT BalanceQtyToHandle(WhseActLine) THEN
            Remark := Text009
        ELSE BEGIN
            WhseActivityRegister.ShowHideDialog(TRUE);
            WhseActivityRegister.RUN(WhseActLine);
        END;
    end;

    local procedure BalanceQtyToHandle(var WhseActivLine2: Record 5767): Boolean
    var
        WhseActLine: Record 5767;
        QtyToPick: Decimal;
        QtyToPutAway: Decimal;
    begin
        WhseActLine.COPY(WhseActivLine2);
        WhseActLine.SETCURRENTKEY("Activity Type", "No.", "Item No.", "Variant Code", "Action Type");
        WhseActLine.SETRANGE("Activity Type", WhseActLine."Activity Type");
        WhseActLine.SETRANGE("No.", WhseActLine."No.");
        WhseActLine.SETRANGE("Action Type");

        IF WhseActLine.FIND('-') THEN
            REPEAT
                WhseActLine.SETRANGE("Item No.", WhseActLine."Item No.");
                WhseActLine.SETRANGE("Variant Code", WhseActLine."Variant Code");
                WhseActLine.SETRANGE("Serial No.", WhseActLine."Serial No.");
                WhseActLine.SETRANGE("Lot No.", WhseActLine."Lot No.");

                IF (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Take) OR
                   (WhseActivLine2.GETFILTER("Action Type") = '')
                THEN BEGIN
                    WhseActLine.SETRANGE("Action Type", WhseActLine."Action Type"::Take);
                    IF WhseActLine.FIND('-') THEN
                        REPEAT
                            QtyToPick := QtyToPick + WhseActLine."Qty. to Handle (Base)";
                        UNTIL WhseActLine.NEXT() = 0;
                END;

                IF (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Place) OR
                   (WhseActivLine2.GETFILTER("Action Type") = '')
                THEN BEGIN
                    WhseActLine.SETRANGE("Action Type", WhseActLine."Action Type"::Place);
                    IF WhseActLine.FIND('-') THEN
                        REPEAT
                            QtyToPutAway := QtyToPutAway + WhseActLine."Qty. to Handle (Base)";
                        UNTIL WhseActLine.NEXT() = 0;
                END;

                IF QtyToPick <> QtyToPutAway THEN
                    EXIT(FALSE);

                WhseActLine.SETRANGE("Action Type");
                WhseActLine.FIND('+');
                WhseActLine.SETRANGE("Item No.");
                WhseActLine.SETRANGE("Variant Code");
                WhseActLine.SETRANGE("Serial No.");
                WhseActLine.SETRANGE("Lot No.");
                QtyToPick := 0;
                QtyToPutAway := 0;
            UNTIL WhseActLine.NEXT() = 0;
        EXIT(TRUE);
    end;

    local procedure PrepareData()
    var
        WhseActivityHeader: Record 5766;
        WhseActivityLine: Record 5767;
        RecId: RecordID;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecId) THEN BEGIN
            RecRef.SETTABLE(WhseActivityHeader);
            WhseActivityLine.SETRANGE("Activity Type", WhseActivityHeader.Type);
            WhseActivityLine.SETRANGE("No.", WhseActivityHeader."No.");
            IF NOT WhseActivityLine.FINDFIRST() THEN BEGIN
                ADCSMgt.SendError(Text012);
                EXIT;
            END;
            RecRef.GETTABLE(WhseActivityLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        END ELSE
            ERROR(Text007);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

