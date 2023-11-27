function loadContent(content, MakeSound) {
  // Call the GetContent procedure in the codeunit
  var d1 = document.getElementById('controlAddIn');
  d1.innerHTML = "";
  d1.insertAdjacentHTML("beforeend", content);
  document.getElementById("ADCSInput").focus();

  if (MakeSound){
    Beep();
  }

  openFullScreen();

  document.body.onkeydown = function(e){
    const input = document.getElementById('ADCSInput');
    const keyList = document.getElementById('ADCSFunctionKeys').textContent.split(',');
    if (keyList.includes(e.code)) {
      e.preventDefault(); // Blokujemy standardowe działanie klawisza
      input.value = e.code; // Ustawiamy wartość inputa na kod klawisza
      NextPage();
    }else{
      switch (e.key){
        case 'Enter':
          document.getElementById('ADCSButton').click();
          break;
      }
    }
};
}

function SelectFromList(No){
document.getElementById('ADCSInput').value = No;
NextPage();
}

function setFunKey(FunName){
var input = document.getElementById(FunName);
input.addEventListener('keydown', function(e) {
  if (e.code != 'Backspace'){
    e.preventDefault(); // Blokujemy standardowe działanie klawisza
    input.value = e.code; // Ustawiamy wartość inputa na kod klawisza
  }
});
}

function NextPage(){
var InputContent = document.getElementById('ADCSInput').value;
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("SendInputValue", [InputContent]);
}

const play = (frequency = 300, duration = 1e3) => {
  const context = new AudioContext();
  const gainNode = context.createGain();
  const oscillator = context.createOscillator();
  oscillator.frequency.value = frequency;
  oscillator.connect(gainNode);
  gainNode.connect(context.destination);
  oscillator.start(0);
  setTimeout(() => oscillator.stop(), duration);
};

function Beep() {
  play(800, 1000);
}

function triggerFunction(FunName){
document.getElementById('ADCSInput').value = FunName;
NextPage();
}

function toggleMenu() {
var menu = document.querySelector('.ADCS-Menu');
menu.style.display = (menu.style.display === 'none') ? 'block' : 'none';
}

function openFullScreen(){
var frame = window.frameElement;
var parentFrame = top[0].frameElement.contentWindow.document;
frame.style = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: white; z-index: 1000;';
var buttons =  parentFrame.getElementsByTagName('button');

for(const button of buttons){
  if(button.className.includes('back-button')){
    button.style.display = "none"; 
  }
}
}
