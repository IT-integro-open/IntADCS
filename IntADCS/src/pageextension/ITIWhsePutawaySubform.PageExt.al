pageextension 69058 "ITI Whse. Put-away Subform" extends "Whse. Put-away Subform"
{
    layout
    {

        addafter("Cross-Dock Information")
        {
            field("ITI Default Bin Code"; Rec."ITI Default Bin Code")
            {
                ApplicationArea = Basic, Suite;
            }
            field("ITI Qty. Avail. to Put in Def. Bin"; Rec."ITI QtyAvailtoPutinDefBin")
            {
                ApplicationArea = Basic, Suite;
            }
            field("ITI Additional Bin Code"; Rec."ITI Additional Bin Code")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
