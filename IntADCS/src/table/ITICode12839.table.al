table 69087 "ITI Code 128 39"
{
    Caption = 'Code 128/39';
    DataClassification = CustomerContent;

    fields
    {
        field(1; CharA; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(2; CharB; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(3; CharC; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Value"; Code[3])
        {
            DataClassification = CustomerContent;
        }
        field(5; Encoding; Code[20])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "CharA")
        {
        }
        key(Key2; Value)
        {
        }
    }
}

