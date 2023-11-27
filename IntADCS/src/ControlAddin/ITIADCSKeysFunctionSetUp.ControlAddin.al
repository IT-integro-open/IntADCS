controladdin "ITI ADCS Keys Function SetUp"
{
    RequestedHeight = 600;
    MinimumHeight = 300;
    MaximumHeight = 900;
    RequestedWidth = 700;
    MinimumWidth = 700;
    MaximumWidth = 700;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts =
        'src/jsscript/ADCSFunctionSetup.js';
    StartupScript = 'src/jsscript/ADCSKeysFunctionSetUp.startupScript.js';
    StyleSheets =
        'src/Stylesheet/ITIADCS.css';
    event OpenPage();
    event SaveFunctionMapping(HtmlContent: Text);

    procedure loadContent(Content: Text);
    procedure SaveMapping();

}