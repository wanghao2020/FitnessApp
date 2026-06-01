import { createStore } from "./state.js";
import { renderApp } from "./render.js";

const app = document.querySelector("#app");
const store = createStore();

function render() {
  renderApp(app, store);
}

store.subscribe(render);
render();
