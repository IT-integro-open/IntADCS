pageextension 69050 "ITI Warehouse Employee List" extends "Warehouse Employee List"
{


    layout
    {
        modify("ADCS User")
        {
            Enabled = false;

        }
        addafter(Default)
        {
            field(ADCSUser; rec."ITI ADCS User")
            {
                ToolTip = 'Specifies the value of the ADCS User field.';
                ApplicationArea = All;

            }
        }
        // Add changes to page layout here
    }
}
