table 69118 ITIADCSItemSearchTemplate
{
    DataClassification = ToBeClassified;
    Caption = 'Item Search Template';

    fields
    {
        field(1; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line No.';
        }
        field(10; "No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'No.';
        }
        field(15; "Vendor Item No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Item No.';
        }
        field(20; "Identifier No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Identifier No.';
        }
        field(25; "Reference No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Reference No.';
        }
        field(26; "Reference Type"; Enum "Item Reference Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Reference Type';
        }
        field(30; "Lot No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Lot No.';
        }
        field(35; "Package No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Package No.';
        }
        field(40; "Serial No."; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Serial No.';
        }     
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }
}