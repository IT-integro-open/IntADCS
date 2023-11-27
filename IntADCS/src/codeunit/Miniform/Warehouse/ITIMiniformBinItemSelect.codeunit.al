// UNUSED
codeunit 69094 "ITI Miniform Bin&Item Select"
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
        Bin: Record Bin;
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        EANErr: Label 'No EAN/BIN %1 not found', Comment = '%1 - EAN/BIN';
        ItemBinErr: Label 'No Item/BIN Found %1', Comment = '%1 - Item/BIN';
        ItemEANErr: Label 'No Item/EAN/BIN found %1', Comment = '%1 - Item/EAN/BIN';
        FunctionErr: Label 'Function not Found';
        InputNodeErr: Label 'No input Node found';
        BinsErr: Label 'No Bins found_BELL__BELL_';
        LinesErr: Label 'No Lines available_BELL__BELL_';
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
        BinContent: Record "Bin Content";
        Item: Record Item;
        ITIADCSSetup: Record "ITI ADCS Setup";
        FuncGroup: Record "ITI Miniform Function Group";
        ITIADCSItemNoSearch: Codeunit ITIADCSItemNoSearch;
        LookupItem: Boolean;
        SearchResult: Code[20];
        FldNo: Integer;


    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputNodeErr);

        LookupItem := false;
        //GlobalLanguage(ADCSMgt.GetLanguageID());
        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := BinsErr;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := BinsErr;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    case FldNo of
                        BinContent.FieldNo("Bin Code"):

                            if Bin.Get(LocationFilter, UpperCase(TextValue)) then begin
                                BinContent.SetRange("Bin Code", UpperCase(TextValue));
                                BinContent.SetFilter("Location Code", LocationFilter);
                            end else begin
                                ITIADCSSetup.Get();
                                // SearchResult := ITIADCSItemNoSearch.GetItemNo(TextValue);
                                
                                case ITIADCSSetup."Item Lookup" of
                                    ITIADCSSetup."Item Lookup"::"Item No.":
                                        if not Item.Get(UpperCase(TextValue)) then
                                            Error(ItemBinErr, UpperCase(TextValue));
                                    ITIADCSSetup."Item Lookup"::EAN:
                                        begin
                                            Item.SetRange("ITI EAN", UpperCase(TextValue));
                                            if not Item.FindFirst() then
                                                Error(EANErr, UpperCase(TextValue));
                                        end;
                                    ITIADCSSetup."Item Lookup"::"Item No. & EAN":
                                        if not Item.Get(UpperCase(TextValue)) then begin
                                            Item.SetRange("ITI EAN", UpperCase(TextValue));
                                            if not Item.FindFirst() then
                                                Error(ItemEANErr, UpperCase(TextValue));
                                        end;
                                    else
                                        Error(BinsErr);
                                end;
                                BinContent.SetRange("Item No.", Item."No.");
                                // BinContent.SetRange("Item No.", SearchResult);
                                BinContent.SetRange("Location Code", LocationFilter);
                                LookupItem := true;
                            end;


                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(BinContent);
                        end;
                    end;

                    if not BinContent.FindFirst() then begin
                        ADCSMgt.SendError(LinesErr);
                        exit;
                    end;

                    RecRef.GetTable(BinContent);
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
            else
                Error(FunctionErr);
        end;

        GlobalLanguage(1033);
        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);

    end;

    local procedure PrepareData()
    var
        BinContent: Record "Bin Content";
    begin
        RecRef.GetTable(BinContent);
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

