pageextension 69063 "ITI Whse. Journal Batches List" extends "Whse. Journal Batches List"
{
    layout
    {
        addlast(content)
        {
            field(ITIADCSJournal; Rec."ITI ADCS Journal")
            {
                ApplicationArea = All;
            }
        }
    }

}
