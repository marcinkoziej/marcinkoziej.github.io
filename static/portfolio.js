// https://www.geeksforgeeks.org/html/draggable-element-using-javascript/

function onMouseDrag(event, element) {
  const quantize = (value, quant) => Math.floor(value / quant) * quant;

  const leftValue = parseInt(window.getComputedStyle(element).left);
  const topValue = parseInt(window.getComputedStyle(element).top);

  let deltaLeft = parseFloat(element.dataset.remLeft) + event.movementX;
  let deltaLeftQ = quantize(deltaLeft, 10);
  element.dataset.remLeft = deltaLeft - deltaLeftQ;

  let deltaTop = parseFloat(element.dataset.remTop) + event.movementY;
  let deltaTopQ = quantize(deltaTop, 10);
  element.dataset.remTop = deltaTop - deltaTopQ;

  // Calculate new positions
  let newLeft = leftValue + deltaLeftQ;
  let newTop = topValue + deltaTopQ;

  // // Get parent container dimensions
  // const parent = element.parentElement;
  // const parentWidth = parent.clientWidth;
  // const parentHeight = parent.clientHeight;
  // const elementWidth = element.offsetWidth;
  // const elementHeight = element.offsetHeight;

  // // Apply constraints
  // newLeft = Math.max(0, newLeft); // No negative values
  // newTop = Math.max(0, newTop);   // No negative values

  // // Don't overflow parent container
  // newLeft = Math.min(newLeft, parentWidth - elementWidth);
  // newTop = Math.min(newTop, parentHeight - elementHeight);

  element.style.left = `${newLeft}px`;
  element.style.top = `${newTop}px`;
}

function raise(element, peerSelector) {
  const peers = [...element.parentNode.children].filter(child => child.matches(peerSelector) && child != element);
  console.log(peers);

  const peersWithZ = peers.map(p => [p, window.getComputedStyle(p)['z-index']])
  let maxZ = 0;
  peersWithZ.sort((a,b) => parseInt(a[1]) - parseInt(b[1]))
  for (const i in peersWithZ) {
    console.log(peersWithZ[i])
    peersWithZ[i][0].style['z-index'] = i;
    maxZ = i;
  }
  element.style['z-index'] = maxZ + 1;

}

export const draggable = (element, handleSelector, peerSelector) => {
  const handles = element.querySelectorAll(handleSelector);

  handles.forEach((handle) => {
    handle.addEventListener("mousedown", (e) => {
      raise(element, peerSelector);
      element.dataset.remLeft = 0;
      element.dataset.remTop = 0;
      document.body.classList.add("no-select");
      const onMove = (event) => onMouseDrag(event, element);

      document.addEventListener("mousemove", onMove);
      document.addEventListener("mouseup", () => {
        document.removeEventListener("mousemove", onMove);
        document.body.classList.remove("no-select");
      }, { once: true });
    });
  });
};
