pageextension 69055 "ITI Put-away Template Subform" extends "Put-away Template Subform"
{
    layout
    {
        addafter("Find Empty Bin")
        {
            field("Find Default Bin"; Rec."ITI Find Default Bin")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Find Default Bin field.';
            }
            field("Find Additional Bin"; Rec."ITI Find Additional Bin")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Find Additional Bin field.';
            }

        }
    }


}
