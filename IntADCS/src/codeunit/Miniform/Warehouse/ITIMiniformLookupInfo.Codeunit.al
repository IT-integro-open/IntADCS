codeunit 69127 "ITI Miniform Lookup Info"
{

    TableNo = "ITI Miniform Header";

    trigger OnRun()
    var
        ADCSSetup: Record "ITI ADCS Setup";
        MiniformMgmt: Codeunit "ITI Miniform Management";
        
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
        InputNotAllowedErr: Label 'Input not allowed, back to previous page.';
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
        ReturnedNodeWithHeader: XmlNode;
        RootNode: XmlNode;


    local procedure ProcessInput()
    var
        BinContent: Record "Bin Content";
        PackageNoInformation: Record "Package No. Information";
        FuncGroup: Record "ITI Miniform Function Group";
        SerialNoInformation: Record "Serial No. Information";
        LotNoInformation: Record "Lot No. Information";
        Item: Record Item;
        RecordId: RecordId;
        TableNo: Integer;
        TextValue: Text[250];
        LookupItemFromHeader: Boolean;


    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputErr);
    
        if not XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNodeWithHeader) then
            Error(InputErr);

        //GlobalLanguage(ADCSMgt.GetLanguageID());
        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        Evaluate(LookupItemFromHeader, ADCSCommunication.GetNodeAttribute(ReturnedNodeWithHeader, 'LookupItem2'));

        if RecRef.Get(RecordId) then
            case TableNo of
                // Package No. information
                6515:
                    begin
                        RecRef.SetTable(PackageNoInformation);
                        if LookupItemFromHeader then
                            PackageNoInformation.SetRange("Item No.", PackageNoInformation."Item No.")
                        // if not LookupItemFromHeader then
                        else
                            PackageNoInformation.SetRange("Package No.",PackageNoInformation."Package No.");
                        // PackageNoInformation.FindSet();
                        RecRef.GetTable(PackageNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                    end;
                // Item
                27:
                    begin
                        RecRef.SetTable(Item);
                        Item.SetRange("No.", Item."No.");
                        Recref.GetTable(Item);
                        ADCSCommunication.SetRecRef(RecRef);
                    end;
                // Lot No information
                6505:
                    begin

                        RecRef.SetTable(LotNoInformation);
                        if LookupItemFromHeader then
                            LotNoInformation.SetRange("Item No.", LotNoInformation."Item No.")
                        // if not LookupItemFromHeader then
                        else
                            LotNoInformation.SetRange("Lot No.", LotNoInformation."Lot No."); 
                        Recref.GetTable(LotNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                    end;
                // Serial No. Information
                6504:
                    begin
                        RecRef.SetTable(SerialNoInformation);
                        if LookupItemFromHeader then
                            SerialNoInformation.SetRange("Item No.", SerialNoInformation."Item No.")
                        else
                            SerialNoInformation.SetRange("Serial No.", SerialNoInformation."Serial No.");
                        Recref.GetTable(SerialNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                    end;
                // Bin Content
                7302:
                    begin
                        RecRef.SetTable(BinContent);
                        if LookupItemFromHeader then
                            BinContent.SetRange("Item No.", BinContent."Item No.")
                        else
                            BinContent.SetRange("Bin Code", BinContent."Bin Code");
                        BinContent.SetRange("Location Code", BinContent."Location Code");
                        BinContent.SetAutoCalcFields(Quantity);
                        BinContent.SetFilter(Quantity, '<>0');
                        RecRef.GetTable(BinContent);
                        ADCSCommunication.SetRecRef(RecRef);
                    end;
            end
        else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::Input:
                Error(InputNotAllowedErr);
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := EndOfDocumentErr;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
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
        Item: Record Item;
        PackageNoInformation: Record "Package No. Information";
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        RecordId: RecordId;
        LookupItem: Boolean;
        TableNo: Integer;
        ItemNo: Code[20];

    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        RecRef.Open(RecordId.TableNo);
        LookupItem := VerifyFieldCorrectValue('LookupItem', Format(true));
        ADCSCommunication.SetGlobalValues('LookupItem2', UpperCase(Format(LookupItem)));

        if RecRef.Get(RecordId) then
            case TableNo of
                // Item
                27:
                    begin
                        RecRef.SetTable(Item);
                        ItemNo := Item."No.";
                        Item.SetRange("No.", ItemNo);
                        if Item.FindSet() then
                            RecRef.GetTable(Item);
                        ADCSCommunication.SetRecRef(RecRef);
                        ActiveInputField := 1;
                        GlobalLanguage(1033);
                        SendForm(ActiveInputField);
                    end;

                // Lot No. Information
                6505:
                    begin
                        RecRef.SetTable(LotNoInformation);
                        // if LookupItem then
                        LotNoInformation.SetRange("Item No.", LotNoInformation."Item No.");
                        if not LookupItem then
                            LotNoInformation.SetRange("Lot No.", LotNoInformation."Lot No." );
                        LotNoInformation.FindSet();
                        RecRef.GetTable(LotNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                        ActiveInputField := 1;
                        GlobalLanguage(1033);
                        SendForm(ActiveInputField);
                    end;

                // Package No information
                6515:
                    begin
                        RecRef.SetTable(PackageNoInformation);
                        PackageNoInformation.SetRange("Item No.", PackageNoInformation."Item No.");
                        if not LookupItem then
                            PackageNoInformation.SetRange("Package No.", PackageNoInformation."Package No.");
                        PackageNoInformation.FindSet();
                        RecRef.GetTable(PackageNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                        ActiveInputField := 1;
                        GlobalLanguage(1033);
                        SendForm(ActiveInputField);
                        
                    end;

                // Serial No. information
                6504:
                    begin
                        RecRef.SetTable(SerialNoInformation);
                        SerialNoInformation.SetRange("Item No.", SerialNoInformation."Item No.");
                        if not LookupItem then
                            SerialNoInformation.SetRange("Serial No.", SerialNoInformation."Serial No.");
                        SerialNoInformation.FindSet();
                        RecRef.GetTable(SerialNoInformation);
                        ADCSCommunication.SetRecRef(RecRef);
                        ActiveInputField := 1;
                        GlobalLanguage(1033);
                        SendForm(ActiveInputField);
                    end;

                // Bin Content information
                7302:
                    begin
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
                    end;
                    
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

