codeunit 69152 "ITI Miniform Sales Order"
{
    TableNo = "ITI Miniform Header";

    var
        ADCSSetup: Record "ITI ADCS Setup";
        MiniformHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        DOMxmlin: XmlDocument;
        RecRef, HeaderRecRef, LineRecRef : RecordRef;
        ActiveInputField: Integer;
        ADCSUserId: Text[250];
        CurrentCode: Text[20];
        LocationFilter: Text[250];
        Remark: Text[250];
        StackCode: Text[250];
        WhseEmpId: Text[250];
        Text000: Label 'Function not Found.';
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found.';
        Text008: Label 'End of Document.';
        Text012: Label 'No Lines available.';
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

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

    local procedure ProcessInput()
    var
        FuncGroup: Record "ITI Miniform Function Group";
        SalesLine: Record "Sales Line";
        RecordId: RecordId;
        FldNo: Integer;
        TableNo: Integer;
        TextValue: Text[250];
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.AsXmlElement().InnerText
        else
            Error(Text006);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SETTABLE(SalesLine);
            SalesLine.SetRange("Document Type", SalesLine."Document Type");
            SalesLine.SetRange("Document No.", SalesLine."Document No.");

            RecRef.GETTABLE(SalesLine);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;
        GetHeaderDoc();

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := Text008;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Action1:
                GetPrevOrNextInput(true);
            FuncGroup.KeyDef::Action2:
                GetPrevOrNextInput(false);
            FuncGroup.KeyDef::Action3:
                CreateNewLine();
            FuncGroup.KeyDef::Input:
                BEGIN
                    EVALUATE(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    CASE FldNo OF
                        SalesLine.FIELDNO("Line No."):
                            ;
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(SalesLine);
                        END;
                    END;

                    SalesLine.MODIFY();
                    RecRef.GETTABLE(SalesLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    IF Remark = '' THEN
                        IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                            RecRef.GETTABLE(SalesLine);
                            IF NOT ADCSCommunication.FindRecRef(1, ActiveInputField) THEN
                                Remark := Text008;
                            ActiveInputField := 1;
                        END ELSE
                            ActiveInputField += 1;
                END;
            ELSE
                ERROR(Text000);
        end;
        GetLines(SalesLine);
        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        SalesLine: Record "Sales Line";
        RecordId: RecordId;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        HeaderRecRef.OPEN(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if HeaderRecRef.Get(RecordId) then begin
            GetLines(SalesLine);
            RecRef.GETTABLE(SalesLine);
            ADCSCommunication.SetRecRef(RecRef);
            ADCSCommunication.SetDocumentHeader(HeaderRecRef);
            ADCSCommunication.SetGlobalValues('DocumentHeader', Format(HeaderRecRef.RecordId));
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end else
            Error(Text007);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;

    local procedure GetHeaderDoc()
    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        HeaderRecordId: RecordId;
        HeadNode: XmlNode;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header', HeadNode);
        Evaluate(HeaderRecordId, ITIXMLDOMManagement.GetAttributeValue(HeadNode, 'DocumentHeader'));
        HeaderRecRef.OPEN(HeaderRecordId.TableNo);
        if HeaderRecRef.Get(HeaderRecordId) then begin
            ADCSCommunication.SetDocumentHeader(HeaderRecRef);
            ADCSCommunication.SetGlobalValues('DocumentHeader', Format(HeaderRecRef.RecordId));
        end;
    end;

    local procedure GetLines(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.Reset();
        HeaderRecRef.SETTABLE(SalesHeader);
        SalesLine.Setrange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if not SalesLine.FindFirst() then begin
            ADCSMgt.SendError(Text012);
            exit;
        end;
        LineRecRef.GETTABLE(SalesLine);
        ADCSCommunication.SetDocumenLines(LineRecRef);
    end;

    local procedure GetPrevOrNextInput(IsNext: Boolean)
    var
        FieldNo: Integer;
    begin
        Evaluate(FieldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
        ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FieldNo);
        if IsNext then begin
            if not ADCSCommunication.LastEntryField(CurrentCode, FieldNo) then
                ActiveInputField += 1;
        end
        else
            if ActiveInputField > 1 then
                ActiveInputField -= 1;
    end;

    local procedure CreateNewLine()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LineNo: Integer;
    begin
        HeaderRecRef.SetTable(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No." + 10000
        else
            LineNo := 10000;


        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);
    end;

}