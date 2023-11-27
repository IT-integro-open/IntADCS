table 69057 "ITI Miniform Line"
{
    Caption = 'Miniform Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Miniform Code"; Code[20])
        {
            Caption = 'Miniform Code';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "ITI Miniform Header".Code;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(11; "Area"; enum "ITI ADCS Area")
        {
            Caption = 'Area';
            DataClassification = CustomerContent;

        }
        field(12; "Field Type"; enum "ITI ADCS Field Type")
        {
            Caption = 'Field Type';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                IF "Field Type" = "Field Type"::Input THEN BEGIN
                    GetMiniFormHeader();
                    IF ((MiniFormHeader."Form Type" = MiniFormHeader."Form Type"::"Selection List") OR
                        (MiniFormHeader."Form Type" = MiniFormHeader."Form Type"::"Data List") or ((MiniFormHeader."Form Type" = MiniFormHeader."Form Type"::Document) and (Rec."Area" = Rec."Area"::Body)))
                    THEN
                        ERROR(NotAllowedErr, "Field Type", MiniFormHeader.FIELDCAPTION("Form Type"), MiniFormHeader."Form Type");
                END;
            end;
        }
        field(13; "Table No."; Integer)
        {
            Caption = 'Table No.';
            DataClassification = CustomerContent;
            TableRelation = "AllObjWithCaption"."Object ID" WHERE("Object Type" = CONST(table));

            trigger OnValidate()
            begin
                IF "Table No." <> 0 THEN BEGIN
                    Field.RESET();
                    Field.SETRANGE(TableNo, "Table No.");
                    Field.FINDFIRST();
                END ELSE
                    VALIDATE("Field No.", 0);
            end;
        }
        field(14; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                Field.RESET();
                Field.SETRANGE(TableNo, "Table No.");
                Field.TableNo := "Table No.";
                Field."No." := "Field No.";
                IF PAGE.RUNMODAL(PAGE::"ITI Fields", Field) = ACTION::LookupOK THEN
                    VALIDATE("Field No.", Field."No.");
            end;

            trigger OnValidate()
            begin
                IF "Field No." <> 0 THEN BEGIN
                    Field.GET("Table No.", "Field No.");
                    VALIDATE(Text, COPYSTR(Field."Field Caption", 1, MAXSTRLEN(Text)));
                    VALIDATE("Field Length", Field.Len);
                END ELSE BEGIN
                    VALIDATE(Text, '');
                    VALIDATE("Field Length", 0);
                END;
            end;
        }
        field(15; Text; Text[30])
        {
            Caption = 'Text';
            DataClassification = CustomerContent;
        }
        field(16; "Field Length"; Integer)
        {
            Caption = 'Field Length';
            DataClassification = CustomerContent;
        }
        field(21; "Call Miniform"; Code[20])
        {
            Caption = 'Call Miniform';
            DataClassification = CustomerContent;
            TableRelation = "ITI Miniform Header";

            trigger OnValidate()
            begin
                GetMiniFormHeader();
            end;
        }
    }

    keys
    {
        key(Key1; "Miniform Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Area")
        {
        }
    }

    fieldgroups
    {
    }

    var
        "Field": Record Field;
        MiniFormHeader: Record "ITI Miniform Header";
        NotAllowedErr: Label '%1 not allowed for %2 %3 in %4 area. ', comment = ' %1 - Field Type, %2 - FIELDCAPTION("Form Type"), %3 - "Form Type", %4';

    procedure GetMiniFormHeader()
    begin
        IF MiniFormHeader.Code <> "Miniform Code" THEN
            MiniFormHeader.GET("Miniform Code");
    end;
}

