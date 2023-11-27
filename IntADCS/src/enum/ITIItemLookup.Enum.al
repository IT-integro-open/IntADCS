enum 69060 "ITI Item Lookup"
{
    Extensible = true;

    value(0; "Item No.")
    {
        Caption = 'Item No.';
    }
    value(10; "EAN")
    {
        Caption = 'EAN', Locked = true;
        ;
    }
    value(20; "Item No. & EAN")
    {
        Caption = 'Item No. & EAN';
    }
}