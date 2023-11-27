pageextension 69057 "ITI ADCS Item List" extends "Item List"
{
    layout
    {
        addafter("Base Unit of Measure")
        {
            field("ITI EAN"; Rec."ITI EAN")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the EAN field.';
            }
        }
    }
    actions
    {
        addlast(Reports)
        {
            action("ITI Print Item Label")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print Item Label';
                Image = Print;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Print Item Label action.';

                trigger OnAction()
                var
                    ItemLabel: Report "ITI Item Label";
                begin
                    Clear(ItemLabel);
                    CurrPage.SetSelectionFilter(Rec);
                    ItemLabel.SetTableView(Rec);
                    ItemLabel.RunModal();
                    Rec.Reset();
                end;
            }
        }
    }
}
