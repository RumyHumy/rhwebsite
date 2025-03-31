//importScripts("/lib/pyodide/pyodide.js");
importScripts("https://cdn.jsdelivr.net/pyodide/v0.27.4/full/pyodide.js");

async function loadPyodideAndPackages() {
	self.pyodide = await loadPyodide({
		stdout: (text) => { postMessage({ type: 'print', data: text }); },
		stderr: (text) => { postMessage({ type: 'print', data: text }); },
	});
	postMessage({ type: 'loaded' });
}
loadPyodideAndPackages()

self.onmessage = async (event) => {
	if (!self.pyodide)
		return;
	var { code } = event.data;
	try {
		await self.pyodide.runPythonAsync("import js\njs.pyodide.globals.clear()\n");
		const result = await self.pyodide.runPythonAsync(code);
		if (result !== undefined) {
			postMessage({ type: 'result', data: result });
		}
	} catch (error) {
		postMessage({ type: 'error', data: error.message });
	}
};
