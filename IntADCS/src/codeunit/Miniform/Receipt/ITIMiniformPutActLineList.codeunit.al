codeunit 69051 "ITI Miniform PutActLine List"
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
        ADCSSetup: Record "ITI ADCS Setup";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        FunctionErr: Label 'Function not Found.';
        InputNodeErr: Label 'No input Node found.';
        DocumentErr: Label 'No Documents found.';
  RecordNotFoundErr: Label 'Record not found.';
  
        NoLinesErr: Label 'No Lines available.';
        AssignedErr: Label '%1 is assigned to %2.', Comment = '%1- Whse Activity Type, %2 - Whse Activity assigned user id';
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
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityLine2: Record "Warehouse Activity Line";

        RecordId: RecordId;
        TableNo: Integer;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := CopyStr(ReturnedNode.AsXmlElement().InnerText, 1, MaxStrLen(TextValue))
        else
            Error(InputNodeErr);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(WhseActivityLine);

              WhseActivityLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type");
            WhseActivityLine.SetRange("No.", WhseActivityLine."No.");
            ADCSSetup.Get(LocationFilter);
            if ADCSSetup."Filter Action Type" then
                case WhseActivityLine."Activity Type" of
                    WhseActivityLine."Activity Type"::Pick:
                        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
                    WhseActivityLine."Activity Type"::"Put-away":
                        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
                end;
            RecRef.GetTable(WhseActivityLine);
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
                    Remark := DocumentErr;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := DocumentErr;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                begin
                    ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
                    ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
                    MiniformHeader2.SaveXMLinExt(DOMxmlin);
                    Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                end;
            else
                Error(FunctionErr);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) then
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        RecordId: RecordId;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecordId) then begin
            RecRef.SetTable(WhseActivityHeader);
            WhseActivityLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
            WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
            WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
            ADCSSetup.Get(LocationFilter);
            if ADCSSetup."Filter Action Type" then
                case WhseActivityHeader.Type of
                    WhseActivityHeader.Type::Pick:
                        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
                    WhseActivityHeader.Type::"Put-away":
                        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
                end;
            if not WhseActivityLine.FindFirst() then begin
                ADCSMgt.SendError(NoLinesErr);
                exit;
            end;
            RecRef.GetTable(WhseActivityLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end else
            Error(RecordNotFoundErr);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

