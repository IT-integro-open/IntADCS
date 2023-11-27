tableextension 69055 "ITI Warehouse Shipment Header" extends "Warehouse Shipment Header"
{
    fields
    {
        field(69050; "ITI Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF CurrFieldNo <> 0 THEN BEGIN
                    CheckLinesExist(FIELDCAPTION("ITI Destination Type"));
                    "ITI Destination No." := '';
                    "ITI Destination Name" := '';
                    "ITI Destination Name 2" := '';

                end;
            end;
        }
        field(69051; "ITI Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = true;
            TableRelation = IF ("ITI Destination Type" = CONST(Customer)) Customer
            ELSE
            IF ("ITI Destination Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("ITI Destination Type" = CONST(Location)) Location
            ELSE
            IF ("ITI Destination Type" = CONST(Item)) Item
            ELSE
            IF ("ITI Destination Type" = CONST(Family)) Family
            ELSE
            IF ("ITI Destination Type" = CONST("Sales Order")) "Sales Header"."No." WHERE("Document Type" = CONST(Order));
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                TESTFIELD("ITI Destination Type");
                IF CurrFieldNo <> 0 THEN
                    CheckLinesExist(FIELDCAPTION("ITI Destination No."));
                CASE "ITI Destination Type" OF
                    "ITI Destination Type"::Customer:
                        IF Customer.GET("ITI Destination No.") THEN BEGIN
                            "ITI Destination Name" := Customer.Name;
                            "ITI Destination Name 2" := Customer."Name 2";
                        END;
                    "ITI Destination Type"::Vendor:
                        IF Vendor.GET("ITI Destination No.") THEN BEGIN
                            "ITI Destination Name" := Vendor.Name;
                            "ITI Destination Name 2" := Vendor."Name 2";
                        END;
                    "ITI Destination Type"::Location:
                        IF Location.GET("ITI Destination No.") THEN BEGIN
                            "ITI Destination Name" := Location.Name;
                            "ITI Destination Name 2" := Location."Name 2";
                        END;
                END;
            end;
        }
        field(69052; "ITI Destination Name"; Text[50])
        {
            Caption = 'Destination Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69053; "ITI Destination Name 2"; Text[50])
        {
            Caption = 'Destination Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69054; "ITI Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
            DataClassification = CustomerContent;
        }
        field(69055; "ITI Package Status"; Enum "ITI Package Status")
        {
            Caption = 'Package Status';
            Editable = true;
            DataClassification = CustomerContent;
        }
        field(69056; "ITI Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = IF ("ITI Destination Type" = CONST(Customer),
                                "ITI Destination No." = FILTER(<> '')) "Ship-to Address"."Code" WHERE("Customer No." = FIELD("ITI Destination No."));
            DataClassification = CustomerContent;
        }

    }
    local procedure CheckLinesExist(ChangedFieldName: Text)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SETRANGE("No.", "No.");
        IF NOT WarehouseShipmentLine.ISEMPTY THEN
            CASE ChangedFieldName OF
                FIELDCAPTION("ITI Destination Type"):
                    TESTFIELD("ITI Destination Type", xRec."ITI Destination Type");
                FIELDCAPTION("ITI Destination No."):
                    TESTFIELD("ITI Destination No.", xRec."ITI Destination No.");
            END;
    end;


    procedure GetPackageStatus(LineNo: Integer; PacStatus: Integer): Integer
    var
        WhseShptLine: Record 7321;
    begin

        WhseShptLine.SETRANGE("No.", "No.");
        IF LineNo <> 0 THEN
            WhseShptLine.SETFILTER("Line No.", '<>%1', LineNo);

        IF NOT WhseShptLine.FINDFIRST THEN
            EXIT(PacStatus);

        WhseShptLine.SETRANGE("ITI Package Status", WhseShptLine."ITI Package Status"::" ");
        IF WhseShptLine.FINDFIRST THEN
            EXIT(WhseShptLine."ITI Package Status"::"Partially Packed");


        WhseShptLine.SETRANGE("ITI Package Status", WhseShptLine."ITI Package Status"::"Partially Packed");
        IF WhseShptLine.FINDFIRST THEN
            EXIT(WhseShptLine."ITI Package Status");

        WhseShptLine.SETRANGE("ITI Package Status", WhseShptLine."ITI Package Status"::"Completely Packed");
        IF WhseShptLine.FINDFIRST THEN
            EXIT(WhseShptLine."ITI Package Status");

        EXIT(WhseShptLine."ITI Package Status"::" ");

    end;

}
