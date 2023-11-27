pageextension 69060 "ITI ADCS Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        addafter("Quantity")
        {
            field("ITI Qty. to Ship from Whse."; Rec."ITI Qty. to Ship from Whse.")
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;

            }
        }
    }
}
