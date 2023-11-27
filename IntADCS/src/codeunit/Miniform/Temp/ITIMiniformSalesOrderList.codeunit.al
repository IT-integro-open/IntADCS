codeunit 69151 "ITI Miniform Sales Order List"
{
    TableNo = "ITI Miniform Header";

    var
        MiniformHeader2: Record "ITI Miniform Header";
        MiniformHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        DOMxmlin: XmlDocument;
        RecRef: RecordRef;
        ActiveInputField: Integer;
        ADCSUserId: Text[250];
        CurrentCode: Text[250];
        LocationFilter: Text[250];
        PreviousCode: Text[250];
        Remark: Text[250];
        StackCode: Text[250];
        TextValue: Text[250];
        WhseEmpId: Text[250];
        Text000: Label 'Function not Found.';
        Text006: Label 'No input Node found.';
        Text009: Label 'No Documents found.';
        Text50000: Label '%1 is assigned to %2.';
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
            PrepareData
        else
            ProcessSelection;

        Clear(DOMxmlin);
    end;


    local procedure ProcessSelection()
    var
        FuncGroup: Record "ITI Miniform Function Group";
        SalesHeader: Record "Sales Header";
        RecordId: RecordId;
        TableNo: Integer;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.AsXmlElement().InnerText
        else
            Error(Text006);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SETTABLE(SalesHeader);
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            RecRef.GETTABLE(SalesHeader);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := Text009;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := Text009;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                begin
                    ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
                    ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2, ADCSUserId);
                    MiniformHeader2.SaveXMLinExt(DOMxmlin);
                    Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                end;
            else
                Error(Text000);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if not SalesHeader.FindFirst() then begin
            if ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' then begin
                ADCSMgt.SendError(Text009);
                exit;
            end;
            ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
            MiniformHeader2.Get(PreviousCode);
            MiniformHeader2.SaveXMLinext(DOMxmlin);
            Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
        end else begin
            RecRef.GETTABLE(SalesHeader);
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
