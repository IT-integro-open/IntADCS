codeunit 69104 "ITI Miniform Whse. Rcpt List"
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
        DocumentsErr: Label 'No Documents found.';
        InputErr: Label 'No input Node found.';
        NotFoundErr: Label 'Function not Found.';
        ADCSUserId: Text[250];
        CurrentCode: Text[250];
        LocationFilter: Text[250];
        PreviousCode: Text[250];
        Remark: Text[250];
        StackCode: Text[250];
        TextValue: Text[250];
        WhseEmpId: Text[250];
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure ProcessSelection()
    var
        FuncGroup: Record "ITI Miniform Function Group";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        RecordId: RecordId;
        TableNo: Integer;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputErr);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(WhseRcptHeader);
            WhseRcptHeader.SetCurrentKey("No.");
            WhseRcptHeader.SetFilter("Assigned User ID", '%1|%2', WhseEmpId, '');
            WhseRcptHeader.SetFilter("Location Code", LocationFilter);
            WhseRcptHeader.SetRange("ITI Completly Scaned", false);
            WhseRcptHeader.SetRange("ITI Partially Posted", false);
            RecRef.GetTable(WhseRcptHeader);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                begin
                    WhseRcptHeader.Validate("Assigned User ID", '');
                    WhseRcptHeader.Modify();
                    ADCSCommunication.RunPreviousMiniform(DOMxmlin);
                end;
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := DocumentsErr;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := DocumentsErr;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                begin
                    WhseRcptHeader.Validate("Assigned User ID", WhseEmpId);
                    WhseRcptHeader.Modify();
                    ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
                    ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
                    MiniformHeader2.SaveXMLinExt(DOMxmlin);
                    Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                end;
            else
                Error(NotFoundErr);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
    begin
        WhseRcptHeader.Reset();
        if WhseEmpId <> '' then begin
            WhseRcptHeader.SetFilter("Assigned User ID", '%1|%2', WhseEmpId, '');
            WhseRcptHeader.SetFilter("Location Code", LocationFilter);
        end;

        if not WhseRcptHeader.FindFirst() then begin
            if ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' then begin
                ADCSMgt.SendError(DocumentsErr);
                exit;
            end;
            ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
            MiniformHeader2.Get(PreviousCode);
            MiniformHeader2.SaveXMLinExt(DOMxmlin);
            Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
        end else begin
            RecRef.GetTable(WhseRcptHeader);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end;
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

