pageextension 69059 "ITI ADCS Bins" extends "Bins"
{
    actions
    {
        addafter("&Contents")
        {
            action("ITI Print Bin")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Print Bin';
                Image = Print;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Print Bin action.';

                trigger OnAction()
                var
                    BinReport: Report "ITI Bin";
                    Bin: Record Bin;
                begin
                    Clear(BinReport);
                    CurrPage.SetSelectionFilter(Bin);
                    BinReport.SetTableView(Bin);
                    BinReport.RunModal();
                end;
            }
        }
    }
}