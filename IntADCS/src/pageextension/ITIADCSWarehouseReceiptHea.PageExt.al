pageextension 69065 "ITI ADCS Warehouse Receipts" extends "Warehouse Receipts"
{
    layout
    {
        addafter("Location Code")
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
