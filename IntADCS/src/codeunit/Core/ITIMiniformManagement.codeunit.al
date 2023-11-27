codeunit 69059 "ITI Miniform Management"
{

    trigger OnRun()
    begin
    end;

    var
        NodeExistErr: Label 'The Node does not exist.';

    procedure ReceiveXML(xmlin: XmlDocument)
    var
        MiniFormHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSManagement: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";

        TextValue: Text;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
    begin
        DOMxmlin := xmlin;
        XMLDOMMgt.GetRootNode(DOMxmlin, RootNode);

        IF XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode) THEN BEGIN

            TextValue := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
            IF UPPERCASE(TextValue) = 'HELLO' THEN
                TextValue := ADCSCommunication.GetLoginFormCode();
            MiniFormHeader.GET(TextValue);
            MiniFormHeader.TESTFIELD("Handling Codeunit");
            MiniFormHeader.SaveXMLinExt(DOMxmlin);
            IF NOT CODEUNIT.RUN(MiniFormHeader."Handling Codeunit", MiniFormHeader) THEN
                ADCSManagement.SendError(GETLASTERRORTEXT);
        END ELSE
            ERROR(NodeExistErr);
    end;

    procedure Initialize(var MiniformHeader: Record "ITI Miniform Header"; var Rec: Record "ITI Miniform Header"; var DOMxmlin: XmlDocument; var ReturnedNode: XmlNode; var RootNode: XmlNode; var XMLDOMMgt: Codeunit "ITI XML DOM Management"; var ADCSCommunication: Codeunit "ITI ADCS Communication"; var ADCSUserId: Text; var CurrentCode: Text; var StackCode: Text; var WhseEmpId: Text; var LocationFilter: Text)
    begin
        MiniformHeader := Rec;
        MiniformHeader.LoadXMLinExt(DOMxmlin);
        XMLDOMMgt.GetRootNode(DOMxmlin, RootNode);
        XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode);
        CurrentCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
        StackCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'StackCode');
        ADCSUserId := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'LoginID');
        ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter);
    end;

    procedure MoveDown(var MiniformLine: Record "ITI Miniform Line")
    var
        MiniformLine2: Record "ITI Miniform Line";
        LastNo: Integer;
        NewNo: Integer;
        OldNo: Integer;
    begin
        MiniformLine.FindFirst();

        MiniformLine2.SetRange("Miniform Code", MiniformLine."Miniform Code");
        MiniformLine2.FindLast();
        LastNo := MiniformLine2."Line No." + 1;

        MiniformLine2.Reset();
        MiniformLine2.SetRange("Miniform Code", MiniformLine."Miniform Code");
        MiniformLine2.SetFilter("Line No.", '>%1', MiniformLine."Line No.");
        if MiniformLine2.FindFirst() then begin
            NewNo := MiniformLine2."Line No.";
            OldNo := MiniformLine."Line No.";
            MiniformLine2.Rename(MiniformLine2."Miniform Code", LastNo);
            MiniformLine.Rename(MiniformLine."Miniform Code", NewNo);
            MiniformLine2.Rename(MiniformLine2."Miniform Code", OldNo);
        end;
    end;

    procedure MoveUp(var MiniformLine: Record "ITI Miniform Line")
    var
        MiniformLine2: Record "ITI Miniform Line";
        LastNo: Integer;
        NewNo: Integer;
        OldNo: Integer;
    begin
        MiniformLine.FindFirst();
        MiniformLine2.SetRange("Miniform Code", MiniformLine."Miniform Code");
        MiniformLine2.FindLast();
        LastNo := MiniformLine2."Line No." + 1;

        MiniformLine2.Reset();
        MiniformLine2.SetRange("Miniform Code", MiniformLine."Miniform Code");
        MiniformLine2.SetFilter("Line No.", '<%1', MiniformLine."Line No.");
        if MiniformLine2.FindLast() then begin
            NewNo := MiniformLine2."Line No.";
            OldNo := MiniformLine."Line No.";
            MiniformLine2.Rename(MiniformLine2."Miniform Code", LastNo);
            MiniformLine.Rename(MiniformLine."Miniform Code", NewNo);
            MiniformLine2.Rename(MiniformLine2."Miniform Code", OldNo);
        end;
    end;

    procedure FillMiniformFunction(var MiniformHeader: Record "ITI Miniform Header")
    var
        MiniformFunction: Record "ITI Miniform Function";
        MiniformFunctionGroup: Record "ITI Miniform Function Group";
    begin
        MiniformFunction.SetRange("Miniform Code", MiniformHeader.Code);
        if MiniformFunction.IsEmpty then
            if MiniformFunctionGroup.FindSet() then
                repeat
                    MiniformFunction.Init();
                    MiniformFunction.Validate("Miniform Code", MiniformHeader.Code);
                    MiniformFunction.Validate("Function Code", MiniformFunctionGroup.Code);
                    MiniformFunction.Insert();
                until MiniformFunctionGroup.Next() = 0;
    end;
}

