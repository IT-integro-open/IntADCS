/// <summary>
/// Constants used by the table data converter functionality.
/// </summary>
codeunit 69146 "ITIADCSDataConverterConstant"
{
    Access = Internal;

    /// <summary>
    /// Retrieves the JSON key for 'Table ID'.
    /// </summary>
    /// <returns>The 'Table ID' key.</returns>
    procedure TableID(): Text
    begin
        exit('Table ID');
    end;

    /// <summary>
    /// Retrieves the JSON key for 'Table Columns'.
    /// </summary>
    /// <returns>The 'Table Columns' key.</returns>
    procedure TableColumns(): Text
    begin
        exit('Table Columns');
    end;

    /// <summary>
    /// Retrieves the JSON key for 'Table Data'.
    /// </summary>
    /// <returns>The 'Table Data' key.</returns>
    procedure TableData(): Text
    begin
        exit('Table Data');
    end;
}