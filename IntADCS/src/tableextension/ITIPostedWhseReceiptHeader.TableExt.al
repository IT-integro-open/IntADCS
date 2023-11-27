tableextension 69064 "ITI PostedWhseReceiptHeader" extends "Posted Whse. Receipt Header"
{
    fields
    {
        field(60050; "ITI Origin Type"; enum "ITI Origin Type")
        {
            Caption = 'Origin Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(60051; "ITI Origin No."; Code[20])
        {
            Caption = 'Origin No.';
            Editable = false;
            TableRelation = IF ("ITI Origin Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("ITI Origin Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("ITI Origin Type" = CONST(Location)) Location.Code;
            DataClassification = CustomerContent;
        }
        field(60052; "ITI Origin Description"; Text[50])
        {
            Caption = 'Origin Description';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(60053; "ITI Origin Description 2"; Text[50])
        {
            Caption = 'Origin Description 2';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}
