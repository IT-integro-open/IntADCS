table 69051 "ITI ADCS Setup"
{
    Caption = 'ADCS Setup';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(10; "Use ADCS"; Boolean)
        {
            Caption = 'Use ADCS';
            DataClassification = CustomerContent;

        }
        field(20; "Filter Action Type"; Boolean)
        {
            Caption = 'Filter Action Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF NOT "Filter Action Type" THEN BEGIN
                    "Automatic Pick Registration" := FALSE;
                    "Automatic Put-away Reg." := FALSE;
                END;
            end;
        }
        field(30; "Allow Change Pick Bin"; Boolean)
        {
            Caption = 'Allow Change Pick Bin';
            DataClassification = CustomerContent;
        }
        field(40; "Allow Change Put-Away Bin"; Boolean)
        {
            Caption = 'Allow Change Put-Away Bin';
            DataClassification = CustomerContent;
        }
        field(50; "Automatic Pick Registration"; Boolean)
        {
            Caption = 'Automatic Pick Registration';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF "Automatic Pick Registration" THEN
                    TESTFIELD("Filter Action Type", TRUE);
            end;
        }
        field(60; "Automatic Put-away Reg."; Boolean)
        {
            Caption = 'Automatic Put-away Registration';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF "Automatic Put-away Reg." THEN
                    TESTFIELD("Filter Action Type", TRUE);
            end;
        }
        field(70; "Sorting Method"; enum "Whse. Activity Sorting Method")
        {
            Caption = 'Sorting Method';
            DataClassification = CustomerContent;
        }
        field(80; "Automatic Close Package"; Boolean)
        {
            Caption = 'Automatic Close Package';
            DataClassification = CustomerContent;
        }
        field(90; "Automatic Movment Reg."; Boolean)
        {
            Caption = 'Automatic Movment Registration';
            DataClassification = CustomerContent;
        }
        field(110; "Post Receipt Line"; Boolean)
        {
            Caption = 'Post Receipt Line';
            DataClassification = CustomerContent;
        }
        field(120; "Assign Whse. Empl. to Put-Away"; Boolean)
        {
            Caption = 'Assign Whse. Empl. to Put-Away';
            DataClassification = CustomerContent;
        }
        field(130; "Automatic Post Production"; Boolean)
        {
            Caption = 'Automatic Post Production';
            DataClassification = CustomerContent;
        }
        field(320; "Item Lookup"; Enum "ITI Item Lookup")
        {
            Caption = 'Item Lookup';
            DataClassification = CustomerContent;
        }

    }
    keys
    {
        key(PK; "Location Code")
        {
            Clustered = true;
        }
    }
}
