/// <summary>
/// Table ITI ADCS User (ID 50060).
/// </summary>
table 69052 "ITI ADCS User"
{
    Caption = 'ADCS User';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[50])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Password; Text[250])
        {
            Caption = 'Password';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                TESTFIELD(Password);
                Password := CalculatePassword(COPYSTR(Password, 1, 30));

            end;
        }
        field(3; "Full Name"; Text[80])
        {
            Caption = 'Full Name';
            DataClassification = CustomerContent;

        }
        field(10; "Allow Post Receipt"; Boolean)
        {
            Caption = 'Allow Post Receipt';
            DataClassification = CustomerContent;

        }
        field(20; "Allow Post Shipment"; Boolean)
        {
            Caption = 'Allow Post Shipment';
            DataClassification = CustomerContent;

        }

        field(30; Printer; text[250])
        {
            Caption = 'Printer';
            TableRelation = Printer;
            DataClassification = CustomerContent;

        }
        field(40; "Profile Id"; code[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Profile Id';
            TableRelation = "ITI ADCS Profile";
        }
                field(50; "Last Login Date"; Date)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Login Date';
        }
                field(60; "Last Login Time"; Time)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Login Time';
        }

    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TESTFIELD(Password);
    end;

    trigger OnModify()
    begin
        TESTFIELD(Password);
    end;

    trigger OnRename()
    begin
        ERROR(RenameIsNotAllowedErr);
    end;

    var
        RenameIsNotAllowedErr: Label 'You cannot rename the record.';

    /// <summary>
    /// CalculatePassword.
    /// </summary>
    /// <param name="Input">Text[30].</param>
    /// <returns>Return variable HashedValue of type Text[250].</returns>
    procedure CalculatePassword(Input: Text[30]) HashedValue: Text[250]
    var
        CryptographyManagement: codeunit "Cryptography Management";
    begin
        HashedValue := copystr(CryptographyManagement.GenerateHashAsBase64String(Input, 4), 1, 250);
    end;
}

