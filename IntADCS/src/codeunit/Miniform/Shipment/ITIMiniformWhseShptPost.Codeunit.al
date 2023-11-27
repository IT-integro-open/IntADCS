codeunit 69110 "ITI Miniform Whse. Shpt Post"
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
            ProcessInput;

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        ADCSSetup: Record "ITI ADCS Setup";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        RecRef: Recordref;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
        ADCSUserId: Text[250];
        Remark: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found';
        Text012: Label 'No Lines available_BELL__BELL_';
        Text013: Label 'Shipment has to be connectet to at least one package_BELL__BELL_';

    local procedure ProcessInput()
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        //UserShipmentOrder: Record "50055";
        TableNo: Integer;
        RecordId: RecordID;
        FldNo: Integer;
        TextValue: Text[250];
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WarehouseShipmentLine);
            WarehouseShipmentLine.SETRANGE("No.", WarehouseShipmentLine."No.");
            IF UPPERCASE(TextValue) = 'TAK' THEN BEGIN
                Post(WarehouseShipmentLine);
                //OpenNextMiniform(DOMxmlin, TextValue, UserShipmentOrder.GET(WhseEmpId));
            END ELSE
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
        END ELSE BEGIN
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            EXIT;
        END;
    end;


    procedure Post(WarehouseShipmentLine2: Record "Warehouse Shipment Line")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        IF NOT WarehouseShipmentLine.GET(WarehouseShipmentLine2."No.", WarehouseShipmentLine2."Line No.") THEN
            ERROR(Text007);
        //WarehouseShipmentLine2.SetRange("No.", WarehouseShipmentLine2."No.");
        WarehouseShipmentLine2.AutofillQtyToHandle(WarehouseShipmentLine2);
        //WhseShptHeader.GET(WarehouseShipmentLine."No.");
        //WhseShptHeader."Posting User ID" := WhseEmpId;
        //WhseShptHeader.MODIFY;

        CLEAR(WhsePostShipment);
        WhsePostShipment.SetPostingSettings(FALSE);
        WhsePostShipment.SetPrint(TRUE);
        WhsePostShipment.RUN(WarehouseShipmentLine);
        //IF UserShipmentOrder.GET(WhseEmpId) THEN BEGIN
        //    UserShipmentOrder."Posted Whse. Shipment No." := WhsePostShipment.GetPostedSourceDocNo;
        //    UserShipmentOrder.MODIFY;
        // END;
    end;

    procedure OpenNextMiniform(var DOMxmlin: XmlDocument; TextValue: Text[250]; FromUserShipment: Boolean)
    var
        MiniformHeader2: Record "ITI Miniform Header";
        PreviousCode: Text[20];
    begin
        IF FromUserShipment THEN
            ADCSCommunication.GetCallMiniForm(MiniformHeader.Code, MiniformHeader2, TextValue)
        ELSE
            ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
        ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
        MiniformHeader2.SaveXMLinExt(DOMxmlin);
        CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;

    local procedure PrepareData()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TableNo: Integer;
        RecordId: RecordID;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        IF ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo') = '' THEN BEGIN
            /*   UserShipmentOrder.GET(WhseEmpId);
               WarehouseShipmentLine.SETRANGE("No.", UserShipmentOrder."Whse. Shipment No.");
           END ELSE BEGIN
               IF UserShipmentOrder.GET(WhseEmpId) THEN
                   UserShipmentOrder.DELETE;*/
            EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
            RecRef.OPEN(TableNo);
            EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
            IF RecRef.GET(RecordId) THEN BEGIN
                RecRef.SETTABLE(WarehouseShipmentHeader);
                WarehouseShipmentLine.SETRANGE("No.", WarehouseShipmentHeader."No.");
            END ELSE
                ERROR(Text007);
        END;

        IF NOT WarehouseShipmentLine.FINDFIRST THEN BEGIN
            ADCSMgt.SendError(Text012);
            EXIT;
        END;

        RecRef.GETTABLE(WarehouseShipmentLine);
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

