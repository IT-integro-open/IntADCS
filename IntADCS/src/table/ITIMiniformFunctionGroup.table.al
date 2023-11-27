table 69055 "ITI Miniform Function Group"
{
    Caption = 'Miniform Function Group';
    DataClassification = CustomerContent;
    LookupPageID = "ITI Functions";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(11; Description; Text[30])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(20; KeyDef; enum "ITI KeyDef")
        {
            Caption = 'KeyDef';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        MiniFunc.RESET();
        MiniFunc.SETRANGE("Function Code", Code);
        MiniFunc.DELETEALL();
    end;

    var
        MiniFunc: Record "ITI Miniform Function";
}

