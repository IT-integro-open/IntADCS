// UNUSED
codeunit 69093 "ITI Miniform Bin Lookup"
{

    TableNo = "ITI Miniform Header";

    trigger OnRun()
    var
        MiniformMgmt: Codeunit "ITI Miniform Management";
        ADCSSetup: Record "ITI ADCS Setup";
    begin
        ADCSSetup.Get();
        GlobalLanguage(1033);
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
        MiniformHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        NotFoundErr: Label 'Function not Found';
        InputErr: Label 'No input Node found';
        RecordErr: Label 'Record not found';
        EndOfDocumentErr: Label 'End of Document_BELL_';
        LinesErr: Label 'No Lines available_BELL__BELL_';
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
        BinContent: Record "Bin Content";
        FuncGroup: Record "ITI Miniform Function Group";
        RecordId: RecordId;
        TableNo: Integer;
        TextValue: Text[250];
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputErr);

        //GlobalLanguage(ADCSMgt.GetLanguageID());
        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(BinContent);
            BinContent.SetRange("Location Code", BinContent."Location Code");
            if not VerifyFieldHeaderCorrectValue('LookupItem', UpperCase(Format(true))) then
                BinContent.SetRange("Bin Code", BinContent."Bin Code")
            else
                BinContent.SetRange("Item No.", BinContent."Item No.");
            BinContent.SetAutoCalcFields(Quantity);
            BinContent.SetFilter(Quantity, '<>0');
            RecRef.GetTable(BinContent);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := EndOfDocumentErr;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := EndOfDocumentErr;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            else
                Error(NotFoundErr);
        end;


        GlobalLanguage(1033);
        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) then
            SendForm(ActiveInputField);
    end;

    local procedure VerifyFieldHeaderCorrectValue(TargetFieldName: Text; TargetFieldValue: Text): Boolean
    var
        LookupItemNode: XmlNode;
        XMLNodeAttributes: XmlAttributeCollection;
        ResultAttibute: XmlAttribute;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header', LookupItemNode) then begin
            XMLNodeAttributes := LookupItemNode.AsXmlElement().Attributes();
            if XMLNodeAttributes.Get('FieldName', ResultAttibute) then
                if UpperCase(TargetFieldName) = UpperCase(ResultAttibute.Value) then
                    if XMLNodeAttributes.Get('FieldValue', ResultAttibute) then
                        exit(UpperCase(ResultAttibute.Value) = UpperCase(TargetFieldValue));
        end;
    end;

    local procedure PrepareData()
    var
        BinContent: Record "Bin Content";
        BinContent2: Record "Bin Content";
        RecordId: RecordId;
        LookupItem: Boolean;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        //GlobalLanguage(ADCSMgt.GetLanguageID());
        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        LookupItem := VerifyFieldCorrectValue('LookupItem', Format(true));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(BinContent);
            BinContent2.SetAutoCalcFields(Quantity);
            BinContent2.SetFilter(Quantity, '<>0');
            BinContent2.SetRange("Location Code", BinContent."Location Code");
            if not LookupItem then
                BinContent2.SetRange("Bin Code", BinContent."Bin Code")
            else
                BinContent2.SetRange("Item No.", BinContent."Item No.");
            if not BinContent2.FindFirst() then begin
                ADCSMgt.SendError(LinesErr);
                exit;
            end;
            RecRef.GetTable(BinContent2);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;

            GlobalLanguage(1033);
            SendForm(ActiveInputField);
        end else
            Error(RecordErr);
        GlobalLanguage(1033);
    end;

    local procedure VerifyFieldCorrectValue(TargetFieldName: Text; TargetFieldValue: Text): Boolean
    var
        XMLAttributes: XmlAttributeCollection;
        ResultAttribute: XmlAttribute;
    begin
        XMLAttributes := ReturnedNode.AsXmlElement().Attributes();
        if XMLAttributes.Get('FieldName', ResultAttribute) then
            if not ((UpperCase(ResultAttribute.Value)) = UpperCase(TargetFieldName)) then
                exit(false);
        if XMLAttributes.Get('FieldValue', ResultAttribute) then
            if not (UpperCase(ResultAttribute.Value) = UpperCase(TargetFieldValue)) then
                exit(false);
        exit(true);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform

        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;

}

