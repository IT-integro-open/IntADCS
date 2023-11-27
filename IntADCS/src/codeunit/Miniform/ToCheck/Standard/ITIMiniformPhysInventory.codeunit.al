codeunit 69063 "ITI Miniform Phys.-Inventory"
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
        WhseJournalLine: Record 7311;
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

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));    // Key1 = TableNo
        RecRef.OPEN(TableNo);
        EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));   // Key2 = RecordID
        IF RecRef.GET(RecId) THEN BEGIN
            RecRef.SETTABLE(WhseJournalLine);
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
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(WhseJournalLine);
                        END;
                    END;

                    WhseJournalLine.MODIFY;
                    RecRef.GETTABLE(WhseJournalLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    IF Remark = '' THEN
                        IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                            RecRef.GETTABLE(WhseJournalLine);
                            IF NOT ADCSCommunication.FindRecRef(1, ActiveInputField) THEN
                                Remark := Text008
                            ELSE
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

    local procedure CheckBinNo(InputValue: Text)
    begin
        IF InputValue = WhseJournalLine."Bin Code" THEN
            EXIT;

        Remark := STRSUBSTNO(Text004, WhseJournalLine.FIELDCAPTION("Bin Code"));
    end;

    local procedure CheckItemNo(InputValue: Text)
    var
        ItemIdent: Record 7704;
    begin
        IF InputValue = WhseJournalLine."Item No." THEN
            EXIT;

        IF NOT ItemIdent.GET(InputValue) THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION(Code));

        IF ItemIdent."Item No." <> WhseJournalLine."Item No." THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION(Code));

        IF (ItemIdent."Variant Code" <> '') AND (ItemIdent."Variant Code" <> WhseJournalLine."Variant Code") THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION(Code));

        IF ((ItemIdent."Unit of Measure Code" <> '') AND (ItemIdent."Unit of Measure Code" <> WhseJournalLine."Unit of Measure Code"))
        THEN
            Remark := STRSUBSTNO(Text004, ItemIdent.FIELDCAPTION(Code));
    end;

    local procedure PrepareData()
    var
        WhseJournalBatch: Record 7310;
        RecId: RecordID;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecId) THEN BEGIN
            RecRef.SETTABLE(WhseJournalBatch);
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
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

