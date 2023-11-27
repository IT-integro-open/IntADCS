pageextension 69052 "ITI Bin Contents" extends "Bin Contents"
{
    layout
    {
        addafter(Default)
        {
            field(ITIAdditional; Rec."ITI Additional")
            {
                ApplicationArea = Basic, Suite;
            }
            field(ITILotNo; Rec."ITI Lot No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field(ITISerialNo; Rec."ITI Serial No.")
            {
                ApplicationArea = Basic, Suite;
            }
            field(ITIEAN; Rec."ITI EAN")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
