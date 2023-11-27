codeunit 69101 "ITI Miniform WhseActLine"
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
            ProcessInput();

        Clear(DOMxmlin);
    end;

    var
        ADCSSetup: Record "ITI ADCS Setup";
        MiniformHeader: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        FunctionNotFoundLbl: Label 'Function not Found.';
        InvalidErr: Label 'Invalid %1.', Comment = '%1 - field';
        NoInputFoundErr: Label 'No input Node found.';
        RecordNotFoundErr: Label 'Record not found.';
        EndOfDocumentLbl: Label 'End of Document.';
        QtyErr: Label 'Qty. does not match.';
        InvalidQtyErr: Label 'Invalid Quantity.';
        NoLinesErr: Label 'No Lines available.';
        ItemInBinErr: Label 'There is no item %1 in bin %2._BELL__BELL_', Comment = '%1 - Item, %2 - Bin';
        BinBlockedErr: Label 'Bin is blocked._BELL__BELL_';
        SplitLineMsg: Label 'Line has been splited';
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
        ItemTrackingSetup: Record "Item Tracking Setup";
        FuncGroup: Record "ITI Miniform Function Group";
        WhseActivityLine: Record "Warehouse Activity Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RecordId: RecordId;
        FldNo: Integer;
        TableNo: Integer;
        TextValue: Text[250];

    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.AsXmlElement().InnerText
        else
            Error(NoInputFoundErr);
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
                begin
                    SplitLine(WhseActivityLine);
                    Remark := SplitLineMsg;
                end;
            //ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");

            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := EndOfDocumentLbl;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := EndOfDocumentLbl;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Reset:
                Reset(WhseActivityLine);
            FuncGroup.KeyDef::Register:
                begin
                    Register(WhseActivityLine);
                    if Remark = '' then
                        ADCSCommunication.RunPreviousMiniform(DOMxmlin)
                    else
                        SendForm(ActiveInputField);
                end;
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    case FldNo of
                        WhseActivityLine.FieldNo("Bin Code"):
                            begin
                                ADCSSetup.Get();
                                if (((WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Pick) and
                                     (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take)) or
                                    ((WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Put-away") and
                                     (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place)) or
                                    (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Movement))
                                then
                                    case WhseActivityLine."Activity Type" of
                                        WhseActivityLine."Activity Type"::Pick:
                                            if ADCSSetup."Allow Change Pick Bin" then
                                                CheckBinNoNew(WhseActivityLine, UpperCase(TextValue))
                                            else
                                                CheckBinNo(WhseActivityLine, UpperCase(TextValue));
                                        WhseActivityLine."Activity Type"::"Put-away":
                                            if ADCSSetup."Allow Change Put-Away Bin" then
                                                CheckBinNoNew(WhseActivityLine, UpperCase(TextValue))
                                            else
                                                CheckBinNo(WhseActivityLine, UpperCase(TextValue));
                                        WhseActivityLine."Activity Type"::Movement:
                                            CheckBinNoNew(WhseActivityLine, UpperCase(TextValue));
                                    end
                                else
                                    CheckBinNoNew(WhseActivityLine, UpperCase(TextValue));
                            end;
                        WhseActivityLine.FieldNo("Item No."):
                            CheckItemNo(WhseActivityLine, UpperCase(TextValue));
                        WhseActivityLine.FieldNo("Qty. to Handle"):
                            CheckQty(WhseActivityLine, TextValue);
                        WhseActivityLine.FieldNo("Lot No."):
                            CheckLotNo(WhseActivityLine, UpperCase(TextValue));
                        WhseActivityLine.FieldNo("Serial No."):
                            CheckSerialNo(WhseActivityLine, TextValue);
                        WhseActivityLine.FieldNo("Package No."):
                            CheckPackageNo(WhseActivityLine, TextValue);
                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(WhseActivityLine);
                        end;
                    end;

                    WhseActivityLine.Modify();
                    RecRef.GetTable(WhseActivityLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), FldNo);
                    if Remark = '' then begin
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseActivityLine.FieldNo("Lot No.")) = ActiveInputField + 1 then begin

                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseActivityLine."Item No.", ItemTrackingSetup);
                            if not ItemTrackingSetup."Lot No. Required" then begin
                                FldNo := WhseActivityLine.FieldNo("Lot No.");
                                ActiveInputField += 1;
                            end;
                        end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseActivityLine.FieldNo("Serial No.")) = ActiveInputField + 1 then begin

                            ItemTrackingMgt.GetWhseItemTrkgSetup(WhseActivityLine."Item No.", ItemTrackingSetup);
                            if not ItemTrackingSetup."Serial No. Required" then begin
                                FldNo := WhseActivityLine.FieldNo("Serial No.");
                                ActiveInputField += 1;
                            end;
                        end;
                        if ADCSCommunication.GetActiveInputNo(CopyStr(CurrentCode, 1, 20), WhseActivityLine.FieldNo("Qty. to Handle")) = ActiveInputField + 1 then
                            if (WhseActivityLine."Qty. to Handle" <> 0) and
                               ((WhseActivityLine."Serial No." <> '') or (WhseActivityLine."Lot No." <> ''))
                            then begin
                                FldNo := WhseActivityLine.FieldNo("Qty. to Handle");
                                ActiveInputField += 1;
                            end;
                        if ADCSCommunication.LastEntryField(CopyStr(CurrentCode, 1, 20), FldNo) then begin
                            ADCSSetup.Get();
                            if ((ADCSSetup."Automatic Pick Registration") and (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Pick)) or
                               ((ADCSSetup."Automatic Put-away Reg.") and (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Put-away")) or
                               ((ADCSSetup."Automatic Movment Reg.") and (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Movement))
                            then begin
                                if WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Movement then begin
                                    if WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place then
                                        Register(WhseActivityLine);
                                end else
                                    Register(WhseActivityLine);

                                RecRef.GetTable(WhseActivityLine);
                                if not ADCSCommunication.FindRecRef(6, MiniformHeader."No. of Records in List") then begin
                                    if (not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List")) and
                                       (not ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List"))
                                    then begin
                                        FuncGroup.KeyDef := FuncGroup.KeyDef::Register;
                                        ADCSCommunication.RunPreviousMiniform(DOMxmlin);
                                    end else
                                        ActiveInputField := 1
                                end else
                                    if (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Movement) then begin
                                        ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List");
                                        ActiveInputField := 1;
                                    end else
                                        ActiveInputField := 1;
                            end else begin
                                RecRef.GetTable(WhseActivityLine);
                                if not ADCSCommunication.FindRecRef(1, ActiveInputField) then begin
                                    Remark := EndOfDocumentLbl;
                                    if (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Movement) then
                                        ActiveInputField := 1;
                                end else
                                    ActiveInputField := 1;

                            end;
                        end else
                            ActiveInputField += 1;
                    end;
                end;
            else
                Error(FunctionNotFoundLbl);
        end;
        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);
    end;

    local procedure CheckBinNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    begin
        if InputValue = WhseActLine."Bin Code" then
            exit;

        Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Bin Code"));
    end;

    local procedure CheckItemNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        WhseActLine2: Record "Warehouse Activity Line";
        ITIADCSItemManagement: Codeunit "ITI ADCS Item Management";
        ItemNo: Code[20];
    begin
        if InputValue = WhseActLine."Item No." then
            exit;
        ITIADCSItemManagement.GetItemNo(WhseActLine."Item No.", InputValue, ItemNo);
        if ItemNo <> WhseActLine."Item No." then
            if WhseActLine."Activity Type" = WhseActLine."Activity Type"::"Put-away" then begin
                WhseActLine2.SetRange("No.", WhseActLine."No.");
                WhseActLine2.SetRange("Item No.", ItemNo);
                WhseActLine2.SetRange("Activity Type", WhseActLine."Activity Type");
                WhseActLine2.SetRange("Action Type", WhseActLine."Action Type");
                if WhseActLine2.FindFirst() then
                    WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.")
                else
                    Remark := StrSubstNo(InvalidErr, WhseActLine2.FieldCaption("Item No."));
            end else
                Remark := StrSubstNo(InvalidErr, WhseActLine2.FieldCaption("Item No."));
    end;

    local procedure CheckQty(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        QtyToHandle: Decimal;
    begin
        if InputValue = '' then begin
            Remark := InvalidQtyErr;
            exit;
        end;
        Evaluate(QtyToHandle, InputValue);
        if QtyToHandle = Abs(QtyToHandle) then begin
            CheckItemNo(WhseActLine, WhseActLine."Item No.");
            if QtyToHandle <= WhseActLine."Qty. Outstanding" then
                WhseActLine.Validate("Qty. to Handle", QtyToHandle)
            else
                Remark := InvalidQtyErr;
        end else
            Remark := InvalidQtyErr;
        if Remark = '' then begin
            WhseActLine."ITI User ID" := CopyStr(WhseEmpId, 1, MaxStrLen(WhseActLine."ITI User ID"));
            UpdateQtyInSecondLine(WhseActLine);
        end;
    end;

    local procedure Reset(var WhseActLine2: Record "Warehouse Activity Line")
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        if not WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") then
            Error(RecordNotFoundErr);

        Remark := '';
        WhseActLine.Validate("Qty. to Handle", 0);
        WhseActLine.Modify();

        RecRef.GetTable(WhseActLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
    end;

    local procedure Register(WhseActLine2: Record "Warehouse Activity Line")
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        if not WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") then
            Error(RecordNotFoundErr);
        if not BalanceQtyToHandle(WhseActLine) then
            Remark := QtyErr
        else begin
            WhseActivityRegister.ShowHideDialog(true);
            WhseActivityRegister.Run(WhseActLine);
        end;
    end;

    local procedure BalanceQtyToHandle(var WhseActivLine2: Record "Warehouse Activity Line"): Boolean
    var
        WhseActLine: Record "Warehouse Activity Line";
        QtyToPick: Decimal;
        QtyToPutAway: Decimal;
    begin
        WhseActLine.Copy(WhseActivLine2);
        WhseActLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type");
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type");
        WhseActLine.SetRange("No.", WhseActLine."No.");
        WhseActLine.SetRange("Action Type");
        if WhseActLine.Findset() then
            repeat
                WhseActLine.SetRange("Item No.", WhseActLine."Item No.");
                WhseActLine.SetRange("Variant Code", WhseActLine."Variant Code");
                WhseActLine.SetRange("Serial No.", WhseActLine."Serial No.");
                WhseActLine.SetRange("Lot No.", WhseActLine."Lot No.");
                WhseActLine.SetRange("Package No.", WhseActLine."Package No.");
                if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Take) or
                   (WhseActivLine2.GetFilter("Action Type") = '')
                then begin
                    WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Take);
                    if WhseActLine.Findset() then
                        repeat
                            QtyToPick := QtyToPick + WhseActLine."Qty. to Handle (Base)";
                        until WhseActLine.Next() = 0;
                end;

                if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Place) or
                   (WhseActivLine2.GetFilter("Action Type") = '')
                then begin
                    WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Place);
                    if WhseActLine.Findset() then
                        repeat
                            QtyToPutAway := QtyToPutAway + WhseActLine."Qty. to Handle (Base)";
                        until WhseActLine.Next() = 0;
                end;

                if QtyToPick <> QtyToPutAway then
                    exit(false);

                WhseActLine.SetRange("Action Type");
                WhseActLine.Findlast();
                WhseActLine.SetRange("Item No.");
                WhseActLine.SetRange("Variant Code");
                WhseActLine.SetRange("Serial No.");
                WhseActLine.SetRange("Lot No.");
                WhseActLine.SetRange("Package No.");
                QtyToPick := 0;
                QtyToPutAway := 0;
            until WhseActLine.Next() = 0;
        exit(true);
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
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;

    local procedure CheckBinNoNew(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        Bin: Record Bin;
        WhseActLine2: Record "Warehouse Activity Line";
    begin

        if not Bin.Get(WhseActLine."Location Code", InputValue) then begin
            Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Bin Code"));
            exit;
        end;

        if (WhseActLine."Bin Code" <> InputValue) then begin
            if WhseActLine."Action Type" = WhseActLine."Action Type"::Take then
                if not FindBinContent(
                  WhseActLine."Location Code", Bin.Code, WhseActLine."Item No.", WhseActLine."Variant Code", Bin."Zone Code", WhseActLine."Serial No.", WhseActLine."Lot No.", WhseActLine."Package No.")
                then begin
                    Remark := StrSubstNo(ItemInBinErr, WhseActLine."Item No.", WhseActLine."Bin Code");
                    exit;
                end;

            if Bin."Block Movement" = Bin."Block Movement"::Outbound then begin
                Remark := BinBlockedErr;
                exit;
            end;

            if Remark = '' then
                if WhseActLine."Activity Type" = WhseActLine."Activity Type"::Movement then begin
                    WhseActLine2.Reset();
                    WhseActLine2.SetRange("Activity Type", WhseActLine."Activity Type");
                    WhseActLine2.SetRange("No.", WhseActLine."No.");
                    WhseActLine2.SetRange("Action Type", WhseActLine."Action Type");
                    WhseActLine2.SetRange("Lot No.", WhseActLine."Lot No.");
                    if WhseActLine2.Count = 1 then begin
                        WhseActLine.Validate("Zone Code", '');
                        WhseActLine.Validate("Bin Code", InputValue);
                        if WhseActLine."Qty. to Handle" <> 0 then
                            CheckQty(WhseActLine, Format(WhseActLine."Qty. to Handle"));
                    end else
                        if WhseActLine2.FindSet() then
                            repeat
                                WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.");
                                WhseActLine.Validate("Zone Code", '');
                                WhseActLine.Validate("Bin Code", InputValue);
                                if WhseActLine."Qty. to Handle" <> 0 then
                                    CheckQty(WhseActLine, Format(WhseActLine."Qty. to Handle"));
                                WhseActLine.Modify();
                            until WhseActLine2.Next() = 0;
                end else begin
                    WhseActLine.Validate("Zone Code", '');
                    WhseActLine.Validate("Bin Code", InputValue);
                end;
        end else
            if (WhseActLine."Activity Type" = WhseActLine."Activity Type"::Movement) and
               (WhseActLine."Action Type" = WhseActLine."Action Type"::Place) and (WhseActLine."Qty. to Handle" <> 0)
            then
                CheckQty(WhseActLine, Format(WhseActLine."Qty. to Handle"));


    end;

    procedure FindBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]): Boolean
    var
        BinContent: Record "Bin Content";
    begin

        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        if LotNo <> '' then
            BinContent.SetRange("Lot No. Filter", LotNo);
        if SerialNo <> '' then
            BinContent.SetRange("Serial No. Filter", SerialNo);
        IF PackageNo <> '' then
            BinContent.SetRange("Package No. Filter", PackageNo);
        BinContent.SetFilter(Quantity, '<>%1', 0);
        exit(not BinContent.IsEmpty());
    end;

    local procedure CheckLotNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        WhseActLine2: Record "Warehouse Activity Line";
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Lot No."));
            exit;
        end;
        case WhseActLine."Activity Type" of
            WhseActLine."Activity Type"::"Put-away":
                begin
                    if InputValue = WhseActLine."Lot No." then begin
                        CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                        exit;
                    end;
                    WhseActLine2.SetRange("No.", WhseActLine."No.");
                    WhseActLine2.SetRange("Item No.", WhseActLine."Item No.");
                    WhseActLine2.SetRange("Activity Type", WhseActLine."Activity Type");
                    WhseActLine2.SetRange("Action Type", WhseActLine."Action Type");
                    WhseActLine2.SetRange("Lot No.", InputValue);
                    if WhseActLine2.FindFirst() then begin
                        WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.");
                        CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                    end else
                        Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Lot No."));
                end;
            WhseActLine."Activity Type"::Pick, WhseActLine."Activity Type"::Movement:
                if InputValue <> WhseActLine."Lot No." then
                    Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Lot No."));
        end;

    end;

    local procedure CheckPackageNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        WhseActLine2: Record "Warehouse Activity Line";
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Package No."));
            exit;
        end;
        case WhseActLine."Activity Type" of
            WhseActLine."Activity Type"::"Put-away":
                begin
                    if InputValue = WhseActLine."Package No." then begin
                        CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                        exit;
                    end;
                    WhseActLine2.SetRange("No.", WhseActLine."No.");
                    WhseActLine2.SetRange("Item No.", WhseActLine."Item No.");
                    WhseActLine2.SetRange("Activity Type", WhseActLine."Activity Type");
                    WhseActLine2.SetRange("Action Type", WhseActLine."Action Type");
                    WhseActLine2.SetRange("Package No.", InputValue);
                    if WhseActLine2.FindFirst() then begin
                        WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.");
                        CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                    end else
                        Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Package No."));
                end;
            WhseActLine."Activity Type"::Pick, WhseActLine."Activity Type"::Movement:
                if InputValue <> WhseActLine."Package No." then
                    Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Package No."));
        end;

    end;

    local procedure CheckSerialNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        WhseActLine2: Record "Warehouse Activity Line";
    begin
        if InputValue = '' then begin
            Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Serial No."));
            exit;
        end;
        case WhseActLine."Activity Type" of
            WhseActLine."Activity Type"::"Put-away":
                begin
                    if InputValue = WhseActLine."Serial No." then begin
                        CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                        exit;
                    end;
                    if WhseActLine."Activity Type" = WhseActLine."Activity Type"::"Put-away" then begin
                        WhseActLine2.SetRange("No.", WhseActLine."No.");
                        WhseActLine2.SetRange("Item No.", WhseActLine."Item No.");
                        WhseActLine2.SetRange("Activity Type", WhseActLine."Activity Type");
                        WhseActLine2.SetRange("Action Type", WhseActLine."Action Type");
                        WhseActLine2.SetRange("Serial No.", InputValue);
                        if WhseActLine2.FindFirst() then begin
                            WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.");
                            CheckQty(WhseActLine, Format(WhseActLine.Quantity));
                        end else
                            Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Serial No."));
                    end;
                end;
            WhseActLine."Activity Type"::Pick, WhseActLine."Activity Type"::Movement:
                begin
                    if (WhseActLine."Serial No." <> '') and (InputValue <> WhseActLine."Serial No.") then begin
                        Remark := StrSubstNo(InvalidErr, WhseActLine.FieldCaption("Serial No."));
                        exit;
                    end;
                    if not FindBinContent(
                       WhseActLine."Location Code", WhseActLine."Bin Code", WhseActLine."Item No.", WhseActLine."Variant Code", WhseActLine."Zone Code",
                       CopyStr(InputValue, 1, 50), '','')
                    then begin
                        Remark := StrSubstNo(ItemInBinErr, WhseActLine."Item No.", WhseActLine."Bin Code");
                        exit;
                    end;

                    WhseActLine.Validate("Serial No.", InputValue);
                end;
        end;
    end;

    local procedure UpdateQtyInSecondLine(WhseActLine2: Record "Warehouse Activity Line")
    var
        Item: Record Item;
        ADCSSetup: Record "ITI ADCS Setup";
        WhseActLine: Record "Warehouse Activity Line";
    begin
        ADCSSetup.Get();
        if (ADCSSetup."Filter Action Type" and
           (((WhseActLine2."Activity Type" = WhseActLine2."Activity Type"::Pick) and (WhseActLine2."Action Type" = WhseActLine2."Action Type"::Take)) or
           ((WhseActLine2."Activity Type" = WhseActLine2."Activity Type"::"Put-away") and (WhseActLine2."Action Type" = WhseActLine2."Action Type"::Place))))
        then begin
            WhseActLine.SetRange("No.", WhseActLine2."No.");
            WhseActLine.SetRange("Activity Type", WhseActLine2."Activity Type");
            WhseActLine.SetRange("ITI Take/Place Line No.", WhseActLine2."ITI Take/Place Line No.");
            WhseActLine.SetFilter("Action Type", '<>%1', WhseActLine2."Action Type");
            if WhseActLine.FindFirst() then begin
                if (WhseActLine2."Lot No." <> '') and (WhseActLine."Lot No." = '') then
                    WhseActLine.Validate("Lot No.", WhseActLine2."Lot No.");
                if (WhseActLine2."Serial No." <> '') and (WhseActLine."Serial No." = '') then
                    WhseActLine.Validate("Serial No.", WhseActLine2."Serial No.");

                if (WhseActLine2."Activity Type" = WhseActLine2."Activity Type"::"Put-away") and
                   (WhseActLine."Qty. per Unit of Measure" <> WhseActLine2."Qty. per Unit of Measure")
                then begin
                    Item.Get(WhseActLine2."Item No.");
                    WhseActLine.Validate("Qty. to Handle", Round(WhseActLine2."Qty. to Handle" * WhseActLine2."Qty. per Unit of Measure", Item."Rounding Precision"))
                end else
                    WhseActLine.Validate("Qty. to Handle", WhseActLine2."Qty. to Handle");
                WhseActLine."ITI User ID" := WhseActLine2."ITI User ID";
                WhseActLine.Modify()
            end;
        end;
    end;

    local procedure SplitLine(WarehouseActivLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivLine.SplitLine(WarehouseActivLine);
    end;
}

