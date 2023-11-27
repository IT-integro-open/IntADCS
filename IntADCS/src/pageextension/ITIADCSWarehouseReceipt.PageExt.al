pageextension 69066 "ITI ADCS Warehouse Receipt" extends "Warehouse Receipt"
{
    layout
    {
        addafter("Document Status")
        {
            field(ITIOriginType; Rec."ITI Origin Type")
            {
                ApplicationArea = All;

            }
            field(ITIOriginNo; Rec."ITI Origin No.")
            {
                ApplicationArea = All;

            }
            field(ITIOriginDescription; Rec."ITI Origin Description")
            {
                ApplicationArea = All;

            }
            field(MyField; Rec."ITI Origin Description 2")
            {
                ApplicationArea = All;

            }

        }
    }
}
