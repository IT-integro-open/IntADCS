tableextension 69057 "ITI Warehouse Receipt Header" extends "Warehouse Receipt Header"
{
    fields
    {
        field(69050; "ITI Origin Type"; Enum "ITI Origin Type")
        {
            Caption = 'Origin Type';

            Editable = false;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF CurrFieldNo <> 0 THEN BEGIN
                    CheckLinesExist(FIELDCAPTION("ITI Origin Type"));
                    "ITI Origin No." := '';
                    "ITI Origin Description" := '';
                    "ITI Origin Description 2" := '';
                END;
            end;
        }
        field(69051; "ITI Origin No."; Code[20])
        {
            Caption = 'Origin No.';
            Editable = false;
            TableRelation = IF ("ITI Origin Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("ITI Origin Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("ITI Origin Type" = CONST(Location)) Location.Code;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var

                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                TESTFIELD("ITI Origin Type");
                IF CurrFieldNo <> 0 THEN
                    CheckLinesExist(FIELDCAPTION("ITI Origin No."));
                CASE "ITI Origin Type" OF
                    "ITI Origin Type"::Customer:
                        BEGIN
                            IF Customer.GET("ITI Origin No.") THEN BEGIN
                                "ITI Origin Description" := Customer.Name;
                                "ITI Origin Description 2" := Customer."Name 2";
                            END;
                        END;
                    "ITI Origin Type"::Vendor:
                        BEGIN
                            IF Vendor.GET("ITI Origin No.") THEN BEGIN
                                "ITI Origin Description" := Vendor.Name;
                                "ITI Origin Description 2" := Vendor."Name 2";
                            END;
                        END;
                    "ITI Origin Type"::Location:
                        BEGIN
                            IF Location.GET("ITI Origin No.") THEN BEGIN
                                "ITI Origin Description" := Location.Name;
                                "ITI Origin Description 2" := Location."Name 2";
                            END;
                        END;
                END;
            end;
        }
        field(69052; "ITI Origin Description"; Text[50])
        {
            Caption = 'Origin Description';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69053; "ITI Origin Description 2"; Text[50])
        {
            Caption = 'Origin Description 2';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69054; "ITI Partially Posted"; Boolean)
        {
            Caption = 'Partially Posted';
            Editable = true;
            DataClassification = CustomerContent;
        }
        field(69055; "ITI Completly Scaned"; Boolean)
        {
            CalcFormula = Min("Warehouse Receipt Line"."ITI Scanned" WHERE("No." = FIELD("No.")));
            Caption = 'Completly Scaned';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69056; "ITI Partially Scaned"; Boolean)
        {
            CalcFormula = Max("Warehouse Receipt Line"."ITI Scanned" WHERE("No." = FIELD("No.")));
            Caption = 'Partially Scaned';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69057; "ITI No. of Lines"; Integer)
        {
            CalcFormula = Count("Warehouse Receipt Line" WHERE("No." = FIELD("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
    }
    local procedure CheckLinesExist(ChangedFieldName: Text[100])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SETRANGE("No.", "No.");
        IF NOT WarehouseReceiptLine.ISEMPTY THEN
            CASE ChangedFieldName OF
                FIELDCAPTION("ITI Origin Type"):
                    TESTFIELD("ITI Origin Type", xRec."ITI Origin Type");
                FIELDCAPTION("ITI Origin No."):
                    TESTFIELD("ITI Origin No.", xRec."ITI Origin No.");
            END;
    end;
}
