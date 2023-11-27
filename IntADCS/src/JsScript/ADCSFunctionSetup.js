function loadContent(content) {
    // Call the GetContent procedure in the codeunit
    var d1 = document.getElementById('controlAddIn');
    d1.innerHTML = "";
    d1.insertAdjacentHTML("beforeend", content);
}


function setFunKey(){
    var input = document.getElementById('ADCSKeyInput');
    input.addEventListener('keydown', function(e) {
      if (e.code != 'Backspace'){
        e.preventDefault(); // Blokujemy standardowe działanie klawisza
        input.value = e.code; // Ustawiamy wartość inputa na kod klawisza
      }
    });
  }

function SaveMapping(){
    var value = document.getElementById('ADCSKeyInput').value;
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('SaveFunctionMapping', [value]);
}