pageextension 69051 "ITI Warehouse Employee" extends "Warehouse Employees"
{

    layout
    {
        modify("ADCS User")
        {
            Enabled = false;

        }
        addafter(Default)
        {
            field(ADCSUser; Rec."ITI ADCS User")
            {
                ToolTip = 'Specifies the value of the ADCS User field.';
                ApplicationArea = All;

            }
        }
        // Add changes to page layout here
    }
}
