tableextension 69054 "ITI Bin Content Buffer" extends "Bin Content Buffer"
{
    fields
    {
        field(69050; "ITI Description"; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(69051; "ITI Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        field(69052; "ITI User ID"; Code[20])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
        }
        field(69053; "ITI No. of Lines"; Text[50])
        {
            Caption = 'No. of Lines';
            DataClassification = CustomerContent;
        }

    }
}
