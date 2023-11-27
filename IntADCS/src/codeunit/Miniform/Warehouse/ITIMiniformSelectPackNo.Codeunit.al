codeunit 69124 "ITI Miniform Select Pack. No."
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
            ProcessSelection();

        Clear(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        SearchOutputErr: Label 'No maching result found.';
        FunctionErr: Label 'Function not Found';
        InputNodeErr: Label 'No input Node found';
        BinsErr: Label 'No Bins found_BELL__BELL_';
        ADCSUserId: Text[250];
        CurrentCode: Text[250];
        LocationFilter: Text[250];
        Remark: Text[250];
        StackCode: Text[250];
        TextValue: Text[250];
        WhseEmpId: Text[250];

        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure ProcessSelection()
    var
        Item: Record Item;
        FuncGroup: Record "ITI Miniform Function Group";
        PackageNoInformation: Record "Package No. Information";
        ITIADCSItemNoSearch: Codeunit ITIADCSItemNoSearch;
        LookupItem: Boolean;
        SearchResult: Code[20];
        FldNo: Integer;
        TableNo: Integer;
        VariantCode: Code[10];
        UnitOfMeasureCode: Code[10];

    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputNodeErr);

        LookupItem := false;
        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::Input:
                begin
                    SearchResult := ITIADCSItemNoSearch.GetItemNo(TextValue, VariantCode, LocationFilter, '', '', UnitOfMeasureCode);
                    if SearchResult = '' then begin
                        ADCSMgt.SendError(SearchOutputErr);
                        exit;
                    end
                    else begin
                        Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
                        RecRef.Open(TableNo);
                        
                        if Item.Get(TextValue) then
                            LookupItem := true;
                        PackageNoInformation.SetRange("Item No.", SearchResult);
                        if VariantCode <> '' then
                            PackageNoInformation.SetRange("Variant Code", VariantCode);
                        if not LookupItem then
                            PackageNoInformation.SetRange("Package No.", TextValue);
                        if PackageNoInformation.FindFirst() then
                            RecRef.GetTable(PackageNoInformation);

                        ADCSCommunication.SetRecRef(RecRef);
                        ADCSCommunication.SetNodeAttribute(ReturnedNode, 'RecordID', Format(RecRef.RecordId)); // added (save RecordID)
                        ReturnedNode.AsXmlElement().SetAttribute('FieldName', 'LookupItem');
                        ReturnedNode.AsXmlElement().SetAttribute('FieldValue', UpperCase(Format(LookupItem)));
                        ActiveInputField := ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), FldNo);

                        if Remark = '' then
                            if ADCSCommunication.LastEntryField(CopyStr(CurrentCode, 1, 20), FldNo) then begin
                                ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code); // added (without this line back to MainMenu)
                                                                                                // if not LookupItem then
                                ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
                                MiniformHeader2.SaveXMLinExt(DOMxmlin);

                                Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                                FuncGroup.KeyDef := FuncGroup.KeyDef::Register;
                            end else
                                ActiveInputField += 1;
                    end;
                end;
            else
                Error(FunctionErr);
        end;

        GlobalLanguage(1033);
        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        PackageNoInformation: Record "Package No. Information";
    begin
        RecRef.GetTable(PackageNoInformation);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
        SendForm(ActiveInputField);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}