controladdin ITIADCSControl
{
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts = 'src/jsscript/ADCSMain.js';
    StyleSheets =
        'src/Stylesheet/ITIADCS.css';
    StartupScript = 'src/jsscript/ADCS.startupScript.js';

    event SendInputValue(InputContent: Text);
    event OpenPage()

    procedure loadContent(Content: Text; MakeSound: Boolean);
    procedure SelectFromList(No: Text);
    procedure NextPage();
}